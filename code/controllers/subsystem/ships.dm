GLOBAL_LIST_EMPTY(ship_control_consoles)

SUBSYSTEM_DEF(ship)
	name = "Ships"
	init_order = INIT_ORDER_SHIPS
	wait = 10

	var/list/ships = list()

	var/list/star_factions = list()
	var/list/ship_components = list()
	var/list/ship_types = list()
	var/list/ship_weight_list = list()

	var/alert_sound = 'sound/machines/warning-buzzer.ogg'
	var/success_sound = 'sound/machines/ping.ogg'
	var/error_sound = 'sound/machines/buzz-sigh.ogg'
	var/notice_sound = 'sound/machines/twobeep.ogg'

/datum/controller/subsystem/ship/Initialize(timeofday)
	init_datums()

/datum/controller/subsystem/ship/proc/init_datums()
	var/list/factions = subtypesof(/datum/star_faction)

	for(var/i in factions)
		star_factions += new i

	var/list/components = subtypesof(/datum/component)

	for(var/i in components)
		ship_components += new i

	var/list/ships = subtypesof(/datum/starship)

	for(var/i in ships)
		ship_types += new i

	for(var/datum/starship/ship in ship_types)
		ship_weight_list[ship.type] = ship.faction[2]

/datum/controller/subsystem/ship/fire()
	process_ships()

/datum/controller/subsystem/ship/proc/process_ships()
	for(var/datum/starship/S in ships)
		calculate_component_damage_effects(S)
		if(S.faction == SHIP_PLAYERSHIP)
			return
		repair_tick(S)
		if(S.target)
			attack_tick(S)
		ship_ai(S) //not done

/datum/controller/subsystem/ship/proc/calculate_component_damage_effects(var/datum/starship/S)
	for(var/i in S.components)
		var/datum/ship_component/weapon/W  = i
		W.fire_rate = round(initial(W.fire_rate) * round(initial(W.health) / W.Health)) //Changes fire rate dependent on how damaged the weapon is
	S.evasion_chance = round(initial(S.evasion_chance) * total_component_damage(SHIP_ENGINES,S)) //Lowers evasion chance based on active component coefficent
	S.recharge_rate = round(initial(S.recharge_rate) * total_component_damage_inverse(SHIP_SHIELDS,S)) //Lowers repair time based on active component coefficent
	S.component_repair_amount = round(initial(S.component_repair_amount) * total_component_damage(SHIP_REPAIR,S)) //Lowers repair amount based on active component coefficent
	if(!total_component_damage(SHIP_CONTROL, S))
		S.evasion_chance = 0 //if you take out the bridge, they lose all evasion

/datum/controller/subsystem/ship/proc/repair_tick(var/datum/starship/S)
	var/old_shields = S.shield_strength
	if(world.time > S.next_recharge && S.recharge_rate) //Check if shields can recharge yet
		S.next_recharge = world.time + S.recharge_rate
		S.shield_strength = min(initial(S.shield_strength), S.shield_strength + S.shield_charge_amount)
		if(S.shield_strength >= initial(S.shield_strength) && S.shield_strength > old_shields)
			broadcast_message("<span class=notice>[faction2prefix(S)] ship ([S.name]) has recharged shields to 100% strength.</span>",notice_sound,S)

	if(!check_broken_componentss(S)) //Nothing is broken, don't start repairs
		S.next_repair = world.time + S.repair_time

	if(world.time > S.next_repair && S.repair_time) //Check if we can repair yet
		S.next_repair = world.time + S.repair_time
		if(check_broken_componentss(S)) //pick a broken component to fix
			var/datum/component/C = pick(get_damaged_components(S))
			C.adjust_health(S.component_repair_amount)
			broadcast_message("<span class=notice>[faction2prefix(S)] ship ([S.name]) has repaired [C.name] at ([C.x_loc],[C.y_loc]).</span>",notice_sound,S)

/datum/controller/subsystem/ship/proc/attack_tick(var/datum/starship/S)
	for(var/i in S.components)
		var/datum/ship_component/weapon/W = i
		if(world.time > W.next_attack && W.fire_rate)
			W.next_attack = world.time + W.fire_rate + rand(1,25)
			if(S.attacking_station)
				attack_station(S, W)
			else
				attack_ship(S.attacking_target, S, W)

/datum/controller/subsystem/ship/proc/ship_ai(var/datum/starship/S)
	S.combat_ai.fire(S)

/datum/controller/subsystem/ship/proc/attack_ship(var/datum/starship/defender, var/datum/starship/attacker, var/datum/ship_component/weapon/W)
	if(isnull(defender)) // fix for runtime
		return
	damage_ship(get_targetable_components(defender), W.attack_data, attacker)

/datum/controller/subsystem/ship/proc/damage_ship(var/datum/component/C, var/datum/ship_attack/attack_data, var/datum/starship/attacking_ship = null)
	var/datum/starship/defending_ship = C.ship
	adjust_relationship(defending_ship.faction, attacking_ship.faction, -5)

	if(attacking_ship)
		broadcast_message("<span class=notice>[faction2prefix(attacking_ship)] ship ([attacking_ship.name]) firing on [faction2prefix(defending_ship)] ship ([defending_ship.name]).",null)
	if(prob(defending_ship.evasion_chance * attack_data.evasion_mod))
		broadcast_message("<span class=notice>Shot missed! [faction2prefix(defending_ship)] ship ([defending_ship.name]) evaded it!</span>",error_sound,defending_ship)
	else
		broadcast_message("<span class=notice>Shot hit! ([defending_ship.name])</span>",success_sound,defending_ship)
	if(defending_ship.shield_strength >= 1 && !attack_data.shield_bust)
		defending_ship.shield_strength = max(defending_ship.shield_strength - attack_data.hull_damage, 0)
		defending_ship.next_recharge = world.time + defending_ship.recharge_rate
		if(defending_ship.shield_strength <= 0)
			broadcast_message("<span class=notice>Shot hit [faction2prefix(defending_ship)] shields. [faction2prefix(defending_ship)] ship ([defending_ship.name]) shields were lowered!</span>",notice_sound,defending_ship)
		else
			broadcast_message("<span class=notice>Shot hit [faction2prefix(defending_ship)] shields. [faction2prefix(defending_ship)] ship shields are at [defending_ship.shield_strength / initial(defending_ship.shield_strength) * 100]%!</span>",notice_sound)

	if(defending_ship.hull_integrity > 0)
		defending_ship.hull_integrity = max(defending_ship.hull_integrity - attack_data.hull_damage,0)

		var/old_component_health = C.health
		C.health = max(C.health - attack_data.hull_damage, 0)

		if(!C.is_active())
			if(old_component_health != old_component_health)
				broadcast_message("<span class=notice>Shot hit [faction2prefix(defending_ship)] hull ([defending_ship.name]). [faction2prefix(defending_ship)] ship's [C.name] destroyed at ([C.x_loc],[C.y_loc]). [faction2prefix(defending_ship)] ship's hull integrity is at [defending_ship.hull_integrity].</span>",notice_sound,defending_ship)
			else
				broadcast_message("<span class=notice>Shot hit [faction2prefix(defending_ship)] hull ([defending_ship.name]). [faction2prefix(defending_ship)] ship's [C.name] was hit at ([C.x_loc],[C.y_loc]) but was already destroyed. [faction2prefix(defending_ship)] ship's hull integrity is at [defending_ship.hull_integrity].</span>",notice_sound,defending_ship)
		else
			broadcast_message("<span class=notice>Shot hit [faction2prefix(defending_ship)] hull ([defending_ship.name]). [faction2prefix(defending_ship)] ship's [C.name] damaged at ([C.x_loc],[C.y_loc]). [faction2prefix(defending_ship)] ship's hull integrity is at [defending_ship.hull_integrity].</span>",notice_sound,defending_ship)

	else if(!defending_ship.destroyed)
		defending_ship.destroyed = TRUE
		destroy_ship(defending_ship)

/datum/controller/subsystem/ship/proc/attack_station(var/datum/starship/S, var/datum/ship_component/weapon/W) //placeholder
	broadcast_message("<span class=warning>Enemy ship ([S.name]) fired their [W.name] at the station and hit! Hit location: .</span>",error_sound)

/datum/controller/subsystem/ship/proc/destroy_ship(var/datum/starship/S)
	message_admins("[S.name] was destroyed by damage.")
	broadcast_message("<span class=notice>[faction2prefix(S)] ship ([S.name]) reactor going supercritical! [faction2prefix(S)] ship destroyed!</span>", success_sound)

	qdel(S)

/datum/controller/subsystem/ship/proc/create_ship(var/datum/starship/starship, var/faction)
	ASSERT(faction && starship)

	var/datum/starship/S = new starship.type(1)
	var/datum/star_faction/mother_faction = id2faction(faction)
	S.faction = faction

	return S

/datum/controller/subsystem/ship/proc/broadcast_message(var/message, var/sound)
	for(var/obj/machinery/computer/ship_control/C in GLOB.ship_control_consoles)
		C.status_update(message,sound)
	for(var/mob/living/silicon/aiPlayer in GLOB.player_list)
		to_chat(aiPlayer, message)

/datum/controller/subsystem/ship/proc/spool_ftl(var/datum/starship/S)//placeholder
	if(S.is_jumping)
		return //Don't spool up when we're already in transit, for the love of all things holy
	broadcast_message("<span class=notice>[SSship.faction2prefix(S)] ship ([S.name]) detected powering up FTL drive. FTL jump imminent.</span>",SSship.notice_sound,S)
	S.is_jumping = 1

/datum/controller/subsystem/ship/proc/distress_call(var/datum/starship/caller, var/chance = 25) //placeholder
	if(prob(chance))
		return
	broadcast_message("<span class=notice>[SSship.faction2prefix(caller)] communications intercepted from [SSship.faction2prefix(caller)] ship ([caller.name]). Distress signal to [caller.faction] fleet command decrypted.</span>",SSship.alert_sound,caller)

///////Helpers///////
///////Factions///////
/datum/controller/subsystem/ship/proc/faction2list(var/faction)
	var/list/f_ships = list()
	for(var/datum/starship/S in SSship.ship_types)
		if(S.faction[1] == faction || S.faction[1] == "neutral" || faction == "pirate") //If it matches the faction we're looking for or has no faction (generic neutral ship), or for pirates, any ship
			var/N = new S.type
			f_ships += N
			f_ships[N] = S.faction[2]

	return f_ships

/datum/controller/subsystem/ship/proc/id2faction(var/faction)
	ASSERT(istext(faction))
	for(var/datum/star_faction/F in SSship.star_factions)
		if(F.id == faction) return F

/datum/controller/subsystem/ship/proc/faction2prefix(var/datum/starship/S)
	if(!S) //Runtimes are bad
		return "Unknown"
	if(S.faction(SHIP_PLAYERSHIP))
		return "Your"
	switch(check_relationship(S.faction, SHIP_PLAYERSHIP))
		if(SHIP_ALLIED_RELATIONSHIP to SHIP_MAX_RELATIONSHIP)
			return "Allied"
		if(SHIP_HOSTILE_RELATIONSHIP to SHIP_ALLIED_RELATIONSHIP)
			return "Neutral"
		if(SHIP_MIN_RELATIONSHIP to SHIP_ALLIED_RELATIONSHIP)
			return "Enemy"

///////Faction relationships///////
/datum/controller/subsystem/ship/proc/check_relationship(var/faction1, var/faction2)
	var/datum/star_faction/factionA = faction1
	for(var/i in factionA.relations)
		if(i == faction2)
			return factionnA.relations[i]

/datum/controller/subsystem/ship/proc/is_hostile(var/faction1, var/faction2)
	if(SHIP_HOSTILE_RELATIONSHIP > check_relationship(faction1, faction2))

/datum/controller/subsystem/ship/proc/adjust_relationship(var/faction1, var/faction2, var/amount) //Changes faction1's opinion of faction2
	var/datum/star_faction/factionA = id2faction(faction1)
	for(var/i in factionA.relations)
		if(i == faction2)
			factionA.relations[i] = Clamp(factionA.relations[i] + amount, SHIP_MIN_RELATIONSHIP, SHIP_MAX_RELATIONSHIP)

/datum/controller/subsystem/ship/proc/set_relationship(var/faction1, var/faction2, var/amount)
	var/datum/star_faction/factionA = id2faction(A)
	for(var/i in factionA.relations)
		if(i == faction2)
			factionA.relations[i] = Clamp(amount, SHIP_MAX_RELATIONSHIP, SHIP_MAX_RELATIONSHIP)

///////Ship components///////
/datum/controller/subsystem/ship/proc/get_attacks(var/datum/starship/S) //Returns a list off all available attacks on a ship
	var/list/available_attacks = list()
	for(var/i in S.components)
		var/datum/ship_component/weapon/W = i
		if(W.attack_data && W.active)
			available_attacks += W.attack_data

			return available_attacks

/datum/controller/subsystem/ship/proc/id2ship_component(var/string)
	ASSERT(istext(string))
	for(var/i in SSship.ship_components)
		var/datum/ship_component/C = i
		if(C.id == string)
			return C

/datum/controller/subsystem/ship/proc/total_component_damage(var/flag, var/datum/starship/S) //Returns the ratio of broken components
	if(!component_amount(flag,S))
		return 0 //No dividing by 0.
	return active_component_amount(flag,S) / component_amount(flag,S)

/datum/controller/subsystem/ship/proc/total_component_damage_inverse(var/flag, var/datum/starship/S) //Returns the inverse of the ratio of broken components
	if(!active_component_amount(flag,S))
		return 0 //No dividing by 0.
	return component_amount(flag,S) / active_component_amount(flag,S)

/datum/controller/subsystem/ship/proc/component_amount(var/flag, var/datum/starship/S)  //Amount of components with a certain flag
	var/comp_numb = 0
	for(var/i in S.ship_components)
		var/datum/ship_component/C = i
		if(C.flags & flag)
			comp_numb++

	return comp_numb

/datum/controller/subsystem/ship/proc/active_component_amount(var/flag,var/datum/starship/S) //Amount of components with a certain flag that are functioning
	var/comp_numb = 0
	for(var/i in S.ship_components)
		var/datum/ship_component/C = i
		if((C.flags & flag) && C.is_active())
			comp_numb++

	return comp_numb

/datum/controller/subsystem/ship/proc/check_broken_components(var/datum/starship/S) //Returns true if any components are broken
	for(var/i in S.ship_components)
		var/datum/ship_component/C = i
		if(!C.is_active())
			return TRUE

/datum/controller/subsystem/ship/proc/get_damaged_components(var/datum/starship/S) //Returns list of all broken components
	var/list/damaged_components = list()
	for(var/i in S.ship_components)
		var/datum/ship_component/C = i
		if(C.is_damaged())
			damaged_components += C

	return damaged_components

/datum/controller/subsystem/ship/proc/get_targetable_components(var/datum/starship/S) //Returns list of all components you can target.
	var/list/target_components = list()
	for(var/i in S.ship_components)
		var/datum/ship_component/C = i
		if(C.flags & OPEN)
			continue
		target_components += C

	return target_components

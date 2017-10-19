/datum/starship
	var/name = "generic ship"
	var/description = "This ship shouldn't be flying, call the space cops."
	var/x_num = 0
	var/y_num = 0

	var/hull_integrity = 0
	var/shield_strength = 0
	var/evasion_chance = 0

	var/repair_time = 30 //Repair interval in deciseconds
	var/component_repair_amount = 5 //Amount of shield points gained per recharge
	var/recharge_rate = 20 //Shield recharge interval in deciseconds
	var/shield_charge_amount = 200 //Amount of shield points gained per recharge

	var/list/ship_components = list()

	var/list/faction //the faction the ship belongs to. Leave blank for a "neutral" ship that all factions can use. with second argument being spawn chance

	var/list/init_ship_components

	var/destroyed = FALSE //To prevent double destruction

	var/attacking_player = FALSE
	var/attacking_station = FALSE

	var/datum/starship/attacking_target = null

	var/next_repair = 0
	var/next_recharge = 0

	var/is_jumping = FALSE

	var/datum/ship_ai/combat_ai = /datum/ship_ai/standard_combat

	var/heat_points = 1 //how angry the faction gets if we kill this

GLOBAL_VAR(next_ship_id)

/datum/starship/New(var/add_to_ships=0)
	name = "[name] \"[name]\" ([GLOB.next_ship_id++])"
	generate_ship()
	if(add_to_ships) //to prevent the master ship list from being processed
		SSship.ships += src

/datum/starship/Destroy()
	SSship.ships -= src
	for(var/i in ship_components)
		qdel(i)
	return QDEL_HINT_HARDDEL_NOW

/datum/starship/proc/generate_ship() //a bit hacky but I can't think of a better way.... multidimensional lists?
	for(var/i in init_ship_components)
		var/datum/ship_component/ship_component = SSship.id2ship_component(init_ship_components[i])
		var/datum/ship_component/C = ship_component.type

		var/list/coords = splittext(i,",")

		var/x_loc = text2num(coords[1])
		var/y_loc = text2num(coords[2])

		create_ship_component(x_loc, y_loc, C)

	combat_ai = new combat_ai

/datum/starship/proc/create_ship_component(x_loc, y_loc, var/datum/ship_component/newcomponent)
	var/datum/ship_component/C = new
	ship_components += C
	C.ship = src

/datum/starship/proc/replace_ship_component(x_loc, y_loc,var/datum/ship_component/newcomponent)
	for(var/i in ship_components)
		var/datum/ship_component/oldcomponent
		if(oldcomponent.x_loc == x_loc && oldcomponent.y_loc == y_loc)
			qdel(oldcomponent)
			create_ship_component(x_loc, y_loc, newcomponent)

// AI MODULES

/datum/ship_ai
	var/id = "PARENT"

/datum/ship_ai/proc/fire(var/datum/starship/ship)
	return

// COMBAT MODULES
/datum/ship_ai/standard_combat
	id = "COMBAT_STANDARD"

/datum/ship_ai/standard_combat/fire(datum/starship/ship)
	if(ship.attacking_target) //If we're already fighting a ship, return
		return

	var/list/possible_targets = list()

	for(var/datum/starship/O in SSship.ships)
		if(ship.faction == O.faction || ship == O)
			continue
		if(SSship.is_hostile(ship.faction, O.faction))
			possible_targets += O
	if(!possible_targets.len) //No targets? Fuck up the station.
		ship.attacking_station = TRUE
		return

	ship.attacking_station = FALSE
	var/datum/starship/chosen_target = pick(possible_targets)
	ship.attacking_target = chosen_target

	if(S.faction == "station") //if the player is picked.
		ship.attacking_player = 1
		SSship.broadcast_message("<span class=notice>Warning! Enemy ship detected powering up weapons! ([ship.name]) Prepare for combat!</span>",SSship.alert_sound)
		message_admins("[ship.name] has engaged the players into combat")
	else
		SSship.broadcast_message("<span class=notice>Caution! [SSship.faction2prefix(ship)] ship ([ship.name]) locking on to [SSship.faction2prefix(ship.attacking_target)] ship ([ship.attacking_target.name]).</span>",null)

	for(var/datum/ship_component/weapon/W in ship.ship_components)
		W.next_attack = world.time + W.fire_rate + rand(1,25) //so we don't get instantly cucked

/obj/machinery/computer/ship_control
	name = "ship tactical console"
	desc = "Used to control ship weaponry and navigation."
	icon = 'icons/obj/computer.dmi'
	icon_keyboard = "security_key"
	icon_screen = "tactical"

	var/list/weapons = list()
	var/list/controlled_ships
	var/datum/starship/customizable/controlled_ship
	var/datum/ship_component/controlled_ship_component

	var/datum/starship/target
	var/datum/ship_component/target_ship_component

/obj/machinery/computer/ship_control/New()
	..()
	GLOB.ship_control_consoles += src
	refresh_ships()
	refresh_weapons()

/obj/machinery/computer/ship_control/Destroy()
	. = ..()
	GLOB.ship_control_consoles -= src

/obj/machinery/computer/ship_control/proc/refresh_ships() //Allows for players to own multiple ships later
	for(var/i in SSship.ships)
		var/datum/starship/S = i
		if(S.faction == SHIP_PLAYERSHIP)
			controlled_ship = S
			controlled_ships += S

/obj/machinery/computer/ship_control/proc/refresh_weapons()
	if(!controlled_ship)
		return
	weapons = list()
	for(var/datum/ship_component/weapon/W in controlled_ship)
		if(W.is_active())
			weapon += W

/obj/machinery/computer/ship_control/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = 0, datum/tgui/master_ui = null, datum/ui_state/state = GLOB.default_state)

	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		var/datum/asset/assets = get_asset_datum(/datum/asset/simple/tactical)
		assets.send(user)

		ui = new(user, src, ui_key, "ship_control", name, 800, 660, master_ui, state)
		ui.open()

/obj/machinery/computer/ship_control/ui_data(mob/user)
	var/list/data = list()

	var/list/weapon_list = list()
	data["weapons"] = weapon_list
	for(var/datum/ship_component/weapon/W in weapons)
		var/list/weapon_list = list()

		weapon_list["name"] = "[W]"
		weapon_list["id"] = "\ref[W]"
		weapon_list["can_fire"] = W.can_fire()
		weapon_list["charge"] = W.charge
		weapon_list["maxcharge"] = W.maxcharge

		weapon_list[++weapon_list.len] = weapon_list

	if(controlled_ship)
		data["controlled_ship"] = controlled_ship.name
		data["shield_charge"] = controlled_ship.shield_strength
		data["shield_charge_max"] = initial(controlled_ship.shield_strength)

		if(controlled_ship.shield_strength > MIN_SHIELD_STRENGTH)
			data["shield_on"] = TRUE
		else
			data["shield_on"] = FALSE

		var/list/controlled_ship_components_list = list()
		data["controlled_components"] = controlled_ship_components_list
		for(var/cy in 1 to controlled_ship.y_num)
			var/list/row = list()
			controlled_ship_components_list[++controlled_ship_components_list.len] = list("row" = row)
			for(var/cx in 1 to controlled_ship.x_num)
				var/list/controlled_ship_component_list = list()
				var/datum/ship_component/C
				for(var/datum/ship_component/check in controlled_ship.ship_components)
					if(check.x_loc == cx && check.y_loc == cy)
						C = check
						break
				if(C != null)
					if(!C.alt_image)
						ship_component_list["image"] = "tactical_[C.cname].png"
					else
						ship_component_list["image"] = "tactical_[C.alt_image].png"
					var/health = C.health / initial(C.health)
					var/color
					if(health == 0)
						color = "red"
					else if(health > 0 && health < 1)
						color = "orange"
					else
						color = "black"
					controlled_ship_component["color"] = color
					controlled_ship_component["health"] = C.health
					controlled_ship_component["max_health"] = initial(C.health)
					controlled_ship_component["selected"] = (C == controlled_ship_component)
					controlled_ship_component["name"] = C.name
					controlled_ship_component["id"] = "\ref[C]"
				row[++row.len] = controlled_ship_component_list

	var/list/ships_list = list()
	data["ships"] = ships_list
	for(var/datum/starship/S in SSship.ships)
		ships_list[++ships_list.len] = list("name" = S.name, "faction" = S.faction, "id" = "\ref[S]", "selected" = (S == target))

	if(target)
		data["target"] = target.name
		var/list/target_ship_components_list = list()
		data["target_components"] = target_ship_components_list
		for(var/cy in 1 to target.y_num)
			var/list/row = list()
			target_ship_components_list[++target_ship_components_list.len] = list("row" = row)
			for(var/cx in 1 to target.x_num)
				var/list/target_ship_components_list = list()
				var/datum/ship_component/C
				for(var/datum/ship_component/check in target.ship_components)
					if(check.x_loc == cx && check.y_loc == cy)
						C = check
						break
				if(C != null)
					if(!C.alt_image)
						target_ship_components_list["image"] = "tactical_[C.cname].png"
					else
						target_ship_components_list["image"] = "tactical_[C.alt_image].png"
					var/health = C.health / initial(C.health)
					var/color
					if(health == 0)
						color = "red"
					else if(health > 0 && health < 1)
						color = "orange"
					else
						color = "black"
					target_ship_components_list["color"] = color
					target_ship_components_list["health"] = C.health
					target_ship_components_list["max_health"] = initial(C.health)
					target_ship_components_list["selected"] = (C == target_ship_component)
					target_ship_components_list["name"] = C.name
					target_ship_components_list["id"] = "\ref[C]"
				row[++row.len] = target_ship_components_list
	return data

/obj/machinery/computer/ship_control/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("refresh")
			refresh_ships()
			refresh_weapons()
			. = 1
		if("fire_weapon")
			var/datum/ship_component/weapon/W = locate(params["id"])
			if(!istype(W))
				return
			if(!(W in weapons))
				return
			if(!target)
				SSship.broadcast_message("No ship targetted! Shot missed!",SSship.error_sound)
				return
			damage_ship(target, W.attack_data, controlled_ship)
			. = 1
		if("target")
			var/datum/starship/S = locate(params["id"])
			if(istype(S))
				target = S
				target_ship_component = S.ship_components[1]
			. = 1

		if("target_ship_component")
			var/datum/ship_component/C = locate(params["id"])
			if(istype(C) && (C in target.ship_components))
				target_ship_component = C
			. = 1

		if("target_own_ship_component")
			var/datum/ship_component/C = locate(params["id"])
			if(istype(C) && (C in controlled_ship.ship_components))
				controlled_ship_component = C
			. = 1

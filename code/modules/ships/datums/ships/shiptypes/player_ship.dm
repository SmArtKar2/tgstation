/datum/starship/customizable
	name = "The SS Bland"
	description = "It's your ship, how neat."

	hull_integrity = 1000
	shield_strength = 4000
	evasion_chance = 10

	x_num = 3
	y_num = 4

	repair_time = 100 //Repair interval in deciseconds
	component_repair_amount = 5 //Amount of shield points gained per recharge

	recharge_rate = 20 //Shield recharge interval in deciseconds
	shield_charge_amount = 200 //Amount of shield points gained per recharge

	faction = list("station")

	init_ship_components = list("1,1" = "hull", "2,1" = "weapon", "3,1" = "hull",\
"1,2" = "hull", "2,2" = "cockpit", "3,2" = "hull",\
"1,3" = "repair", "2,3" = "engine", "3,3" = "shields")

/datum/starship/proc/refresh_ship()
	for(var/i in ship_components)
		qdel(i)
	for(var/i in init_ship_componentsS)
		var/datum/ship_component/ship_component = SSship.id2ship_component(init_ship_components[i])
		var/datum/ship_component/C = new ship_component.type
		ship_components += C

		var/list/coords = splittext(i,",")

		C.x_loc = text2num(coords[1])
		C.y_loc = text2num(coords[2])
		C.ship = src

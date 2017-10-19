/datum/starship/clanker
	name = "pirate clanker"
	description = "A pirate rustbucket made from the scraps of various ships. What a miracle that it actually works."
	faction = list("pirate",60)

	x_num = 3
	y_num = 3

	hull_integrity = 1000
	shield_strength = 2000
	evasion_chance = 15

	repair_time = 100 //Repair interval in deciseconds
	component_repair_amount = 5 //Amount of shield points gained per recharge

	recharge_rate = 20 //Shield recharge interval in deciseconds
	shield_charge_amount = 200 //Amount of shield points gained per recharge

	init_ship_components = list("1,1" = "ion_weapon", "2,1" = "cockpit", "3,1" = "chaingun",\
	"1,2" = "shields", "2,2" = "repair", "3,2" = "shields",\
	"1,3" = "engine","2,3" = "engine", "3,3" = "engine")

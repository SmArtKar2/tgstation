/datum/ship_component
	var/name = "generic ship component"
	var/id = "ship component"

	var/health = 10
	var/flags = 0

	var/x_loc = 0 //(1,1) is top left
	var/y_loc = 0

	var/datum/starship/ship

	var/alt_image

/datum/ship_component/New()
	if(attack_data)
		attack_data = new attack_data
		attack_data.our_ship_component = src

/datum/ship_component/proc/adjust_health(amount)
	health = Clamp(health + amount, 0, initial(health))

/datum/ship_component/proc/is_active()
	if(health > 0)
		return TRUE

/datum/ship_component/proc/is_damaged()
	if(health < initial(health))
		return TRUE

/datum/ship_component/open
	name = "open space"
	id = "open"

	health = 0

	flags = SHIP_OPEN

/datum/ship_component/cockpit
	name = "bridge"
	id = "cockpit"

	health = 300

	flags = SHIP_CONTROL

/datum/ship_component/shields
	name = "shield generator"
	id = "shields"

	health = 200

	flags = SHIP_SHIELDS

/datum/ship_component/repair
	name = "engineering section"
	id = "repair"

	health = 200

	flags = SHIP_REPAIR

/datum/ship_component/engines
	name = "engine"
	id = "engine"

	health = 100

	flags = SHIP_ENGINES

/datum/ship_component/hull
	name = "hull"
	id = "hull"

	health = 200

/datum/ship_component/reactor //compact engineering + shield ship_component for smaller ships.
	name = "reactor compartment"
	id = "reactor"

	health = 200

	flags = SHIP_SHIELDS | SHIP_REPAIR

/datum/ship_component/drone_core
	name = "drone control core"
	id = "drone"

	health = 200

	flags = SHIP_WEAPONS | SHIP_CONTROL

/datum/ship_component/weapon
	name = "ship weapon"
	id = "weapon"

	health = 200

	flags = SHIP_WEAPONS

	var/datum/ship_attack/attack_data = null
	var/fire_rate = 0
	var/next_attack = 0

	var/maxcharge = 2000
	var/charge = 0

	alt_image = "weapon"


/datum/ship_component/weapon/proc/CanFire()
	if(charge >= maxcharge)
		return TRUE

/datum/ship_component/weapon/random
	name = "standard mount"
	id = "r_weapon"
	fire_rate = 300

/datum/ship_component/weapon/random
	name = "standard mount"
	id = "r_weapon"
	fire_rate = 300


	var/list/possible_weapons = list(/datum/ship_attack/laser,/datum/ship_attack/ballistic,/datum/ship_attack/chaingun)

/datum/ship_component/weapon/random/New()
		attack_data = pick(possible_weapons)
		attack_data = new attack_data
		name = attack_data.id

/datum/ship_component/weapon/random/special
	name = "special mount"
	id = "s_weapon"
	fire_rate = 300

	possible_weapons = list(/datum/ship_attack/ion,/datum/ship_attack/stun_bomb,/datum/ship_attack/flame_bomb)

/datum/ship_component/weapon/random/memegun
	name = "meme weapon"
	id = "meme_weapon"
	fire_rate = 100

	possible_weapons = list(/datum/ship_attack/slipstorm,/datum/ship_attack/honkerblaster,/datum/ship_attack/bananabomb)


		//Phase Cannons
/datum/ship_component/weapon/phase
	name = "phase cannon"
	id = "phase_cannon"
	fire_rate = 200

	attack_data = /datum/ship_attack/laser

		//MAC Cannons
/datum/ship_component/weapon/mac_cannon
	name = "MAC cannon"
	id = "mac_cannon"
	fire_rate = 400

	attack_data = /datum/ship_attack/ballistic

		//Ion Cannons
/datum/ship_component/weapon/ion
	name = "ion cannon"
	id = "ion_weapon"
	fire_rate = 300

	attack_data = /datum/ship_attack/ion

		//Firebombs
/datum/ship_component/weapon/firebomb
	name = "firebomber"
	id = "firebomber"
	fire_rate = 300

	attack_data = /datum/ship_attack/flame_bomb


			//Stun Bombs
/datum/ship_component/weapon/stunbomb
	name = "stunbomber"
	id = "stunbomber"
	fire_rate = 300

	attack_data = /datum/ship_attack/stun_bomb


			//Chainguns
/datum/ship_component/weapon/chaingun
	name = "chaingun"
	id = "chaingun"
	fire_rate = 500

	attack_data = /datum/ship_attack/chaingun

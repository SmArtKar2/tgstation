/datum/star_faction
	var/name = "faction"
	var/id = ""

	var/list/relations

	var/list/ships = list()

/datum/star_faction/station
	name = "station"
	id = "station"
	relations = list("nanotrasen" = 100, "syndicate" = -100, "solgov" = 0, "pirate" = -100)

/datum/star_faction/solgov
	name = "SolGov"
	relations = list("station" = 0, "nanotrasen" = 25, "syndicate"= 25, "pirate"= -75)

/datum/star_faction/nanotrasen
	name = "Nanotrasen"
	relations = list("station" = 100, "syndicate" = -100, "solgov" = 25, "pirate"= -100)

/datum/star_faction/syndicate
	name = "Syndicate"
	relations = list("station" = -100, "nanotrasen" = -100, "solgov" = 25, "pirate" = -100)

/datum/star_faction/pirate //arr matey get me some rum
	name = "Pirates"
	relations = list("station" = -100, "nanotrasen" = -100, "solgov" = -100, "syndicate" = -100)

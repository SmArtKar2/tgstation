
///Craving whims make you want a specific object to eat/drink/use
/datum/whim/craving
	mood_reward = 10
	var/craved_object_category

/datum/whim/craving/setup_whim()
	. = ..()
	craved_object_category = generate_craved_item()
	desc = "I could really go for some [craved_object_category] right now."

///Proc to be used to generate the desired object
/datum/whim/craving/proc/generate_craved_item()
	return

///Food whim, makes you crave a specific food
/datum/whim/craving/food

/datum/whim/craving/food/setup_whim()
	. = ..()
	RegisterSignal(whim_owner, COMSIG_LIVING_ATE_FOOD, .proc/OnEatFood)

/datum/whim/craving/food/fulfilled()
	. = ..()
	UnregisterSignal(whim_owner, COMSIG_LIVING_ATE_FOOD)

/datum/whim/craving/food/generate_craved_item()
	. = .. ()
	craved_object_category = pick(assoc_list_strip_value(GLOB.whim_food_categories)) //Get the keys of the list and pick one

/datum/whim/craving/food/proc/OnEatFood(datum/source, atom/eaten_food)
	SIGNAL_HANDLER

	var/typecache_food = GLOB.whim_food_categories[craved_object_category]

	if(is_type_in_typecache(eaten_food.type, typecache_food))
		fulfilled()

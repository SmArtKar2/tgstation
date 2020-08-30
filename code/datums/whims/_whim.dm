/datum/whim
	var/desc = "gimme gimme gimme"
	var/mood_reward = 5
	var/mob/living/carbon/whim_owner

/datum/whim/New(mob/living/carbon/whim_owner)
	. = ..()
	src.whim_owner = whim_owner
	setup_whim()

/datum/whim/proc/setup_whim()

/datum/whim/proc/fulfilled()
	SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "whim", /datum/mood_event/whim, mood_reward)

/datum/whim/craving
	mood_reward = 10
	var/craved_object

/datum/whim/craving/setup_whim()
	craved_object = generate_craved_item()
	desc = "I could really go for a [initial(craved_object.name)] right now."

/datum/whim/craving/proc/generate_craved_item()
	return

/datum/whim/craving/food

/datum/whim/craving/food/setup_whim()
	RegisterSignal(parent, COMSIG_ITEM_AFTERATTACK, .proc/mobCheck)

/datum/whim/proc/check_requirements(datum/source, )

/datum/whim/craving/food/generate_craved_item()
	return get_random_food()

/datum/whim/craving/drink

/datum/whim/craving/drink/generate_craved_item()
	return get_random_drink()





///Whims are desires a character might have, will reward the player for completion.
/datum/whim
	var/desc = "gimme gimme gimme"
	var/mood_reward = 5
	var/mob/living/carbon/whim_owner

/datum/whim/New(mob/living/carbon/whim_owner)
	. = ..()
	src.whim_owner = whim_owner
	setup_whim()

///Used for any extra behavior to allow the whim to work
/datum/whim/proc/setup_whim()

///Text to print when whim is examined
/datum/whim/proc/get_whim_text()
	return desc

///Should be called when the whim is succesfully fulfilled
/datum/whim/proc/fulfilled()
	SEND_SIGNAL(whim_owner, COMSIG_WHIM_COMPLETED)






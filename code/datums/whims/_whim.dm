/datum/whim
	var/desc = "gimme gimme gimme"
	var/mood_reward = 3

/datum/whim/proc/fulfilled()
	SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "whim", /datum/mood_event/whim, mood_reward)

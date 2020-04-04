#define EXPERIMENT_CONFIG_ATTACKSELF 	"experiment_config_attackself"
#define EXPERIMENT_CONFIG_ALTCLICK 		"experiment_config_altclick"
#define EXPERIMENT_CONFIG_CUSTOMSIGNAL	"experiment_config_customsignal"

/**
  * # Experiment Handler
  *
  * This is the base component for interacting with experiments from a connected techweb
  */
/datum/component/experiment_handler
	/// Holds the currently linked techweb to get experiments from
	var/datum/techweb/linked_web
	/// Holds the currently selected experiment
	var/datum/experiment/selected_experiment
	/// Holds the list of types of experiments that this experiment_handler can interact with
	var/list/allowed_experiments
	/// Holds the list of types of experiments that this experimennt_handler should NOT interact with
	var/list/blacklisted_experiments

/**
  * Initializes a new instance of the experiment_handler component
  *
  * Arguments:
  * * allowed_experiments - The list of /datum/experiment types that can be performed with this component
  * * blacklisted_experiments - The list of /datum/experiment types that explicitly cannot be performed with this component
  * * config_mode - The define that determines how the experiment_handler should display the configuration UI
  */
/datum/component/experiment_handler/Initialize(allowed_experiments = list(),
												blacklisted_experiments = list(),
												config_mode = EXPERIMENT_CONFIG_ATTACKSELF)
	. = ..()
	src.allowed_experiments = allowed_experiments
	src.blacklisted_experiments = blacklisted_experiments

	// Determine UI display mode
	switch(config_mode)
		if (EXPERIMENT_CONFIG_ATTACKSELF)
			RegisterSignal(parent, COMSIG_ITEM_ATTACK_SELF, .proc/configure_experiment)
		if (EXPERIMENT_CONFIG_ALTCLICK)
			RegisterSignal(parent, COMSIG_CLICK_ALT, .proc/configure_experiment)
		if (EXPERIMENT_CONFIG_CUSTOMSIGNAL)
			RegisterSignal(parent, COMSIG_EXPERIMENT_CONFIGURE, .proc/configure_experiment)

/**
  * Attempts to show the user the experiment configuration panel
  *
  * Arguments:
  * * user - The user to show the experiment configuration panel to
  */
/datum/component/experiment_handler/proc/configure_experiment(datum/source, mob/user)
	ui_interact(user)

/**
  * Attempts to link this experiment_handler to a provided techweb
  *
  * This proc attempts to link the handler to a provided techweb, overriding the existing techweb if relevant
  *
  * Arguments:
  * * new_web - The new techweb to link to
  */
/datum/component/experiment_handler/proc/link_techweb(datum/techweb/new_web)
	if (new_web == linked_web)
		return
	selected_experiment = null
	linked_web = new_web

/**
  * Unlinks this handler from the selected techweb
  */
/datum/component/experiment_handler/proc/unlink_techweb()
	selected_experiment = null
	linked_web = null

/**
  * Attempts to link this experiment_handler to a provided experiment
  *
  * Arguments:
  * * e - The experiment to attempt to link to
  */
/datum/component/experiment_handler/proc/link_experiment(datum/experiment/e)
	if (e && can_select_experiment(e))
		selected_experiment = e

/**
  * Unlinks this handler from the selected experiment
  */
/datum/component/experiment_handler/proc/unlink_experiment()
	selected_experiment = null

/**
  * Attempts to get rnd servers on the same z-level as a provided turf
  *
  * Arguments:
  * * pos - The turf to get servers on the same z-level of
  */
/datum/component/experiment_handler/proc/get_available_servers(var/turf/pos = null)
	if (!pos)
		pos = get_turf(parent)
	var/list/local_servers = list()
	for (var/obj/machinery/rnd/server/s in SSresearch.servers)
		var/turf/s_pos = get_turf(s)
		if (pos && s_pos && s_pos.z == pos.z)
			local_servers += s
	return local_servers

/**
  * Checks if an experiment is valid to be selected by this handler
  *
  * Arguments:
  * * e - The experiment to check
  */
/datum/component/experiment_handler/proc/can_select_experiment(datum/experiment/e)
	// Check against the list of allowed experimentors
	if (e.allowed_experimentors && e.allowed_experimentors.len)
		var/matched = FALSE
		for (var/t in e.allowed_experimentors)
			if (istype(parent, t))
				matched = TRUE
				break
		if (!matched)
			return FALSE

	// Check that this experiment is visible currently
	if (!linked_web || !(e in linked_web.active_experiments))
		return FALSE

	// Check that this experiment type isn't blacklisted
	for (var/t in blacklisted_experiments)
		if (istype(e, t))
			return FALSE

	// Check against the allowed experiment types
	for (var/t in allowed_experiments)
		if (istype(e, t))
			return TRUE

	// If we haven't returned yet then this shouldn't be allowed
	return FALSE

/datum/component/experiment_handler/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = FALSE, \
												datum/tgui/master_ui = null, datum/ui_state/state = GLOB.physical_state)
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "experiment_configure", "Experiment Configuration", 650, 525, master_ui, state)
		ui.open()

/datum/component/experiment_handler/ui_data(mob/user)
	. = list()
	.["servers"] = list()
	for (var/obj/machinery/rnd/server/s in get_available_servers())
		var/list/data = list(
			name = s.name,
			web_id = s.stored_research ? s.stored_research.id : null,
			web_org = s.stored_research ? s.stored_research.organization : null,
			location = get_area(s),
			selected = linked_web && s.stored_research ? s.stored_research == linked_web : FALSE,
			ref = REF(s)
		)
		.["servers"] += list(data)
	.["experiments"] = list()
	if (linked_web)
		for (var/datum/experiment/e in linked_web.active_experiments)
			var/list/data = list(
				name = e.name,
				description = e.description,
				selectable = can_select_experiment(e),
				selected = selected_experiment == e,
				progress = e.check_progress(),
				ref = REF(e)
			)
			.["experiments"] += list(data)

/datum/component/experiment_handler/ui_act(action, params)
	. = ..()
	if (.)
		return
	switch (action)
		if ("select_server")
			. = TRUE
			var/obj/machinery/rnd/server/s = locate(params["ref"])
			if (s)
				link_techweb(s.stored_research)
				return
		if ("clear_server")
			. = TRUE
			unlink_techweb()
		if ("select_experiment")
			. = TRUE
			var/datum/experiment/e = locate(params["ref"])
			if (e)
				link_experiment(e)
		if ("clear_experiment")
			. = TRUE
			unlink_experiment()

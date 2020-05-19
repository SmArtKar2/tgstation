/turf/open
	plane = FLOOR_PLANE
	var/slowdown = 0 //negative for faster, positive for slower

	var/postdig_icon_change = FALSE
	var/postdig_icon
	var/wet

	var/footstep = null
	var/barefootstep = null
	var/clawfootstep = null
	var/heavyfootstep = null

	///Layer this turf's edges are on, if this is higher than its neighbour it will use only its own edge icon. Used for SMOOTH_EDGES
	var/edge_layer = 0
	///Ref to any turf edge ontop of this turf.
	var/obj/effect/smooth_edge/smooth_edge

/turf/open/ComponentInitialize()
	. = ..()
	if(wet)
		AddComponent(/datum/component/wet_floor, wet, INFINITY, 0, INFINITY, TRUE)

//direction is direction of travel of A
/turf/open/zPassIn(atom/movable/A, direction, turf/source)
	return (direction == DOWN)

//direction is direction of travel of A
/turf/open/zPassOut(atom/movable/A, direction, turf/destination)
	return (direction == UP)

//direction is direction of travel of air
/turf/open/zAirIn(direction, turf/source)
	return (direction == DOWN)

//direction is direction of travel of air
/turf/open/zAirOut(direction, turf/source)
	return (direction == UP)

/turf/open/edge_smooth(adjacencies)
	for(var/cdir in GLOB.alldirs)
		if(cdir in adjacencies) //We dont put the edge on things we smooth with.
			continue
		var/turf/open/T = get_step(src, cdir)
		if(!istype(T))
			continue
		if(edge_layer > T.edge_layer) //Our edge layer has to be higher for this to apply
			if(!T.smooth_edge) //If this turf has no smooth edge on it yet, create it.
				T.smooth_edge = new(T, src)
				T.smooth_edge.icon = icon
				T.smooth_edge.layer = (edge_layer/100)+TURF_LAYER //Just above the turf layer
				T.smooth_edge.name = name
				T.smooth_edge.desc = desc
			else //Otherwise just update it
				smooth_icon(T.smooth_edge)


/obj/effect/smooth_edge
	smooth = SMOOTH_TRUE | SMOOTH_EDGES
	anchored = TRUE
	plane = FLOOR_PLANE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/effect/smooth_edge/Initialize(turf/open/T, turf/open/connected_turf)
	. = ..()
	canSmoothWith = list(connected_turf.type)
	RegisterSignal(connected_turf, COMSIG_ATOM_SMOOTH, .proc/on_smoothing_change)
	queue_smooth(src)

///This proc handles cleanup
/obj/effect/smooth_edge/proc/on_smoothing_change()
	var/should_delete = TRUE
	for(var/cdir in GLOB.alldirs)
		var/turf/open/T = get_step(src, cdir)
		if(!istype(T))
			continue
		should_delete = FALSE
	if(should_delete)
		qdel(src)
	queue_smooth(src)

/obj/effect/smooth_edge/edge_smooth(adjacencies)
	var/atom/movable/AM
	for(var/direction in list(5,6,9,10))
		AM = find_type_in_direction(src, direction)
		if(AM == NULLTURF_BORDER)
			if((smooth & SMOOTH_BORDER))
				adjacencies |= 1 << direction
		else if((AM && !istype(AM)) || (istype(AM) && AM.anchored) )
			adjacencies |= 1 << direction
	var/dirs = 0
	if(adjacencies & N_NORTH)
		dirs |= NORTH
		adjacencies &= ~(N_NORTHEAST|N_NORTHWEST|N_NORTH)
	if(adjacencies & N_SOUTH)
		dirs |= SOUTH
		adjacencies &= ~(N_SOUTHEAST|N_SOUTHWEST|N_SOUTH)
	if(adjacencies & N_EAST)
		dirs |= EAST
		adjacencies &= ~(N_NORTHEAST|N_SOUTHEAST|N_EAST)
	if(adjacencies & N_WEST)
		dirs |= WEST
		adjacencies &= ~(N_NORTHWEST|N_SOUTHWEST|N_WEST)
	icon_state = "e_[dirs]"
	cut_overlays()
	if(adjacencies & N_NORTHWEST)
		add_overlay("c_1")
	if(adjacencies & N_NORTHEAST)
		add_overlay("c_2")
	if(adjacencies & N_SOUTHWEST)
		add_overlay("c_3")
	if(adjacencies & N_SOUTHEAST)
		add_overlay("c_4")

/turf/open/indestructible
	name = "floor"
	icon = 'icons/turf/floors.dmi'
	icon_state = "floor"
	footstep = FOOTSTEP_FLOOR
	barefootstep = FOOTSTEP_HARD_BAREFOOT
	clawfootstep = FOOTSTEP_HARD_CLAW
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY
	tiled_dirt = TRUE

/turf/open/indestructible/Melt()
	to_be_destroyed = FALSE
	return src

/turf/open/indestructible/singularity_act()
	return

/turf/open/indestructible/TerraformTurf(path, new_baseturf, flags, defer_change = FALSE, ignore_air = FALSE)
	return

/turf/open/indestructible/sound
	name = "squeaky floor"
	footstep = null
	barefootstep = null
	clawfootstep = null
	heavyfootstep = null
	var/sound

/turf/open/indestructible/sound/Entered(atom/movable/AM)
	..()
	if(ismob(AM))
		playsound(src,sound,50,TRUE)

/turf/open/indestructible/necropolis
	name = "necropolis floor"
	desc = "It's regarding you suspiciously."
	icon = 'icons/turf/floors.dmi'
	icon_state = "necro1"
	baseturfs = /turf/open/indestructible/necropolis
	initial_gas_mix = LAVALAND_DEFAULT_ATMOS
	footstep = FOOTSTEP_LAVA
	barefootstep = FOOTSTEP_LAVA
	clawfootstep = FOOTSTEP_LAVA
	heavyfootstep = FOOTSTEP_LAVA
	tiled_dirt = FALSE

/turf/open/indestructible/carpet
	name = "carpet"
	desc = "Soft velvet carpeting. Feels good between your toes."
	icon = 'icons/turf/floors/carpet.dmi'
	icon_state = "carpet"
	smooth = SMOOTH_TRUE
	canSmoothWith = list(/turf/open/indestructible/carpet)
	flags_1 = NONE
	bullet_bounce_sound = null
	footstep = FOOTSTEP_CARPET
	barefootstep = FOOTSTEP_CARPET_BAREFOOT
	clawfootstep = FOOTSTEP_CARPET_BAREFOOT
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY
	tiled_dirt = FALSE


/turf/open/indestructible/necropolis/Initialize()
	. = ..()
	if(prob(12))
		icon_state = "necro[rand(2,3)]"

/turf/open/indestructible/necropolis/air
	initial_gas_mix = OPENTURF_DEFAULT_ATMOS

/turf/open/indestructible/boss //you put stone tiles on this and use it as a base
	name = "necropolis floor"
	icon = 'icons/turf/boss_floors.dmi'
	icon_state = "boss"
	baseturfs = /turf/open/indestructible/boss
	initial_gas_mix = LAVALAND_DEFAULT_ATMOS

/turf/open/indestructible/boss/air
	initial_gas_mix = OPENTURF_DEFAULT_ATMOS

/turf/open/indestructible/hierophant
	icon = 'icons/turf/floors/hierophant_floor.dmi'
	initial_gas_mix = LAVALAND_DEFAULT_ATMOS
	baseturfs = /turf/open/indestructible/hierophant
	smooth = SMOOTH_TRUE
	tiled_dirt = FALSE

/turf/open/indestructible/hierophant/two

/turf/open/indestructible/hierophant/get_smooth_underlay_icon(mutable_appearance/underlay_appearance, turf/asking_turf, adjacency_dir)
	return FALSE

/turf/open/indestructible/paper
	name = "notebook floor"
	desc = "A floor made of invulnerable notebook paper."
	icon_state = "paperfloor"
	footstep = null
	barefootstep = null
	clawfootstep = null
	heavyfootstep = null
	tiled_dirt = FALSE

/turf/open/indestructible/binary
	name = "tear in the fabric of reality"
	CanAtmosPass = ATMOS_PASS_NO
	baseturfs = /turf/open/indestructible/binary
	icon_state = "binary"
	footstep = null
	barefootstep = null
	clawfootstep = null
	heavyfootstep = null

/turf/open/indestructible/airblock
	icon_state = "bluespace"
	blocks_air = TRUE
	baseturfs = /turf/open/indestructible/airblock

/turf/open/Initalize_Atmos(times_fired)
	excited = 0
	update_visuals()

	current_cycle = times_fired
	ImmediateCalculateAdjacentTurfs()
	for(var/i in atmos_adjacent_turfs)
		var/turf/open/enemy_tile = i
		var/datum/gas_mixture/enemy_air = enemy_tile.return_air()
		if(!excited && air.compare(enemy_air))
			//testing("Active turf found. Return value of compare(): [is_active]")
			excited = TRUE
			SSair.active_turfs |= src

/turf/open/proc/GetHeatCapacity()
	. = air.heat_capacity()

/turf/open/proc/GetTemperature()
	. = air.temperature

/turf/open/proc/TakeTemperature(temp)
	air.temperature += temp
	air_update_turf()

/turf/open/proc/freon_gas_act()
	for(var/obj/I in contents)
		if(I.resistance_flags & FREEZE_PROOF)
			continue
		if(!(I.obj_flags & FROZEN))
			I.make_frozen_visual()
	for(var/mob/living/L in contents)
		if(L.bodytemperature <= 50)
			L.apply_status_effect(/datum/status_effect/freon)
	MakeSlippery(TURF_WET_PERMAFROST, 50)
	return TRUE

/turf/open/proc/water_vapor_gas_act()
	MakeSlippery(TURF_WET_WATER, min_wet_time = 100, wet_time_to_add = 50)

	for(var/mob/living/simple_animal/slime/M in src)
		M.apply_water()

	SEND_SIGNAL(src, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_WEAK)
	for(var/obj/effect/O in src)
		if(is_cleanable(O))
			qdel(O)
	return TRUE

/turf/open/handle_slip(mob/living/carbon/C, knockdown_amount, obj/O, lube, paralyze_amount, force_drop)
	if(C.movement_type & FLYING)
		return 0
	if(has_gravity(src))
		var/obj/buckled_obj
		if(C.buckled)
			buckled_obj = C.buckled
			if(!(lube&GALOSHES_DONT_HELP)) //can't slip while buckled unless it's lube.
				return 0
		else
			if(!(lube&SLIP_WHEN_CRAWLING) && (!(C.mobility_flags & MOBILITY_STAND) || !(C.status_flags & CANKNOCKDOWN))) // can't slip unbuckled mob if they're lying or can't fall.
				return 0
			if(C.m_intent == MOVE_INTENT_WALK && (lube&NO_SLIP_WHEN_WALKING))
				return 0
		if(!(lube&SLIDE_ICE))
			to_chat(C, "<span class='notice'>You slipped[ O ? " on the [O.name]" : ""]!</span>")
			playsound(C.loc, 'sound/misc/slip.ogg', 50, TRUE, -3)

		SEND_SIGNAL(C, COMSIG_ADD_MOOD_EVENT, "slipped", /datum/mood_event/slipped)
		if(force_drop)
			for(var/obj/item/I in C.held_items)
				C.accident(I)

		var/olddir = C.dir
		C.moving_diagonally = 0 //If this was part of diagonal move slipping will stop it.
		if(!(lube & SLIDE_ICE))
			C.Knockdown(knockdown_amount)
			C.Paralyze(paralyze_amount)
			C.stop_pulling()
		else
			C.Knockdown(20)

		if(buckled_obj)
			buckled_obj.unbuckle_mob(C)
			lube |= SLIDE_ICE

		if(lube&SLIDE)
			new /datum/forced_movement(C, get_ranged_target_turf(C, olddir, 4), 1, FALSE, CALLBACK(C, /mob/living/carbon/.proc/spin, 1, 1))
		else if(lube&SLIDE_ICE)
			if(C.force_moving) //If we're already slipping extend it
				qdel(C.force_moving)
			new /datum/forced_movement(C, get_ranged_target_turf(C, olddir, 1), 1, FALSE)	//spinning would be bad for ice, fucks up the next dir
		return 1

/turf/open/proc/MakeSlippery(wet_setting = TURF_WET_WATER, min_wet_time = 0, wet_time_to_add = 0, max_wet_time = MAXIMUM_WET_TIME, permanent)
	AddComponent(/datum/component/wet_floor, wet_setting, min_wet_time, wet_time_to_add, max_wet_time, permanent)

/turf/open/proc/MakeDry(wet_setting = TURF_WET_WATER, immediate = FALSE, amount = INFINITY)
	SEND_SIGNAL(src, COMSIG_TURF_MAKE_DRY, wet_setting, immediate, amount)

/turf/open/get_dumping_location()
	return src

/turf/open/proc/ClearWet()//Nuclear option of immediately removing slipperyness from the tile instead of the natural drying over time
	qdel(GetComponent(/datum/component/wet_floor))

/turf/open/rad_act(pulse_strength)
	. = ..()
	if (air.gases[/datum/gas/carbon_dioxide] && air.gases[/datum/gas/oxygen])
		pulse_strength = min(pulse_strength,air.gases[/datum/gas/carbon_dioxide][MOLES]*1000,air.gases[/datum/gas/oxygen][MOLES]*2000) //Ensures matter is conserved properly
		air.gases[/datum/gas/carbon_dioxide][MOLES]=max(air.gases[/datum/gas/carbon_dioxide][MOLES]-(pulse_strength/1000),0)
		air.gases[/datum/gas/oxygen][MOLES]=max(air.gases[/datum/gas/oxygen][MOLES]-(pulse_strength/2000),0)
		air.assert_gas(/datum/gas/pluoxium)
		air.gases[/datum/gas/pluoxium][MOLES]+=(pulse_strength/4000)
		air.garbage_collect()

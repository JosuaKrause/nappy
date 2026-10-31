class_name EventManager
extends Node
## **A day's events, in whatever world she walks**: the one thing the run flow, the resistance, the
## city and the observers talk to about events. It starts a day (`start_day()`), steps its live
## instances once a physics tick in a fixed order (`_tick_the_events()`), answers what charges the
## baby at a point (`excitement_sources_at()`), sees what struck her (`_check_hard_fails()`) and
## ends the day's charges. The work behind that face is handed to the parts that own it, each handed
## the one `EventWorld` they share:
##
## - `EventStreaming`: the day's plan and the live instance each plan streams in as, the repeats,
##   the masts, a finished plan spent;
## - `EventSpawner`: every instance made (its scar, its body, the bang outside), what a finished row
##   leaves behind, the rows summoned on sight and the run's pelican bag;
## - `WarningBoard`: the screen-edge badges up for something not in the world yet, and the mark over
##   her head;
## - `EventsAhead`: what the director puts in front of her while she walks;
## - `CheckpointController`: the district doors as she meets them, whose holds and releases come
##   back as intents this applies to the player it was handed (`_take_her_in()`, `_hold_her()`,
##   `_let_her_out()`).
##
## **Every world's events, the escape's building included.** It is handed the map of the world its
## events stand in (`WorldMap`) and runs whatever plan it is given on it: a city's day it plans
## itself (`start_day()`), and a plan handed over whole — the escape's city, the building's own
## placements (`BuildingPlan`) — it takes as given (`start_planned()`). A world that is not the city
## has no city to plan a day over (`setup_world()`): no director sites anything ahead of her there,
## and a plan that comes again (`EventScheduler.Planned.repeats()`) is brought back on its own
## clock.
##
## **Handed what it depends on, never fetching it**: the city, its map and navigator (`setup()`), or
## a world that is not the city (`setup_world()`); the run (`City.run`, or `use_run()`); the player
## (`use_player()`); the walk's spec (`use_the_spec()`).
##
## Lookup is a linear scan. The budget formula tops out around 32 concurrent events on the last day
## — 32 distance checks per physics tick is nothing, and a spatial hash would be more code with more
## ways to be subtly wrong. Revisit if an act ever wants hundreds of sources at once.
##
## **This node owns no instance as a scene child.** Every `EventInstance` is added to the world its
## map is drawn in (`WorldMap.add_entity()`), under that world's y-sorted entity layer rather than
## under here, so `EventInstance._ready()` sets its own physics interpolation rather than inheriting
## the setting from this node.

## What every part works over: the world, the run, the player, what she can see and the live
## instances.
var world := EventWorld.new()
## The day's plan and the live instances it streams in as.
var streaming: EventStreaming
## Every instance made, what a finished row leaves, the summons and the pelican bag.
var spawner: EventSpawner
## The warnings up for something not in the world yet, and the mark over her head.
var warnings: WarningBoard
## What the director puts in front of her while she walks.
var ahead: EventsAhead
## **The district doors as she meets them** (`CheckpointController`): the holds, the releases, the
## walks under a raised boom and the guard a crossing sets on her, over this manager's own live
## instances.
var checkpoints: CheckpointController
## What a protest points at, answering a world point or `Vector2.INF` for nothing: handed in by the
## resistance (`ResistanceDirector.setup()`, its `pointable_objective()`) and asked on behalf of
## every instance made here. Unset where there is no resistance, and a protest then points at
## nothing.
var points_at := Callable():
	set(value):
		points_at = value
		world.points_at = value
## Where the manager, the day's planning and every instance it creates write their own account for
## the run log — the city's, set before `setup()`; silent until then.
var trace := RunTrace.new():
	set(value):
		trace = value
		world.trace = value
## `--skip events`, handed in by the city before `setup()`: every instance this makes skips its
## own drawing.
var skip_drawing := false:
	set(value):
		skip_drawing = value
		world.skip_drawing = value
## How close the player has to be for a planned event to exist (`EventStreaming.stream_radius`).
## `INF` turns streaming off and puts the whole day in the world at once, which is what the escape's
## building and a test rig with no player want.
var stream_radius: float:
	get:
		return streaming.stream_radius
	set(value):
		streaming.stream_radius = value
## What a rig makes `EventSpawner.rolls_a_pelican()` answer (`EventSpawner.pelican_rig`): `--pelican` sets
## every rider the pelican.
var pelican_rig: EventSpawner.PelicanRig:
	get:
		return spawner.pelican_rig
	set(value):
		spawner.pelican_rig = value
var _hard_failed := false

## Whether falling asleep owes her a return on this walk (`DaySpec.owes_a_return`), as the run flow
## hands it in (`use_the_spec()`): a day's, `DaySpec`'s own default, until a spec is handed in.
var _owes_a_return := true
## The whole spec the run flow handed in (`use_the_spec()`), whose placement settings `start_day()`
## plans the day's seals and events under; null until one is handed in, when `start_day()` plans
## under a day's own (`DaySpec.for_day()`).
var _spec: DaySpec = null

## Authored scenes install a complete event plan; ambient directors cannot replace its actors.
var _recipe_plan := false

## Builds the parts, each handed the one world, and connects the doors' intents and crossings.
func _init() -> void:
	warnings = WarningBoard.new(world)
	spawner = EventSpawner.new(world, warnings)
	streaming = EventStreaming.new(world, spawner)
	ahead = EventsAhead.new(world, streaming, spawner, warnings)
	checkpoints = CheckpointController.new(world, spawner.spawn, EventBus,
			EventCatalogue.door_guard())
	checkpoints.door_crossed.connect(func(at: Vector2, axis: Vector2, inspected: bool) -> void:
			door_crossed.emit(at, axis, inspected))
	checkpoints.takes_her_in.connect(_take_her_in)
	checkpoints.holds_her.connect(_hold_her)
	checkpoints.lets_her_out.connect(_let_her_out)

## Takes the one reference on the baked page every `EventInstance` draws from — the whole catalogue,
## the checkpoint kit and the crater on one page (`EventPictures.ATLAS_GROUP`), for the manager's
## own life rather than one per family per instant: a page that came and went with the last instance
## of a family would be a blocking read from disk in a played frame the next time one streamed in
## (PLAYTEST-109). In a booted game the count is on a page `main.RESIDENT_GROUPS` already holds; the
## pair is what proves the page is there while a day's events draw from it.
## `_enter_tree()`/`_exit_tree()` rather than `_ready()`, so a manager that leaves the tree and
## comes back keeps the count right.
func _enter_tree() -> void:
	AtlasLibrary.acquire(EventPictures.ATLAS_GROUP)

func _exit_tree() -> void:
	AtlasLibrary.release(EventPictures.ATLAS_GROUP)

## **Lets go of the warnings when the manager goes**, so the parts go with it. A warning still up
## holds the callbacks that put its row in the world or owe it again (`PendingWarning.arrive`,
## `on_withdrawn`), and those hold the part that raised it (`EventsAhead`, `EventSpawner`), which
## holds the board the warning is on: a ring of references nothing else breaks, which would keep
## the parts, the world and its map alive past the manager.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		warnings.clear()
		ahead.clear()

## Hands the manager its city, the map it places on and the navigator its figures move by — the
## city's own (`City.navigator`), or the map's own (`WorldMap.navigator()`) for a rig that hands
## none — and the city's run (`City.run`).
func setup(city: City, map: CityMap, navigator: Navigator = null) -> void:
	world.city = city
	world.map = map
	world.city_map = map
	# A map a rig hands in on its own is drawn in the city it hands with it.
	if city and not map.has_world():
		map.world = city
	if city:
		world.signals = city.signals
		world.run = city.run
	world.use_navigator(navigator if navigator else map.navigator())
	ahead.use_director(map, world.navigator())
	# **Connected once however often this is called.** `City.build()` calls `setup()` and a rig
	# that wants its own map calls it again on the same manager, which Godot answers with an
	# `ERROR: Signal ... is already connected` — an error line in a headless run is a failed
	# `check.sh`, and a second connection would fire the same forward twice besides.
	if not EventBus.return_phase_started.is_connected(_owe_the_return):
		EventBus.return_phase_started.connect(_owe_the_return)

## Hands the manager a world that is not the city — the escape's building — whose events stand on
## `map` and move by its navigator, belonging to `run`: no city to plan a day over, no director
## siting anything ahead of her, no lights. What runs there is the plan it is given
## (`start_planned()`).
func setup_world(map: WorldMap, run: RunState) -> void:
	world.city = null
	world.city_map = null
	ahead.drop_director()
	world.signals = null
	world.map = map
	world.use_navigator(map.navigator())
	world.run = run

## Hands the manager the run its events belong to, for a rig that builds no city.
func use_run(run: RunState) -> void:
	world.run = run

## **Hands the manager the player**, whose position every instance is told each tick, whose sight
## the events are placed out of and whose catch ends the day; null for none in the world. The run
## flow hands her in whenever she is put into a world (`main._put_her_in()`).
func use_player(player: Node2D) -> void:
	world.player = player

## `--force <id> [seconds]`: the one row the director hands out from the next day on, every
## `interval` seconds, or "" for the ordinary day. See `EventDirector.force()`.
func force(row: String, interval: float) -> void:
	ahead.force(row, interval)

## Forwards to `EventDirector.owe_the_return()` the moment the baby is asleep and the day turns to
## `RETURNING`, for the day she is walking.
##
## **A walk that owes no return is owed none** (`DaySpec.owes_a_return`, false for the escape's
## sections, which have no walk home). `Baby.force_sleep()` emits this signal, and the escape
## force-sleeps her at the top of every section and every retry, so without the setting a walk that
## is outbound from its first frame to its last would be handed the return leg's own pressure at the
## moment it begins, and the director's pacing would tighten to `Tuning.RETURN_PATROL_INTERVAL` for
## the rest of it.
func _owe_the_return() -> void:
	if not _owes_a_return or _recipe_plan:
		return
	ahead.owe_the_return(world.day)

## Clears yesterday and plans today. `consumed_one_shots` is appended to in place.
##
## `focus` is where the player will be standing when the day starts, so the events already
## around the doorstep are in the world on the first frame rather than appearing during it.
func start_day(day: int, rng: RandomNumberGenerator, consumed_one_shots: Array[String],
		focus := Vector2.ZERO) -> void:
	_recipe_plan = false
	clear()
	_hard_failed = false
	_struck_by = ""
	world.day = day
	_encounters.day = day
	streaming.consumed = consumed_one_shots
	# The corridor the city grew this morning, before it placed its closures off it. Passed rather
	# than grown again so that the walls, the friction and the picture are all stated against one
	# tree; `RouteTree.for_day` would give the same answer, and two places agreeing by arithmetic
	# is a thing that stops being true the first time one of them takes an argument. Kept as a local
	# rather than re-read from `world.city` below, for the same reason — `SealPlanner` needs the same
	# tree the catalogue's own placements were just stated against.
	#
	# **`world.city.route_tree()` can itself be null even when `world.city` is not** — a live
	# `world.city` whose own `start_day` was never called for this day, which is the whole rig
	# `tests/test_event_manager.gd` and `tests/test_balance.gd` drive: `EventManager.start_day` on its
	# own, with no `City.start_day` first. A ternary on `world.city` alone always took the true branch
	# there and handed every planner below a null tree — `docs/TODO.md`'s M100 defect, "a rig driving
	# EventManager before City.start_day seals nothing". The explicit null check grows one the same way
	# `City._close_streets` does, from the same `RouteTree.for_day(map, day)`, so the fallback and the
	# real thing can never disagree.
	var tree: RouteTree = world.city.route_tree() if world.city else null
	if not tree:
		tree = RouteTree.for_day(world.city_map, day)
	# Grown the same way `tree` was, so the two never answer for two different days — see
	# `City._close_streets`. `world.city.region_plan()` can itself be null for the same reason as
	# `tree` above, and the explicit null check here falls through to growing one the same way.
	var region_plan: RegionPlanner.RegionPlan = world.city.region_plan() if world.city else null
	if not region_plan:
		region_plan = RegionPlanner.plan_day(world.city_map, day, tree)

	# Held ground, before `EventScheduler.build_day` rolls a single candidate — see
	# `CityMap.held_segments`. Closures, the region's own wall and door segments, and the
	# streets around the home block are all known already; the hard seals are not, which is
	# why `SealPlanner.plan_day` moved ahead of `build_day` below (see that call's own note).
	#
	# A rig driving `EventManager` off a `City` that has not run its own `start_day` yet still
	# gets no closures held: `world.city.closures()` reads `City`'s own `_closures`, which only
	# `City.start_day()` ever populates, and there is no fallback for it the way `tree` and
	# `region_plan` now grow their own just above — closures are `ClosurePlanner`'s to plan, not
	# `EventManager`'s, so a rig that wants them run has to run `City.start_day()` first. The
	# wall, the doors and the home block are still held, because all three come from
	# `region_plan` and `world.map` alone.
	world.city_map.clear_day_holds()
	if world.city:
		for closure in world.city.closures():
			world.city_map.hold_segment(closure.segment.key())
	for segment in region_plan.walls:
		world.city_map.hold_segment(segment.key())
	for segment in region_plan.doors:
		world.city_map.hold_segment(segment.key())
	var spec := _spec if _spec else DaySpec.for_day(day)
	# The seals and events are planned under `spec.number` and the day's streams under `day`: a spec
	# left over from another day would plan that day's catalogue on today's streams, so it fails here.
	assert(spec.number == day, "EventManager.start_day(%d) was handed day %d's spec" % [day, spec.number])
	if spec.holds_the_home_streets:
		for segment in StreetNetwork.around_blocks(Rect2i(world.city_map.home_block, Vector2i.ONE)):
			world.city_map.hold_segment(segment.key())

	# Off the catalogue's own budget on purpose — see `SealPlanner`'s own doc. It seals everything
	# `EventScheduler` was not permitted to touch: every street off `tree` (a share of them from
	# `Tuning.REGION_WALL_FIRST_DAY` on, see `SealPlanner._seals_this_street`), hard or soft, plus the
	# mouths of any through-alley that never reaches it — except today's region boundary, wall or
	# door, and any crossing alley, both skipped here: the wall already carries its own hard seal
	# below, and a door or a crossing alley's own door is meant to stay open for the structure the
	# milestone's second half places there. Segment keys (`Vector3i`) and alley rect positions
	# (`Vector2i`) share one `Dictionary` without colliding — see `SealPlanner.plan_day`'s own doc.
	var boundary := {}
	for segment in region_plan.walls:
		boundary[segment.key()] = true
	for segment in region_plan.doors:
		boundary[segment.key()] = true
	for rect in region_plan.alley_walls:
		boundary[rect.position] = true
	for rect in region_plan.alley_doors:
		boundary[rect.position] = true
	# **Planned before `build_day` now, not after.** `SealPlanner.plan_day` is a pure function of
	# `world.map`, `day`, `tree` and its own RNG stream (`world.run.day_rng(day, "seals")`, never
	# shared with the catalogue's), so moving it earlier changes which seals a day gets not at all —
	# only how soon `build_day` can see where they landed. `held` is `world.city_map.held_segments`
	# itself: a hard seal's segment is marked there as it is placed, so the catalogue never offers a
	# candidate row that same ground (`docs/DECISIONS.md`, M100, "Events spawn inside a fully blocked
	# street").
	var seals := SealPlanner.plan_day(world.city_map, spec, tree, world.run.day_rng(day, "seals"),
			boundary, world.city_map.held_segments)
	# Where today's doors stand, before a single candidate is rolled. `build_day` keeps
	# `Tuning.CHECKPOINT_EVENT_GAP` of clear ground around each of them — the ground she is let out
	# onto, on either side — by refusing a candidate whose field or beat reaches inside it, which is
	# the same "checked before it is accepted, never repaired afterwards" every closure is placed
	# under. The wall's own bodies are deliberately not in this list: a wall is structure and stands
	# where the boundary is.
	var doors := PackedVector2Array()
	for body in region_plan.door_bodies:
		doors.append(body.position)
	# The day's narrow resistance target — day 9's door, day 12's swing, the station's front door —
	# as the tiles its contact may stand on today, and what obstructs the day whatever the
	# catalogue does: the seals just planned and the region wall's own bodies. `build_day` keeps a
	# route from home to one of those tiles among the day's own bodies, the way it keeps one to the
	# calm (`docs/CITY.md`, "Guarantees"). Here rather than in `build_day` because only here is every
	# hold the director refuses already on the map — the closures, the wall and doors, the home's
	# streets and the hard seals — so the tiles protected are tiles the contact may actually take.
	var standing: Array[EventScheduler.Planned] = []
	standing.append_array(seals)
	standing.append_array(region_plan.wall_bodies)
	var plans := EventScheduler.build_day(spec, rng, world.city_map, consumed_one_shots,
			world.run.attempt_spend.scars, world.run.settled_this_act(), tree,
			world.run.resistance.progress, doors,
			ResistanceDirector.target_ground(world.city_map, day, region_plan), standing, trace)
	plans.append_array(seals)
	# The wall's own bodies — hard seals of the roadblock row, one region boundary at a time. Kept
	# as `RegionPlanner`'s own returned list rather than folded into `SealPlanner`'s: a caller that
	# wants to know where the wall stands reads `region_plan.wall_bodies` directly rather than
	# filtering it back out of the whole day's plan.
	plans.append_array(region_plan.wall_bodies)
	# The door structure — a hut on each pavement and a gate over the road at a street door, a
	# guard at each mouth of an alley door. Same reasoning as `wall_bodies` just above: kept as
	# its own list on `region_plan` and appended here rather than merged into `SealPlanner`'s, so
	# `region_plan.door_bodies` stays the one place that answers "where do today's doors stand"
	# without filtering.
	plans.append_array(region_plan.door_bodies)
	# Every stationary solid body the day has sited, recorded per tile so the crowd goes round it —
	# see `CityMap.obstructed_tiles`. Taken from the **plan** rather than from the live instances
	# because a body is a body whether or not the player has come near enough to stream it in, and
	# the crowd is placed and steered across the whole map. Last of the assembly, so that everything
	# the day places — the catalogue's rows, the seals, the wall and the door structure — is in
	# `_plans`, and so that every held segment the record refuses against is already on the map.
	streaming.take(plans)
	for plan in plans:
		if plan.is_placed():
			spawner.record_the_body(plan.get_instance_id(), plan.def, plan.position, plan.facing)
	ahead.start_day(day, tree, doors)
	streaming.stream_around(focus)

## Clears whatever was here and takes a walk's whole plan as given, under `spec`'s settings
## (`use_the_spec()`) and day number, which counts her encounters (`EncounterWatch`).
##
## **Everything `start_day` works out, the plan has already decided**, which is the whole of why
## this is a second entry point rather than a flag on that one. The escape's city has no route tree
## to grow and no region plan to place against — its route is an ordered chain and not a tree — and
## no closures: `FinalePlanner.plan()` has already asked the day's own `SealPlanner.plan_day()` what
## closes the city off the chains and `EventScheduler.build_day()` what stands on them, under the
## section's spec. The building's plan is its own placements (`BuildingPlan`). What arrives here is
## the result.
##
## The streaming, the successors, the scars, the detentions and the hard fails are all the day's
## own and are untouched: an explosion leaves its crater through exactly the `aftermath.on_finish`
## mechanism a convoy leaves a barricade through, and a plan that comes again comes on its own
## clock (`EventStreaming.bring_back_what_repeats()`).
func start_planned(spec: DaySpec, plans: Array[EventScheduler.Planned],
		focus := Vector2.ZERO) -> void:
	_recipe_plan = false
	clear()
	set_physics_process(true)
	_hard_failed = false
	_struck_by = ""
	world.day = world.run.header.day
	_encounters.day = spec.number
	use_the_spec(spec)
	# Nothing is held: a hold keeps the catalogue's own roll off ground something else has taken,
	# and nothing rolls here. Cleared rather than left, so a rig that ran a day before the escape
	# does not leave yesterday's holds on the map.
	if world.city_map:
		world.city_map.clear_day_holds()
	streaming.take(plans)
	streaming.find_what_repeats()
	ahead.start_a_given_walk(world.day)
	streaming.stream_around(focus)

## Accepts only the builder's validated placements. Streaming, collisions, pursuits, event
## successors and warnings keep their production behavior; random siting is suppressed. `spec` is
## the walk the recipe stands for, handed in by the recipe's runtime — a day's, or the escape city's
## — and its settings are the walk's; `day` keys the walk's streams and counts its encounters.
func start_recipe(plans: Array[EventScheduler.Planned], spec: DaySpec, day: int,
		focus: Vector2) -> void:
	var held := world.city_map.held_segments.duplicate()
	start_planned(spec, plans, focus)
	world.city_map.held_segments.merge(held)
	for plan in plans:
		if plan.is_placed():
			spawner.record_the_body(plan.get_instance_id(), plan.def, plan.position, plan.facing)
	world.day = day
	_encounters.day = day
	_recipe_plan = true

## Everything in this world stops, because she is not in it any more: the escape's building once
## she has walked out of its service exit into the city. Every instance goes, its charge counted cut
## short, and nothing comes again until a plan is started here once more (`start_planned()`).
func stand_down() -> void:
	clear()
	set_physics_process(false)

## **The walk's own settings, out of the spec the run flow hands in**: whether falling asleep owes
## her a return (`DaySpec.owes_a_return`) and whether a torn poster sends a pursuer
## (`DaySpec.poster_pursuits`). `main` hands each day's spec in before it starts the day
## (`start_day()`); a walk whose plan is given is handed its spec with the plan (`start_planned()`).
## Until one is handed in, a day's settings (`DaySpec`'s own defaults).
func use_the_spec(spec: DaySpec) -> void:
	_spec = spec
	_owes_a_return = spec.owes_a_return
	ahead.sends_poster_pursuits = spec.poster_pursuits

## **Every charge still running ends for its counter as cut short** (`EventInstance.
## report_the_charge_cut_short()`): asked by `DayDirector.finish_day()` as a day ends, before the
## day's own end is counted, and by `clear()` for anything a section's end leaves running. A charge
## that caught her, or is over, has already ended and is not counted twice. Telemetry only.
func end_the_charges_still_running() -> void:
	for instance in world.instances:
		if is_instance_valid(instance):
			instance.report_the_charge_cut_short()

func clear() -> void:
	end_the_charges_still_running()
	ahead.clear()
	for instance in world.instances:
		instance.queue_free()
	world.instances.clear()
	streaming.clear()
	# Yesterday's bodies go with yesterday's events, the same once-a-day sweep `clear_day_holds()`
	# and `clear_day_soft_seals()` get — every owner in the record is a plan or an instance this
	# call has just thrown away.
	world.map.clear_day_obstructions()
	checkpoints.clear()
	spawner.clear()
	warnings.clear()
	_encounters.end_day()

## The page's counter's encounters and bouts of running — see `EncounterWatch`. Telemetry only: it
## reads and decides nothing gameplay reads.
var _encounters := EncounterWatch.new()

## Tells `_encounters` that `instance` has struck her, for the catch `_watch_the_encounters()` did
## not see: a door's release (`CheckpointController.check_detentions()`) sets her down within
## reach after the watch has run, and the day ends on that frame. Watched on the same terms as a
## tick.
func _tell_the_watch_of_the_catch(instance: EventInstance) -> void:
	if not world.player.is_in_group("player"):
		return
	_encounters.caught_by(instance, world.visible, world.player.global_position)

## Asks `_encounters` about this frame, while a day is being played — the escape's city included,
## which is a day of its own — but not behind the title screen, which runs the city with her stood
## aside out of the `player` group.
func _watch_the_encounters(delta: float) -> void:
	if not world.player.is_in_group("player"):
		return
	var stroller := world.player as Stroller
	var running := stroller != null and stroller.run_excess_ratio() > 0.0
	_encounters.tick(delta, world.instances, world.visible, world.player.global_position, running,
			checkpoints.hold_that_would_begin)

## What she can see this frame — see `world.visible`.
func visible_view() -> VisibleView:
	return world.visible

## Whether a world point is in sight this frame: `VisibleView.sees()` on `world.visible`. `margin`
## world px past the edge count as in sight as well.
func sees(world_position: Vector2, margin := 0.0) -> bool:
	return world.visible.sees(world_position, margin)

## Whether a world point is anywhere in the camera's whole view this frame, the corners the
## joystick's controls cover included: `world.visible`'s view with no corners laid on it, the view
## `PendingWarning.seen_from()` places against. What the resistance asks before it places or
## removes something (`ResistanceDirector.set_sight()`, wired by `main`), since a thing under a
## covered corner is still drawn there *(olive-hedgehog, inbox #598, the player: "off screen is not
## the same as visible -- the corners get removed for visible not for off screen")*. `false` until
## the view has been looked through, the same as `sees()`.
func on_screen(world_position: Vector2) -> bool:
	return world.visible.view.has_point(world_position)

## Tells `world.visible` this frame's view and scheme (`VisibleView.look_through()`): the camera's
## view, `Tuning.VIEW_HALF_EXTENT` about the centre of the screen, which her look-ahead moves off
## her a little, and whether the on-screen controls are the joystick scheme, whose rings and buttons
## cover the view's bottom corners *(inbox #581, the player: "yes, everything should follow this
## (and treat it depending on the input mode)")*.
func _look_through_the_camera() -> void:
	world.visible.look_through(world.player)

## What the run log and the page's counter call the event whose lethal reach ended today
## (`EventInstance.logged_name()` — `pelican` for a pelican, otherwise its row's id), or "" when no
## event's reach has (a car, or nothing yet). Set by `_check_hard_fails()` with the
## `hard_fail_triggered` it sends, read by `DayDirector.finish_day()` for `EventBus.day_ended`, and
## reset with `_hard_failed` when a day starts. Telemetry only.
func what_struck_her() -> String:
	return _struck_by

var _struck_by := ""

## She has crossed a district door — `CheckpointController.door_crossed`, forwarded, so a listener
## asks the day's events rather than the controller behind them (`ResistanceDirector`).
signal door_crossed(at: Vector2, axis: Vector2, inspected: bool)

## How many events are in the world right now — *what is around the player* rather than what the
## day contains; see `planned_count()` for the other question.
func active_count() -> int:
	return world.instances.size()

func instances() -> Array[EventInstance]:
	return world.instances

# ------------------------------------------------------------ WorldContext ---

## Every live instance's own contribution at this point, as `[instance, contribution]` pairs, for
## every instance whose contribution here is actually positive.
##
## **Inside a door, the door's toll is the only thing that charges.** `door_holding_her_at()` below
## says whether this point is inside a running region-door hold; while it is, the hold's own flat
## `Tuning.CHAT_EXCITEMENT` rate is the whole of the answer and every other field in the city is
## off. See that function for why that is a fact about where she is rather than a special case.
##
## **And the region boundary's own structures charge as one source rather than as their sum** —
## *"since two gates can be adjacent to each other their influence shouldn't add up"*. Every
## instance whose def carries `EventDef.barrier_structure` is a piece of a street being held, and
## the strongest of them here is the one that lands; the rest contribute nothing and are not in the
## returned pairs at all, so `Baby._update_excitement()` attributes what actually reaches the bar to
## the structure that was the maximum and `ExcitementHalo`'s colour follows it by construction.
## Everything else in the catalogue still sums, which is the contract the density is built on.
func excitement_sources_at(world_position: Vector2) -> Array:
	var inside := door_holding_her_at(world_position)
	if inside:
		return [[inside, inside.contribution_at(world_position)]]
	var sources: Array = []
	# Ties keep the first of `world.instances`, which is the order the day streamed them in — a stable,
	# seed-determined answer rather than one that depends on floating-point luck.
	var strongest: EventInstance = null
	var strongest_rate := 0.0
	for instance in world.instances:
		var contribution := instance.contribution_at(world_position)
		if contribution <= 0.0:
			continue
		if instance.def.barrier_structure:
			if contribution > strongest_rate:
				strongest_rate = contribution
				strongest = instance
			continue
		sources.append([instance, contribution])
	if strongest:
		sources.append([strongest, strongest_rate])
	return sources

## The one barrier structure that lands at `world_position` — the strongest of them, the same
## answer `excitement_sources_at()` keeps — or `null` when none reaches. Used once a frame by
## `_tell_them_where_she_is()` to tell the others they are outranked, so the caret and the halo
## agree with the meter about which body is charging her. See
## `EventInstance.outranked_by_a_stronger_barrier`.
func _strongest_barrier_at(world_position: Vector2) -> EventInstance:
	var strongest: EventInstance = null
	var strongest_rate := 0.0
	for instance in world.instances:
		if not instance.def.barrier_structure:
			continue
		var contribution := instance.contribution_at(world_position)
		if contribution > strongest_rate:
			strongest_rate = contribution
			strongest = instance
	return strongest

## The region door whose hold is running right now and whose trigger circle `world_position` lies
## inside, or null: `CheckpointController.door_holding_her_at()`. Inside a door, the door's toll is
## the only thing that charges (`excitement_sources_at()`), and `City` asks it for the crowd's half.
func door_holding_her_at(world_position: Vector2) -> EventInstance:
	return checkpoints.door_holding_her_at(world_position)

func total_excitement_at(world_position: Vector2) -> float:
	var total := 0.0
	for pair in excitement_sources_at(world_position):
		total += pair[1]
	return total

# ------------------------------------------------------------------ ticking ---

func _physics_process(delta: float) -> void:
	if FrameRecord.on:
		var outer := FrameRecord.enter(FrameRecord.EVENTS)
		_tick_the_events(delta)
		FrameRecord.leave(outer)
	else:
		_tick_the_events(delta)

## The manager's own tick, timed under `FrameRecord.EVENTS`.
func _tick_the_events(delta: float) -> void:
	streaming.broadcast_clock += delta
	streaming.retire_finished()
	streaming.bring_back_what_repeats(delta)
	var she_is_here := world.has_player()
	if she_is_here:
		# First, so everything below asks the same view of what she can see this frame.
		_look_through_the_camera()
		# Before the streaming, so a plan sited this frame is in the world on the same frame it
		# would have been had the day placed it at dawn. Nothing is sited in a world with no
		# director.
		if not _recipe_plan and ahead.has_director():
			ahead.site_what_is_on_her_way(delta)
		streaming.stream_around(world.player.global_position)
		if not _recipe_plan and ahead.has_director():
			ahead.place_what_is_owed_ahead(delta)
		spawner.summon_what_has_been_sighted(streaming.plans())
		spawner.report_the_pelicans_in_view()
		_watch_the_encounters(delta)
		warnings.run(delta, world.player.global_position)
		_tell_them_where_she_is()
	# Then every live event takes its step, having been told where she is, with or without her.
	_step_them(delta)
	if she_is_here:
		ahead.let_the_officers_out()
		warnings.warn_about_the_ground_she_is_on()
		checkpoints.warn_at_the_doors()
		checkpoints.watch_the_door_lines(delta)
		checkpoints.check_detentions()
	# Last, on the same tick as the step that caught her.
	_check_hard_fails()

## **Every live event's step, once a physics tick, in the order they live in `world.instances`**
## (`EventInstance.step()`). What the tick made before it (a successor, a repeat, a streamed or
## summoned row) takes its first step on the tick it is made; what is made during or after it (an
## officer, a door's guard, anything an event's own step sets off) takes its first on the next,
## since the step runs over a copy. One a hand holds (`EventInstance.held_by_hand`) is left as it
## stands.
func _step_them(delta: float) -> void:
	for instance in world.instances.duplicate():
		if is_instance_valid(instance) and not instance.held_by_hand:
			instance.step(delta)

## Hands every instance her position.
##
## Here rather than in the instance for the same reason `Crowd` writes `pedestrian_ahead` rather
## than letting each car look: the player is found once a frame in one place, and an
## `EventInstance` has never had to know she exists. It is handed a point, and everything it does
## with the point is a distance.
##
## Everything gets it, not only the pursuers: *"am I out of sight yet"* is the same question asked
## by anything that is **leaving** — see `EventInstance._be_done`.
##
## The second fact handed over is whether she is running, and **`world.player` is deliberately a
## `Node2D`**: the cast is here rather than on the field so that "an instance is handed a point"
## stays true of everything except the one row that has to know. A `Node2D` has no
## `run_excess_ratio`, so reading it off the untyped field is a per-frame runtime error that aborts
## this whole callback and stops the day dead — and `check.sh` cannot see it, because nothing is
## wrong until it runs.
## **The third fact is which barrier structure is the one charging her**, and it is handed over
## here because this is already the once-a-frame visit to every instance that knows where she is.
## `excitement_sources_at()` keeps only the strongest of the boundary kit, so a caret or a halo
## rim on one of the others would be promising a cost the meter is not taking — see
## `EventInstance.outranked_by_a_stronger_barrier`.
func _tell_them_where_she_is() -> void:
	var stroller := world.player as Stroller
	var running: bool = stroller != null and stroller.run_excess_ratio() > 0.0
	var awake: bool = stroller == null or stroller.baby_is_awake()
	var strongest := _strongest_barrier_at(world.player.global_position)
	# Inside a district door's hold, nothing but the door's toll reaches her
	# (`door_holding_her_at()`), so a man who would stop her waits for her outside
	# (`EventInstance.she_is_held`).
	var held := door_holding_her_at(world.player.global_position) != null
	# Her pram's own body, on her circumference along her facing — what a car that drives keeps clear
	# of as well as her (`EventInstance.pram_at`). None while she carries the baby.
	var pram := Vector2.INF
	if stroller != null and not stroller.carrying:
		pram = stroller.global_position + stroller.facing * Tuning.PLAYER_BODY_RADIUS
	for instance in world.instances:
		instance.player_at = world.player.global_position
		instance.player_view = world.visible.view
		instance.pram_at = pram
		instance.player_running = running
		instance.baby_awake = awake
		instance.she_is_held = held
		instance.outranked_by_a_stronger_barrier = \
				instance.def.barrier_structure and instance != strongest

## How many times today she has walked across a door's line rather than being let through it:
## `CheckpointController.walks_under_a_boom()`.
func walks_under_a_boom() -> int:
	return checkpoints.walks_under_a_boom()

func _check_hard_fails() -> void:
	if _hard_failed or not world.has_player():
		return
	for instance in world.instances:
		if instance.is_lethal_at(world.player.global_position):
			_hard_failed = true
			_struck_by = instance.logged_name()
			_tell_the_watch_of_the_catch(instance)
			# The charge's own catch, counted whatever the day does (`EventInstance.report_the_catch()`).
			instance.report_the_catch()
			# Ahead of the hard fail, which ends the day and sends its loss.
			if instance.is_pelican:
				EventBus.pelican_struck_her.emit(instance)
			EventBus.hard_fail_triggered.emit(instance.def.id)
			return

# ------------------------------------------------------------ the doors' intents ---
# `CheckpointController` says what a door does to her and this carries it out on the player it was
# handed, on the same tick and in the order the controller says it (the signals are synchronous).

## **She goes in, out of sight, and the camera goes to the door** — on the tick the hold starts, so
## no drawn frame catches her outside.
func _take_her_in(door_at: Vector2) -> void:
	var body := world.player as Stroller
	if body:
		body.hide_for_inspection()
		body.focus_camera_on(door_at)

## Her controls are locked for a hold's `seconds` (`Stroller.detain()`).
func _hold_her(seconds: float) -> void:
	var body := world.player as Stroller
	if body:
		body.detain(seconds)

## **Moved, then shown, in that order and on this one tick**: `teleport_to()` puts her down and
## resets her interpolation, so the first frame drawn after this draws her at the door she is coming
## out of and nowhere else; the camera comes back here too, so its ease home starts from the hut
## toward where she actually is.
func _let_her_out(at: Vector2) -> void:
	var body := world.player as Stroller
	if body:
		body.teleport_to(at)
		body.show_after_inspection()
		body.release_camera_focus()

# ------------------------------------------------------------------ the public face ---
# What the run flow, the resistance, the city and the observers ask of a day's events, answered by
# the part that owns it.

## Brings into the world everything within reach of `at` (`EventStreaming.stream_around()`).
func stream_around(at: Vector2) -> void:
	streaming.stream_around(at)

## The planned instance of the row `id` within a tile of `at`, put in the world and kept there
## (`EventStreaming.keep_live()`).
func keep_live(id: String, at: Vector2) -> EventInstance:
	return streaming.keep_live(id, at)

## Takes today's plans of the rows `ids` inside `rect` out of the day
## (`EventStreaming.take_away_within()`).
func take_away_within(rect: Rect2, ids: Array[String]) -> int:
	return streaming.take_away_within(rect, ids)

## Today's foot for a mast id (`EventStreaming.mast_foot()`).
func mast_foot(mast_id: String) -> Vector2:
	return streaming.mast_foot(mast_id)

## Silences one mast for the rest of the day (`EventStreaming.silence_mast()`).
func silence_mast(mast_id: String) -> bool:
	return streaming.silence_mast(mast_id)

## Silences every mast for the rest of the day (`EventStreaming.silence_all_masts()`).
func silence_all_masts() -> int:
	return streaming.silence_all_masts()

## How many sited events the day is carrying (`EventStreaming.planned_count()`).
func planned_count() -> int:
	return streaming.planned_count()

## The day's plan, for the readouts and the telemetry. Not for anything that acts on it.
func plans() -> Array[EventScheduler.Planned]:
	return streaming.plans()

## Events the day has budgeted for the director to put in front of her and has not spent yet.
func owed_ahead() -> int:
	return ahead.owed_ahead()

## The warnings up for something not in the world yet — what `DangerEdge` draws a badge for
## alongside `instances()` (`WarningBoard.pending_warnings()`).
func pending_warnings() -> Array[PendingWarning]:
	return warnings.pending_warnings()

## Puts up a warning for `def` with nothing in the world yet (`WarningBoard.warn_first()`).
func warn_first(def: EventDef, her: Vector2, where: Callable,
		arrive: Callable) -> PendingWarning:
	return warnings.warn_first(def, her, where, arrive)

## Creates `def` on `path` for a row whose warning ran before it existed
## (`EventSpawner.spawn_warned()`).
func spawn_warned(def: EventDef, path: PackedVector2Array, pelican := false) -> EventInstance:
	return spawner.spawn_warned(def, path, pelican)

## Adds an event outside the day's plan and outside the streaming, at a path the caller chose — the
## resistance's robbery, its neighbor, raid and column (`EventSpawner.spawn()`).
func spawn_extra(def: EventDef, at: Vector2, path := PackedVector2Array()) -> EventInstance:
	return spawner.spawn(def, at, path)

## Retires one unplanned instance (`EventSpawner.retire()`).
func retire(instance: EventInstance) -> void:
	spawner.retire(instance)

## Moves one unplanned instance with everything it is in the middle of
## (`EventSpawner.move_extra()`).
func move_extra(instance: EventInstance, at: Vector2) -> void:
	spawner.move_extra(instance, at)

## One more mast for day 11's task (`EventsAhead.queue_a_mast()`).
func queue_a_mast(offered: Array[Vector2i], rng: RandomNumberGenerator) -> EventScheduler.Planned:
	return ahead.queue_a_mast(offered, rng)

## A task's own row, placed the way the day places one, near her (`EventsAhead.queue_a_task_row()`).
func queue_a_task_row(def: EventDef, offered: Array[Vector2i], rng: RandomNumberGenerator,
		her: Vector2) -> EventInstance:
	return ahead.queue_a_task_row(def, offered, rng, her)

## Does at dawn the one-time work of a task row's placement (`EventsAhead.prepare_a_task_row()`).
func prepare_a_task_row(def: EventDef) -> void:
	ahead.prepare_a_task_row(def)

## Rigs her route's bag for a task (`EventsAhead.rig_her_route()`).
func rig_her_route(ids: Array[String], size: int) -> Array:
	return ahead.rig_her_route(ids, size)

## Lights the set piece she never met, at dusk on a won day
## (`EventsAhead.light_what_she_never_met()`).
func light_what_she_never_met(at: Vector2) -> bool:
	return ahead.light_what_she_never_met(at)

## A torn poster drew the pursuit marble (`EventsAhead.send_a_pursuer()`).
func send_a_pursuer() -> void:
	ahead.send_a_pursuer()

## A scene's route, from the bag its recipe rigs, with everything the director does while she walks
## switched back on (`EventsAhead.start_recipe_route()`).
func start_recipe_route(marbles: Array, pre_bag: Array, owed: int, first_after: float) -> int:
	_recipe_plan = false
	return ahead.start_recipe_route(marbles, pre_bag, owed, first_after)

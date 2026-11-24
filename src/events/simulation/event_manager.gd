class_name EventManager
extends Node
## **A day's events, in whatever world she walks**: the one thing the run flow, the resistance, the
## city and the observers talk to about events. It starts a day (`start_day()`), steps its live
## instances once a physics tick in a fixed order (`_tick_the_events()`), answers what charges the
## baby at a point (`excitement_sources()`), sees what struck her (`check_hard_fails()`) and
## ends the day's charges. The work behind that face is handed to the parts that own it, each handed
## the one `EventWorld` they share:
##
## - `WalkEvents`: the walk's plans, and what it was planned against (the doors, the calm areas),
##   read through one object by everything that acts on them;
## - `EventStreaming`: the live instance each plan streams in as, the repeats, the masts, a
##   finished plan spent;
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
## events stand in (`WorldMap`) and starts every walk on it the one way (`start_day(spec)`): the
## spec chooses what plans it (`DayPlanner`) — a city's day, the escape's city on its two chains, the
## building's own placements (`BuildingPlan`). A world that is not the city has no city to plan a
## day over: no director sites anything ahead of her there, and a plan that comes again
## (`EventPlan.repeats()`) is brought back on its own clock.
##
## **Handed what it depends on, never fetching it**: what its events are set up in, built where its
## world is and handed as the manager is made (`EventManager.new()`, `EventSurroundings`: the map
## and whether it is the city's, the navigator, the lights, the run log, the atlas, the drawing and
## the frame timing); then the run, today's streets and the poster walls (`setup()`), once, since
## a manager is set up for one world and asserts so; the player (`use_player()`); the walk's spec
## (`use_the_spec()`).
##
## Lookup is a linear scan. Only what is inside `EVENT_STREAM_RADIUS` is live, a few dozen at most
## — that many distance checks per physics tick is nothing, and a spatial hash would be more code with more
## ways to be subtly wrong. Revisit if an act ever wants hundreds of sources at once.
##
## **This node owns no instance as a scene child.** Every `EventInstance` is added to the world it
## is drawn in (`EventSurroundings.world_drawn_in()`, `WorldContext.add_entity()`), under that
## world's y-sorted entity layer rather than under here, so `EventInstance._ready()` sets its own
## physics interpolation rather than inheriting the setting from this node.

## What every part works over: the world, the run, the player, what she can see and the live
## instances.
var world: EventWorld
## The walk's plans, read through one object (`walk_events()`).
var _walk_events := WalkEvents.new()
## The live instances the walk's plans stream in as.
var _streaming: EventStreaming
## Every instance made, what a finished row leaves, the summons and the pelican bag.
var _spawner: EventSpawner
## The warnings up for something not in the world yet, and the mark over her head.
var _warnings: WarningBoard
## What the director puts in front of her while she walks.
var _ahead: EventsAhead
## **The district doors as she meets them** (`CheckpointController`): the holds, the releases, the
## walks under a raised boom and the guard a crossing sets on her, over this manager's own live
## instances.
var _checkpoints: CheckpointController
## **Hands in what a protest points at**, answering a world point or `Vector2.INF` for nothing: the
## resistance's (`ResistanceDirector.setup()`, its `_pointable_objective()`), asked on behalf of
## every instance made here, an instance made before it was handed included, since they share
## the one `EventSurroundings`. Never handed where there is no resistance, and a protest then
## points at nothing.
func use_protest_target(where: Callable) -> void:
	world.surroundings().pointing_protests_with(where)

## **Sets how close the player has to be for a planned event to exist**
## (`EventStreaming.stream_within()`). `INF` turns streaming off and puts the whole day in the world
## at once, every unit of the day's drawn at the walk's start, which is what the escape's building
## and a test rig with no player want.
func stream_within(radius: float) -> void:
	_streaming.stream_within(radius)

var _hard_failed := false

## Whether falling asleep owes her a return on this walk (`DaySpec.owes_her_a_return()`), as the run flow
## hands it in (`use_the_spec()`): a day's, `DaySpec`'s own default, until a spec is handed in.
var _owes_a_return := true
## What plans each walk `start_day()` starts, chosen by its spec (`DaySpec`): a day's, the escape
## city's or the building's (`DayPlanner`), handed the one world every part shares. A rig that hands
## a walk's placements in on purpose hands its own planner in its place.
var _planner: DayPlanner

## **Hands in what plans each walk** `start_day()` starts, in place of the day planner this makes: a rig
## that hands a walk's placements in on purpose (`GivenPlanner`).
func use_planner(planner: DayPlanner) -> void:
	_planner = planner
## The walk the last plan was stated against (`walk()`).
var _walk: RouteSource = null

## Authored scenes install a complete event plan; ambient directors cannot replace its actors.
var _recipe_plan := false

## Builds the parts, each handed the one world, and connects the doors' intents and crossings.
## `surroundings` is what its events are set up in, built where the world is (`SimulationBuilder`);
## none, and they are set up on open ground with every default, as a suite's manager is.
func _init(surroundings: EventSurroundings = null) -> void:
	world = EventWorld.new(surroundings)
	_warnings = WarningBoard.new(world)
	_planner = DayPlanner.new(world)
	_spawner = EventSpawner.new(world, _warnings)
	_streaming = EventStreaming.new(world, _spawner, _walk_events)
	_ahead = EventsAhead.new(world, _streaming, _spawner, _warnings, _walk_events)
	_ahead.use_sitings(SitingMaker.new(world, _walk_events))
	_checkpoints = CheckpointController.new(world, _spawner.spawn, EventCatalogue.door_guard())
	_encounters = EncounterWatch.new(world.reports())
	_sources = EventSources.new(world, _checkpoints)
	_checkpoints.door_crossed.connect(func(at: Vector2, axis: Vector2, inspected: bool) -> void:
			door_crossed.emit(at, axis, inspected))
	_checkpoints.takes_her_in.connect(_take_her_in)
	_checkpoints.holds_her.connect(_hold_her)
	_checkpoints.lets_her_out.connect(_let_her_out)

## Takes the one reference on the baked page every `EventInstance` draws from — the whole catalogue,
## the checkpoint kit and the crater on one page (`EventPictures.ATLAS_GROUP`), for the manager's
## own life rather than one per family per instant: a page that came and went with the last instance
## of a family would be a blocking read from disk in a played frame the next time one streamed in
## (PLAYTEST-109). In a booted game the count is on a page `main.RESIDENT_GROUPS` already holds; the
## pair is what proves the page is there while a day's events draw from it.
## `_enter_tree()`/`_exit_tree()` rather than `_ready()`, so a manager that leaves the tree and
## comes back keeps the count right.
func _enter_tree() -> void:
	world.surroundings().atlas().acquire(EventPictures.ATLAS_GROUP)

func _exit_tree() -> void:
	world.surroundings().atlas().release(EventPictures.ATLAS_GROUP)

## **Lets go of the warnings when the manager goes**, so the parts go with it. A warning still up
## holds the callbacks that put its row in the world or owe it again (`PendingWarning.arrive`,
## the retry `when_withdrawn()` hands it), and those hold the part that raised it (`EventsAhead`, `EventSpawner`), which
## holds the board the warning is on: a ring of references nothing else breaks, which would keep
## the parts, the world and its map alive past the manager.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_warnings.clear()
		_ahead.clear()

## **Hands the manager the parts of its world that are not what its events are set up in**: the run
## its events belong to, today's streets (`DayStreets`), the city's own, which a day is planned
## against and a siting reads its region off, and the poster walls a crew pastes on
## (`PosterWalls`). The map, the navigator and the lights it works over are asked of what its
## events are set up in (`EventSurroundings`). Where that is the city's map
## (`EventSurroundings.in_the_city()`) the city's plan builder is made here, once, over it
## (`EventWorld.plan_builder()`), and so is where something sent at her may start
## (`spawn_siting()`); a world that is not the city has none, no director siting anything ahead
## of her, and what runs there is the walk it is handed (`start_day()`).
## A rig that builds no city hands what it has and null for the rest: a day it starts is planned
## against the streets it hands, so it hands streets whose day it began (`DayStreets.begin_day()`).
##
## **A manager is set up once, for one world**: nothing is undone by a second call, so one is
## refused in a debug run.
func setup(run: RunState, streets: DayStreets = null, poster_walls: PosterWalls = null) -> void:
	assert(not _set_up, "a manager is set up for one world")
	_set_up = true
	world.use_run(run)
	world.use_streets(streets)
	world.use_poster_walls(poster_walls)
	var map := world.city_map()
	if map == null:
		return
	world.work_out_mast_sites(map)
	world.use_plan_builder(PlanBuilder.new(map, EventInstance.mover_for,
			StreetInvalidation.room_around))
	var director := EventDirector.new(map, world.navigator())
	_spawn_siting = SpawnSiting.new(map, world.navigator(), visible_view,
			streets.siting_region if streets else Callable())
	_ahead.use_director(director, _spawn_siting)

## **Where something sent at her may start in the city** (`SpawnSiting`): made once, in `setup()`,
## over the map against the navigator, this manager's own view of her and the day's region, and
## handed to the director here and to the resistance by whoever builds both. Null in a world that
## is not the city.
func spawn_siting() -> SpawnSiting:
	return _spawn_siting

## The siting `spawn_siting()` answers, made by `setup()`; null in a world that is not the city.
var _spawn_siting: SpawnSiting
## Whether `setup()` has been called: a manager is set up for one world.
var _set_up := false

## The event bus script, so the bus handed in has a class.
const _BUS := preload("res://src/autoload/event_bus.gd")

## **Hands the manager the bus its events report on, and it hears the baby fall asleep on**
## (`return_phase_started`, for the return leg's patrols: `_owe_the_return()`), or null for none.
## Whoever stands the manager hands it once, as it makes it (`SimulationBuilder`). Every part says
## what happened through the world's one `EventReports`, so the bus reaches all of them, a live
## event already in the world included, and nothing has to be handed before `setup()`. A manager
## handed none reports to nobody and is never told she is on her way home.
func use_bus(bus: _BUS) -> void:
	world.reports().use_bus(bus)
	if bus and not bus.return_phase_started.is_connected(_owe_the_return):
		bus.return_phase_started.connect(_owe_the_return)

## **Hands the manager the player**, whose position every instance is told each tick, whose sight
## the events are placed out of and whose catch ends the day; null for none in the world. The run
## flow hands her in whenever she is put into a world (`main._put_her_in()`).
func use_player(player: Node2D) -> void:
	world.use_player(player)

## **Hands the manager what the on-screen controls cover** (`TouchControls.covering()`), which the
## day's view reads the scheme from each frame (`VisibleView.use_cover()`); null for none, the tap
## scheme's whole view. Handed in by `main` from the UI that owns the controls.
func use_controls(covering: ScreenCover) -> void:
	world.visible_view().use_cover(covering)

## `--force <id> [seconds]`: the one row the director hands out from the next day on, every
## `interval` seconds, or "" for the ordinary day. See `EventDirector.force()`.
func force(row: String, interval: float) -> void:
	_ahead.force(row, interval)

## Forwards to `EventDirector.owe_the_return()` the moment the baby is asleep and the day turns to
## `RETURNING`, for the day she is walking.
##
## **A walk that owes no return is owed none** (`DaySpec.owes_her_a_return()`, false for the escape's
## sections, which have no walk home). `Baby.force_sleep()` emits this signal, and the escape
## force-sleeps her at the top of every section and every retry, so without the setting a walk that
## is outbound from its first frame to its last would be handed the return leg's own pressure at the
## moment it begins, and the director's pacing would tighten to `EventDirector.RETURN_PATROL_INTERVAL` for
## the rest of it.
func _owe_the_return() -> void:
	if not _owes_a_return or _recipe_plan:
		return
	_ahead.owe_the_return(world.day())

## **Starts a walk: clears whatever was here and plans `spec`'s** — a day, the escape's city or the
## escape's building — on `rng`, through the planner chosen by the spec (`DayPlanner`), and takes
## what it places as the walk's plan. `consumed_one_shots` is the one-shots the run has already spent,
## appended to in place as a day spends them. The one entry for every walk: what differs between a
## day and a section of the escape is the spec's.
##
## `focus` is where the player will be standing when the walk starts, so the events already
## around her are in the world on the first frame rather than appearing during it.
##
## **A day is keyed by its own number** (`DaySpec.day_number()`): its streams and the rows it sends. **The
## escape's sections keep the run's last day**, on whose streams their plans are drawn
## (`DaySpec.day_number()`'s own doc), and count her encounters under their own number. A day leaves the
## director what it owes her walk (`EventsAhead.start_day()`) and records its bodies for
## the crowd; a walk planned whole before she sets off owes the director nothing
## (`EventsAhead.start_a_given_walk()`), and a plan of it that comes again
## (`EventPlan.repeats()`) comes on its own clock
## (`EventStreaming.bring_back_what_repeats()`). The streaming, the successors, the scars, the
## detentions and the hard fails are the same for all three: an explosion leaves its crater through
## the same `aftermath.leaves_behind()` mechanism on the escape's streets as it would anywhere.
func start_day(spec: DaySpec, rng: RandomNumberGenerator, consumed_one_shots: Array[String],
		focus := Vector2.ZERO) -> void:
	_begin(spec)
	_streaming.use_the_spent_one_shots(consumed_one_shots)
	var plan := _planner.plan(spec, rng, consumed_one_shots)
	_take(spec, plan, focus, plan.belongs_to_a_day())

## **The first half of every walk's start**, before anything is planned: clears whatever was here
## (so the planning sees the map without yesterday's holds and bodies) and takes the walk's settings.
func _begin(spec: DaySpec) -> void:
	_recipe_plan = false
	_clear()
	set_physics_process(true)
	_hard_failed = false
	_struck_by = ""
	use_the_spec(spec)

## **The second half, which every walk shares** (a day, a section of the escape, a scene's recipe):
## takes `plan`'s placements, draws the day's units round `focus` (a day's alone has a unit draw)
## and streams the events around `focus`. A day's plan, and a scene recipe's
## (`records_its_bodies`), records its bodies; a day's hands the director what the day owes her, and
## a walk planned whole hands it nothing. `world.day()` is the plan's: the day's own number for a day,
## the run's last day for the escape's sections.
func _take(spec: DaySpec, plan: DayPlanner.Plan, focus: Vector2, records_its_bodies: bool) -> void:
	world.take_the_day(spec.day_number() if plan.belongs_to_a_day() else world.run().header().day())
	_encounters.count_under(spec.day_number())
	_walk = plan.walk()
	# Where she can get to from home, worked out as the walk starts, from what it planned and the
	# map's closures and soft seals as they stand now, and told what each unit draws (`DayReach`).
	var reach := DayReach.of(world.city_map(), plan.placements()) if world.city_map() else null
	_walk_events.take(plan.placements(), plan.calm(), plan.doors(), reach, plan.locations(),
			plan.ground(), plan.unit_draw())
	# Every stationary solid body the walk has sited, where `records_its_bodies` (a day, a scene
	# recipe), recorded per tile so the crowd goes round it — see `CityMap.obstructed_tiles`. Taken
	# from the **plan** rather than from the live instances because a body is a body whether or not
	# the player has come near enough to stream it in, and the crowd is placed and steered across
	# the whole map. After the whole plan is assembled, so that everything the dawn places — its
	# rows, the seals, the wall and the door structure — is in it, and every held segment the record
	# refuses against is already on the map; a unit's draws are recorded as each unit draws
	# (`EventStreaming.add()`).
	if records_its_bodies:
		for placed in plan.placements():
			if placed.is_placed():
				_spawner.record_the_body(placed.get_instance_id(), placed.row(),
						placed.placed_at(), placed.faces())
	if plan.belongs_to_a_day():
		_ahead.start_day(world.day(), plan.walk() as RouteTree)
	else:
		_streaming.find_what_repeats()
		_ahead.start_a_given_walk(world.day(), plan.walk() as RouteTree)
	# What works out the route of a row the director sends ahead of her as it goes (`WayOn`): made
	# once a walk, after the walk's bodies are recorded, so the dawn's seals, the region wall and its
	# doors, or a scene recipe's rows, are in its through roads with the day's closures. A body put
	# down later is asked of the ground leg by leg.
	if world.city_map() and _ahead.director():
		_ahead.director().use_way_on(WayOn.new(world.city_map(), world.navigator(),
				ThroughRoads.over(world.city_map(), Mover.vehicle())))
	# The day's units round where she starts draw before anything streams in (`stream_around()`).
	stream_around(focus)

## The walk the plan `start_day()` started is stated against (`RouteSource`): the day's route tree,
## the escape's two chains (`FinalePlanner.Plan`), or null in the building and before a walk starts.
func walk() -> RouteSource:
	return _walk

## Accepts only the builder's validated placements. Streaming, collisions, pursuits, event
## successors and warnings keep their production behavior; random siting is suppressed. `spec` is
## the walk the recipe stands for, handed in by the recipe's runtime — a day's, or the escape city's
## — and its settings are the walk's; `day` keys the walk's streams and counts its encounters.
## `calm` is the calm areas the recipe's rows were placed against (`calm_as_the_map_stands()`), so
## the walk sites against the same ones; a rig that places none hands none. `ground` is the
## ground the recipe's rows were placed on (`EventScheduler.row_ground()`), which the walk's
## events answer (`WalkEvents.ground()`) so what is sited while she walks asks it rather than
## making one; a rig that hands none, whether it places rows or not, has the walk make its own as
## a walk no dawn planned does. `tree` and `locations` are the route tree and the day's
## locations the recipe's rows were placed against, which what is sited while she walks (day
## 11's queued mast, a rigged route) and day 13's task are handed rather than growing and laying
## out their own; a rig that hands none has them made then.
##
## **The recipe's holds stay**: its builder holds what it placed (`SceneRecipeRuntime`), and nothing
## here rolls against them. Its plans are taken as a walk planned whole is (`start_day()`), with
## their bodies recorded as a day's are.
func start_recipe(plans: Array[EventPlan], spec: DaySpec, day: int,
		focus: Vector2, calm: CalmAreas = null, ground: RowGround = null,
		tree: RouteTree = null, locations: DayLocations = null) -> void:
	var plan := DayPlanner.Plan.new(plans, tree, PackedVector2Array(), false)
	if ground:
		plan.use_ground(ground)
	plan.use_locations(locations)
	# The recipe's walk is sited against the calm areas its rows were placed against, or, handed
	# none, those a day's would be as the map stands.
	if calm:
		plan.use_calm(calm)
	elif world.city_map():
		plan.use_calm(_planner.calm_as_the_map_stands())
	_begin(spec)
	# Its rows' bodies are recorded as a day's are, before its way on is made, so its through roads
	# have them (`_take()`).
	_take(spec, plan, focus, true)
	world.take_the_day(day)
	_encounters.count_under(day)
	_recipe_plan = true

## **The day's calm areas as the map stands now** (`DayPlanner.calm_as_the_map_stands()`): what a
## scene recipe's rows are placed against, handed back to `start_recipe()` so its walk sites against
## the same ones.
func calm_as_the_map_stands() -> CalmAreas:
	return _planner.calm_as_the_map_stands()

## Everything in this world stops, because she is not in it any more: the escape's building once
## she has walked out of its service exit into the city. Every instance goes, its charge counted cut
## short, and nothing comes again until a walk is started here once more (`start_day()`).
func stand_down() -> void:
	_clear()
	set_physics_process(false)

## **The walk's own settings, out of the spec the run flow hands in**: whether falling asleep owes
## her a return (`DaySpec.owes_her_a_return()`), and the two `EventsAhead` takes from the spec
## itself (`use_the_walk_of()`): whether a torn poster sends a pursuer and whether what is sited
## after dawn keeps off the home's streets, which `EventsAhead` keeps as the rule it makes a ground
## under for a walk no dawn planned; a day's ground keeps the rule it was made under at dawn. Every
## walk hands its spec in as it starts (`start_day()`); a rig may hand another in mid-walk, which
## sets the rule of a ground made after it for a walk no dawn planned and leaves a day's ground, and
## so a day's later sitings, as dawn made it. Until one is handed in, a day's settings (`DaySpec`'s
## own defaults).
func use_the_spec(spec: DaySpec) -> void:
	_owes_a_return = spec.owes_her_a_return()
	_ahead.use_the_walk_of(spec)

## **Every charge still running ends for its counter as cut short** (`EventInstance.
## report_the_charge_cut_short()`): asked by `DayDirector.finish_day()` as a day ends, before the
## day's own end is counted, and by `_clear()` for anything a section's end leaves running. A charge
## that caught her, or is over, has already ended and is not counted twice. Telemetry only.
func end_the_charges_still_running() -> void:
	for instance in world.instances():
		if is_instance_valid(instance):
			instance.report_the_charge_cut_short()

func _clear() -> void:
	# The last walk's word is nobody's now: an event streamed in before the new walk's first word
	# hears nowhere, not where she stood at the end of the last one.
	world.where_she_is().forget()
	end_the_charges_still_running()
	_ahead.clear()
	for instance in world.instances():
		instance.take_out()
	world.let_go_of_every_event()
	_streaming.clear()
	# Yesterday's bodies go with yesterday's events, the same once-a-day sweep `clear_day_holds()`
	# and `clear_day_soft_seals()` get — every owner in the record is a plan or an instance this
	# call has just thrown away.
	world.map().clear_day_obstructions()
	_checkpoints.clear()
	_spawner.clear()
	_warnings.clear()
	_encounters.end_day()

## The page's counter's encounters and bouts of running — see `EncounterWatch`. Telemetry only: it
## reads and decides nothing gameplay reads.
var _encounters: EncounterWatch

## Tells `_encounters` that `instance` has struck her, for the catch `_watch_the_encounters()` did
## not see: a door's release (`CheckpointController.check_detentions()`) sets her down within
## reach after the watch has run, and the day ends on that frame. Watched on the same terms as a
## tick.
func _tell_the_watch_of_the_catch(instance: EventInstance) -> void:
	if not world.player().is_in_group("player"):
		return
	_encounters.caught_by(instance, world.visible_view(), world.player().global_position)

## Asks `_encounters` about this frame, while a day is being played — the escape's city included,
## which is a day of its own — but not behind the title screen, which runs the city with her stood
## aside out of the `player` group.
func _watch_the_encounters(delta: float) -> void:
	if not world.player().is_in_group("player"):
		return
	var stroller := world.player() as Stroller
	var running := stroller != null and stroller.run_excess_ratio() > 0.0
	_encounters.tick(delta, world.instances(), world.visible_view(), world.player().global_position, running,
			_checkpoints.hold_that_would_begin)

## What she can see this frame — see `world.visible_view()`.
func visible_view() -> VisibleView:
	return world.visible_view()

## Whether a world point is in sight this frame: `VisibleView.sees()` on `world.visible_view()`. `margin`
## world px past the edge count as in sight as well.
func sees(world_position: Vector2, margin := 0.0) -> bool:
	return world.visible_view().sees(world_position, margin)

## Tells `world.visible_view()` this frame's view and scheme (`VisibleView.look_from()`): the camera's
## view, `Tuning.VIEW_HALF_EXTENT` about the centre of the screen, which her look-ahead moves off
## her a little, and whether the on-screen controls are the joystick scheme, whose rings and buttons
## cover the view's bottom corners *(inbox #581, the player: "yes, everything should follow this
## (and treat it depending on the input mode)")*.
func _look_through_the_camera() -> void:
	world.visible_view().look_from(Stroller.view_centre_of(world.player()))

## What the run log and the page's counter call the event whose lethal reach ended today
## (`EventInstance.logged_name()` — `pelican` for a pelican, otherwise its row's id), or "" when no
## event's reach has (a car, or nothing yet). Set by `check_hard_fails()` with the
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
	return world.instances().size()

func instances() -> Array[EventInstance]:
	return world.instances()

## **The live event of `plan`** while it is in the world, null otherwise: for a caller that names
## or commands it (a scene recipe's runtime sets it on her, keeps it coming or holds it). A caller
## that only asks something of a plan asks the plan (`EventPlan.is_in_the_world()`).
func event_of(plan: EventPlan) -> EventInstance:
	return _streaming.event_of(plan)

# ------------------------------------------------------------ WorldContext ---

## **These events as one set of things that charge the baby** (`EventSources`): the door's toll
## alone inside a held door, a region boundary's structures as their strongest, everything else
## summed. Handed to the world the events stand in (`WorldContext.use_excitement_sources()`),
## which hands it to the baby and the halo.
var _sources: EventSources

## What charges the baby in this world's events, handed to the world they stand in
## (`WorldContext.use_excitement_sources()`).
func excitement_sources() -> EventSources:
	return _sources

## The region door whose hold is running right now and whose trigger circle `world_position` lies
## inside, or null: `CheckpointController.door_holding_her_at()`. Inside a door, the door's toll is
## the only thing that charges (`EventSources.holds_her_alone()`).
func door_holding_her_at(world_position: Vector2) -> EventInstance:
	return _checkpoints.door_holding_her_at(world_position)

# ------------------------------------------------------------------ ticking ---

func _physics_process(delta: float) -> void:
	var timing := world.surroundings().timing()
	if timing.is_on():
		var outer := timing.enter(FrameTiming.EVENTS)
		_tick_the_events(delta)
		timing.leave(outer)
	else:
		_tick_the_events(delta)

## The manager's own tick, timed under `FrameTiming.EVENTS`.
func _tick_the_events(delta: float) -> void:
	_streaming.advance_the_broadcast(delta)
	_streaming.retire_finished()
	_streaming.bring_back_what_repeats(delta)
	var she_is_here := world.has_player()
	if she_is_here:
		step_what_is_ahead(delta)
		_spawner.summon_what_has_been_sighted(_walk_events.plans())
		_spawner.report_the_pelicans_in_view()
		_watch_the_encounters(delta)
		_warnings.run(delta, world.player().global_position)
	step_the_encounters(delta)
	if she_is_here:
		_warnings.warn_about_the_ground_she_is_on()
	step_the_doors(delta)
	# Last, on the same tick as the step that caught her, and on every event's committed pose: each
	# step above has been proposed, checked and committed (`EventInstance.step()`).
	check_hard_fails()

## **The doors' own step, in the order the tick takes it**: with her in the world, the guards' hands
## go up or down at the doors she is across, the doors' lines are watched for her crossing, and the
## holds she walks into are begun and released. The tick calls it after the encounters' step; a caller
## that wants only the doors (a suite that walks her across a door's line for minutes of play) calls
## it and nothing else of the tick, with `step_the_encounters()` before it where a hut's or a guard's
## own step is wanted.
func step_the_doors(delta: float) -> void:
	if not world.has_player():
		return
	_checkpoints.warn_at_the_doors()
	_checkpoints.watch_the_door_lines(delta)
	_checkpoints.check_detentions()

## **What the director puts in front of her, in the order the tick takes it**: the tick's whole
## stretch from her camera's view to what is owed, and nothing else of the tick, with her in the
## world (with none it returns at once). The view is set first, so everything after asks the
## same view of what she can see this frame. The day's units she comes near draw next, before
## anything is streamed in: every unit within the stream radius of her whole, so the streaming
## finds no row of it missing (`EventsAhead.draw_what_comes_near()`); a beat sited below takes a
## location of a unit that has not drawn where her way has one, and that unit draws round it
## (`WalkSiting.lay_ahead()`). What her walk sites comes before the streaming, so a plan sited
## this frame is in the world on the same frame it would have been had the day placed it at
## dawn; nothing is sited in a world with no director or in a walk planned whole. What is owed
## comes after it. The tick calls it, and a suite that walks her down a day's route and reads
## what the director met on the way calls it in the tick's place: a real tick there also meets
## what the walk is not about, measured in the run log: a district door's hold that put her down
## elsewhere, a chatting mother on her way in, and an extra row the director sent.
func step_what_is_ahead(delta: float) -> void:
	if not world.has_player():
		return
	_look_through_the_camera()
	_ahead.draw_what_comes_near(world.player().global_position, _streaming.stream_radius())
	if not _recipe_plan and _ahead.has_director():
		_ahead.site_what_is_on_her_way(delta)
	_streaming.stream_around(world.player().global_position)
	if not _recipe_plan and _ahead.has_director():
		_ahead.place_what_is_owed_ahead(delta)

## **The encounters' own step, in the order the tick takes it**: with her in the world, every
## instance is told where she is, then every live event takes its step (with or without her), then
## the officers owed are let out. The tick calls it between the warnings and the doors' watch, and
## `check_hard_fails()` after them; a caller that wants only the encounters (a test of a vehicle and
## its men) calls these two and nothing else of the tick.
func step_the_encounters(delta: float) -> void:
	var she_is_here := world.has_player()
	if she_is_here:
		_tell_them_where_she_is()
	# Then every live event takes its step, having been told where she is, with or without her.
	_step_them(delta)
	if she_is_here:
		_ahead.let_the_officers_out()

## **Every live event's step, once a physics tick, in the order they live in `world.instances()`**
## (`EventInstance.step()`). What the tick made before it (a successor, a repeat, a streamed or
## summoned row) takes its first step on the tick it is made; what is made during or after it (an
## officer, a door's guard, anything an event's own step sets off) takes its first on the next,
## since the step runs over a copy. One a hand holds (`EventInstance.is_held_by_hand()`) is left as it
## stands.
func _step_them(delta: float) -> void:
	for instance: EventInstance in world.instances().duplicate():
		if is_instance_valid(instance) and not instance.is_held_by_hand():
			instance.step(delta)

## **Tells where she is, once a tick** (`WhereSheIs.tell()`, `EventWorld.where_she_is()`), which
## every instance was handed when it was made and hears from then on.
##
## Here rather than in the instance for the same reason `Crowd` finds who stands ahead of a car
## (`LaneMover.Lane.see_a_pedestrian_at()`) rather than letting each car look: the player is found
## once a frame in one place, and an `EventInstance` has never had to know she exists. It is handed
## a point, and everything it does with the point is a distance.
##
## Everything hears it, not only the pursuers: *"am I out of sight yet"* is the same question asked
## by anything that is **leaving** — see `EventInstance._be_done`.
##
## Whether she is running is one of the facts, and **`world.player()` answers a `Node2D`
## deliberately**: the cast is here rather than in the world so that "an instance is handed a
## point" stays true of everything except the one row that has to know. A `Node2D` has no
## `run_excess_ratio`, so asking it of the untyped answer is a per-frame runtime error that aborts
## this whole callback and stops the day dead — and `check.sh` cannot see it, because nothing is
## wrong until it runs.
## **Then each instance is told which barrier structure is the one charging her**, here because
## this is already the once-a-frame visit to every instance that knows where she is.
## `EventSources` keeps only the strongest of the boundary kit, so a caret or a halo rim on one of
## the others would be promising a cost the meter is not taking (`ExcitementSource.set_outranked()`,
## which `is_outranked()` answers).
func _tell_them_where_she_is() -> void:
	var stroller := world.player() as Stroller
	var running: bool = stroller != null and stroller.run_excess_ratio() > 0.0
	var awake: bool = stroller == null or stroller.baby_is_awake()
	var strongest := _sources.strongest_barrier_at(world.player().global_position)
	# Inside a district door's hold, nothing but the door's toll reaches her
	# (`door_holding_her_at()`), so a man who would stop her waits for her outside
	# (`WhereSheIs.is_held_at_a_door()`).
	var held := door_holding_her_at(world.player().global_position) != null
	# Her pram's own body, on her circumference along her facing — what a car that drives keeps clear
	# of as well as her (`WhereSheIs.pram_at()`). None while she carries the baby.
	var pram := Vector2.INF
	if stroller != null and not stroller.is_carrying():
		pram = stroller.global_position + stroller.facing_direction() * Tuning.PLAYER_BODY_RADIUS
	world.where_she_is().tell(world.player().global_position, pram,
			world.visible_view().camera_view(), running, awake, held)
	for instance in world.instances():
		instance.source().set_outranked(instance.counts_as_one_barrier() and instance != strongest)

func check_hard_fails() -> void:
	if _hard_failed or not world.has_player():
		return
	for instance in world.instances():
		if instance.is_lethal_at(world.player().global_position):
			_hard_failed = true
			_struck_by = instance.logged_name()
			_tell_the_watch_of_the_catch(instance)
			# The charge's own catch, counted whatever the day does (`EventInstance.report_the_catch()`).
			instance.report_the_catch()
			# Ahead of the hard fail, which ends the day and sends its loss.
			if instance.is_drawn_as_a_pelican():
				world.reports().tell_pelican_struck_her(instance)
			world.reports().tell_hard_fail_triggered(instance.row_id())
			return

# ------------------------------------------------------------ the doors' intents ---
# `CheckpointController` says what a door does to her and this carries it out on the player it was
# handed, on the same tick and in the order the controller says it (the signals are synchronous).

## **She goes in, out of sight, and the camera goes to the door** — on the tick the hold starts, so
## no drawn frame catches her outside.
func _take_her_in(door_at: Vector2) -> void:
	var body := world.player() as Stroller
	if body:
		body.hide_for_inspection()
		body.focus_camera_on(door_at)

## Her controls are locked for a hold's `seconds` (`Stroller.detain()`).
func _hold_her(seconds: float) -> void:
	var body := world.player() as Stroller
	if body:
		body.detain(seconds)

## **Moved, then shown, in that order and on this one tick**: `teleport_to()` puts her down and
## resets her interpolation, so the first frame drawn after this draws her at the door she is coming
## out of and nowhere else; the camera comes back here too, so its ease home starts from the hut
## toward where she actually is.
func _let_her_out(at: Vector2) -> void:
	var body := world.player() as Stroller
	if body:
		body.teleport_to(at)
		body.show_after_inspection()
		body.release_camera_focus()

# ------------------------------------------------------------------ the public face ---
# What the run flow, the resistance, the city and the observers ask of a day's events, answered by
# the part that owns it.

## Brings into the world everything within reach of `at` (`EventStreaming.stream_around()`),
## **every unit of the day's locations any part of which lies within the stream radius of `at`
## drawn first** (`EventsAhead.draw_the_ground_round()`), so the streaming finds each whole wherever
## a walk starts and wherever she is put down (her doorstep, a scene's start, the developer's
## `--spawn`).
func stream_around(at: Vector2) -> void:
	_ahead.draw_the_ground_round(at, _streaming.stream_radius())
	_streaming.stream_around(at)

## The planned instance of the row `id` within a tile of `at`, put in the world and kept there
## (`EventStreaming.keep_live()`).
func keep_live(id: String, at: Vector2) -> EventInstance:
	return _streaming.keep_live(id, at)

## Takes today's plans of the rows `ids` inside `rect` out of the day
## (`EventStreaming.take_away_within()`), the units over `rect` drawn first
## (`_draw_the_ground_over()`).
func take_away_within(rect: Rect2, ids: Array[String]) -> int:
	_draw_the_ground_over(rect)
	return _streaming.take_away_within(rect, ids)

## Takes today's plans inside `rect` not yet in the world out of the day, all but the ambient rows
## (`EventStreaming.take_away_the_unseen_within()`), the units over `rect` drawn first
## (`_draw_the_ground_over()`).
func take_away_the_unseen_within(rect: Rect2) -> int:
	_draw_the_ground_over(rect)
	return _streaming.take_away_the_unseen_within(rect)

## **Draws every undrawn unit of the day any part of which lies within `reach` of `at`**, each after
## every unit it waits for (`EventsAhead.draw_the_ground_round()`): what a place the resistance
## sends her to asks before it looks at ground. Answers whether it drew any unit.
func draw_the_ground_round(at: Vector2, reach: float) -> bool:
	return _ahead.draw_the_ground_round(at, reach)

## The units over `rect` drawn before an area is cleared of its rows (a frontage boarded up, a park
## cordoned off), so no unit draws a row there after it was cleared: round its centre, as far as
## half its diagonal.
func _draw_the_ground_over(rect: Rect2) -> void:
	_ahead.draw_the_ground_round(rect.get_center(), rect.size.length() * 0.5)

## Today's foot for a mast id (`EventStreaming.mast_foot()`).
func mast_foot(mast_id: String) -> Vector2:
	return _streaming.mast_foot(mast_id)

## Silences one mast for the rest of the day (`EventStreaming.silence_mast()`).
func silence_mast(mast_id: String) -> bool:
	return _streaming.silence_mast(mast_id)

## Silences every mast for the rest of the day (`EventStreaming.silence_all_masts()`).
func silence_all_masts() -> int:
	return _streaming.silence_all_masts()

## How many sited events the day is carrying (`EventStreaming.planned_count()`).
func planned_count() -> int:
	return _streaming.planned_count()

## The day's plan, for the readouts and the telemetry. Not for anything that acts on it.
func plans() -> Array[EventPlan]:
	return _walk_events.plans()

## Today's events by id, as the run log prints them. Counted rather than listed one per line: which
## of the catalogue's kinds are out is what makes a day, and where each instance stands is only
## interesting for the ones she actually walked into, which the `near` lines cover at the moment it
## matters. The *plan*, not what is live: what is live is a fact about where she is standing this
## frame. The plan as it stands: the dawn's, and what each unit drawn so far placed (at a day's
## start, the units round where she starts; `EventsAhead.draw_what_comes_near()`). `none` when
## nothing is planned.
func event_summary() -> String:
	var counts := {}
	for plan in plans():
		counts[plan.row_id()] = int(counts.get(plan.row_id(), 0)) + 1
	var parts: Array[String] = []
	for id: String in counts:
		parts.append("%s x%d" % [id, counts[id]] if counts[id] > 1 else id)
	parts.sort()
	return ", ".join(parts) if not parts.is_empty() else "none"

## **The walk's events, read through one object** (`WalkEvents`): what the resistance and every
## placement made while she walks are handed.
func walk_events() -> WalkEvents:
	return _walk_events

## **The city's plan builder** (`PlanBuilder`), the world's (`EventWorld.plan_builder()`): what the
## resistance and the happenings build a plan at a tile with. Null where the world is not the city.
func plan_builder() -> PlanBuilder:
	return world.plan_builder()

## Events the day owes the director to put in front of her and has not spent yet.
func owed_ahead() -> int:
	return _ahead.owed_ahead()

## **Hands in what makes every siting the director's walk asks for** (`SitingMaker`), in place
## of the maker `_init()` makes over this manager's world and walk: the game keeps its own, and a
## test hands in a fake that answers the siting a check set and records each ask.
func use_sitings(maker: SitingMaker) -> void:
	_ahead.use_sitings(maker)

## **Today's copy of the row `id` as her route's bag hands it out**
## (`EventDirector.route_row()`), or null with no director or for a row the bag holds none of. No
## game class asks it: a suite reads the director's state through it, since the game shows that
## copy only by putting it down on a walk.
func route_row(id: String) -> EventDef:
	if not _ahead.has_director():
		return null
	return _ahead.director().route_row(id)

## **The walk's way on** (`EventDirector.way_on()`: how a car the director sends drives on past
## its route), or null with no director. No game class asks it: a suite reads the director's
## state through it, since no run log line names a leg of a sent patrol's way.
func way_on() -> WayOn:
	if not _ahead.has_director():
		return null
	return _ahead.director().way_on()

## The warnings up for something not in the world yet — what `DangerEdge` draws a badge for
## alongside `instances()` (`WarningBoard.pending_warnings()`).
func pending_warnings() -> Array[PendingWarning]:
	return _warnings.pending_warnings()

## Puts up a warning for `def` with nothing in the world yet (`WarningBoard.warn_first()`).
func warn_first(def: EventDef, her: Vector2, where: Callable,
		arrive: Callable) -> PendingWarning:
	return _warnings.warn_first(def, her, where, arrive)

## Sends `def` at her from out of her sight, warned first, where `search` says he starts and
## `arrive` creates him (`WarningBoard.send_from_out_of_sight()`): a task's trap and day 13's task
## guard, as the resistance sends them.
func send_from_out_of_sight(def: EventDef, her: Vector2, search: Callable,
		arrive: Callable) -> PendingWarning:
	return _warnings.send_from_out_of_sight(def, her, search, arrive)

## Creates `def` on `path` for a row whose warning ran before it existed
## (`EventSpawner.spawn_warned()`).
func spawn_warned(def: EventDef, path: PackedVector2Array, pelican := false) -> EventInstance:
	return _spawner.spawn_warned(def, path, pelican)

## Adds an event outside the day's plan and outside the streaming, at a path the caller chose — the
## resistance's robbery, its neighbor, raid and column (`EventSpawner.spawn()`).
func spawn_extra(def: EventDef, at: Vector2, path := PackedVector2Array()) -> EventInstance:
	return _spawner.spawn(def, at, path)

## Retires one unplanned instance (`EventSpawner.retire()`).
func retire(instance: EventInstance) -> void:
	_spawner.retire(instance)

## Moves one unplanned instance with everything it is in the middle of
## (`EventSpawner.move_extra()`).
func move_extra(instance: EventInstance, at: Vector2) -> void:
	_spawner.move_extra(instance, at)

## One more mast for day 11's task (`EventsAhead.queue_a_mast()`).
func queue_a_mast(offered: Array[Vector2i]) -> EventPlan:
	return _ahead.queue_a_mast(offered)

## Day 13's task roadblock `plan` across a section of the day's locations, whatever it held spent
## (`EventsAhead.swap_in_a_section()`).
func swap_in_a_section(section: Location, plan: EventPlan) -> EventInstance:
	return _ahead.swap_in_a_section(section, plan)

## Rigs her route's bag for a task, its place laid just ahead of her where `just_ahead`
## (`EventsAhead.rig_her_route()`).
func rig_her_route(ids: Array[String], size: int, just_ahead := false) -> Array:
	return _ahead.rig_her_route(ids, size, just_ahead)

## Lights the set piece she never met, at dusk on a won day
## (`EventsAhead.light_what_she_never_met()`).
func light_what_she_never_met(at: Vector2) -> bool:
	return _ahead.light_what_she_never_met(at)

## A torn poster drew the pursuit marble (`EventsAhead.send_a_pursuer()`).
func send_a_pursuer() -> void:
	_ahead.send_a_pursuer()

## A scene's route, from the bag its recipe rigs, with everything the director does while she walks
## switched back on (`EventsAhead.start_recipe_route()`).
func start_recipe_route(marbles: Array, pre_bag: Array, owed: int, first_after: float) -> int:
	_recipe_plan = false
	return _ahead.start_recipe_route(marbles, pre_bag, owed, first_after)

## Hands in who is told the ground a body placed after dawn stands on, the crowd's call that
## recycles a car standing there (`EventStreaming.use_body_listener()`).
func use_body_listener(listener: Callable) -> void:
	_streaming.use_body_listener(listener)

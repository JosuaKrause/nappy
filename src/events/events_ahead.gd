class_name EventsAhead
extends RefCounted
## **What is put in front of her while she walks**, the director's half of a day: the places the day
## left for her walk, sited ahead of her as she goes (`site_what_is_on_her_way()`); the rows owed
## ahead of her, down her line or her heading, warned first where they come from off screen
## (`place_what_is_owed_ahead()`); the men a stopped vehicle lets out (`let_the_officers_out()`);
## the pursuer on foot a torn poster sends (`send_a_pursuer()`); the mast and the task row a
## resistance task places after dawn (`queue_a_mast()`, `queue_a_task_row()`); and the set piece she
## never met, lit at dusk (`light_what_she_never_met()`). Nothing here is planned at dawn: the day's
## plan is `EventStreaming`'s, and what this places joins it.
##
## Handed the world the events stand in (`EventWorld`), the streaming a placed plan joins
## (`EventStreaming`), the spawner a row is made by (`EventSpawner`) and the warning board a row
## from off screen is warned on (`WarningBoard`); and, with the director, where something sent at
## her may start (`SpawnSiting`).

## The world the events stand in, the run, the player and the live instances.
var world: EventWorld
var _streaming: EventStreaming
var _spawner: EventSpawner
var _warnings: WarningBoard
## Whether a torn poster sends a pursuer on this walk (`DaySpec.poster_pursuits`), as the manager
## is handed the spec.
var sends_poster_pursuits := true
## Whether the home's streets are the walk's (`DaySpec.holds_the_home_streets`), as the manager is
## handed the spec: every placement context made here for a siting after dawn reads it
## (`EventScheduler.WalkSiting.holds_the_home_streets`), so what is sited while she walks keeps the
## rule the walk was planned under at dawn.
var holds_the_home_streets := true

func _init(the_world: EventWorld, streaming: EventStreaming, spawner: EventSpawner,
		warnings: WarningBoard) -> void:
	world = the_world
	_streaming = streaming
	_spawner = spawner
	_warnings = warnings

## Makes the director that sites rows ahead of her over the city's `map`, its figures moving by
## `navigator`, handed the forced row a director made before it had, and keeps `spawn_siting`, where
## the pursuer a torn poster sends may start.
func use_director(map: CityMap, navigator: Navigator, spawn_siting: SpawnSiting) -> void:
	_director = EventDirector.new(map, navigator)
	_director.force(_forced_row, _forced_interval)
	_spawn_siting = spawn_siting

## No director: a world that is not the city, where nothing is sited while she walks.
func drop_director() -> void:
	_director = null
	_spawn_siting = null

## Whether a director sites anything ahead of her in this world.
func has_director() -> bool:
	return _director != null

## The day's director (`EventDirector`), or null in a world with none.
func director() -> EventDirector:
	return _director

## Starts the director's day over the day's plan, as the manager planned it against `tree` and the
## doors at `doors`, and keeps the placement context a row left for her walk is sited against.
func start_day(day: int, tree: RouteTree, doors: PackedVector2Array) -> void:
	# The day's placement context, kept past dawn for the one kind of plan the day budgets and
	# leaves for her walk to site — see `EventScheduler.WalkSiting` and `EventDef.on_her_way`.
	# Built from exactly what `build_day` was handed, so a placement made later is stated against
	# the same corridor, the same protected calm and the same doors as every other one. Only on a
	# day that has such a plan: the context grows a corridor and the protected-calm rects, and a day
	# with nothing left for her walk would pay for both and read neither.
	_siting = null
	_day_tree = tree
	_day_doors = doors
	for plan in _streaming.plans():
		if plan.def.on_her_way != null and not plan.is_placed():
			if not _siting:
				_siting = EventScheduler.WalkSiting.new(day, world.city_map, tree,
						world.run.settled_this_act(), doors)
				_siting.holds_the_home_streets = holds_the_home_streets
				# Where a crew may paste: only the city's buildings know their blank walls.
				if world.city and world.city.poster_walls():
					_siting.fronts = world.city.poster_walls().fronts()
			# The first attempt's one-time scans, done here rather than mid-walk. See `prepare()`.
			_siting.prepare(plan.def, _streaming.everything_but(plan))
	_director.start_day(day, _streaming.plans(), world.run.day_rng(day, "ahead"), _siting,
			world.run.resistance.progress)

## Starts the director over a walk whose plan was handed in whole. It owes nothing — every such
## placement is `MAP`-sited — but it is started anyway so that `owed_ahead()` and its own per-day
## state answer for this walk rather than for whatever ran before it.
func start_a_given_walk(day: int) -> void:
	_siting = null
	if _director:
		_director.start_day(day, _streaming.plans(), world.run.day_rng(day, "finale-ahead"))

## Forwards to `EventDirector.owe_the_return()` the moment the baby is asleep and the day turns to
## `RETURNING`, for the day `day` at the run's heat.
func owe_the_return(day: int) -> void:
	if _director:
		_director.owe_the_return(day, world.run.resistance.progress)

## Forgets the day's owed pursuer and the poster tear's pursuer.
func clear() -> void:
	_pursuer_owed = null
	_pursuer_retry_in = 0.0
	_pursuer_failure_logged = false
	_sent_after_her = null
	_sent_warning = null

## What sites rows ahead of her on a day, over the city (`EventDirector`); none in a world with no
## city (`EventManager.setup_world()`), where nothing is sited while she walks.
var _director: EventDirector
## Where something sent at her may start (`SpawnSiting`): the city's, handed in with the director;
## none in a world with no city, where no torn poster sends anybody.
var _spawn_siting: SpawnSiting
## The day's placement context for a row the day left for her walk to site, or `null` on a day that
## left none — the whole of `EventDef.on_her_way`, which today is day 3's fire and nothing
## else. Built in `start_day()` and read twice: the director sites against it while she walks, and
## `light_what_she_never_met()` places off it at dusk on a day she never met what it was for.
var _siting: EventScheduler.WalkSiting = null
## The day's own route tree and door positions, as `start_day()` handed them to `build_day`, kept
## for a placement made later in the day that has no `_siting` to read them from (`queue_a_mast()`).
var _day_tree: RouteTree = null
var _day_doors := PackedVector2Array()

## `--force <id> [seconds]`, kept here so a director made again by `setup()` is handed it too.
var _forced_row := ""
var _forced_interval := 0.0

## `--force <id> [seconds]`: the one row the director hands out from the next day on, every
## `interval` seconds, or "" for the ordinary day. See `EventDirector.force()`.
func force(row: String, interval: float) -> void:
	_forced_row = row
	_forced_interval = interval
	if _director:
		_director.force(row, interval)

# --------------------------------------------------------- the pursuer on foot ---
# *(Inbox #591 in olive-hedgehog, the player: "the poster pursuit should not be placed! it should
# happen instantly with the pursuer spawning off-screen! and it should be a proper pursuer not a
# police car -- maybe a policeman on foot?" · "the poster tear marble bag is a completely separate
# marble bag than the event marbles. nothing influences across them. the pursuer is not a scheduled
# event. it is instant! policemen get switched to guardman on day 9.")*

## The pursuer on foot a torn poster sent, once he is in the world, or null. Kept only so a second
## pursuit marble while he is still after her sends nobody more (`a_pursuer_is_after_her()`).
var _sent_after_her: EventInstance = null
## His warning while it is up, before he exists, or null.
var _sent_warning: PendingWarning = null

## **A torn poster drew the pursuit marble** (`PosterWalls`): the pursuer on foot is sent at her at
## once — a policeman through day 8, a guardsman from day 9 (`EventCatalogue.on_foot_on()`). He is
## warned and placed as a task's robber is (`WarningBoard.send_from_out_of_sight()`, as
## `ResistanceDirector._send_at_her()` sends him): the screen-edge badge goes up alone at once for
## his half second (`EventDef.warned_for()`), pointing where he will start
## (`_where_the_sent_pursuer_starts()`), and then he is created just out of sight that way from
## where she is by then, already chasing (`_spawner.spawn_warned()`,
## `PursuitSpec.Start.ARRIVES_CHASING`). No wait for a heading or a street: the tear is the moment.
##
## **Outside the day's own plan, queue and streams.** He is not the scheduler's or the director's:
## nothing here draws from a day stream, takes a turn in the director's queue or moves its clock,
## so a tear and its pursuer change nothing the day's event bags draw — the tears' bag is its own
## ("nothing influences across them"). Which of above and below he is tried from first is a hash of
## the run and the tear count, not a roll.
##
## **One at a time, and nothing on a walk with no poster pursuits** (`DaySpec.poster_pursuits`,
## false for the escape's sections). A pursuit marble drawn while his warning is up or while he is
## still after her (`a_pursuer_is_after_her()`) sends nobody more; once he has caught her, given up
## or run out his chase, the next marble sends the next one. *(Proposed, not asked for: the README
## of sandy-ferret.)* `EventBus.poster_pursuit_sent` fires only when this sends one, the moment his
## warning goes up, so the counter's `poster-pursuit` is one per pursuer sent.
func send_a_pursuer() -> void:
	if not sends_poster_pursuits or not world.has_player() or a_pursuer_is_after_her() \
			or not _spawn_siting:
		return
	var def := EventCatalogue.on_foot_on(world.day)
	if not def:
		return
	var her := world.player.global_position
	var first_up := posmod(hash("%d:%d:tear-pursuer" % [world.run.header.run_seed,
			world.run.posters.tears]), 2) == 0
	var search := func(standing: Vector2, prefer: Vector2) -> SpawnSiting.Start:
		return _where_the_sent_pursuer_starts(def, standing, prefer, first_up)
	var arrive := func(place: Vector2, standing: Vector2, start: SpawnSiting.Start) -> void:
		_sent_after_her = _spawner.spawn_warned(def, PackedVector2Array([place]))
		var who := "a %s" % def.noun
		world.trace.note("roll", "poster tear: %s sent after her from %s, %.0fpx off (%s)"
				% [who, RunTrace.tile(world.map.world_to_tile(place)),
				standing.distance_to(place), "a clear run at her" if start.clear
						else "no clear run at her"])
	_sent_warning = _warnings.send_from_out_of_sight(def, her, search, arrive)
	if not _sent_warning:
		world.trace.note("roll", "poster tear sends nobody: no walkable ground out of sight of her "
				+ "at %s" % RunTrace.tile(world.map.world_to_tile(her)))
		return
	# `VisitCounter`'s own "poster-pursuit" — see docs/TELEMETRY.md, "The page counts visits".
	EventBus.poster_pursuit_sent.emit()

## **The men an investigating vehicle lets out.** *(merry-stork, the player: "an investigating
## police car should not leave the street. it should stop if close to her and a policeman should
## emerge and pursue her"; inbox #669 in coral-lark: "Van stops, men get out (Recommended)" · "Same
## as the police".)* Every vehicle that has just stopped for her (`EventInstance.officers_owed()`) —
## a patrol car's one, a hunting van's two — gets the day's pursuer on foot as he gets out of a
## vehicle (`EventCatalogue.out_of_the_car()`: a policeman through day 8, a guardsman from day 9;
## out of the patrol car on the `PRESSES` rung his catch is a stop, out of a `HUNTS` van it ends the
## day) put down at its door on her side (`EventInstance.door_for_its_officer()`), spread along its
## flank `OFFICER_SPACING` apart when there are two, or on the other side where hers is not ground
## he may stand on (`SpawnSiting.Rule.OPEN_TO_IT`), or at the vehicle itself where neither is. They
## appear in her view, so there is no badge: their notice is the sight of them, standing with a hand
## raised (`PursuitSpec.Start.SETS_OFF_BESIDE_HER`, `PursuitSpec.stands`). Outside the day's plan,
## like everything put down after dawn by a director.
func let_the_officers_out() -> void:
	var siting := _spawn_siting if _spawn_siting else SpawnSiting.over(world.city_map)
	for vehicle: EventInstance in world.instances.duplicate():
		var owed := vehicle.officers_owed()
		if owed <= 0:
			continue
		var def := EventCatalogue.out_of_the_car(world.day,
				vehicle.def.heat_response != EventDef.HeatResponse.HUNTS)
		var stands := siting.ask_of_ground(Rect2(), EventInstance.mover_for(def))
		for i in owed:
			var along := (float(i) - float(owed - 1) * 0.5) * OFFICER_SPACING
			var at := vehicle.door_for_its_officer(def, 1.0, along)
			if not siting.allows(SpawnSiting.Rule.OPEN_TO_IT, stands, at):
				at = vehicle.door_for_its_officer(def, -1.0, along)
			if not siting.allows(SpawnSiting.Rule.OPEN_TO_IT, stands, at):
				at = vehicle.global_position
			var officer := _spawner.spawn(def, at)
			officer.player_at = world.player.global_position
			vehicle.let_out(officer)
		# Under `ahead`: men put down from her walk, where she stood — no seed says where a vehicle
		# noticed her. See docs/TELEMETRY.md, "The entry kinds".
		var who := "a %s gets out" % def.noun if owed == 1 \
				else "%d %s get out" % [owed, def.noun_plural]
		world.trace.note("ahead", "%s at %s, %.0fpx from her, and %s"
				% ["an investigating patrol stops" if vehicle.def.vehicle != null
						else "%s, standing," % vehicle.def.id,
				RunTrace.tile(world.map.world_to_tile(vehicle.global_position)),
				vehicle.global_position.distance_to(world.player.global_position), who])

## How far apart along a vehicle's flank its men get out when it lets out more than one, in px:
## a body and a half of a man apart, so neither stands in the other.
const OFFICER_SPACING := 28.0

## Whether a torn poster's pursuer is on his way or after her: his warning is up, or he is in the
## world and neither finished nor leaving.
func a_pursuer_is_after_her() -> bool:
	if _sent_warning != null and _warnings.pending_warnings().has(_sent_warning):
		return true
	return is_instance_valid(_sent_after_her) and not _sent_after_her.is_finished \
			and not _sent_after_her.is_leaving

## The torn poster's pursuer in the world, or null — for the tests.
func sent_pursuer() -> EventInstance:
	return _sent_after_her if is_instance_valid(_sent_after_her) else null

## How far either side of straight up or straight down a start is tried, in radians — the robber's
## own cone (`ResistanceDirector.ARRIVAL_CONE`), stepped rather than rolled.
const SENT_CONE := PI / 6.0

## **Where the pursuer a torn poster sends starts: just out of sight of her, under the task
## robber's rules** (`SpawnSiting.start_out_of_sight()`): on legal ground, nowhere on the camera's
## whole view, never with a run at her through the day's region wall or a district door, and a clear
## run at her deciding it, the first start that passes the rest standing in where none has one.
## Nothing is drawn from a stream: `prefer`, the bearing his badge already points along, first when
## it is asked again; then straight above or below her (`first_up` says which first), since the view
## is shorter that way; then at `SENT_CONE` either side of each; then straight along her street
## either way. Its `at` is `Vector2.INF` when no start qualifies.
func _where_the_sent_pursuer_starts(def: EventDef, her: Vector2, prefer: Vector2,
		first_up: bool) -> SpawnSiting.Start:
	var asked := _spawn_siting.ask(EventFootprints.footprint_of(def), EventInstance.mover_for(def),
			her)
	var bearings: Array[Vector2] = []
	if prefer != Vector2.ZERO:
		bearings.append(prefer)
	var up := Vector2.UP if first_up else Vector2.DOWN
	bearings.append_array([up, -up, up.rotated(SENT_CONE), up.rotated(-SENT_CONE),
			-up.rotated(SENT_CONE), -up.rotated(-SENT_CONE), Vector2.RIGHT, Vector2.LEFT])
	return _spawn_siting.start_out_of_sight(asked, bearings)

## **One more mast, for day 11's task, generated as the next event** when no live mast stands near
## the mark she read (`ResistanceDirector._place_at_a_mast()`). *(2026-10-03, quiet-yak, inbox #486,
## the player: "The 6 masts rule is stupid anyway. It doesn't come from me. And it actually makes it
## harder to encounter masts. We need to discuss this again but not now. Now just add a new mast
## close by" · inbox #503 in quiet-yak: "no events are dynamically created as you walk around -- if
## there is a mast queued up that will be the next event to be generated".)* So it is not put down
## where the director points: it is generated the way every row the day plans is, a `loudspeaker`
## heated like the day's own (`world.run.resistance.progress`) placed by `EventScheduler._best_of()`
## among `offered` — the tiles the director found near her and out of her view — against the whole
## of the day's plan: `EventScheduler._room_around()`'s spacing, so it never stands inside anything else or inside
## a lethal row's field, the region doors' clear ground and the calm she has not used; a mast is
## exempt from the three rules that keep a line along her routes (the route junctions, the route
## sidewalks and a pacing beat's opening), as the fixed ones are (inbox #684 in coral-lark).
## Appended to the day's plan under `EventScheduler.added_mast_id()` with its body recorded, it
## streams in like any planned row, broadcasts on the one clock, is silenced by
## `EventStreaming.silence_mast()`, counts for `EventStreaming.silence_all_masts()`, and once
## silenced stands silenced on later days from its scar (`EventScheduler._place_masts()`). Null when no offered tile passes, which leaves day 11 to the
## nearest live mast, or, when no live mast stands at all, with nowhere to go.
func queue_a_mast(offered: Array[Vector2i], rng: RandomNumberGenerator) -> EventScheduler.Planned:
	if offered.is_empty():
		return null
	var def := EventCatalogue.heated(EventCatalogue.mast(),
			world.run.resistance.progress)
	var siting := _siting
	if not siting:
		siting = EventScheduler.WalkSiting.new(world.day, world.city_map, _day_tree,
				world.run.settled_this_act(), _day_doors)
		siting.holds_the_home_streets = holds_the_home_streets
	var plan := siting.among(def, rng, _streaming.plans(), offered)
	if not plan:
		return null
	plan.mast_id = EventScheduler.added_mast_id(plan.position)
	_streaming.add(plan)
	return plan

## **A task's own row, placed the way the day places one, near where she read its mark**: day 13's
## roadblock (`ResistanceDirector._place_the_roadblock_near()`, the player: "let's place one
## properly and guide to that -- just make sure it's closeby"). Placed by
## `EventScheduler.WalkSiting.near_her()` among `offered` — the tiles the director found near her
## and out of her view — under every rule a planned row is placed under, against the whole of the
## day's plan, and refused where it would close her way home or to a calm area from `her`. Appended
## to the day's plan with its body recorded, and put in the world at once and kept there for the
## rest of the day (`EventStreaming.keep_live()`'s rule), since a task's contact rides it and must not lose it to
## the streaming. Answers its live instance, or null when no offered tile passes.
func queue_a_task_row(def: EventDef, offered: Array[Vector2i], rng: RandomNumberGenerator,
		her: Vector2) -> EventInstance:
	if offered.is_empty() or not def:
		return null
	var plan := _task_siting().near_her(def, rng, _streaming.plans(), offered, her)
	if not plan:
		return null
	_streaming.add(plan)
	_streaming.stream_in(plan)
	plan.kept_live = true
	return plan.live

## Does at dawn the one-time work `queue_a_task_row()` would otherwise do on the frame she reads the
## mark: the scan for the ground `def` may stand on and the reachability grid
## (`EventScheduler.WalkSiting.prepare()`). Nothing here rolls, so the day is the same day whether
## or not this ran.
func prepare_a_task_row(def: EventDef) -> void:
	if def:
		_task_siting().prepare(def, _streaming.plans())

## The day's placement context for `queue_a_task_row()`: the one the day kept for her walk, or one
## built from what the day was planned against and kept for the rest of the day (`_day_tree` names
## the day it was built for), so the ground scans, the corridor and the reachability grid it builds
## are paid for once however often a placement is asked.
func _task_siting() -> EventScheduler.WalkSiting:
	if _siting:
		return _siting
	if not _task_siting_cache or _task_siting_tree != _day_tree:
		_task_siting_cache = EventScheduler.WalkSiting.new(world.day, world.city_map, _day_tree,
				world.run.settled_this_act(), _day_doors)
		_task_siting_cache.holds_the_home_streets = holds_the_home_streets
		_task_siting_tree = _day_tree
	return _task_siting_cache

var _task_siting_cache: EventScheduler.WalkSiting
var _task_siting_tree: RouteTree

## Events the day has budgeted for the director to put in front of the player and has not
## spent yet.
func owed_ahead() -> int:
	return _director.owed() if _director else 0

## The director's half of the day: something that happens *to* her, in front of her, while she
## is walking. See `EventDirector` for why a cat is authored as a moment rather than a place.
func place_what_is_owed_ahead(delta: float) -> void:
	var body := world.player as CharacterBody2D
	if not body:
		return
	if _pursuer_owed and body.velocity.length() >= Tuning.AHEAD_MIN_SPEED:
		_pursuer_retry_in -= delta
		if _pursuer_retry_in <= 0.0:
			var owed := _pursuer_owed
			_pursuer_owed = null
			_warn_down_her_heading(owed, body.global_position,
					body.global_position + body.velocity.normalized())
	# A dog waiting for legal ground never stops the director's other clocks or due events.
	var due := _director.due(delta, body.global_position, body.velocity)
	if due.is_empty():
		return
	var def := due[0] as EventDef
	var path := due[1] as PackedVector2Array
	if def.warns_before_it_exists():
		_warn_down_her_line(def, body.global_position, (path[0] - path[1]).normalized())
		return
	if def.comes_down_her_line():
		_send_down_her_line(def, body.global_position, (path[0] - path[1]).normalized())
		return
	if def.pursuit != null:
		_warn_down_her_heading(def, body.global_position, path[0])
		return
	var crossing := _spawner.spawn(def, path[0], path)
	# A run cut short by a solid crouches longer by the run it lost, as the director worked it out
	# with the run (`EventDef.crouch_for_a_run()`).
	if due.size() > 2:
		crossing.hold_still_longer(float(due[2]))
	# The distance it was actually sited at rather than the constant. A pursuer is sited beyond its
	# own stand-off and a cat at `AHEAD_LEAD_DISTANCE`, so printing the constant makes every
	# `ahead` line for the one row a chase is about say the wrong number.
	# A crossing is measured where the director sited it to cross her line (`due[3]`), not at its
	# midpoint, which a run from the open side is not centred on. A row that comes down her own
	# street has no crossing, so it is measured to where it is created, `path[0]`.
	var crosses := due.size() > 3 and due[3] is Vector2
	var lead := (due[3] as Vector2 if crosses else path[0]).distance_to(body.global_position)
	var verb := "crosses" if crosses else "comes at her from"
	world.trace.note("ahead", "%s %s %.0fpx in front of her at %s" % [
		def.id, verb, lead,
		RunTrace.tile(world.map.world_to_tile(body.global_position))])

## A place a marble from her route's bag named — the man shouting or the mast a rigged bag puts on
## it — sited for the first time by the director ahead of her on the branch she is walking
## (`EventDirector._place_on_her_route()`, then `EventDirector.site_what_is_on_her_way()`). It joins
## the day's plan with the bookkeeping a dawn placement had: its body recorded per tile, the way
## `queue_a_mast()` records a mast's, and it streams in like any planned row once she walks on.
func _put_down_on_her_route(plan: EventScheduler.Planned, body: Node2D) -> void:
	# A mast is a mast like the one `queue_a_mast()` adds: it broadcasts on the one clock, is
	# silenced by `EventStreaming.silence_mast()` and counts for
	# `EventStreaming.silence_all_masts()`.
	if plan.def.role == EventDef.Role.MAST:
		plan.mast_id = EventScheduler.added_mast_id(plan.position)
	_streaming.add(plan)
	# Where, because nothing else records it: the siting depends on the walk she took.
	world.trace.note("ahead", "%s is put on her route %.0fpx ahead of her at %s, %s of where she is at %s"
			% [plan.def.id, plan.position.distance_to(body.global_position),
			RunTrace.tile(world.map.world_to_tile(plan.position)),
			CheckpointController.heading_name((body as CharacterBody2D).velocity.normalized()),
			RunTrace.tile(world.map.world_to_tile(body.global_position))])

## **Rigs her route so the marbles of `ids` are among the next `size` events handed out on it** —
## see `EventDirector.rig_her_route()` and `MarbleBag.rig()`. A place among them is handed to her
## walk when its marble comes up and sited ahead of her once her walk finds it a site, by the day's
## placement context, which is built here if the day had none, and its first scans are done now
## rather than on the frame it is sited. Answers the rigged bag's marbles.
func rig_her_route(ids: Array[String], size: int) -> Array:
	# A rig that never started a day has no route to rig, and building it a placement context for
	# nothing would grow a route tree to no end.
	if not _director.route_bag():
		return []
	if not _siting:
		_siting = EventScheduler.WalkSiting.new(world.day, world.city_map, _day_tree if _day_tree \
				else RouteTree.for_day(world.city_map, world.day), world.run.settled_this_act(), _day_doors)
		_siting.holds_the_home_streets = holds_the_home_streets
		if world.city and world.city.poster_walls():
			_siting.fronts = world.city.poster_walls().fronts()
	var rigged := _director.rig_her_route(ids, size, world.run.resistance.progress, _siting)
	for id in ids:
		var row := _director.route_row(id)
		if row and row.spawn_mode_on(world.day) == EventDef.SpawnMode.MAP:
			_siting.prepare(row, _streaming.plans())
	return rigged

## A row the director sited down her own line, warned first: the badge goes up at once, pointing
## just out of sight in `direction` on a sidewalk or a square (`PendingWarning.down_her_line()`),
## and once its second is up the thing is created where that now is, down her line.
##
## **The route is asked of the region doors again when it is created**, the same refusal
## `EventDirector.due()` makes when it sites one — she has walked on since, and a cyclist coming
## through a door's gap is exactly what that refuses. A refusal withdraws the warning.
func _warn_down_her_line(def: EventDef, her: Vector2, direction: Vector2) -> void:
	# Rolled as the warning goes up rather than when the rider is created, so the badge's own lines
	# in the run log already name the pelican — see `_spawner.rolls_a_pelican()`.
	var pelican := _spawner.rolls_a_pelican(def)
	var where := func(at: Vector2) -> Vector2:
		return PendingWarning.down_her_line(world.city_map, def, at, direction, world.visible)
	var arrive := func(place: Vector2, at: Vector2) -> bool:
		var path := _route_down_her_line(def, place, at, direction)
		if path.size() < 2 or not _director.clear_of_the_doors(path, def):
			return false
		var instance := _spawner.spawn_warned(def, path, pelican)
		world.trace.note("ahead", "%s comes at her from %.0fpx in front of her at %s, its warning over"
				% [instance.logged_name(), place.distance_to(at),
				RunTrace.tile(world.map.world_to_tile(at))])
		return true
	var warning := _warnings.warn_first(def, her, where, arrive)
	if warning:
		warning.is_pelican = pelican

## The route a row coming down her line is created on (`PendingWarning.route_down_her_line()`), cut
## to the ground the row can run on (`Navigator.trim()`), so a bike or a dog never comes through a
## building, a barrier or a body; fewer than two points where it cannot set off at all.
func _route_down_her_line(def: EventDef, place: Vector2, her: Vector2,
		direction: Vector2) -> PackedVector2Array:
	return world.navigator().trim(PendingWarning.route_down_her_line(world.city_map, place, her,
			direction),
			EventInstance.mover_for(def))

## A row the director sends down her own line that does not telegraph its coming (`loose_dog`,
## `EventDef.telegraphs`): no badge and no warning, so it is created at once just out of sight down
## her line on its own ground (`PendingWarning.down_her_line()`, against what she can see), with its
## telegraph spent at the age a warned row would have (`EventSpawner.age_when_warned()`), so it
## meets her the same. Nothing is created where there is no such ground, or its route would come
## through a region door; the director has already spent the moment either way.
func _send_down_her_line(def: EventDef, her: Vector2, direction: Vector2) -> void:
	var place := PendingWarning.down_her_line(world.city_map, def, her, direction, world.visible)
	if place == Vector2.INF:
		return
	var path := _route_down_her_line(def, place, her, direction)
	if path.size() < 2 or not _director.clear_of_the_doors(path, def):
		return
	var instance := _spawner.spawn(def, path[0], path)
	instance.resume(EventSpawner.age_when_warned(def), 0.0)
	world.trace.note("ahead", "%s comes at her from %.0fpx in front of her at %s, unannounced"
			% [def.id, place.distance_to(her), RunTrace.tile(world.map.world_to_tile(her))])

## A pursuer the director sends at her down her heading — `charging_dog`, on the day it teaches the
## run and when it is sprinkled into a later one — warned first *(M226, PLAYTEST-145: "the new
## system should be made to work to retain that timing for the pursuing dog")*: its badge is up
## alone for its own `offscreen_notice` (the dog's half second), pointing down the way `sited` lies
## from her, and it is then created just off screen that way on walkable ground (`PendingWarning.
## along_her_heading()`), its telegraph — the approach she watches — still to run. With nowhere to
## stand then, or now, it is owed again (`_pursuer_owed`) and the run log says so.
func _warn_down_her_heading(def: EventDef, her: Vector2, sited: Vector2) -> void:
	var direction := (sited - her).normalized()
	if direction == Vector2.ZERO:
		return
	var where := func(at: Vector2) -> Vector2:
		return PendingWarning.along_her_heading(world.city_map, def, at, direction, world.visible)
	var arrive := func(place: Vector2, at: Vector2) -> bool:
		_spawner.spawn_warned(def, PackedVector2Array([place]))
		world.trace.note("ahead", "%s comes at her from %.0fpx in front of her at %s, its warning over"
				% [def.id, place.distance_to(at), RunTrace.tile(world.map.world_to_tile(at))])
		return true
	var warning := _warnings.warn_first(def, her, where, arrive)
	if warning:
		_pursuer_failure_logged = false
		warning.on_withdrawn = func() -> void: _owe_pursuer_again(def)
		return
	# Nowhere off screen to stand down her heading: the lesson is not lost, it is owed again on
	# the next placement retry (`place_what_is_owed_ahead()`).
	_owe_pursuer_again(def)
	if not _pursuer_failure_logged:
		_pursuer_failure_logged = true
		world.trace.note("ahead", "%s has nowhere off screen to stand down her heading at %s; owed again"
				% [def.id, RunTrace.tile(world.map.world_to_tile(her))])

## A pursuer the director sent that found nowhere off screen to stand, or whose warning was
## withdrawn: tried again down her current heading after a second of walking, the director's own
## cadence for a failed placement. Null when none is owed; keeps the day-3 lesson from being lost.
var _pursuer_owed: EventDef = null
var _pursuer_retry_in := 0.0
var _pursuer_failure_logged := false

func _owe_pursuer_again(def: EventDef) -> void:
	_pursuer_owed = def
	_pursuer_retry_in = 1.0

## The other half of the director's day: a place left unsited, put ahead of her on the branch she
## is walking once her heading for the day is clear — day 3's fire and the day's poster crews
## (`EventDef.on_her_way`), and a place a marble from her route's bag names, which joins the
## day's plan here (`_put_down_on_her_route()`). See `EventDirector.site_what_is_on_her_way`.
##
## **The bookkeeping a late placement owes is the bookkeeping dawn already did for everything
## else.** A body is recorded per tile from the *plan* so the crowd steers round it whether or not
## the player has come near enough for it to exist (see "the bodies in the street" above), and a
## plan that has just been moved was recorded at a position it is no longer standing at — so the old
## footprint is given back and the new one taken, under the same owner id, in the one place that
## knows the move happened.
func site_what_is_on_her_way(delta: float) -> void:
	var body := world.player as CharacterBody2D
	if not body:
		return
	var moved := _director.site_what_is_on_her_way(delta, body.global_position, body.velocity,
			_streaming.plans())
	for plan in moved:
		# A place from her route's bag is not in the day's plan until its first siting.
		if _director.is_from_her_route(plan) and not _streaming.plans().has(plan):
			_put_down_on_her_route(plan, body)
			continue
		world.map.release_obstruction(plan.get_instance_id())
		_spawner.record_the_body(plan.get_instance_id(), plan.def, plan.position, plan.facing)
		# A mast's id is its foot (`EventScheduler.added_mast_id()`), so a mast moved before it was
		# ever in the world is named by where it now stands.
		if plan.mast_id != "":
			plan.mast_id = EventScheduler.added_mast_id(plan.position)
		# Where and why, because nothing else records it: the siting depends on the walk she took
		# and no seed reproduces it from outside. The same `ahead` entry the director's crossings
		# write, for the same reason.
		world.trace.note("ahead", "%s is sited %.0fpx ahead of her at %s, %s of where she is at %s" % [
			plan.def.id, plan.position.distance_to(body.global_position),
			RunTrace.tile(world.map.world_to_tile(plan.position)),
			CheckpointController.heading_name(body.velocity.normalized()),
			RunTrace.tile(world.map.world_to_tile(body.global_position))])

## **A day 3 she wins with the fire never met still burns.** *"I agree with the fire fix"*
## (PLAYTEST-121). Lights whatever the day owed her walk and never got to put in the world — day 3's
## fire and nothing else — off her path, on a site the dawn rules accept, and records everything a
## fire records: the scar the run keeps, the arc the block it stood in moves along, and the one-shot
## spent. Answers whether it lit anything.
##
## **Why it has to exist.** `burning_building` runs on day 3 and no other day, and it is spent where
## it enters the world rather than where it is planned — so a day 3 she wins while every siting was
## refused ends the run with no fire, no scar and no shell, and the shell is what the city
## remembering day 3 is made of and what day 8's errand goes to. Meeting it stays the strong
## guarantee; this is what the weak one owes.
##
## **Lit and then taken out of the world again**, which is not a repair: the day is over, so nothing
## is left standing for her to walk into and nothing is drawn. What the run keeps is the scar, the
## arc and the spend, and all three are the bookkeeping `EventStreaming.stream_in()` does on a first
## instantiation — reused here rather than copied, because a second copy of that list is a second answer to "what
## does a fire do to a run".
##
## Called by `DayDirector.finish_day()` on a won day only. A lost day gives everything back
## (`world.run.finish_day`), so lighting a fire on one would be handing the retry a shell it never
## earned.
func light_what_she_never_met(at: Vector2) -> bool:
	if not _siting:
		return false
	for plan in _streaming.plans():
		# The fire is the set piece a run owes; a crew she never met simply was not met.
		if plan.def.on_her_way == null or plan.def.kind != GameEnums.EventKind.ONE_SHOT \
				or plan.was_live or plan.spent:
			continue
		# Its own stream, so a dusk placement cannot move anything the day already rolled.
		var rng := world.run.day_rng(world.day, "dusk-fire")
		var sited := _siting.off_her_path(plan.def, rng, _streaming.everything_but(plan), at)
		if not sited:
			continue
		plan.position = sited.position
		plan.path = sited.path
		plan.facing = sited.facing
		plan.role = sited.role
		_streaming.stream_in(plan)
		_streaming.stream_out(plan)
		# It is over the moment it is recorded: the day has ended, and a plan left unspent would be
		# streamed back in by the next `stream_around` a rig made on the same day.
		plan.spent = true
		world.map.release_obstruction(plan.get_instance_id())
		# `VisitCounter`'s own "fire-unmet" — a won day on which this row was lit off her path
		# rather than met. See docs/TELEMETRY.md, "The page counts visits".
		EventBus.event_lit_unmet.emit(plan.def.id)
		# Where and why, because nothing else records it: which site a dusk fire took depends on
		# where she finished the day, and no seed reproduces that from outside.
		world.trace.note("ahead", "%s was never met: lit at dusk at %s, %.0fpx from where she "
				% [plan.def.id, RunTrace.tile(world.map.world_to_tile(plan.position)),
				plan.position.distance_to(at)] + "finished the day")
		return true
	return false

## The day's placement context for the row it left for her walk, or `null` on a day that left none.
## Read by `tests/probes/m179_fire_on_her_way.gd` for the refusals a long wait was made of; nothing
## in the game asks.
func walk_siting() -> EventScheduler.WalkSiting:
	return _siting

## **A scene's route, from the bag its recipe rigs** (`setup.route_bag`, `docs/SCENE_RECIPES.md`). A
## recipe's day starts with nothing owed and with everything the director does while she walks
## switched off (`EventManager.start_recipe()`). This hands the director the recipe's bag to draw
## her route's events from by its own rules (`EventDirector.start_recipe_route()`) and switches all
## of it back on, as a played day has it: the events owed ahead of her
## (`place_what_is_owed_ahead()`), the places a marble or the day leaves for her walk to site
## (`site_what_is_on_her_way()`), and, once the baby sleeps and the walk home begins, the act III
## and IV return patrols (`owe_the_return()`). Answers how many events her route is now owed.
func start_recipe_route(marbles: Array, pre_bag: Array, owed: int, first_after: float) -> int:
	_director.start_recipe_route(marbles, pre_bag, owed, first_after,
			world.run.resistance.progress)
	return _director.owed() if _director else 0

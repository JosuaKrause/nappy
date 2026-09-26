class_name EventManager
extends Node
## Owns the live events for one day: spawns them from the scheduler's plan, sums their
## excitement, retires them when they finish, and fires hard fails.
##
## Lookup is a linear scan. The architecture sketch called for a spatial hash, but the
## budget formula tops out around 32 concurrent events on the last day — 32 distance
## checks per physics frame is nothing, and a hash would be more code with more ways to be
## subtly wrong. Revisit if an act ever wants hundreds of sources at once.
##
## **A day's plan and a day's live events are different things.** The scheduler plans the whole
## city at dawn, which is what keeps every invariant that is stated over a day (one usable park, a
## walkable route to it, determinism); a plan becomes an `EventInstance` only when the player comes
## within `EVENT_STREAM_RADIUS` of it, and goes away again when she leaves.
##
## The gameplay half of that is bigger than the frames it saves. Loading the day upfront gives days
## in which **zero** events ever come within reach: a twenty-second event planted across the city
## fires and finishes at dawn, unobserved, and the budget bought nothing. An event that waits for
## her is an event she meets.
##
## **This node owns no instance as a scene child.** Every `EventInstance` is added under `City`'s
## shared, y-sorted `Entities` node (`City.add_entity()`) rather than under here, so
## `EventInstance._ready()` opts itself out of physics interpolation rather than inheriting the
## setting from this node.

var _instances: Array[EventInstance] = []
## Today's whole plan, sited and unsited, spent and unspent. See `EventScheduler.Planned`.
var _plans: Array[EventScheduler.Planned] = []
var _director: EventDirector
var _city: City
var _map: CityMap
var _player: Node2D
var _hard_failed := false
## Today's own day number, kept only for `_summon_the_sighted_row()`'s RNG stream — the
## direction a summoned row enters from is a coin flip like any other placement, and it has to
## come from the day's own seed to stay deterministic.
var _day := 0

## True between `start_finale()` and the next `start_day()`: this walk is the escape, not a day.
## Read by `_owe_the_return()` only — see there for why the difference matters.
var _walking_the_finale := false

## Elapsed seconds since this day started, advanced every physics frame regardless of whether
## anybody is near a mast. **The city's own broadcast clock** — every mast reads it, not its own
## age, at the moment it streams in (`_stream_in()`), which is what makes six masts met minutes
## apart still speak in phase: they are not coordinated frame to frame, they are all telling the
## same time. Reset with the rest of the day in `clear()`.
var _broadcast_clock := 0.0

## Which planned events have already summoned the row their own `spawns_on_sight` names, so a
## `burning_building` streamed out and back in — a fresh `EventInstance` every time, unlike the
## `Planned` it comes from, see `_stream_in()` — does not hand out a second fire engine. Keyed by
## `Planned` rather than by instance for exactly that reason, and cleared with the rest of the
## day in `clear()`.
var _sighted: Dictionary = {}

## The day's placement context for a row the day left for her walk to site, or `null` on a day that
## left none — the whole of `EventDef.sited_on_her_way`, which today is day 3's fire and nothing
## else. Built in `start_day()` and read twice: the director sites against it while she walks, and
## `light_what_she_never_met()` places off it at dusk on a day she never met what it was for.
var _siting: EventScheduler.WalkSiting = null

## The run's spent one-shots — `start_day`'s own argument, kept because one kind of one-shot is
## spent while the day is running rather than while it is being planned. See `_stream_in()`. Empty
## until a day has been started, which is the finale's case and is right: an escape spends nothing.
var _consumed: Array[String] = []

## Which side of a redetaining instance's own crossing she was on when its conversation started —
## `instance -> signf(...)`, the sign of her offset from the body against `facing_now()`. Present
## only while that instance's own detention is running; `_release_finished_door_detentions()` reads
## and clears it the frame the conversation ends. See `EventDef.redetains`.
var _door_entry_side: Dictionary = {}

## Where she stood the last time `_watch_the_door_lines()` looked, and how many outright moves
## (`Stroller.outright_moves`) she had had by then — the frame-to-frame step the walk-under check
## reads. `Vector2.INF` until the first look of a day, so a day's first frame compares nothing.
var _last_seen_at := Vector2.INF
var _last_outright_moves := 0
## How many times today she has walked across a door's line rather than being let through it.
## Read by `walks_under_a_boom()`; the run log has a line for each.
var _walked_under := 0
## The guard a walked crossing last set on her, or `null` — one at a time, see
## `_set_a_guard_on_her()`.
var _guard_after_her: EventInstance = null

## One `ReleaseLatch` per redetaining instance she has been let out of — `instance -> latch`. Armed
## the frame the release teleports her, with that instance's own trigger circle, and holding until
## she is measured outside it: the far side of a door is inside the door's own reach, so without
## this she is taken in again the instant she is put down. See `_release_finished_door_detentions()`
## and `ReleaseLatch`, which the escape scene's own doors reuse.
var _door_release_latches: Dictionary = {}

## How close the player has to be for a planned event to exist. `INF` turns streaming off and
## puts the whole day in the world at once, which is what a test rig with no player wants —
## `tests/test_event_manager.gd` and `tests/test_full_run.gd` are about a day's whole event set
## rather than about what one player walked past.
var stream_radius := Tuning.EVENT_STREAM_RADIUS

## Takes the one reference on the baked page every `EventInstance` draws from — the whole
## catalogue, the checkpoint kit and the crater on one page (`EventInstance.ATLAS_GROUP`).
##
## **One reference for the manager's own life, not one per family per instant.** This replaces a
## pass that rebuilt the wanted set of runtime-packed families from `_instances` after every change
## to that list, requested what was new and released what had gone: with a baked page there is
## nothing to pack, and a page that came and went with the last instance of a family would be a
## blocking read from disk in a played frame the next time one streamed in — *"don't unload
## anything that might be needed in one day and in the next"* (PLAYTEST-109). In a booted game the
## count is on a page `main.RESIDENT_GROUPS` already holds; the pair is what proves the page is
## there while a day's events draw from it.
##
## `_enter_tree()`/`_exit_tree()` rather than `_ready()`, so a manager that leaves the tree and
## comes back keeps the count right — the same pairing every other consumer of a page uses.
func _enter_tree() -> void:
	AtlasLibrary.acquire(EventInstance.ATLAS_GROUP)

func _exit_tree() -> void:
	AtlasLibrary.release(EventInstance.ATLAS_GROUP)

func setup(city: City, map: CityMap) -> void:
	_city = city
	_map = map
	_director = EventDirector.new(map)
	# **Connected once however often this is called.** `City.build()` calls `setup()` and a rig
	# that wants its own map calls it again on the same manager, which Godot answers with an
	# `ERROR: Signal ... is already connected` — an error line in a headless run is a failed
	# `check.sh`, and a second connection would fire the same forward twice besides.
	if not EventBus.return_phase_started.is_connected(_owe_the_return):
		EventBus.return_phase_started.connect(_owe_the_return)

## Forwards to `EventDirector.owe_the_return()` the moment the baby is asleep and the day turns
## to `RETURNING` — see that function's own doc for the shape it owes. `_day` is `start_day()`'s
## own argument, kept for exactly this: the signal carries nothing, so this is the one place still
## reading the day and the resistance level directly rather than having them threaded through.
##
## **The escape owes no return, because it has no walk home.** `Baby.force_sleep()` emits this
## signal, and the escape force-sleeps her at the top of every section and every retry — *"the
## player holding the sleeping baby (sleep bar is full)"* — so without this guard a walk that is
## outbound from its first frame to its last would be handed the return leg's own pressure at the
## moment it begins, and the director's pacing would tighten to `Tuning.RETURN_PATROL_INTERVAL`
## for the rest of it. The guard is on the day rather than on the act because it has to hold
## whatever day the escape is eventually entered from: today the flag boots it on day 1, where
## `RETURN_PATROLS_PER_ACT[0]` is 0 and nothing would be owed anyway, and from day 14 — the one
## `TODO.md` item still open — act IV would owe three.
func _owe_the_return() -> void:
	if _walking_the_finale:
		return
	_director.owe_the_return(_day, GameState.resistance_progress)

## A torn poster drew the pursuit marble: sends a `police_patrol` toward her from off screen, at the
## run's own heat. See `EventDirector.send_a_patrol()` for how and when it is sited, and
## `PosterWalls` for the bag it was drawn from. Nothing is sent during the escape.
func send_a_patrol() -> void:
	if _walking_the_finale:
		return
	_director.send_a_patrol(GameState.resistance_progress)

## Whether a torn poster's patrol is on its way and not yet sited. For the tests.
func has_a_sent_patrol() -> bool:
	return _director.has_a_sent_patrol()

## Clears yesterday and plans today. `consumed_one_shots` is appended to in place.
##
## `focus` is where the player will be standing when the day starts, so the events already
## around the doorstep are in the world on the first frame rather than appearing during it.
func start_day(day: int, rng: RandomNumberGenerator, consumed_one_shots: Array[String],
		focus := Vector2.ZERO) -> void:
	clear()
	_hard_failed = false
	_day = day
	_consumed = consumed_one_shots
	_walking_the_finale = false
	# The corridor the city grew this morning, before it placed its closures off it. Passed rather
	# than grown again so that the walls, the friction and the picture are all stated against one
	# tree; `RouteTree.for_day` would give the same answer, and two places agreeing by arithmetic
	# is a thing that stops being true the first time one of them takes an argument. Kept as a local
	# rather than re-read from `_city` below, for the same reason — `SealPlanner` needs the same
	# tree the catalogue's own placements were just stated against.
	#
	# **`_city.route_tree()` can itself be null even when `_city` is not** — a live `_city` whose
	# own `start_day` was never called for this day, which is the whole rig `tests/test_event_
	# manager.gd` and `tests/test_balance.gd` drive: `EventManager.start_day` on its own, with no
	# `City.start_day` first. A ternary on `_city` alone always took the true branch there and
	# handed every planner below a null tree — `docs/TODO.md`'s M100 defect, "a rig driving
	# EventManager before City.start_day seals nothing". The explicit null check grows one the
	# same way `City._close_streets` does, from the same `RouteTree.for_day(map, day)`, so the
	# fallback and the real thing can never disagree.
	var tree: RouteTree = _city.route_tree() if _city else null
	if not tree:
		tree = RouteTree.for_day(_map, day)
	# Grown the same way `tree` was, so the two never answer for two different days — see
	# `City._close_streets`. `_city.region_plan()` can itself be null for the same reason as
	# `tree` above, and the explicit null check here falls through to growing one the same way.
	var region_plan: RegionPlanner.RegionPlan = _city.region_plan() if _city else null
	if not region_plan:
		region_plan = RegionPlanner.plan_day(_map, day, tree)

	# Held ground, before `EventScheduler.build_day` rolls a single candidate — see
	# `CityMap.held_segments`. Closures, the region's own wall and door segments, and the
	# streets around the home block are all known already; the hard seals are not, which is
	# why `SealPlanner.plan_day` moved ahead of `build_day` below (see that call's own note).
	#
	# A rig driving `EventManager` off a `City` that has not run its own `start_day` yet still
	# gets no closures held: `_city.closures()` reads `City`'s own `_closures`, which only
	# `City.start_day()` ever populates, and there is no fallback for it the way `tree` and
	# `region_plan` now grow their own just above — closures are `ClosurePlanner`'s to plan, not
	# `EventManager`'s, so a rig that wants them run has to run `City.start_day()` first. The
	# wall, the doors and the home block are still held, because all three come from
	# `region_plan` and `_map` alone.
	_map.clear_day_holds()
	if _city:
		for closure in _city.closures():
			_map.hold_segment(closure.segment.key())
	for segment in region_plan.walls:
		_map.hold_segment(segment.key())
	for segment in region_plan.doors:
		_map.hold_segment(segment.key())
	for segment in StreetNetwork.around_blocks(Rect2i(_map.home_block, Vector2i.ONE)):
		_map.hold_segment(segment.key())

	# Off the catalogue's own budget on purpose — see `SealPlanner`'s own doc. It seals everything
	# `EventScheduler` was not permitted to touch: every street off `tree`, hard or soft, plus the
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
	# `_map`, `day`, `tree` and its own RNG stream (`GameState.day_rng(day, "seals")`, never shared
	# with the catalogue's), so moving it earlier changes which seals a day gets not at all — only
	# how soon `build_day` can see where they landed. `held` is `_map.held_segments` itself: a hard
	# seal's segment is marked there as it is placed, so the catalogue never offers a candidate row
	# that same ground (`docs/DECISIONS.md`, M100, "Events spawn inside a fully blocked street").
	var seals := SealPlanner.plan_day(_map, day, tree, GameState.day_rng(day, "seals"), boundary,
			_map.held_segments)
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
	_plans = EventScheduler.build_day(day, rng, _map, consumed_one_shots, GameState.scars,
			GameState.settled_this_act(), tree, GameState.resistance_progress, doors,
			ResistanceDirector.target_ground(_map, day, region_plan), standing)
	_plans.append_array(seals)
	# The wall's own bodies — hard seals of the roadblock row, one region boundary at a time. Kept
	# as `RegionPlanner`'s own returned list rather than folded into `SealPlanner`'s: a caller that
	# wants to know where the wall stands reads `region_plan.wall_bodies` directly rather than
	# filtering it back out of the whole day's plan.
	_plans.append_array(region_plan.wall_bodies)
	# The door structure — a hut on each pavement and a gate over the road at a street door, a
	# guard at each mouth of an alley door. Same reasoning as `wall_bodies` just above: kept as
	# its own list on `region_plan` and appended here rather than merged into `SealPlanner`'s, so
	# `region_plan.door_bodies` stays the one place that answers "where do today's doors stand"
	# without filtering.
	_plans.append_array(region_plan.door_bodies)
	# Every stationary solid body the day has sited, recorded per tile so the crowd goes round it —
	# see `CityMap.obstructed_tiles`. Taken from the **plan** rather than from the live instances
	# because a body is a body whether or not the player has come near enough to stream it in, and
	# the crowd is placed and steered across the whole map. Last of the assembly, so that everything
	# the day places — the catalogue's rows, the seals, the wall and the door structure — is in
	# `_plans`, and so that every held segment the record refuses against is already on the map.
	for plan in _plans:
		if plan.is_placed():
			_record_the_body(plan.get_instance_id(), plan.def, plan.position, plan.facing)
	# The day's placement context, kept past dawn for the one kind of plan the day budgets and
	# leaves for her walk to site — see `EventScheduler.WalkSiting` and `EventDef.sited_on_her_way`.
	# Built from exactly what `build_day` above was handed, so a placement made later is stated
	# against the same corridor, the same protected calm and the same doors as every other one.
	# Only on a day that has such a plan: the context grows a corridor and the protected-calm
	# rects, and a day with nothing left for her walk would pay for both and read neither.
	_siting = null
	for plan in _plans:
		if plan.def.sited_on_her_way and not plan.is_placed():
			if not _siting:
				_siting = EventScheduler.WalkSiting.new(day, _map, tree,
						GameState.settled_this_act(), doors)
				# Where a crew may paste: only the city's buildings know their blank walls.
				if _city and _city.poster_walls():
					_siting.fronts = _city.poster_walls().fronts()
			# The first attempt's one-time scans, done here rather than mid-walk. See `prepare()`.
			_siting.prepare(plan.def, _everything_but(plan))
	_director.start_day(day, _plans, GameState.day_rng(day, "ahead"), _siting)
	stream_around(focus)

## Clears whatever was here and takes the escape's whole plan as given.
##
## **Everything `start_day` works out, the finale has already decided**, which is the whole of why
## this is a second entry point rather than a flag on that one. There is no route tree to grow and
## no region plan to place against — the finale's route is an ordered chain and not a tree — no
## closures, and no catalogue budget: `FinalePlanner` has already asked `SealPlanner` what closes
## the city off the chains and `EventScheduler.build_finale` what stands on them, and what arrives
## here is the result. Trying to express that as a mode inside `start_day` would mean skipping six
## of its seven passes.
##
## The streaming, the successors, the scars, the detentions and the hard fails are all the day's
## own and are untouched: an explosion leaves its crater through exactly the `spawns_on_finish`
## mechanism a convoy leaves a barricade through.
func start_finale(plans: Array[EventScheduler.Planned], focus := Vector2.ZERO) -> void:
	clear()
	_hard_failed = false
	_day = GameState.day
	_walking_the_finale = true
	# Nothing is held: a hold keeps the catalogue's own roll off ground something else has taken,
	# and nothing rolls here. Cleared rather than left, so a rig that ran a day before the escape
	# does not leave yesterday's holds on the map.
	_map.clear_day_holds()
	_siting = null
	_plans = plans
	# The director owes nothing — every finale placement is `MAP`-sited — but it is started anyway
	# so that `owed_ahead()` and its own per-day state answer for this walk rather than for
	# whatever ran before it.
	_director.start_day(_day, _plans, GameState.day_rng(_day, "finale-ahead"))
	stream_around(focus)

func clear() -> void:
	for instance in _instances:
		instance.queue_free()
	_instances.clear()
	for plan in _plans:
		plan.live = null
	_plans.clear()
	# Yesterday's bodies go with yesterday's events, the same once-a-day sweep `clear_day_holds()`
	# and `clear_day_soft_seals()` get — every owner in the record is a plan or an instance this
	# call has just thrown away.
	if _map:
		_map.clear_day_obstructions()
	_door_entry_side.clear()
	_door_release_latches.clear()
	_last_seen_at = Vector2.INF
	_walked_under = 0
	_guard_after_her = null
	_sighted.clear()
	_broadcast_clock = 0.0

## Brings into the world everything within reach of a point, and takes away what has gone out
## of it. Idempotent, and cheap: one distance check per planned event.
##
## The hysteresis is not a nicety. Without it a player pacing on the boundary of an event's
## reach rebuilds it every other frame, and since a rebuilt instance starts its telegraph again
## that is an event permanently crouching at her and never arriving.
func stream_around(at: Vector2) -> void:
	for plan in _plans:
		if plan.spent or not plan.is_placed():
			continue
		var distance := plan.distance_from(at)
		if plan.live == null:
			if distance <= stream_radius:
				_stream_in(plan)
		elif distance > stream_radius + Tuning.EVENT_STREAM_HYSTERESIS:
			_stream_out(plan)

func _stream_in(plan: EventScheduler.Planned) -> void:
	var first_time := not plan.was_live
	# The scar is recorded the first time the event is put in the world and never again: walking
	# back past a burnt-out shell must not re-report the fire that made it.
	plan.live = _create(plan.def, plan.position, plan.path, first_time, plan.facing)
	# **A set piece the day owed her walk is spent here rather than at dawn**, because here is where
	# it becomes something that happened — see `EventScheduler._place_one_shots`. The list is the
	# one `start_day` was handed, which in a played game is `GameState.consumed_one_shots` and in a
	# rig is the rig's own.
	if first_time and plan.def.sited_on_her_way and plan.def.kind == GameEnums.EventKind.ONE_SHOT \
			and not plan.def.id in _consumed:
		_consumed.append(plan.def.id)
	# The shared boom state, for a `checkpoint_gate` plan only — `null` on every other plan, which
	# is a harmless no-op assignment rather than a special case here.
	plan.live.gate_state = plan.gate_state
	# **An event that has already run picks up where it left off.** Without this a streamed-out
	# event is rebuilt from `plan.position`, which is the tile the *day* chose at dawn — so a dog
	# walker that has covered three hundred pixels teleports back to the top of its street every
	# time the player leaves its radius and returns, and at 32px/s against her 92 that is most
	# times. From outside it reads as an event that never goes anywhere.
	#
	# It resumes rather than catching up on lost time, which is the whole design of streaming: the
	# day is planned across the whole city but an event **waits** for her. Ageing it in absentia
	# would put back exactly the thing streaming exists to fix — a twenty-second event that is over
	# before anybody could reach it.
	#
	# `plan.noticed_at` carries the same resume for a `pursues_within` row: without it a pursuer
	# streamed out mid-chase forgets she was ever noticed and comes back `is_waiting()`, standing
	# where the day planted it rather than still coming for her.
	#
	# **A mast's own age is the broadcast clock, not `plan.age`.** Every mast reads the same clock
	# at every stream-in, first time or the fifth, so two masts met minutes apart still read the
	# same pulse phase — "all masts speak at once" is true because they are all telling the same
	# time, not because anything coordinates them frame to frame. See `_broadcast_clock` below.
	var resume_age := _broadcast_clock if plan.mast_id != "" else plan.age
	plan.live.resume(resume_age, plan.travelled, plan.noticed_at)
	plan.live.silenced = plan.silenced
	plan.was_live = true
	_instances.append(plan.live)
	_spend_the_rest_of_the_group(plan)

## A set piece is planned at **every** site of a covering set and happens at exactly one of them:
## the one she reaches.
##
## This is where "the one she reaches" is decided, and it has to be here rather than anywhere
## later. The moment an event enters the world it is real — `_create` records its scar and moves
## its block along its arc — so the alternatives have to stop being possible on the same frame,
## not when it finishes.
##
## It reads like a special case and it is the opposite: the day cannot know which route she will
## take, so it offers the fire engine on every route and lets *walking* choose. Nothing here has to
## predict her, which is the whole reason the covering set is a set.
func _spend_the_rest_of_the_group(chosen: EventScheduler.Planned) -> void:
	if chosen.set_piece_group == "":
		return
	for plan in _plans:
		if plan == chosen or plan.set_piece_group != chosen.set_piece_group:
			continue
		plan.spent = true
		# A sibling that will now never be placed is a body that is not in the street, so the
		# ground it was holding opens again.
		_map.release_obstruction(plan.get_instance_id())
		# A sibling cannot already be live — the group is spent the first time any of them enters
		# the world, and `stream_around` skips a spent plan — but taking one out is the only safe
		# thing to do if that ever stops being true, because a second live one is a second scar.
		if plan.live:
			_stream_out(plan)

func _stream_out(plan: EventScheduler.Planned) -> void:
	plan.age = plan.live.age
	plan.travelled = plan.live.path_travelled()
	plan.noticed_at = plan.live.noticed_at()
	_map.release_obstruction(plan.live.get_instance_id())
	_instances.erase(plan.live)
	plan.live.queue_free()
	plan.live = null

# --------------------------------------------------- the bodies in the street ---
# Every stationary solid body is recorded per tile for the day, so the crowd steers round it
# instead of walking and driving through it — *("yes every solid body should do that -- not
# necessarily force a turn around but at least avoid the solid")*. `CityMap.obstructed_tiles` is
# the record and says which bodies it deliberately leaves out; this is the whole of what fills it.
#
# **Two identities record the same footprint and both give it back.** A `Planned` records its body
# at dawn, because the crowd runs across the whole map and a body is a body whether or not the
# player has come near enough for it to exist yet; the `EventInstance` records the same tiles again
# while it is live, because a body placed later in the day — a successor left where a fire burnt
# out, the resistance's own robbery — has no plan behind it. The record counts rather than flags
# for exactly this reason, so neither release can open ground the other is still standing on.

## Records one body's footprint under `owner`, or nothing at all for anything the record leaves
## out. Safe to call for every plan and every instance: the deciding is all in
## `obstructed_footprint()`.
func _record_the_body(owner: int, def: EventDef, at: Vector2, facing: Vector2) -> void:
	if not _map:
		return
	_map.obstruct_tiles(owner, obstructed_footprint(_map, def, at, facing))

## The tiles a row's own solid body stands on when it is sited at `at` looking `facing`, or an
## empty list for anything `CityMap.obstructed_tiles` deliberately leaves out — a mobile row, a
## door body, or a row with no body at all.
##
## **The placement and the axis are read back out of `EventInstance`'s own statics rather than
## worked out again here.** Where a body actually stands is not `Planned.position`: a stationary,
## unpinned body is shifted onto the middle of its pavement band, and a segment body lies along
## whichever axis the street it stands on gives it. Both are decided in exactly one place, and a
## second copy of that arithmetic would agree with it right up to the first time one of the two
## took an argument — which would leave the crowd avoiding ground no body is on and walking
## through the ground one is.
##
## **It is the row's pieces that are rasterised, never the one disc of `obstructs_radius`.** A row
## is solid where `EventDef.parts()` says it is, which is one piece at the origin carrying `shape`
## for every row that declares none — so a one-piece row records exactly the tiles it always did,
## and a row solid in parts records its pieces and leaves the ground between them open. That is the
## whole of what makes a crash two cars to the crowd rather than a wall: the pieces are a subset of
## `shape` (`EventDef.validate()` refuses one reaching past it), so the change only ever *removes*
## tiles from the record, and removing obstruction can only add reachable ground.
static func obstructed_footprint(map: CityMap, def: EventDef, at: Vector2,
		facing: Vector2) -> Array[Vector2i]:
	var nothing: Array[Vector2i] = []
	if not map or def == null or def.shape == null or def.obstructs_radius <= 0.0:
		return nothing
	# A moving wall pins her, so the catalogue exempts anything mobile from being solid at all; a
	# door is a crossing the day means to keep open, answered for a walker by `WalkerDoorHold` at a
	# hut or a post and for a car by `Crowd._stop_for_gates()` at the boom — which detains nobody,
	# so it is named by its own flag rather than by `detain_seconds`.
	if def.mobile or def.detain_seconds > 0.0 or def.lifts_for_traffic:
		return nothing
	var placed := at
	if def.pavement_side == EventDef.Pavement.ANY:
		placed = EventInstance._centred_on_the_pavement_band(map, at)
	# A hard seal's own body and a region wall's are recorded like any other, and that is what a
	# walker actually meets. The hold on their segment is a car's answer — a car cannot turn round
	# against a barrier, so it has to turn at the last junction, before it can see one — and it is
	# nobody else's: a walker walks the street up to the body and turns where it stands, so the
	# record has to say where the body is. It is also what keeps a crash walkable on its pavements,
	# since a row solid in parts records its pieces and the two cars are the only pieces there are.
	var axis := _body_axis(map, def, placed, facing)
	# Which way round a piece's own offset is laid is `EventInstance._spread_at()`'s question, and
	# it is asked of the placed position for the same reason the axis is: a piece offset the wrong
	# way is a body recorded across the street from the car it belongs to.
	var spread_vertical := EventInstance._spread_is_vertical(map, placed)
	var covered: Array[Vector2i] = []
	for piece in def.parts():
		var offset := piece.offset_for(spread_vertical)
		var centre := placed + (Vector2(0.0, offset) if spread_vertical else Vector2(offset, 0.0))
		for tile in piece.shape.tiles_under(centre, axis):
			# Two pieces may overhang one tile, and the record counts **bodies** rather than
			# pieces: a body that recorded one tile twice would need two releases to give it back.
			if not covered.has(tile):
				covered.append(tile)
	return covered

## The ground-plane direction a sited body's spine lies along — `EventInstance._solid_axis()` for a
## body that does not exist yet, off the same two statics that instance would read.
static func _body_axis(map: CityMap, def: EventDef, placed: Vector2, facing: Vector2) -> Vector2:
	if EventInstance.has_a_spread(def) or def.look == EventDef.Look.PROTEST \
			or def.look == EventDef.Look.FIREFIGHT:
		return Vector2.DOWN if EventInstance._spread_is_vertical(map, placed) else Vector2.RIGHT
	return Vector2.RIGHT if EventInstance._stationary_vehicle_uses_side(def.look, map, placed,
			facing) else Vector2.DOWN

## Adds an event outside the day's plan and outside the streaming, at a path the caller chose.
## The director's cats arrive this way, and so does the resistance's robbery.
func _spawn_unplanned(def: EventDef, at: Vector2,
		path := PackedVector2Array()) -> EventInstance:
	var instance := _create(def, at, path)
	_instances.append(instance)
	return instance

## Builds an instance, puts it in the world, and records any permanent mark it leaves.
## Everything that puts an event on the map goes through here, so a scar can never be
## missed by whichever path created the event.
func _create(def: EventDef, at: Vector2, path := PackedVector2Array(), record_scar := true,
		facing := Vector2.RIGHT) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, at, path, facing, _map)
	_city.add_entity(instance)
	# Its own copy of the footprint, given back when it streams out or finishes. A planned body has
	# already recorded the same tiles from its plan; a body placed later in the day has not, and
	# this is the one path every one of those comes through. See "the bodies in the street" above.
	_record_the_body(instance.get_instance_id(), def, at, facing)
	if def.scar_id != "" and record_scar:
		# A scar is where the city stopped being recomputable: it exists because of what
		# happened on an earlier day, so from day 4 onwards the map depends on run history.
		Telemetry.note("scar", "%s left at %s by %s" % [
			def.scar_id, TelemetryLog.tile(_map.world_to_tile(instance.global_position)),
			def.id])
		GameState.add_scar(def.scar_id, instance.global_position)
		_mark_the_block(def.scar_id, instance.global_position)
	return instance

## An event that leaves a scar may also move the block it happened to along its arc — if the
## arc was waiting for exactly that cause. A fire in a block whose plan has no fire in it
## leaves the shell and changes nothing else, which is what keeps the city coherent.
##
## The block presents its new purpose *the next morning*, not immediately: `CityMap.repaint`
## runs at the start of a day, so the fire burns today and the street is ashes tomorrow.
func _mark_the_block(scar_id: String, at: Vector2) -> void:
	var cause: int = _CAUSES.get(scar_id, -1)
	if cause < 0:
		return
	GameState.city_state.apply_cause(_map.block_plans, _map.block_at(at),
			cause as GameEnums.BlockCause, GameState.day)

## Which scars move a block along its arc. Keyed by scar id rather than by event id, because
## what matters to a block is what was left behind, not which siren left it.
const _CAUSES := {
	"burnt_shell": GameEnums.BlockCause.FIRE,
	"barricade": GameEnums.BlockCause.MILITARY,
}

## Adds an event outside the day's plan. Used by the resistance director to plant the
## robbery that may be waiting where a contact is, and by the resistance's own happenings — the
## neighbor, the raid, the column — which hand a mover the `path` it walks or drives.
func spawn_extra(def: EventDef, at: Vector2, path := PackedVector2Array()) -> EventInstance:
	return _spawn_unplanned(def, at, path)

## Retires one unplanned instance outside the day's own closures and events — the resistance
## director's own use, when a chalk mark moves and the guard standing over the old spot has to go
## with it: mark it finished and let `_retire_finished()`'s ordinary sweep free it, rather than
## freeing it here and risking a reference something else still holds this frame. Unlike a mast
## going quiet, the thing retired here really is leaving.
func retire(instance: EventInstance) -> void:
	if instance and is_instance_valid(instance) and not instance.is_finished:
		instance._finish()

## **Takes today's plans of the rows `ids` standing inside `rect` out of the day**, placed or live —
## what a once-only happening that empties a place owes the day's own plan: day 11's market stalls
## at the block boarded up ahead of her, and day 12's playground once its park is taken
## (`ResistanceHappenings`). A plan not yet in the world is spent, so it never streams in, and its
## body's ground opens (the same release a spent plan gets); a live one is retired, the ordinary
## departure. Only ever a removal, the one direction the city's guarantees allow after dawn.
## Returns how many plans it took.
func take_away_within(rect: Rect2, ids: Array[String]) -> int:
	var taken := 0
	for plan in _plans:
		if plan.spent or not plan.is_placed() or not (plan.def.id in ids) \
				or not rect.has_point(plan.position):
			continue
		taken += 1
		if plan.live:
			retire(plan.live)
			continue
		plan.spent = true
		_map.release_obstruction(plan.get_instance_id())
	return taken

## Today's own foot for a mast id, or `Vector2.INF` if today carries no mast with that id — the
## point day 11's task (silence a mast by reaching its foot, the way she touches a chalk mark)
## records its scar at. Reads the ordinary broadcast's own
## plan, which always exists for a live mast's id; the curfew announcement shares the same foot.
func mast_foot(mast_id: String) -> Vector2:
	for plan in _plans:
		if plan.mast_id == mast_id and plan.def.id == "loudspeaker":
			return plan.position
	return Vector2.INF

## Silences one mast by id, for the rest of the day — a mast still stands once silenced, with no
## arcs and no field, so this sets `Planned.silenced` and its live instance's own mirror rather
## than finishing it: `EventInstance._finish()` is for something that leaves, and a mast never
## does. Returns whether a mast with that id was found. Matches every plan whose `mast_id` is this
## one — a mast's ordinary broadcast and, on `Tuning.CURFEW_ANNOUNCE_DAY`, its curfew announcement
## too, so silencing a mast mid-announcement silences both at once.
##
## **Run-long, it is a scar.** Day 11's task silences one mast for the rest of the run: the
## director calls this for today and records `EventScheduler.SILENCED_MAST` at the foot, which
## `EventScheduler._place_masts()` reads on every later day. The id is `MastSites.Site.id`, stable
## across days, and the foot is its own.
func silence_mast(mast_id: String) -> bool:
	var found := false
	for plan in _plans:
		if plan.mast_id != mast_id:
			continue
		found = true
		plan.silenced = true
		if plan.live:
			plan.live.silenced = true
			# The same invalidation `_finish()` does for `is_finished` — `age` does not move the
			# instant this flips, so the cache `contribution_at()` keeps would otherwise go on
			# answering the pre-silence contribution for the rest of this tick.
			plan.live._invalidate_contribution_cache()
	return found

## Silences every mast, for the rest of the day. The masts stop because the power does: this is what
## the last night's blackout calls (`Blackout.go_dark()`), in the same frame the windows and the
## traffic lights go out, and it reaches a mast out of reach right now as well as a live one, since
## it marks the plan. Returns how many masts were silenced.
func silence_all_masts() -> int:
	var silenced := {}
	for plan in _plans:
		if plan.mast_id == "":
			continue
		silenced[plan.mast_id] = true
		plan.silenced = true
		if plan.live:
			plan.live.silenced = true
			plan.live._invalidate_contribution_cache()
	return silenced.size()

## How many events are in the world right now — *what is around the player* rather than what the
## day contains; see `planned_count()` for the other question.
func active_count() -> int:
	return _instances.size()

## How many sited events the day is carrying, live or waiting to be walked past. This is the
## number that answers "is thirteen events on day one a city or a gauntlet"; `active_count()`
## answers "what is she standing in".
func planned_count() -> int:
	var total := 0
	for plan in _plans:
		if plan.is_placed() and not plan.spent:
			total += 1
	return total

## The day's plan, for the readouts and the telemetry. Not for anything that acts on it.
func plans() -> Array[EventScheduler.Planned]:
	return _plans

## Events the day has budgeted for the director to put in front of the player and has not
## spent yet.
func owed_ahead() -> int:
	return _director.owed()

func instances() -> Array[EventInstance]:
	return _instances

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
	# Ties keep the first of `_instances`, which is the order the day streamed them in — a stable,
	# seed-determined answer rather than one that depends on floating-point luck.
	var strongest: EventInstance = null
	var strongest_rate := 0.0
	for instance in _instances:
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
	for instance in _instances:
		if not instance.def.barrier_structure:
			continue
		var contribution := instance.contribution_at(world_position)
		if contribution > strongest_rate:
			strongest_rate = contribution
			strongest = instance
	return strongest

## The region door whose hold is running right now and whose own trigger circle `world_position`
## lies inside, or `null` when this point is not inside a door. `City.excitement_sources_at()` asks
## it too, for the crowd half of the same sum.
##
## **She is *inside the hut*, so the street does not reach her.** A hold is the one state in the
## game where she is not standing on the ground the meter is being asked about: she is hidden, the
## camera has left her, and the two seconds are a toll rather than a place —
## *"it works in both directions with the same cost each time"* is the recorded rule, and fields
## that keep charging through the hold make the same crossing cost whatever happens to stand beside
## that particular door. `Tuning.EXCITEMENT_DECAY_IDLE` is already zero, so nothing gives back
## either: with everything else silenced the hold is exactly `Tuning.CHAT_EXCITEMENT` and nothing
## more.
##
## **Stated over the point rather than over "a hold is running", so the query stays pure.** The
## ground a street away is not inside the hut and is answered for normally, which is what the
## telemetry, the debug fields layer and a probe sampling the map all want; she is inside the
## circle by construction for the whole hold, since the release only ever sets her down inside the
## same trigger.
##
## **`redetains` rather than every detainer**, which is what keeps `chatting_mother` out of it: her
## conversation happens on the pavement in plain sight, with her own picture, the player's and the
## street all still drawn, so a lorry reversing beside the two of them is part of what that
## conversation costs. A door is the opposite — she goes in.
func door_holding_her_at(world_position: Vector2) -> EventInstance:
	for instance in _instances:
		if not instance.def.redetains or not instance.is_chatting():
			continue
		if instance.global_position.distance_to(world_position) <= instance.def.detain_distance():
			return instance
	return null

func total_excitement_at(world_position: Vector2) -> float:
	var total := 0.0
	for pair in excitement_sources_at(world_position):
		total += pair[1]
	return total

# ------------------------------------------------------------------ ticking ---

func _physics_process(delta: float) -> void:
	_broadcast_clock += delta
	_retire_finished()
	if _find_player():
		# Before the streaming, so a plan sited this frame is in the world on the same frame it
		# would have been had the day placed it at dawn.
		_site_what_is_on_her_way(delta)
		stream_around(_player.global_position)
		_place_what_is_owed_ahead(delta)
		_summon_what_has_been_sighted()
		_tell_them_where_she_is()
		_warn_about_the_ground_she_is_on()
		_watch_the_door_lines()
		_check_detentions()
	_check_hard_fails()

# ------------------------------------------------------- called in on sight ---
# The opposite of a successor: `_successor_of()` hands the day something the moment a row is
# *done*; this hands it something the moment a row is first *seen*. `burning_building` is what
# it exists for — see `EventDef.spawns_on_sight`.

## Whether a live instance whose def names `spawns_on_sight` has been seen yet, and if it just
## has, creates the row it names entering along its own street. Run every frame there is a
## player, the same as `_place_what_is_owed_ahead` beside it.
func _summon_what_has_been_sighted() -> void:
	for plan in _plans:
		if not plan.live or plan.def.spawns_on_sight == "" or _sighted.get(plan, false):
			continue
		if not _is_on_screen(plan.live.global_position):
			continue
		if _summon_the_sighted_row(plan.def, plan.live.global_position):
			_sighted[plan] = true

## Whether a world point is inside the camera's view of the player — the same
## `Tuning.VIEW_HALF_EXTENT` box `DangerEdge` measures the screen edge against
## (`Tuning.offscreen_boundary()`'s own box, and the camera holds her at its centre at a fixed
## zoom — see docs/DECISIONS.md, "M77 — Everything arrives from off screen"). A direct geometry
## test rather than `DangerEdge.is_on_screen()` itself: that call needs a live `Control` in the
## viewport tree, which a headless rig driving `EventManager` alone —
## `tests/test_event_manager.gd` — has none of, and asks the identical question
## `ResistanceDirector.set_sight()` is wired to that same `Control` for. Ignores screen rotation,
## which only a touch layout ever applies: the smaller reading of a silence, since nothing else
## here is stated per input scheme.
func _is_on_screen(world_position: Vector2) -> bool:
	if not _player:
		return false
	var offset := world_position - _player.global_position
	return absf(offset.x) <= Tuning.VIEW_HALF_EXTENT.x and absf(offset.y) <= Tuning.VIEW_HALF_EXTENT.y

## Creates the row `source.spawns_on_sight` names, entering along `at`'s own street from off
## screen and ending at `at` itself — `at` is a sidewalk point (`burning_building` is placed
## `AGAINST_THE_BUILDING`), so the along-street axis is `CityMap.pavement_inward()` turned a
## quarter turn, the construction `EventDirector._onto_her_side()` uses for the same reason: it
## is the corridor's own axis, not whichever way she happens to be facing. Returns false, and
## creates nothing, when neither direction along that axis lands in bounds.
##
## **Sited by `Tuning.offscreen_lead()`, not `Tuning.outlasting_telegraph_lead()`.** The
## stricter siting `EventDirector._toward_her()` gives a `hard_fail` row exists to hold the
## *whole* telegraph in reserve before a lethal thing can reach her; the engine cannot end the
## day, so the ordinary M77 margin — off screen, plus its own closing notice — is what "far
## enough up the street" owes on its own. What is still owed is `EventDef.validate()`'s own rule
## for an ordinary `TOWARD_PLAYER` row (`outer_radius` must sit inside the siting distance, so
## she can never be found already inside a field that has just become visible) — the row's
## `minimum_telegraph()` contract then buys the walk clear of it, exactly as it does wherever
## else in the catalogue a row is met. Both halves are checked from the worst position on the
## street in `tests/test_events.gd` rather than trusted from the geometry alone.
##
## **The margin is measured off `at`, not off her.** Every other caller of `offscreen_lead()`
## states its siting relative to her own live position, which is exactly where the view is
## centred, so clearing the view already clears her. This one is triggered by `at` coming on
## screen, which only bounds her distance from `at` to the half diagonal of the view,
## `Tuning.VIEW_HALF_EXTENT.length()` (≈367px, `ResistanceDirector.NOTICE_RADIUS`'s own
## reasoning) — so the siting also has to clear the engine's own forward reach from *that* worst
## case, not only the screen edge.
func _summon_the_sighted_row(source: EventDef, at: Vector2) -> bool:
	var summoned := EventCatalogue.by_id(source.spawns_on_sight)
	if not summoned:
		push_error("event '%s' summons unknown '%s' on sight" % [source.id, source.spawns_on_sight])
		return false
	var inward := _map.pavement_inward(_map.world_to_tile(at))
	if inward == Vector2i.ZERO:
		return false
	var along := Vector2(inward.y, inward.x)
	var road_at := where_the_summoned_row_stops(_map, at)
	var closing := summoned.speed + Tuning.WALK_SPEED
	var lead := maxf(Tuning.offscreen_lead(along, closing, summoned.offscreen_notice),
			summoned.field_reach() + Tuning.VIEW_HALF_EXTENT.length())
	var headings: Array[Vector2] = [along, -along]
	if GameState.day_rng(_day, "sighted:%s" % source.id).randf() < 0.5:
		headings.reverse()
	for heading in headings:
		var entry: Vector2 = road_at + heading * lead
		if not _map.in_bounds(_map.world_to_tile(entry)):
			continue
		var instance := _create(summoned, entry, PackedVector2Array([entry, road_at]))
		_instances.append(instance)
		return true
	return false

## Where a row summoned on sight comes to rest: the near kerb across from `at`, which is the
## sidewalk point the row that summoned it is standing on. `Vector2.INF` where `at` is not beside a
## carriageway at all, which is a point with no kerb to park at.
##
## **One place decides it, because two callers have to agree about it exactly.**
## `_summon_the_sighted_row()` sends the engine here, and `EventScheduler.WalkSiting` treats the
## field standing here as closed ground before it will accept a site for the fire — so a second copy
## of this arithmetic would be a day whose acceptance check was made about a different kerb than the
## engine parks at, and nothing would ever say so.
##
## `CityMap.pavement_inward` points away from the carriageway, into the block she is walking beside,
## so the road is the other way; `AGAINST_THE_BUILDING` puts `at` on the sidewalk tile touching the
## building, the far tile of the two-tile band (`Tuning.SIDEWALK_WIDTH`) from the kerb, and the near
## edge of the carriageway is that many tiles further in `-inward`.
static func where_the_summoned_row_stops(map: CityMap, at: Vector2) -> Vector2:
	var inward := map.pavement_inward(map.world_to_tile(at))
	if inward == Vector2i.ZERO:
		return Vector2.INF
	return at - Vector2(inward) * (Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE)

# ------------------------------------------------------- the mark over her head ---
# There are no rings around dangerous things. This is the half of what replaces them that is about
# the player rather than about the thing; `Crowd` does the same for the traffic, and the two
# compose because `Stroller.warn()` keeps the loudest level rather than the last caller's opinion.

## Raises the exclamation mark when the ground she is standing on is the problem.
##
## **The mark means: this will end your day.** Two levels, and nothing else raises either.
## `SOON` is a lethal event still telegraphing whose radius already covers her — the thing has
## not happened yet and walking out is the answer, which is exactly what the fairness contract
## promises her time to do. `NOW` is one of them live with her inside its reach: one step left
## between her and the end of the day.
##
## **Raising it for any telegraphing event whose radius reaches her is the mistake to avoid.** Most
## of the catalogue is not a `hard_fail`, and for those the mark would mean *a number is about to
## move faster*, which the meter already says continuously and proportionally — a mark a player can
## correctly ignore, *"I can just keep doing what I was doing"*. The caret over an entity follows
## the same rule — **a cue that marks everything says nothing** — except that this is the one cue in
## the game that cannot afford it, because it is the only one that gives an *instruction*.
##
## The cost of that narrowness is real and is the right cost: six rows in the whole catalogue are
## lethal, so the mark is rare, and it is rarest early. That is not the cue being broken, it is the
## cue being honest about a game whose first days are barely dangerous.
##
## **And `NOW` is about the pair of them, not about the disc.** Raised for any live lethal event
## whose **outer** radius covers her, it is up across about three times the area that could hurt
## her — a cyclist ends the day inside 33px and its outer radius reaches 60 — and it stays up while
## the bike rides away, which is *"the flashing exclamation marks after the fact"* on the events'
## side of a fix the traffic already has in `stand_down()`.
##
## So it is two conditions: she is within `LETHAL_MARK_LEAD` seconds of the radius that ends the
## day, **and** the gap is actually shrinking at the speeds in play.
##
## The closing rate is **relative** — her velocity is in it — and that is deliberately the opposite
## of the screen-edge badge, which measures the event's own approach with the player held still.
## The two cues say different sentences. A badge says *a thing exists and is coming*, so
## her walking towards it must not raise one; this mark says *the contract is now about you*, which
## is a statement about the pair of them and is false the moment she is opening the gap. It is also
## what makes the mark work for something that never moves: a reversing lorry cannot come to her, so
## the only way it becomes about her is that she is walking into it.
func _warn_about_the_ground_she_is_on() -> void:
	var here := _player.global_position
	var body := _player as Stroller
	if not body:
		return
	for instance in _instances:
		if instance.is_finished or not instance.def.hard_fail:
			continue
		var gap := instance.global_position.distance_to(here) - instance.def.inner_radius
		# `SOON` is anything that cannot kill her *yet* — a telegraph running, or a pursuer that has
		# not noticed her. Without the second half a man standing in an alley raises `NOW` — one
		# step from the end of the day — from two hundred pixels away, which is the marks-everything
		# mistake arriving at the one cue that cannot afford it.
		#
		# It keeps the whole outer radius, because that is exactly what the fairness contract
		# promises her time to walk out of. Only `NOW` is about a moment.
		if instance.is_telegraphing() or instance.is_waiting():
			if gap + instance.def.inner_radius <= instance.def.outer_radius:
				body.warn(Stroller.Alert.SOON, WARNING_HOLD, WARNING_SOURCE)
			continue
		var to_her := here - instance.global_position
		if to_her.length_squared() < 1.0:
			body.warn(Stroller.Alert.NOW, WARNING_HOLD, WARNING_SOURCE)
			continue
		var closing := (instance.travel_velocity() - body.velocity).dot(to_her.normalized())
		if closing > 0.0 and gap <= closing * Tuning.LETHAL_MARK_LEAD:
			body.warn(Stroller.Alert.NOW, WARNING_HOLD, WARNING_SOURCE)

## How long a raised warning stays up. A shade longer than a physics frame, so the mark does not
## strobe on the boundary of a radius she is walking along — which is short enough that this
## side of the vocabulary never needs `stand_down()`: it is re-raised every frame it is true and
## gone a frame after it stops being.
const WARNING_HOLD := 0.35
## Named so the traffic's hold and this one cannot take each other down. See `Stroller.warn`.
const WARNING_SOURCE := &"events"

## The director's half of the day: something that happens *to* her, in front of her, while she
## is walking. See `EventDirector` for why a cat is authored as a moment rather than a place.
func _place_what_is_owed_ahead(delta: float) -> void:
	var body := _player as CharacterBody2D
	if not body:
		return
	var due := _director.due(delta, body.global_position, body.velocity)
	if due.is_empty():
		return
	var def := due[0] as EventDef
	var path := due[1] as PackedVector2Array
	_spawn_unplanned(def, path[0], path)
	# The distance it was actually sited at rather than the constant. A pursuer is sited beyond its
	# own stand-off and a cat at `AHEAD_LEAD_DISTANCE`, so printing the constant makes every
	# `ahead` line for the one row a chase is about say the wrong number.
	var crossing_point: Vector2 = path[0] if path.size() < 2 \
			else (path[0] + path[path.size() - 1]) * 0.5
	var lead := crossing_point.distance_to(body.global_position)
	var verb := "comes at her from" \
			if def.pursues or def.spawn_mode == EventDef.SpawnMode.TOWARD_PLAYER else "crosses"
	Telemetry.note("ahead", "%s %s %.0fpx in front of her at %s" % [
		def.id, verb, lead,
		TelemetryLog.tile(_map.world_to_tile(body.global_position))])

## The other half of the director's day: a place the day budgeted and left unsited, put on a
## building face ahead of her once her heading for the day is clear. Day 3's fire is the only row
## that asks for this — see `EventDef.sited_on_her_way` and `EventDirector.site_what_is_on_her_way`.
##
## **The bookkeeping a late placement owes is the bookkeeping dawn already did for everything else.**
## A body is recorded per tile from the *plan* so the crowd steers round it whether or not the
## player has come near enough for it to exist (see "the bodies in the street" above), and a plan
## that has just been moved was recorded at a position it is no longer standing at — so the old
## footprint is given back and the new one taken, under the same owner id, in the one place that
## knows the move happened.
func _site_what_is_on_her_way(delta: float) -> void:
	var body := _player as CharacterBody2D
	if not body:
		return
	var moved := _director.site_what_is_on_her_way(delta, body.global_position, body.velocity,
			_plans)
	for plan in moved:
		_map.release_obstruction(plan.get_instance_id())
		_record_the_body(plan.get_instance_id(), plan.def, plan.position, plan.facing)
		# Where and why, because nothing else records it: the siting depends on the walk she took
		# and no seed reproduces it from outside. The same `ahead` entry the director's crossings
		# write, for the same reason.
		Telemetry.note("ahead", "%s is sited %.0fpx ahead of her at %s, %s of where she is at %s" % [
			plan.def.id, plan.position.distance_to(body.global_position),
			TelemetryLog.tile(_map.world_to_tile(plan.position)),
			_heading_name(body.velocity.normalized()),
			TelemetryLog.tile(_map.world_to_tile(body.global_position))])

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
## arc and the spend, and all three are the bookkeeping `_stream_in` does on a first instantiation —
## reused here rather than copied, because a second copy of that list is a second answer to "what
## does a fire do to a run".
##
## Called by `main._on_day_finished()` on a won day only. A lost day gives everything back
## (`GameState.finish_day`), so lighting a fire on one would be handing the retry a shell it never
## earned.
func light_what_she_never_met(at: Vector2) -> bool:
	if not _siting:
		return false
	for plan in _plans:
		# The fire is the set piece a run owes; a crew she never met simply was not met.
		if not plan.def.sited_on_her_way or plan.def.kind != GameEnums.EventKind.ONE_SHOT \
				or plan.was_live or plan.spent:
			continue
		# Its own stream, so a dusk placement cannot move anything the day already rolled.
		var rng := GameState.day_rng(_day, "dusk-fire")
		var sited := _siting.off_her_path(plan.def, rng, _everything_but(plan), at)
		if not sited:
			continue
		plan.position = sited.position
		plan.path = sited.path
		plan.facing = sited.facing
		plan.role = sited.role
		_stream_in(plan)
		_stream_out(plan)
		# It is over the moment it is recorded: the day has ended, and a plan left unspent would be
		# streamed back in by the next `stream_around` a rig made on the same day.
		plan.spent = true
		_map.release_obstruction(plan.get_instance_id())
		# Where and why, because nothing else records it: which site a dusk fire took depends on
		# where she finished the day, and no seed reproduces that from outside.
		Telemetry.note("ahead", "%s was never met: lit at dusk at %s, %.0fpx from where she "
				% [plan.def.id, TelemetryLog.tile(_map.world_to_tile(plan.position)),
				plan.position.distance_to(at)] + "finished the day")
		return true
	return false

## Everything the day has planned except `plan` — what a placement is spaced and checked against.
## The one being placed is never in it: a row moved off a position it has not been seen at must not
## be spaced against its own old body.
func _everything_but(plan: EventScheduler.Planned) -> Array[EventScheduler.Planned]:
	var others: Array[EventScheduler.Planned] = []
	for other in _plans:
		if other != plan:
			others.append(other)
	return others

## The day's placement context for the row it left for her walk, or `null` on a day that left none.
## Read by `tests/probes/m179_fire_on_her_way.gd` for the refusals a long wait was made of; nothing
## in the game asks.
func walk_siting() -> EventScheduler.WalkSiting:
	return _siting

func _find_player() -> bool:
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as Node2D
	return _player != null

func _retire_finished() -> void:
	var survivors: Array[EventInstance] = []
	var successors: Array[EventInstance] = []
	for instance in _instances:
		if instance.is_finished:
			var successor := _successor_of(instance)
			if successor:
				successors.append(successor)
			_mark_plan_spent(instance)
			# The body is gone from the street, so the ground under it is open again. Its plan gives
			# back its own copy in `_mark_plan_spent()`; this is the instance's.
			_map.release_obstruction(instance.get_instance_id())
			instance.queue_free()
		else:
			survivors.append(instance)
	if successors.is_empty() and survivors.size() == _instances.size():
		return
	survivors.append_array(successors)
	# Assigned in place rather than reassigned: `instances()` hands this array out by reference,
	# and the danger-edge indicator holds it across frames.
	_instances.assign(survivors)

## An event that has finished has finished for the day: its plan is spent, so walking back past
## the place it happened does not start it over. This is the half of streaming that a rebuilt
## instance would otherwise get wrong — an event is allowed to come and go while it is running,
## and is not allowed to come back once it is over.
func _mark_plan_spent(instance: EventInstance) -> void:
	for plan in _plans:
		if plan.live == instance:
			plan.live = null
			plan.spent = true
			# A spent plan is a body that has left, so its ground opens again — the plan's own half
			# of the release. See "the bodies in the street".
			_map.release_obstruction(plan.get_instance_id())
			return

## An event that leaves something behind where it stopped — how a fire engine ends its run
## at a fire. The successor is placed at the finishing position, not at a planned tile, so
## the two are always consistent.
func _successor_of(instance: EventInstance) -> EventInstance:
	if instance.def.spawns_on_finish == "":
		return null
	var def := EventCatalogue.by_id(instance.def.spawns_on_finish)
	if not def:
		push_error("event '%s' spawns unknown '%s'"
				% [instance.def.id, instance.def.spawns_on_finish])
		return null
	return _create(def, instance.global_position)

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
## The second fact handed over is whether she is running, and **`_player` is deliberately a
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
	var stroller := _player as Stroller
	var running: bool = stroller != null and stroller.run_excess_ratio() > 0.0
	var awake: bool = stroller == null or stroller.baby_is_awake()
	var strongest := _strongest_barrier_at(_player.global_position)
	for instance in _instances:
		instance.player_at = _player.global_position
		instance.player_running = running
		instance.baby_awake = awake
		instance.outranked_by_a_stronger_barrier = \
				instance.def.barrier_structure and instance != strongest

## Coming within `EventDef.detain_distance()` of an instance that has not yet chatted locks her
## controls for `detain_seconds` — the one mechanic in the catalogue that takes them away rather
## than costing a meter. This is the one place that can actually do it: `EventInstance` only ever
## gets handed a point (`player_at`), never a `Stroller`, and `Stroller.detain()` needs the real
## thing. See `EventDef.detain_seconds`, `EventInstance.start_chat()`.
##
## **Only the nearest eligible instance captures her**, and it is not an optimisation. A street
## door stands three bodies a tile apart across the street, each reaching a tile past its own edge,
## so ground that is inside two of them at once exists — and two holds starting on the same frame
## means two releases, the second reading the position the first teleported her to and sending her
## back through the door she has just come out of.
##
## **A `redetains` row is armed again once released, and what re-arms it is her leaving** — in
## either direction. `checkpoint_hut` and `checkpoint_post` are the two, and this is the whole of
## what makes a door a toll rather than a one-time gate. The boom between a street door's huts is
## not a third: it never inspects her (`EventDef.lifts_for_traffic`).
##
## **And a hut never takes her in from the carriageway its own door's boom spans.** A hut's trigger
## reaches a reach past its wall, which is further than the kerb, so without this a hut would reach
## out into the road and inspect her at the boom — the boom inspecting her in all but name, and a
## raised boom never a way past. That ground is the boom's: lowered it blocks her, raised she may
## walk under it. See `_on_a_booms_carriageway()`. `has_chatted()` is
## only the gate for everything else in the catalogue, since `chatting_mother`'s own contract is one
## conversation for good. A redetaining instance is skipped while it is chatting and then while its
## own `ReleaseLatch` holds — the far side of a door is a body's width away and the trigger reaches
## further than that, so she is standing inside it the moment she is let out, and the latch is what
## says *she has not walked back in, she has not left yet*. One step outside the circle clears it
## and the ordinary distance check below re-arms the door exactly as if it had never fired.
func _check_detentions() -> void:
	var body := _player as Stroller
	if not body:
		return
	_release_finished_door_detentions(body)
	_update_door_release_latches(body)
	# **One hold at a time, and it is not the same rule as the one below.** That one settles a tie
	# inside a single frame; this one settles the *next* frame, where the body that captured her is
	# skipped as already chatting and the next one along is free to start a hold of its own on top.
	# A door's three bodies stand a tile apart and all three reach her in the middle of it, so the
	# gate took her in, the hut took her in again a frame later, and the two released her in turn —
	# the second reading the position the first had teleported her to, and charging her
	# `Tuning.CHAT_EXCITEMENT` twice for one crossing. Asked of the instances rather than of
	# `Stroller.is_detained()`, because a hold and the input lock it sets run on two clocks that can
	# end a frame apart, and it is the hold that owns the release.
	for instance in _instances:
		if instance.is_chatting():
			return
	var nearest: EventInstance = null
	var nearest_range := INF
	for instance in _instances:
		if instance.def.detain_seconds <= 0.0 or instance.is_finished or instance.is_leaving:
			continue
		if instance.is_chatting():
			continue
		if not instance.def.redetains and instance.has_chatted():
			continue
		var latch: ReleaseLatch = _door_release_latches.get(instance)
		if latch and latch.holds():
			continue
		if instance.def.redetains and _on_a_booms_carriageway(instance, body.global_position):
			continue
		var range_to := instance.global_position.distance_to(body.global_position)
		if range_to > instance.def.detain_distance() or range_to >= nearest_range:
			continue
		nearest = instance
		nearest_range = range_to
	if not nearest:
		return
	nearest.start_chat()
	if nearest.def.redetains:
		_end_the_guard_for_a_hold()
		var axis := nearest.facing_now()
		var offset := body.global_position - nearest.global_position
		# **Never `signf()`, which answers zero in the doorway.** Walking *across* a crossing —
		# out of the carriageway at a hut, or straight up the middle of the road at the gate —
		# puts her exactly level with the body along the street, and a zero here multiplies the
		# release distance to nothing: she is set down where she was caught, inside the trigger,
		# and held again the next frame for as long as she stands there. Level with the door is
		# not a third side; it is one of the two, chosen the same way every time.
		_door_entry_side[nearest] = -1.0 if offset.dot(axis) < 0.0 else 1.0
	body.detain(nearest.def.detain_seconds)
	Telemetry.note("chat", "%s at %s, %.1fs, baby %s, meter %s" % [
		nearest.def.id, TelemetryLog.tile(_map.world_to_tile(nearest.global_position)),
		nearest.def.detain_seconds,
		"awake" if nearest.baby_awake else "asleep",
		("+%.0f" % Tuning.CHAT_EXCITEMENT) if nearest.baby_awake else "+0 (asleep)"])

## Whether `at` is on the carriageway spanned by the boom of the door `door_body` stands in — a
## live `lifts_for_traffic` instance on the same cross-street line (its own `facing_now()` axis),
## with `at` no further across that line from the boom's centre than the boom's own body reaches.
## The boom is laid over exactly the carriageway, so its reach is the carriageway's half-width and
## this is "she is in the road at this door" stated over the door's own geometry rather than over
## the map's tiles — the same datum the huts and the boom were placed from.
##
## `false` for an alley door, which has no boom, so a post's trigger is untouched.
func _on_a_booms_carriageway(door_body: EventInstance, at: Vector2) -> bool:
	for instance in _instances:
		if not instance.def.lifts_for_traffic:
			continue
		var axis := instance.facing_now()
		if absf((door_body.global_position - instance.global_position).dot(axis)) > 1.0:
			continue
		var offset := at - instance.global_position
		if (offset - axis * offset.dot(axis)).length() <= instance.def.obstructs_radius:
			return true
	return false

## The other half of `checkpoint_hut`/`checkpoint_post`'s own toll: the moment a redetaining
## instance's conversation ends, teleport her to the mirror of where she stood, reflected through
## the crossing's own cross-street line and set down **just clear of the body**, as close to the
## door as she can stand — see `Tuning.CHECKPOINT_RELEASE_MARGIN`. Run *before* the ordinary
## detention pass in the same frame, so a distance check that would otherwise fire again this frame
## sees where she has just been put rather than where she was captured.
##
## **She is let out inside the door's own trigger, and that is on purpose.** The far side of a body
## she cannot walk through is a body's width away and the trigger reaches further than that, so the
## only way to land outside it is to throw her further than the door is wide — *(2026-09-12, the
## player: "she just spawns further away now? it should work that she has a flag 'just spawned' that
## only resets once she leaves the area".)* A `ReleaseLatch` armed here with that instance's own
## trigger circle is that flag: it holds until she is measured outside the circle, so standing where
## she was let out costs her nothing however long she stands there, and the toll comes back the
## moment she leaves and walks in again.
##
## **The teleport, not `move_and_slide()`.** She is standing inside the band that is about to seal
## behind her — walking her out through the world would mean colliding with the very body that is
## detaining her, which is the thing `Stroller.teleport_to()`'s own doc explains at length.
func _release_finished_door_detentions(body: Stroller) -> void:
	for instance in _instances:
		if not instance.def.redetains or not _door_entry_side.has(instance):
			continue
		if instance.is_chatting():
			continue
		var entry_sign: float = _door_entry_side[instance]
		_door_entry_side.erase(instance)
		var axis := instance.facing_now()
		# Against the body, not against the trigger: the far side of the door is where the far side
		# of the door is, and the latch below is what keeps her from being taken in again there.
		var clearance := instance.def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS \
				+ Tuning.CHECKPOINT_RELEASE_MARGIN
		var offset := body.global_position - instance.global_position
		var along := offset.dot(axis)
		var released_along := -entry_sign * maxf(absf(along), clearance)
		var across := offset - axis * along
		var released_at := instance.global_position + axis * released_along + across
		body.teleport_to(released_at)
		# **Moved, then shown, in that order and in this one frame.** `teleport_to()` has just put
		# her down and reset her interpolation, so the first frame drawn after this call draws her
		# at the door she is coming out of and nowhere else. The un-hide cannot live on the
		# instance's own clock — that runs in `_process`, a drawn frame, and every frame between it
		# and the next physics tick drew her standing at the place she went in. The camera comes
		# back here for the same reason: its ease home then starts from the hut toward where she
		# actually is rather than toward where she was caught.
		body.show_after_inspection()
		body.release_camera_focus()
		_latch_everything_she_was_let_out_into(released_at)
		Telemetry.note("checkpoint", "%s at %s, %.1fs, released on the %s side" % [
			instance.def.id, TelemetryLog.tile(_map.world_to_tile(instance.global_position)),
			instance.def.detain_seconds, _compass_of(axis, released_along)])

## Arms a `ReleaseLatch` for **every** redetaining body whose own trigger `at` is inside, not only
## the one that just let her out.
##
## Doors stand close enough together that their reaches overlap — two doors meeting at a corner —
## so the ground one hut lets her out onto can be inside another door body's reach: latching only
## the releasing body means being let out of one and taken straight into the next, which is one
## crossing charged twice and, to the player, the door refusing to let go. **One crossing is one toll** — *"it works in both directions with
## the same cost each time"* — so what she has just come out of is the whole door, and every part of
## it waits until she has walked out of its own circle.
func _latch_everything_she_was_let_out_into(at: Vector2) -> void:
	for instance in _instances:
		if not instance.def.redetains or instance.is_finished or instance.is_leaving:
			continue
		var reach := instance.def.detain_distance()
		if instance.global_position.distance_to(at) > reach:
			continue
		var latch := ReleaseLatch.new()
		latch.arm(instance.global_position, reach)
		_door_release_latches[instance] = latch

## Tells every live release latch where she is now, so one that she has walked out of clears itself
## and its door is a toll again. Run once a frame from `_check_detentions()`, before anything asks
## `holds()`: a latch only updated when somebody remembers is a latch that holds too long, and a
## door that never re-arms is not a door. A latch whose instance has gone — streamed out, or the
## day over — goes with it.
func _update_door_release_latches(body: Stroller) -> void:
	if _door_release_latches.is_empty():
		return
	var spent: Array = []
	for instance in _door_release_latches:
		var latch: ReleaseLatch = _door_release_latches[instance]
		latch.update(body.global_position)
		if not latch.holds() or not is_instance_valid(instance):
			spent.append(instance)
	for instance in spent:
		_door_release_latches.erase(instance)

# ------------------------------------------------------------ under the boom ---
# *(2026-09-24, the player: "If a car opens it for her and she walks through she would probably get
# hit by the car, no?" · "A yes".)* A raised boom is ground she may walk under, and that skips the
# huts' inspection. **It is detected, not guessed**: a door's huts, its posts and a lowered boom are
# solid, and an inspection's release is a teleport, so a crossing of a door's own line that she
# *walked* is a crossing under a raised boom and nothing else. Nothing here asks where the arm is.
#
# *(2026-09-24: "The guards should start pursuing her in that case".)* **And it sets a guard on
# her**, one, from the door's hut nearer to her; a catch ends the day, since *"not going through the
# checkpoint is a clear unlawful thing here"*. See `EventCatalogue._door_guard()`.

## How many times today she has walked across a door's line rather than being let through it —
## the count `tests/test_route_rig.gd` holds a rig run to zero on.
func walks_under_a_boom() -> int:
	return _walked_under

## Once a frame: whether she has crossed a door body's own cross-street line since the last look,
## and no `Stroller.teleport_to()` (nor `reset_at()`) moved her in between. Run before
## `_check_detentions()`, so a release that teleports her this frame is seen by the next look as
## the outright move it is.
##
## **A door's line is its bodies' line, one body's width at a time.** Each door body — a hut, a
## post, the boom — stands on the crossing's own cross-street line (the one an inspection's release
## is reflected through, `facing_now()`'s axis), and the crossing counts against the body whose own
## reach across that line it happened inside, so the three bodies of a street door cover the street
## kerb to kerb between them and a line through a door never extends past the door.
func _watch_the_door_lines() -> void:
	var body := _player as Stroller
	if not body:
		return
	var here := body.global_position
	var was := _last_seen_at
	var put_down := body.outright_moves != _last_outright_moves
	_last_seen_at = here
	_last_outright_moves = body.outright_moves
	if was == Vector2.INF or put_down:
		return
	var crossed: EventInstance = null
	for instance in _instances:
		if not instance.def.redetains and not instance.def.lifts_for_traffic:
			continue
		if where_she_crossed(instance.global_position, instance.facing_now(),
				instance.def.obstructs_radius, was, here) != Vector2.INF:
			crossed = instance
			break
	if not crossed:
		return
	_walked_under += 1
	Telemetry.note("checkpoint", "%s at %s walked through, heading %s — not inspected%s" % [
		crossed.def.id, TelemetryLog.tile(_map.world_to_tile(crossed.global_position)),
		_heading_name(here - was),
		(", the boom up" if crossed.is_raised() else ", the boom down")
		if crossed.def.lifts_for_traffic else ""])
	_set_a_guard_on_her(crossed, here)

## One `door_guard` after her, stepping out of the wall of the hut nearer to her — of the huts on the
## crossed body's own line — on the side of the line she has crossed to. *(2026-09-24: "Or guards
## that pursue her should spawn at the huts" · "One guard is enough".)* The guards drawn at the huts
## stay at their posts; this is another man out of the door.
##
## **One at a time.** A second walk under the same boom while he is still after her sets nobody else
## on her; once he has caught her, given up or run out his chase, the next walk under sets the next
## one. A crossed alley post is its own door and its own guard, so he steps out of the post.
func _set_a_guard_on_her(crossed: EventInstance, here: Vector2) -> void:
	if is_instance_valid(_guard_after_her) \
			and not _guard_after_her.is_finished and not _guard_after_her.is_leaving:
		return
	var axis := crossed.facing_now()
	var hut: EventInstance = null
	var nearest := INF
	for instance in _instances:
		if not instance.def.redetains or instance.is_finished or instance.is_leaving:
			continue
		if absf(instance.facing_now().dot(axis)) < 0.99 \
				or absf((instance.global_position - crossed.global_position).dot(axis)) > 1.0:
			continue
		var range_to := instance.global_position.distance_to(here)
		if range_to < nearest:
			nearest = range_to
			hut = instance
	if not hut:
		return
	var side := -1.0 if (here - hut.global_position).dot(axis) < 0.0 else 1.0
	var at := hut.global_position + axis * side * hut.def.obstructs_radius
	_guard_after_her = _spawn_unplanned(EventCatalogue.by_id("door_guard"), at)

## *(2026-09-24, the player, answering whether a hold should end the chase: "we can try b. if she
## voluntarily goes to a hut the whole pursuit has been accomplished".)* Called from
## `_check_detentions()` the moment any `redetains` row — a checkpoint hut or an alley post, the one
## `_guard_after_her` stepped out of included — starts a hold: he gives up exactly as
## `EventInstance._chase()` has him give up when she outruns it, same state, same drawing, same
## telemetry, through `EventInstance.give_up_the_chase()`. A guard still in his own notice when the
## hold starts gives up too, since nothing here asks whether it is over — the smallest reading of
## "the whole pursuit has been accomplished" once she is inside a hut of her own accord. The
## roadblock's hunting guard and the escape's masked pursuer are never `_guard_after_her`, so a hold
## never reaches them.
func _end_the_guard_for_a_hold() -> void:
	if is_instance_valid(_guard_after_her) \
			and not _guard_after_her.is_finished and not _guard_after_her.is_leaving:
		_guard_after_her.give_up_the_chase()

## Where the step from `was` to `here` crosses the line through `at` across `axis` — the door
## body's own cross-street line — if it crosses it within `reach` of `at` along the line, or
## `Vector2.INF` if it does not. Which side she is on is read the way `_check_detentions()` reads
## an entry side: level with the line counts as the positive side, so standing on it is on one of
## the two rather than on both.
static func where_she_crossed(at: Vector2, axis: Vector2, reach: float, was: Vector2,
		here: Vector2) -> Vector2:
	var before := (was - at).dot(axis)
	var after := (here - at).dot(axis)
	if (before < 0.0) == (after < 0.0):
		return Vector2.INF
	var crossing := was.lerp(here, before / (before - after))
	var offset := crossing - at
	if (offset - axis * offset.dot(axis)).length() > reach:
		return Vector2.INF
	return crossing

## Which compass direction `along` (a signed distance down `axis`) points at — `axis` is always
## `Vector2.RIGHT` (an east-west street) or `Vector2.DOWN` (north-south, since Y grows downward on
## screen), the two values `RegionPlanner._along_axis` ever hands a door body's `Planned.facing`.
static func _compass_of(axis: Vector2, along: float) -> String:
	if absf(axis.x) > absf(axis.y):
		return "east" if along > 0.0 else "west"
	return "south" if along > 0.0 else "north"

## The same question asked of a free heading rather than of a street's own axis: whichever of the
## two she is mostly going, named the same way. Most headings are diagonal — a press sets an
## arbitrary unit vector — so the dominant component is the only honest one-word answer.
static func _heading_name(heading: Vector2) -> String:
	if absf(heading.x) > absf(heading.y):
		return _compass_of(Vector2.RIGHT, heading.x)
	return _compass_of(Vector2.DOWN, heading.y)

func _check_hard_fails() -> void:
	if _hard_failed or not _find_player():
		return
	for instance in _instances:
		if instance.is_lethal_at(_player.global_position):
			_hard_failed = true
			EventBus.hard_fail_triggered.emit(instance.def.id)
			return

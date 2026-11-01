class_name EventStreaming
extends RefCounted
## **A day's plan and its live events are different things, and this is what joins them.** The day
## is planned whole at dawn (`EventManager.start_day()`), which is what keeps every invariant stated
## over a day (one usable park, a walkable route to it, determinism); a plan becomes an
## `EventInstance` only when the player comes within `stream_radius` of it (`stream_in()`), and goes
## again when she leaves (`stream_out()`), carrying what it was in the middle of — except a plan a
## task rides, which `keep_live()` puts in the world at once and keeps there. A plan that comes
## again (`EventScheduler.Planned.repeats()`) is brought back on its own clock
## (`bring_back_what_repeats()`), and a finished one is spent for the day (`retire_finished()`).
##
## The gameplay half of that is bigger than the frames it saves. Loading the day upfront gives days
## in which **zero** events ever come within reach: a twenty-second event planted across the city
## fires and finishes at dawn, unobserved, and the budget bought nothing. An event that waits for
## her is an event she meets.
##
## Handed the world the events stand in (`EventWorld`) and the spawner every instance is made by
## (`EventSpawner`).

## The world the events stand in, the player and the live instances.
var world: EventWorld
## What makes an instance of a plan, and what a finished one leaves behind.
var _spawner: EventSpawner

func _init(the_world: EventWorld, spawner: EventSpawner) -> void:
	world = the_world
	_spawner = spawner

## Takes `plans` as the day's whole plan, the very array handed in. A walk whose plans come again
## finds them with `find_what_repeats()`.
func take(plans: Array[EventScheduler.Planned]) -> void:
	_plans = plans

## Adds one plan placed after dawn to the day's, its body recorded where it stands, so it streams
## in like any planned row.
func add(plan: EventScheduler.Planned) -> void:
	_plans.append(plan)
	_spawner.record_the_body(plan.get_instance_id(), plan.def, plan.position, plan.facing)

## Forgets the day's plan: every plan's live instance let go (the manager frees the instances), the
## repeats and the broadcast clock.
func clear() -> void:
	for plan in _plans:
		plan.live = null
	_plans.clear()
	_repeating.clear()
	broadcast_clock = 0.0

## Today's whole plan, sited and unsited, spent and unspent. See `EventScheduler.Planned`.
var _plans: Array[EventScheduler.Planned] = []
## The plans in `_plans` that come again (`EventScheduler.Planned.repeats()`), found once when a
## walk starts so the per-frame pass over them (`bring_back_what_repeats()`) asks nothing of the
## rest.
var _repeating: Array[EventScheduler.Planned] = []
## Elapsed seconds since this day started, advanced every physics frame regardless of whether
## anybody is near a mast. **The city's own broadcast clock** — every mast reads it, not its own
## age, at the moment it streams in (`stream_in()`), which is what makes six masts met minutes
## apart still speak in phase: they are not coordinated frame to frame, they are all telling the
## same time. Reset with the rest of the day in `clear()`.
var broadcast_clock := 0.0

## The run's spent one-shots — `start_day`'s own argument, kept because one kind of one-shot is
## spent while the day is running rather than while it is being planned. See `stream_in()`. Empty
## until a day has been started, which is the finale's case and is right: an escape spends nothing.
var consumed: Array[String] = []

## How close the player has to be for a planned event to exist. `INF` turns streaming off and
## puts the whole day in the world at once, which is what a test rig with no player wants —
## `tests/test_event_manager.gd` and `tests/test_full_run.gd` are about a day's whole event set
## rather than about what one player walked past.
var stream_radius := Tuning.EVENT_STREAM_RADIUS

## Brings into the world everything within reach of a point, and takes away what has gone out
## of it. Idempotent, and cheap: one distance check per planned event.
##
## The hysteresis is not a nicety. Without it a player pacing on the boundary of an event's
## reach rebuilds it every other frame, and since a rebuilt instance starts its telegraph again
## that is an event permanently crouching at her and never arriving.
##
## **Asked of every plan on every physics tick**, several hundred of them, most of which stand at
## one point: so a point plan's distance is worked out here rather than through
## `Planned.is_placed()` and `Planned.distance_from()`, which answer the same number by the same
## expression, and only a route goes to `distance_from()`.
func stream_around(at: Vector2) -> void:
	var stream_out_beyond := stream_radius + Tuning.EVENT_STREAM_HYSTERESIS
	for plan in _plans:
		# A plan waiting to come again is brought back on its own clock, not by her distance.
		if plan.spent or plan.comes_in > 0.0:
			continue
		var position := plan.position
		if position == Vector2.INF:
			continue
		var distance := position.distance_to(at) if plan.path.size() < 2 \
				else plan.distance_from(at)
		if plan.live == null:
			if distance <= stream_radius:
				stream_in(plan)
		elif not plan.kept_live and distance > stream_out_beyond \
				and not _could_be_watched(plan.live, at):
			stream_out(plan)

## The planned instance of the row `id` standing within a tile of `at`, put in the world now
## wherever she is and kept there for the rest of the day — never streamed out — or null when today
## plans none there. For a task that rides a planned place: day 8's burnt shell, whose mark she may
## read from the far side of the city, and which must not be streamed away from under its contact
## when she walks off again. The plan's own instance rather than a second one beside it, so its
## field is counted once.
func keep_live(id: String, at: Vector2) -> EventInstance:
	for plan in _plans:
		if plan.def.id != id or plan.spent or not plan.is_placed() \
				or plan.position.distance_to(at) >= Tuning.TILE_SIZE:
			continue
		if plan.live == null:
			stream_in(plan)
		plan.kept_live = true
		return plan.live
	return null

func stream_in(plan: EventScheduler.Planned) -> void:
	var first_time := not plan.was_live
	# The scar is recorded the first time the event is put in the world and never again: walking
	# back past a burnt-out shell must not re-report the fire that made it.
	plan.live = _spawner.create(plan.def, plan.position, plan.path, first_time, plan.facing)
	# **A set piece the day owed her walk is spent here rather than at dawn**, because here is where it
	# becomes something that happened — see `EventScheduler._place_one_shots`. The list is the one
	# `start_day` was handed, which in a played game is `world.run.attempt_spend.consumed_one_shots`
	# and in a rig is the rig's own.
	if first_time and plan.def.on_her_way != null and plan.def.kind == GameEnums.EventKind.ONE_SHOT \
			and not plan.def.id in consumed:
		consumed.append(plan.def.id)
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
	# `plan.noticed_at` carries the same resume for a `EventDef.notice` row: without it a pursuer
	# streamed out mid-chase forgets she was ever noticed and comes back `is_waiting()`, standing
	# where the day planted it rather than still coming for her.
	#
	# **A mast's own age is the broadcast clock, not `plan.age`.** Every mast reads the same clock
	# at every stream-in, first time or the fifth, so two masts met minutes apart still read the
	# same pulse phase — "all masts speak at once" is true because they are all telling the same
	# time, not because anything coordinates them frame to frame. See `broadcast_clock` below.
	var resume_age := broadcast_clock if plan.mast_id != "" else plan.age
	plan.live.resume(resume_age, plan.travelled, plan.noticed_at)
	# A guard spent before the stream-out comes back as only his barrier, never as a guard again
	# (`EventBarrierPost.restore()`).
	plan.live.restore_behaviours(plan.behaviours)
	plan.live.silenced = plan.silenced
	plan.was_live = true
	world.instances.append(plan.live)
	_spend_the_rest_of_the_group(plan)

## A set piece is planned at **every** site of a covering set and happens at exactly one of them:
## the one she reaches.
##
## This is where "the one she reaches" is decided, and it has to be here rather than anywhere
## later. The moment an event enters the world it is real — `EventSpawner.create()` records its scar and moves
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
		world.map.release_obstruction(plan.get_instance_id())
		# A sibling cannot already be live — the group is spent the first time any of them enters
		# the world, and `stream_around` skips a spent plan — but taking one out is the only safe
		# thing to do if that ever stops being true, because a second live one is a second scar.
		if plan.live:
			stream_out(plan)

## **Whether `instance` is near enough to `at` for her to be watching it** — within
## `Tuning.OUT_OF_SIGHT`, the distance beyond which nothing can be seen. A plan is streamed out by
## how far she is from its *route* (`EventScheduler.Planned.distance_from()`), but an instance that
## is leaving carries on past the route's end, and a car she follows out of its street is a long way
## from the route while she is a few paces behind it. Streaming that one out would delete it in
## front of her (*nothing vanishes while you are looking at it*, "Going away" in `docs/EVENTS.md`),
## so it stays until it is out of sight — where its own departure ends it anyway
## (`EventDeparture.leave()`).
func _could_be_watched(instance: EventInstance, at: Vector2) -> bool:
	return is_instance_valid(instance) \
			and instance.global_position.distance_to(at) <= Tuning.OUT_OF_SIGHT

func stream_out(plan: EventScheduler.Planned) -> void:
	plan.age = plan.live.age
	plan.travelled = plan.live.path_travelled()
	plan.noticed_at = plan.live.noticed_at()
	plan.behaviours = plan.live.save_behaviours()
	# **A departure streamed out is over**, as one that finished is (`_mark_plan_spent()`): it is not
	# rebuilt to run an ended event again. Walking back, it would be rebuilt 900px or more from her
	# and finish out of view, so no car is seen coming back; what the spend keeps out is a person
	# streamed out mid-`leave_along` standing in day 12's closed park again. A guard walking away from
	# his barrier is the one that comes back, as only the barrier.
	if plan.live.is_leaving and not (plan.live.barrier_post and plan.live.barrier_post.is_spent()):
		plan.spent = true
		world.map.release_obstruction(plan.get_instance_id())
	world.map.release_obstruction(plan.live.get_instance_id())
	world.instances.erase(plan.live)
	plan.live.take_out()
	plan.live = null

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
			_spawner.retire(plan.live)
			continue
		plan.spent = true
		world.map.release_obstruction(plan.get_instance_id())
	return taken

## Today's own foot for a mast id, or `Vector2.INF` if today carries no mast with that id — the
## point day 11's task (silence a mast by reaching its foot, the way she touches a chalk mark)
## records its scar at. Reads the ordinary broadcast's own
## plan, which always exists for a live mast's id; the curfew announcement shares the same foot.
func mast_foot(mast_id: String) -> Vector2:
	for plan in _plans:
		if plan.mast_id == mast_id and plan.def.role == EventDef.Role.MAST:
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
			# instant this flips, so the cache the present rate keeps would otherwise go on
			# answering the pre-silence contribution for the rest of this tick.
			plan.live.excitement.invalidate_contribution()
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
			plan.live.excitement.invalidate_contribution()
	return silenced.size()

## How many sited events the day is carrying, live or waiting to be walked past. This is the
## number that answers "is thirteen events on day one a city or a gauntlet"; `EventManager.active_count()`
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

## Everything the day has planned except `plan` — what a placement is spaced and checked against.
## The one being placed is never in it: a row moved off a position it has not been seen at must not
## be spaced against its own old body.
func everything_but(plan: EventScheduler.Planned) -> Array[EventScheduler.Planned]:
	var others: Array[EventScheduler.Planned] = []
	for other in _plans:
		if other != plan:
			others.append(other)
	return others

func retire_finished() -> void:
	var survivors: Array[EventInstance] = []
	var successors: Array[EventInstance] = []
	for instance in world.instances:
		if instance.is_finished:
			var successor := _spawner.successor_of(instance)
			if successor:
				successors.append(successor)
			_mark_plan_spent(instance)
			# The body is gone from the street, so the ground under it is open again. Its plan gives
			# back its own copy in `_mark_plan_spent()`; this is the instance's.
			world.map.release_obstruction(instance.get_instance_id())
			instance.take_out()
		else:
			survivors.append(instance)
	if successors.is_empty() and survivors.size() == world.instances.size():
		return
	survivors.append_array(successors)
	# Assigned in place rather than reassigned: `EventManager.instances()` hands this array out by reference,
	# and the danger-edge indicator holds it across frames.
	world.instances.assign(survivors)

## An event that has finished has finished for the day: its plan is spent, so walking back past
## the place it happened does not start it over. This is the half of streaming that a rebuilt
## instance would otherwise get wrong — an event is allowed to come and go while it is running,
## and is not allowed to come back once it is over.
func _mark_plan_spent(instance: EventInstance) -> void:
	for plan in _plans:
		if plan.live == instance:
			if plan.repeats():
				_done_for_now(plan)
				return
			plan.live = null
			plan.spent = true
			# A spent plan is a body that has left, so its ground opens again — the plan's own half
			# of the release. See "the bodies in the street".
			world.map.release_obstruction(plan.get_instance_id())
			return

# ------------------------------------------------------------- what comes again ---
# A plan that repeats (`EventScheduler.Planned.repeats()`) is not spent when its instance is done:
# it waits and comes again, a fresh instance every time, so each comes, warns and runs exactly as
# the first did. The building's vents blow on their own periods, the masked man comes up the shaft
# again once the last has run out of the top, and the explosions outside come on theirs.

## Counts every repeating plan's clock down and brings back each whose time has come: a vent its
## period after its last blow began (`repeat_every`), the masked man his wait after the last one
## started leaving (`repeat_after`), and one sited at her (`at_her`) where she stands now. A row
## from outside the walls (`EventDef.from_outside`) is shown by the world as it comes
## (`WorldContext.bang_outside()`), whether or not there is anybody for its charge to stand on.
func bring_back_what_repeats(delta: float) -> void:
	for plan in _repeating:
		if plan.spent:
			continue
		# Its run is over when it is off the end of it, not when the instance is finally freed: a
		# mobile row that has run out of route spends a leaving phase walking out of sight, so a wait
		# counted from its deletion would be the stated one plus however long that took.
		if plan.live != null and (plan.live.is_leaving or plan.live.is_finished):
			_done_for_now(plan)
		if plan.wait_began:
			plan.wait_began = false
			continue
		plan.comes_in -= delta
		if plan.live != null or plan.comes_in > 0.0:
			continue
		plan.comes_in += plan.repeat_every
		if plan.at_her:
			if not world.has_player():
				# Nobody for its charge to stand on, and the bang still goes off.
				_spawner.show_the_bang(plan.def)
				continue
			plan.position = world.player.global_position
		stream_in(plan)

## Finds the plans of the walk just started that come again (`_repeating`). A day's own plan has
## none; the building's vents, its masked man and its explosions outside are.
func find_what_repeats() -> void:
	_repeating.clear()
	for plan in _plans:
		if plan.repeats():
			_repeating.append(plan)

## A repeating plan whose instance is done, made ready to come again: the instance is let go — a
## leaving one walks on out of sight on its own, retired when it is finished — the plan's own body
## is given back, it will start over from where every instance of it starts, and a wait on its last
## one (`repeat_after`) begins now.
func _done_for_now(plan: EventScheduler.Planned) -> void:
	plan.live = null
	world.map.release_obstruction(plan.get_instance_id())
	plan.age = plan.arrives_aged
	plan.travelled = 0.0
	plan.noticed_at = INF
	plan.behaviours = {}
	if plan.repeat_after > 0.0:
		plan.comes_in = maxf(plan.comes_in, plan.repeat_after)
		plan.wait_began = true

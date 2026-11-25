class_name EventStreaming
extends RefCounted
## **A day's plan and its live events are different things, and this is what joins them.** The day
## follows from its seed whatever her path: the dawn plans its part (`EventManager.start_day()`)
## and every unit of the day's locations draws the same whatever order it is drawn in, as she comes
## near it (`UnitDraw`, `EventsAhead.draw_what_comes_near()`), which is what keeps every invariant
## stated over a day (one usable park, a walkable route to it, determinism); a plan becomes an
## `EventInstance` only when the player comes within `stream_radius()` of it (`stream_in()`), and goes
## again when she leaves (`stream_out()`), carrying what it was in the middle of — except a plan a
## task rides, which `keep_live()` puts in the world at once and keeps there. A plan that comes
## again (`EventPlan.repeats()`) is brought back on its own clock
## (`bring_back_what_repeats()`), and a finished one is spent for the day (`retire_finished()`).
## The live event of each plan and the clock of one that comes again are kept here, in a table of
## this class's own (`_state`), and the plan is told when its event enters the world and leaves it
## (`EventPlan.enter_the_world()`, `leave_the_world()`).
##
## The gameplay half of that is bigger than the frames it saves. Loading the day upfront gives days
## in which **zero** events ever come within reach: a twenty-second event planted across the city
## fires and finishes at dawn, unobserved, and the day held it for nothing. An event that waits for
## her is an event she meets.
##
## Handed the world the events stand in (`EventWorld`), the spawner every instance is made by
## (`EventSpawner`) and the walk's plans (`WalkEvents`), which it streams.

## The world the events stand in, the player and the live instances.
var world: EventWorld
## What makes an instance of a plan, and what a finished one leaves behind.
var _spawner: EventSpawner
## The walk's plans, sited and unsited, spent and unspent. See `EventPlan`.
var _walk: WalkEvents

## **What streaming keeps of one plan**, made when the plan is first streamed in or when the walk's
## repeating plans are found (`find_what_repeats()`) and read by this class alone: the live event
## it made of the plan while the plan is in the world, and the clock of a plan that comes again.
class StreamedPlan:
	extends RefCounted
	## The plan's live event while it is in the world, null otherwise.
	var live: EventInstance = null
	## Seconds until the plan's instance next comes; nothing streams it in before then. 0 for a
	## plan whose instance may be in the world now, which is every plan that does not come again.
	var comes_in := 0.0
	## Set the frame a wait on the plan's last instance begins, so that frame is not counted off
	## the wait.
	var waits_from_now := false

## What streaming keeps of each plan it has streamed in or that comes again. A plan without an entry
## is not in the world and waits for nothing.
var _state: Dictionary[EventPlan, StreamedPlan] = {}

## The entry of `plan`, made if it has none.
func _entry_of(plan: EventPlan) -> StreamedPlan:
	var entry: StreamedPlan = _state.get(plan)
	if entry == null:
		entry = StreamedPlan.new()
		_state[plan] = entry
	return entry

## **The live event of `plan`** while it is in the world, null otherwise: for a caller that names or
## commands it (`EventManager.event_of()`). A caller that only asks something of a plan asks the plan
## (`EventPlan.is_in_the_world()`).
func event_of(plan: EventPlan) -> EventInstance:
	var entry: StreamedPlan = _state.get(plan)
	return entry.live if entry != null else null

func _init(the_world: EventWorld, spawner: EventSpawner, walk: WalkEvents) -> void:
	world = the_world
	_spawner = spawner
	_walk = walk

## Who is told the ground a body placed after dawn stands on (`use_body_listener()`), a
## `func(tiles: Array[Vector2i]) -> void`. Invalid for none: a rig with no crowd.
var _body_listener := Callable()

## **Hands in who is told where a body stands**, called by `add()` and `move_the_body()` with the
## tiles a plan's body covers (`EventSpawner.footprint_of()`) once the body is recorded on
## the map, so a crowd that holds a car on those tiles can recycle it (`Crowd.recycle_cars_on()`)
## and the car's new place is rolled with the body already in the map's record. A body placed after
## dawn goes through one of two calls, each through `_record_and_tell()`: `add()` for a plan new to
## the walk (a unit's draw as she comes near it, day 13's swapped roadblock (`swap_section()`), day
## 11's added mast, a place put down on her route) and `move_the_body()` for a plan the walk already
## holds that the director sites on her way, the first time or again (day 3's fire, a poster crew, a
## route's mast before it is in the world). The tiles are read and never changed: they are the
## map's own record of the body.
## The simulation's builder, which makes both the events and the crowd, hands it the crowd's call
## (`SimulationBuilder`). A body spawned
## with no plan (`EventSpawner.spawn()`) is told to nobody: it has no plan to add, and what spawns
## one is a rig or a scripted moment, not the walk. With no listener nothing is told.
func use_body_listener(listener: Callable) -> void:
	_body_listener = listener

## Adds one plan new to the walk (placed after dawn) to the walk's, its body recorded where it
## stands, so it streams in like any planned row, and tells the listener the ground that body
## stands on.
func add(plan: EventPlan) -> void:
	_walk.add(plan)
	_record_and_tell(plan)

## **Gives back the ground a plan's body stood on and takes the ground it stands on now**, under
## the same owner, and tells the listener it: for a plan the walk already holds that the director
## sites on her way, the first time or again (day 3's fire, a poster crew, a route's mast before it
## is in the world; `EventsAhead.site_what_is_on_her_way()`).
func move_the_body(plan: EventPlan) -> void:
	world.map().release_obstruction(plan.get_instance_id())
	_record_and_tell(plan)

## Records `plan`'s body on the map, then tells the listener the tiles it covers, so what the
## listener rolls (a recycled car's new place) reads the body as already there.
func _record_and_tell(plan: EventPlan) -> void:
	var tiles := _spawner.record_the_body(plan.get_instance_id(), plan.row(), plan.placed_at(),
			plan.faces())
	if _body_listener.is_valid() and not tiles.is_empty():
		_body_listener.call(tiles)

## **`new` across a section in place of what the section held** (`olds`, day 13's swap,
## `EventsAhead.swap_in_a_section()`): each of `olds` spent, its body given back and taken out of the
## world if it is in it, and `new` added with its body recorded, put in the world now and kept there
## for the rest of the day, since a task's contact rides it. Answers `new`'s live instance.
func swap_section(olds: Array[EventPlan], new: EventPlan) -> EventInstance:
	for old in olds:
		old.spend()
		world.map().release_obstruction(old.get_instance_id())
		if old.is_in_the_world():
			stream_out(old)
	add(new)
	stream_in(new)
	new.keep_in_the_world()
	return event_of(new)

## Forgets the walk: every plan's live instance let go (the manager frees the instances), the walk's
## plans, the repeats and the broadcast clock.
func clear() -> void:
	for plan in _walk.plans():
		plan.leave_the_world(plan.saved())
	_state.clear()
	_walk.clear()
	_repeating.clear()
	_broadcast_clock = 0.0

## The plans of the walk that come again (`EventPlan.repeats()`), found once when a
## walk starts so the per-frame pass over them (`bring_back_what_repeats()`) asks nothing of the
## rest.
var _repeating: Array[EventPlan] = []
## Elapsed seconds since this day started, advanced every physics frame regardless of whether
## anybody is near a mast. **The city's own broadcast clock** — every mast reads it, not its own
## age, at the moment it streams in (`stream_in()`), which is what makes six masts met minutes
## apart still speak in phase: they are not coordinated frame to frame, they are all telling the
## same time. Reset with the rest of the day in `clear()`.
var _broadcast_clock := 0.0

## Lets `delta` seconds pass on the city's broadcast clock.
func advance_the_broadcast(delta: float) -> void:
	_broadcast_clock += delta

## The run's spent one-shots — `start_day`'s own argument, kept because one kind of one-shot is
## spent while the day is running rather than while it is being planned. See `stream_in()`. Empty
## until a day has been started, which is the finale's case and is right: an escape spends nothing.
var _consumed: Array[String] = []

## Hands in the run's spent one-shots, which a one-shot spent while the day runs is added to
## (`stream_in()`). The list is shared by reference, never copied: the run's own is the one that grows.
func use_the_spent_one_shots(spent: Array[String]) -> void:
	_consumed = spent

## How close the player has to be for a planned event to exist. `INF` turns streaming off and
## puts the whole day in the world at once, which is what a test rig with no player wants —
## `tests/test_event_manager.gd` and the full run suites (`tests/full_run_rig.gd`) are about a day's whole event set
## rather than about what one player walked past.
var _stream_radius := Tuning.EVENT_STREAM_RADIUS

## Sets how close the player has to be for a planned event to exist. See `stream_radius()`.
func stream_within(radius: float) -> void:
	_stream_radius = radius

## How close the player has to be for a planned event to exist, `INF` when streaming is off.
func stream_radius() -> float:
	return _stream_radius

## Brings into the world everything within reach of a point, and takes away what has gone out
## of it. Idempotent, and cheap: one distance check per planned event.
##
## The hysteresis is not a nicety. Without it a player pacing on the boundary of an event's
## reach rebuilds it every other frame, and since a rebuilt instance starts its telegraph again
## that is an event permanently crouching at her and never arriving.
##
## **Asked of every plan on every physics tick**, several hundred of them, most of which stand at
## one point: so each plan is asked one question (`EventPlan.streaming_distance_from()`, which answers
## a point plan's distance by one expression and only a route through `distance_from()`) and one
## table lookup answers the rest; `EventPlan.is_kept_in_the_world()` is asked only of a plan in the
## world that she has walked beyond the hysteresis from.
func stream_around(at: Vector2) -> void:
	var stream_out_beyond := _stream_radius + Tuning.EVENT_STREAM_HYSTERESIS
	for plan in _walk.plans():
		# One question to the plan: its distance, infinite for a spent or an unplaced one.
		var distance := plan.streaming_distance_from(at)
		if distance == INF:
			continue
		var entry: StreamedPlan = _state.get(plan)
		if entry == null:
			# Never streamed in and waiting for nothing.
			if distance <= _stream_radius:
				stream_in(plan)
			continue
		# A plan waiting to come again is brought back on its own clock, not by her distance.
		if entry.comes_in > 0.0:
			continue
		if entry.live == null:
			if distance <= _stream_radius:
				stream_in(plan)
		elif distance > stream_out_beyond and not plan.is_kept_in_the_world() \
				and not _could_be_watched(entry.live, at):
			stream_out(plan)

## The planned instance of the row `id` standing within a tile of `at`, put in the world now
## wherever she is and kept there for the rest of the day — never streamed out — or null when today
## plans none there. For a task that rides a planned place: day 8's burnt shell, whose mark she may
## read from the far side of the city, and which must not be streamed away from under its contact
## when she walks off again. The plan's own instance rather than a second one beside it, so its
## field is counted once.
func keep_live(id: String, at: Vector2) -> EventInstance:
	for plan in _walk.plans():
		if plan.row_id() != id or plan.is_spent() or not plan.is_placed() \
				or plan.placed_at().distance_to(at) >= Tuning.TILE_SIZE:
			continue
		if event_of(plan) == null:
			stream_in(plan)
		plan.keep_in_the_world()
		return event_of(plan)
	return null

func stream_in(plan: EventPlan) -> void:
	var first_time := not plan.has_been_in_the_world()
	# The scar is recorded the first time the event is put in the world and never again: walking
	# back past a burnt-out shell must not re-report the fire that made it.
	# The shared boom state, for a `checkpoint_gate` plan only (`null` on every other plan), is handed
	# to the event's one setup call.
	var live := _spawner.create(plan.row(), plan.placed_at(), plan.walks(), first_time, plan.faces(),
			plan.gate())
	_entry_of(plan).live = live
	plan.enter_the_world(live.standing())
	# **A set piece the day owed her walk is spent here rather than at dawn**, because here is where it
	# becomes something that happened — see `DawnOneShots`. The list is the one
	# `start_day` was handed, which in a played game is `world.run().attempt_spend().consumed_one_shots()`
	# and in a rig is the rig's own.
	if first_time and plan.is_a_set_piece_on_her_way() and not plan.row_id() in _consumed:
		_consumed.append(plan.row_id())
	# **An event that has already run picks up where it left off.** Without this a streamed-out
	# event is rebuilt from `plan.placed_at()`, which is the tile the *day* chose at dawn — so a dog
	# walker that has covered three hundred pixels teleports back to the top of its street every
	# time the player leaves its radius and returns, and at 32px/s against her 92 that is most
	# times. From outside it reads as an event that never goes anywhere.
	#
	# It restores rather than catching up on lost time, which is the whole design of streaming: the
	# day is planned across the whole city but an event **waits** for her. Ageing it in absentia
	# would put back exactly the thing streaming exists to fix — a twenty-second event that is over
	# before anybody could reach it.
	#
	# The plan's save carries the same restore for a row that waits for her
	# (`EventDef.waits_for_her()`): without its notice a pursuer streamed out mid-chase forgets
	# she was ever noticed and comes back `is_waiting()`, standing where the day planted it
	# rather than still coming for her.
	#
	# **A mast's own age is the broadcast clock, not the saved age.** Every mast reads the same
	# clock at every stream-in, first time or the fifth, so two masts met minutes apart still read the
	# same pulse phase — "all masts speak at once" is true because they are all telling the same
	# time, not because anything coordinates them frame to frame. See `_broadcast_clock` below.
	var save := plan.saved()
	if plan.mast_id() != "":
		save = save.at_age(_broadcast_clock)
	# A guard spent before the stream-out comes back as only his barrier, never as a guard again
	# (`EventBarrierPost.restore()`).
	live.restore(save)
	if plan.is_silenced():
		live.silence()
	world.take_in(live)

## **Whether `instance` is near enough to `at` for her to be watching it** — within
## `Tuning.OUT_OF_SIGHT`, the distance beyond which nothing can be seen. A plan is streamed out by
## how far she is from its *route* (`EventPlan.distance_from()`), but an instance that
## is leaving carries on past the route's end, and a car she follows out of its street is a long way
## from the route while she is a few paces behind it. Streaming that one out would delete it in
## front of her (*nothing vanishes while you are looking at it*, "Going away" in `docs/EVENTS.md`),
## so it stays until it is out of sight — where its own departure ends it anyway
## (`EventDeparture.leave()`).
func _could_be_watched(instance: EventInstance, at: Vector2) -> bool:
	return is_instance_valid(instance) \
			and instance.global_position.distance_to(at) <= Tuning.OUT_OF_SIGHT

func stream_out(plan: EventPlan) -> void:
	var entry: StreamedPlan = _state[plan]
	var live := entry.live
	plan.leave_the_world(live.save())
	# **A departure streamed out is over**, as one that finished is (`_mark_plan_spent()`): it is not
	# rebuilt to run an ended event again. Walking back, it would be rebuilt 900px or more from her
	# and finish out of view, so no car is seen coming back; what the spend keeps out is a person
	# streamed out mid-`leave_along` standing in day 12's closed park again. A guard walking away from
	# his barrier is the one that comes back, as only the barrier.
	if live.is_on_its_way_out() and not live.has_lost_its_guard():
		plan.spend()
		world.map().release_obstruction(plan.get_instance_id())
	world.map().release_obstruction(live.get_instance_id())
	world.let_go(live)
	live.take_out()
	entry.live = null

## **Takes today's plans of the rows `ids` standing inside `rect` out of the day**, placed or live —
## what a once-only happening that empties a place owes the day's own plan: day 11's market stalls
## at the block boarded up ahead of her, and day 12's playground once its park is taken
## (`ResistanceHappenings`). A plan not yet in the world is spent, so it never streams in, and its
## body's ground opens (the same release a spent plan gets); a live one is retired, the ordinary
## departure. Only ever a removal, the one direction the city's guarantees allow after dawn.
## Returns how many plans it took.
func take_away_within(rect: Rect2, ids: Array[String]) -> int:
	var taken := 0
	for plan in _walk.plans():
		if plan.is_spent() or not plan.is_placed() or not (plan.row_id() in ids) \
				or not rect.has_point(plan.placed_at()):
			continue
		taken += 1
		var live := event_of(plan)
		if live:
			_spawner.retire(live)
			continue
		plan.spend()
		world.map().release_obstruction(plan.get_instance_id())
	return taken

## **Takes today's plans standing inside `rect` that are not in the world out of the day**, every
## row but an ambient one (a playground, which has no figure to walk out): what day 12's park owes
## the day as its cordon closes it (`ParkCordon`), its people walked out and what has not come yet
## never coming. Each is spent and its body's ground opened, as `take_away_within()` does with a plan
## not yet in the world. Not in the world means out of her sight, since it would be streamed in
## otherwise. Only ever a removal. Returns how many plans it took.
func take_away_the_unseen_within(rect: Rect2) -> int:
	var taken := 0
	for plan in _walk.plans():
		if plan.is_spent() or plan.is_in_the_world() or not plan.is_placed() \
				or not rect.has_point(plan.placed_at()) \
				or plan.is_ambient():
			continue
		taken += 1
		plan.spend()
		world.map().release_obstruction(plan.get_instance_id())
	return taken

## Today's own foot for a mast id, or `Vector2.INF` if today carries no mast with that id — the
## point day 11's task (silence a mast by reaching its foot, the way she touches a chalk mark)
## records its scar at. Reads the ordinary broadcast's own
## plan, which always exists for a live mast's id; the curfew announcement shares the same foot.
func mast_foot(mast_id: String) -> Vector2:
	for plan in _walk.plans():
		if plan.mast_id() == mast_id and plan.is_a_mast():
			return plan.placed_at()
	return Vector2.INF

## Silences one mast by id, for the rest of the day — a mast still stands once silenced, with no
## arcs and no field, so this silences the plan (`EventPlan.silence()`) and its live instance
## (`EventInstance.silence()`) rather than finishing it: `EventInstance.end_now()` is for something
## that leaves, and a mast never does. Returns whether a mast with that id was found. Matches every plan whose `mast_id()` is this
## one — a mast's ordinary broadcast and, on `DawnMasts.CURFEW_ANNOUNCE_DAY`, its curfew announcement
## too, so silencing a mast mid-announcement silences both at once.
##
## **Run-long, it is a scar.** Day 11's task silences one mast for the rest of the run: the
## director calls this for today and records `DawnMasts.SILENCED_MAST` at the foot, which
## `DawnMasts` reads on every later day. The id is `MastSites.Site.id()`, stable
## across days, and the foot is its own.
func silence_mast(mast_id: String) -> bool:
	var found := false
	for plan in _walk.plans():
		if plan.mast_id() != mast_id:
			continue
		found = true
		plan.silence()
		var live := event_of(plan)
		if live:
			live.silence()
	return found

## Silences every mast, for the rest of the day. The masts stop because the power does: this is what
## the last night's blackout calls (`Blackout._go_dark()`), in the same frame the windows and the
## traffic lights go out, and it reaches a mast out of reach right now as well as a live one, since
## it marks the plan. Returns how many masts were silenced.
func silence_all_masts() -> int:
	var silenced := {}
	for plan in _walk.plans():
		if plan.mast_id() == "":
			continue
		silenced[plan.mast_id()] = true
		plan.silence()
		var live := event_of(plan)
		if live:
			live.silence()
	return silenced.size()

## How many sited events the day is carrying, live or waiting to be walked past. This is the
## number that answers "is thirteen events on day one a city or a gauntlet"; `EventManager.active_count()`
## answers "what is she standing in".
func planned_count() -> int:
	var total := 0
	for plan in _walk.plans():
		if plan.is_placed() and not plan.is_spent():
			total += 1
	return total

## **Takes every finished instance out of the world, and puts in what one leaves as it goes off**
## (`EventInstance.take_what_it_leaves()`, `EventSpawner.successor_of()`): the escape's explosion's
## crater, at its place, on the tick it bangs where it did not come in already with the plan a place
## set off (`set_off()`). Run every tick.
func retire_finished() -> void:
	var survivors: Array[EventInstance] = []
	var successors: Array[EventInstance] = []
	for instance in world.instances():
		var successor := _spawner.successor_of(instance)
		if successor:
			successors.append(successor)
		if instance.is_gone():
			_mark_plan_spent(instance)
			# The body is gone from the street, so the ground under it is open again. Its plan gives
			# back its own copy in `_mark_plan_spent()`; this is the instance's.
			world.map().release_obstruction(instance.get_instance_id())
			instance.take_out()
		else:
			survivors.append(instance)
	if successors.is_empty() and survivors.size() == world.instances().size():
		return
	survivors.append_array(successors)
	# Assigned in place rather than reassigned: `EventManager.instances()` hands this array out by reference,
	# and the danger-edge indicator holds it across frames.
	world.keep_only(survivors)

## An event that has finished has finished for the day: its plan is spent, so walking back past
## the place it happened does not start it over. This is the half of streaming that a rebuilt
## instance would otherwise get wrong — an event is allowed to come and go while it is running,
## and is not allowed to come back once it is over.
func _mark_plan_spent(instance: EventInstance) -> void:
	for plan: EventPlan in _state:
		var entry: StreamedPlan = _state[plan]
		if entry.live == instance:
			if plan.repeats():
				_done_for_now(plan)
				return
			entry.live = null
			plan.leave_the_world(plan.saved())
			plan.spend()
			# A spent plan is a body that has left, so its ground opens again — the plan's own half
			# of the release. See "the bodies in the street".
			world.map().release_obstruction(plan.get_instance_id())
			return

# ------------------------------------------------------------- what comes again ---
# A plan that repeats (`EventPlan.repeats()`) is not spent when its instance is done:
# it waits and comes again, a fresh instance every time, so each comes, warns and runs exactly as
# the first did. The building's vents blow on their own periods, the masked man comes up the shaft
# again once the last has run out of the top, and the explosions outside come on theirs.

## Counts every repeating plan's clock down and brings back each whose time has come: a vent its
## period after its last blow began (`comes_again_every()`), the masked man his wait after the last one
## started leaving (`comes_again_after()`), and one sited at her (`comes_where_she_stands()`) where
## she stands now. A row
## from outside the walls (`FieldSpec.through_walls()`) is shown by the world as it comes
## (`WorldContext.bang_outside()`), whether or not there is anybody for its charge to stand on.
func bring_back_what_repeats(delta: float) -> void:
	for plan in _repeating:
		if plan.is_spent():
			continue
		var entry := _entry_of(plan)
		# Its run is over when it is off the end of it, not when the instance is finally freed: a
		# mobile row that has run out of route spends a leaving phase walking out of sight, so a wait
		# counted from its deletion would be the stated one plus however long that took.
		if entry.live != null and (entry.live.is_on_its_way_out() or entry.live.is_gone()):
			_done_for_now(plan)
		if entry.waits_from_now:
			entry.waits_from_now = false
			continue
		# A plan a place sets off is set off by her reaching its place (`SetOffWatch`), not by its
		# clock: the clock only says when it may come (`may_set_off()`).
		if plan.is_set_off_by_a_place():
			entry.comes_in = maxf(entry.comes_in - delta, 0.0)
			continue
		entry.comes_in -= delta
		if entry.live != null or entry.comes_in > 0.0:
			continue
		entry.comes_in += plan.comes_again_every()
		if plan.comes_where_she_stands():
			if not world.has_player():
				# Nobody for its charge to stand on, and the bang still goes off.
				_spawner.show_the_bang(plan.row())
				continue
			plan.came_at(world.player().global_position)
		stream_in(plan)

## **Whether a plan a place sets off may come now** (`EventPlan.is_set_off_by_a_place()`,
## `SetOffWatch`): placed and not spent, its instance not in the world, and, for one that comes again,
## its wait since the last one run.
func may_set_off(plan: EventPlan) -> bool:
	if plan.is_spent() or not plan.is_placed():
		return false
	var entry: StreamedPlan = _state.get(plan)
	return entry == null or (entry.live == null and entry.comes_in <= 0.0)

## **Brings a plan a place set off into the world**, where its warning pointed, once the warning has
## run (`SetOffWatch`): created where it starts, told it came under a warning, its telegraph spent
## (`EventSpawner.age_when_warned()`), so from its first tick it is what it is after it. It stays
## until it is done (`EventPlan.streaming_distance_from()`). **What it leaves where it goes off
## comes with it, on this tick** (the escape city's explosion's crater): its place was cleared out
## of her sight with that included (`EventFootprints.footprint_of()`) against the view of this
## tick, which by the next she may have walked on toward. Answers whether it came.
func set_off(plan: EventPlan) -> bool:
	if not may_set_off(plan):
		return false
	var live := _spawner.create(plan.row(), plan.placed_at(), plan.walks(),
			not plan.has_been_in_the_world(), plan.faces(), plan.gate())
	live.arrive_from_its_warning()
	live.restore(EventSave.aged(EventSpawner.age_when_warned(plan.row())))
	_entry_of(plan).live = live
	plan.enter_the_world(live.standing())
	world.take_in(live)
	var left := _spawner.successor_of(live)
	if left:
		world.take_in(left)
	return true

## Finds the plans of the walk just started that come again (`_repeating`) and starts each one's clock
## from the seconds its first instance comes in (`EventPlan.first_comes_in()`). A day's own plan has
## none; the building's vents, its masked man and its explosions outside are.
func find_what_repeats() -> void:
	_repeating.clear()
	for plan in _walk.plans():
		if plan.repeats():
			_repeating.append(plan)
			_entry_of(plan).comes_in = plan.first_comes_in()

## A repeating plan whose instance is done, made ready to come again: the instance is let go — a
## leaving one walks on out of sight on its own, retired when it is finished — the plan's own body
## is given back, it will start over from where every instance of it starts, and a wait on its last
## one (`comes_again_after()`) begins now.
func _done_for_now(plan: EventPlan) -> void:
	var entry := _entry_of(plan)
	entry.live = null
	world.map().release_obstruction(plan.get_instance_id())
	plan.leave_the_world(EventSave.aged(plan.arrives_aged()))
	if plan.comes_again_after() > 0.0:
		entry.comes_in = maxf(entry.comes_in, plan.comes_again_after())
		entry.waits_from_now = true

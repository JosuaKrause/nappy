class_name CheckpointController
extends RefCounted
## **The district doors as she meets them**: a hut's or a post's hold, the release on the far side
## and its latch, a walk under a raised boom, the crossing's warning and the one guard it sets on
## her. Everything about a door that is not one door body's own: which body takes her in, which
## hut's guard warns her, when a crossing counts (`door_crossed`). Each body's own clock and drawing
## stay on its `EventInstance`.
##
## **Handed what it works over, never fetching it**: the live instances it reads the door bodies
## from (the event manager's own list, shared), the map its run-log lines name tiles on, where it
## writes them, the player it holds and lets out, how a guard is put in the world (`_spawn`), and
## the event sink it tells the observers through (`_bus`).
## Its own door rules, as the player gave them, are in `docs/EVENTS.md`, "Checkpoints".

## The live instances it reads the door bodies from: the event manager's own list, shared.
var _instances: Array[EventInstance]
## `func(def: EventDef, at: Vector2) -> EventInstance`: puts a guard in the world.
var _spawn: Callable
## Where it tells the observers what a door did — a hold begun (`player_detained`), a guard's raised
## hand (`pursuit_warned`): `EventBus` in the game, a fake in a test.
var _bus: Node
## The map the run-log lines name tiles on.
var map: WorldMap = WorldMap.open_ground()
## Where its account goes in the run log; silent until handed one.
var trace := RunTrace.new()
## The player it holds and lets out, or null for none in the world.
var player: Stroller = null

func _init(instances: Array[EventInstance], spawn: Callable, bus: Node) -> void:
	_instances = instances
	_spawn = spawn
	_bus = bus

## She has crossed a district door: let out on its far side after the inspection
## (`release_finished_holds()`, `inspected` true), or walked through its line under a
## raised boom (`watch_the_door_lines()`, `inspected` false), sent once that crossing's warning has
## run with her still across, the frame the door's own guard is set on her
## (`_run_the_crossing_warning()`): a crossing she takes back is never announced, and one made while
## another door's crossing is warning her is announced with that one or not at all
## (`_held_crossings`). `at` is the body of the door that saw it and `axis` the street's own axis,
## which every body of one door shares, so a listener can tell which door it was. Day 9's task is
## completed on it either way, and sends its trap only after an inspection
## (`ResistanceDirector._on_door_crossed()`).
signal door_crossed(at: Vector2, axis: Vector2, inspected: bool)

## Which side of a redetaining instance's own crossing she was on when its conversation started —
## `instance -> signf(...)`, the sign of her offset from the body against `facing_now()`. Present
## only while that instance's own detention is running; `release_finished_holds()` reads
## and clears it the frame the conversation ends. See `EventDef.redetains`.
var _door_entry_side: Dictionary = {}

## Where she stood the last time `watch_the_door_lines()` looked, and how many outright moves
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
## **A crossing still warning her** (`watch_the_door_lines()`): the door body whose line she walked
## across, the hut or post whose guard raises his hand at her, which side of the line she crossed
## to, and for how long she has stood across it. `null` with no crossing pending.
var _crossing: EventInstance = null
var _crossing_hut: EventInstance = null
var _crossed_to := 0.0
var _crossing_for := 0.0
## The crossing's warning (`Warning`), read against `_crossing_for`: running while `_crossing` is
## warning her, `Tuning.CROSSING_WARNING` long.
var _crossing_warning := Warning.new()
## **Crossings held behind the one still warning her**: `[position, facing]` of each other door's
## line she walked across while `_crossing` was warning her, which starts no warning of its own.
## Each is announced (`door_crossed`) the frame that warning runs out and its guard is set on
## her, and dropped if it is called off or she walks back across that door's line first. **The
## rule, once: a walked crossing counts only if she is still across that door's line when a
## guard is set on her for it** (two doors meeting at a corner).
var _held_crossings: Array = []

## One `ReleaseLatch` per redetaining instance she has been let out of — `instance -> latch`. Armed
## the frame the release teleports her, with that instance's own trigger circle, and holding until
## she is measured outside it: the far side of a door is inside the door's own reach, so without
## this she is taken in again the instant she is put down. See `release_finished_holds()`
## and `ReleaseLatch`, which the escape scene's own doors reuse.
var _door_release_latches: Dictionary = {}

## Forgets the day's doors: the holds, the latches, the crossing and the guard after her.
func clear() -> void:
	_door_entry_side.clear()
	_door_release_latches.clear()
	_last_seen_at = Vector2.INF
	_walked_under = 0
	_guard_after_her = null
	_crossing = null
	_crossing_hut = null
	_crossing_warning.stop()
	_held_crossings.clear()

## The guard a walked crossing last set on her, while he is in the world, or null.
func guard_after_her() -> EventInstance:
	return _guard_after_her if is_instance_valid(_guard_after_her) else null

## The door body whose crossing is warning her right now, or null.
func crossing_door() -> EventInstance:
	return _crossing if is_instance_valid(_crossing) else null

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
## not a third: it never inspects her (`EventDef.SolidWhen.WHILE_LOWERED`).
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
func check_detentions() -> void:
	var body := player
	if not body:
		return
	release_finished_holds(body)
	_update_door_release_latches(body)
	var nearest := hold_that_would_begin(body.global_position)
	if not nearest:
		return
	nearest.start_chat()
	if nearest.def.redetains:
		# **She goes in, out of sight, and the camera goes to the door** — on the same physics frame
		# the hold starts, so no drawn frame catches her outside. Coming out is the release's
		# (`release_finished_holds()`), on the frame she is moved.
		body.hide_for_inspection()
		body.focus_camera_on(nearest.global_position)
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
	# `VisitCounter`'s own "chat"/"checkpoint" — `nearest.def.id` names which. See
	# docs/TELEMETRY.md, "The page counts visits".
	_bus.player_detained.emit(nearest.def.id)
	trace.note("chat", "%s at %s, %.1fs, baby %s, meter %s" % [
		nearest.def.id, RunTrace.tile(map.world_to_tile(nearest.global_position)),
		nearest.def.detain_seconds,
		"awake" if nearest.baby_awake else "asleep",
		("+%.0f" % Tuning.CHAT_EXCITEMENT) if nearest.baby_awake else "+0 (asleep)"])

## The instance whose hold would begin on this frame with her at `at`, or null: the test
## `check_detentions()` makes, here so that `EncounterWatch` asks the very same question (a pure
## read: it starts nothing). Nothing when a hold is already running, and otherwise the nearest of
## the instances that may take her in.
func hold_that_would_begin(at: Vector2) -> EventInstance:
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
			return null
	var nearest: EventInstance = null
	var nearest_range := INF
	for instance in _instances:
		if instance.def.detain_seconds <= 0.0 or instance.is_finished or instance.is_leaving:
			continue
		if instance.is_chatting():
			continue
		if not instance.def.redetains and instance.has_chatted():
			continue
		# Every test here is a pure filter, so their order decides nothing but the cost: the range
		# comes before the boom's, which walks every live instance, since a door she is not inside
		# is almost every door.
		var range_to := instance.global_position.distance_to(at)
		if range_to > instance.def.detain_distance() or range_to >= nearest_range:
			continue
		var latch: ReleaseLatch = _door_release_latches.get(instance)
		if latch and latch.holds():
			continue
		if instance.def.redetains and _on_a_booms_carriageway(instance, at):
			continue
		nearest = instance
		nearest_range = range_to
	return nearest

## Whether `at` is on the carriageway spanned by the boom of the door `door_body` stands in — a
## live boom instance (`EventDef.SolidWhen.WHILE_LOWERED`) on the same cross-street line (its own `facing_now()` axis),
## with `at` no further across that line from the boom's centre than the boom's own body reaches.
## The boom is laid over exactly the carriageway, so its reach is the carriageway's half-width and
## this is "she is in the road at this door" stated over the door's own geometry rather than over
## the map's tiles — the same datum the huts and the boom were placed from.
##
## `false` for an alley door, which has no boom, so a post's trigger is untouched.
func _on_a_booms_carriageway(door_body: EventInstance, at: Vector2) -> bool:
	for instance in _instances:
		if instance.def.solid_when != EventDef.SolidWhen.WHILE_LOWERED:
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
func release_finished_holds(body: Stroller) -> void:
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
		door_crossed.emit(instance.global_position, axis, true)
		trace.note("checkpoint", "%s at %s, %.1fs, released on the %s side" % [
			instance.def.id, RunTrace.tile(map.world_to_tile(instance.global_position)),
			instance.def.detain_seconds, _compass_of(axis, released_along)])

## Arms a `ReleaseLatch` for **every** redetaining body whose own trigger `at` is inside, not only
## the one that just let her out.
##
## Doors stand close enough together that their reaches overlap — two doors meeting at a corner —
## so the ground one hut lets her out onto can be inside another door body's reach: latching only
## the releasing body means being let out of one and taken straight into the next, which is one
## crossing charged twice and, to the player, the door refusing to let go. **One crossing is one
## toll** — *"it works in both directions with the same cost each time"* — so what she has just
## come out of is the whole door, and every part of it waits until she has walked out of its own
## circle.
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
## and its door is a toll again. Run once a frame from `check_detentions()`, before anything asks
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
# her**, one, from the door's hut across the road from her, once the crossing's warning has run with
# her still across (`_start_the_crossing_warning()`); a catch ends the day, since *"not going
# through the checkpoint is a clear unlawful thing here"*. See `EventCatalogue._door_guard()`.

## How many times today she has walked across a door's line rather than being let through it —
## the count `tests/test_route_rig.gd` holds a rig run to zero on.
func walks_under_a_boom() -> int:
	return _walked_under

## Once a frame: whether she has crossed a door body's own cross-street line since the last look,
## and no `Stroller.teleport_to()` (nor `reset_at()`) moved her in between, which starts a
## crossing's warning, and one frame of the crossing already warning her
## (`_run_the_crossing_warning()`). Run before
## `check_detentions()`, so a release that teleports her this frame is seen by the next look as
## the outright move it is.
##
## **A door's line is its bodies' line, one body's width at a time.** Each door body — a hut, a
## post, the boom — stands on the crossing's own cross-street line (the one an inspection's release
## is reflected through, `facing_now()`'s axis), and the crossing counts against the body whose own
## reach across that line it happened inside, so the three bodies of a street door cover the street
## kerb to kerb between them and a line through a door never extends past the door.
func watch_the_door_lines(delta := 0.0) -> void:
	var body := player
	if not body:
		return
	var here := body.global_position
	var was := _last_seen_at
	var put_down := body.outright_moves != _last_outright_moves
	_last_seen_at = here
	_last_outright_moves = body.outright_moves
	if was == Vector2.INF or put_down:
		return
	var called_off := _run_the_crossing_warning(here, delta)
	var crossed: EventInstance = null
	for instance in _instances:
		if not instance.def.redetains and instance.def.solid_when != EventDef.SolidWhen.WHILE_LOWERED:
			continue
		if where_she_crossed(instance.global_position, instance.facing_now(),
				instance.def.obstructs_radius, was, here) != Vector2.INF:
			crossed = instance
			break
	if not crossed:
		return
	_walked_under += 1
	trace.note("checkpoint", "%s at %s walked through, heading %s — not inspected%s" % [
		crossed.def.id, RunTrace.tile(map.world_to_tile(crossed.global_position)),
		heading_name(here - was),
		(", the boom up" if crossed.is_raised() else ", the boom down")
		if crossed.def.solid_when == EventDef.SolidWhen.WHILE_LOWERED else ""])
	# Back across the line of the crossing still warning her: that crossing is called off, and the
	# walk back starts no warning of its own.
	if called_off:
		return
	if _crossing != null and _crossing_is_on(crossed):
		_call_off_the_crossing("she went back")
		return
	# **A walked crossing counts once it stands** (`door_crossed`, day 9's task): when its
	# warning has run with her still across (`_run_the_crossing_warning()`), so a crossing she
	# takes back counts for nothing. **One made while another door's crossing is warning her is
	# held with it** (`_held_crossings`): counted when that warning runs out and its guard
	# comes, dropped if it is called off or she walks back across that door first. One that
	# starts no warning of its own otherwise — a guard already after her, a door with no hut
	# today — has no clock to wait for and counts as it happens: the guard after her is its price.
	if _crossing != null:
		# Back across a door whose crossing is held: taken back, so it is dropped, not held twice.
		var held := _held_crossing_on(crossed)
		if held >= 0:
			_held_crossings.remove_at(held)
		else:
			_held_crossings.append([crossed.global_position, crossed.facing_now()])
		return
	if not _start_the_crossing_warning(crossed, here):
		door_crossed.emit(crossed.global_position, crossed.facing_now(), false)

## **A crossing warns first, on a clock** *(inbox #788 in minty-lemur, the player: "The actual
## crossing will start the timer and if the player goes back no charge happens but if they stay
## crossed the charge will start. Warning starts when the player is crossing")*: the guard at
## the hut across the road from her (or an alley door's post) raises his hand at her
## (`EventInstance.guard_warns_her`, drawn by `warn_at_the_doors()`) from the frame she crosses.
## Back across the line before `Tuning.CROSSING_WARNING` has run, the crossing is called off and
## nothing comes; still across it once it has run, a guard is set on her
## (`_set_a_guard_on_her()`). One crossing at a time, and none while a guard is already after
## her. Answers whether a warning started.
func _start_the_crossing_warning(crossed: EventInstance, here: Vector2) -> bool:
	if _crossing != null or (is_instance_valid(_guard_after_her)
			and not _guard_after_her.is_finished and not _guard_after_her.is_leaving):
		return false
	var hut := _hut_on_the_line_nearest(crossed, here, true)
	if not hut:
		return false
	_crossing = crossed
	_crossing_hut = hut
	_crossed_to = signf((here - crossed.global_position).dot(crossed.facing_now()))
	_crossing_for = 0.0
	_crossing_warning.start(_crossing_for, Tuning.CROSSING_WARNING)
	trace.note("checkpoint", "%s at %s warns her: back across within %.1fs or a guard comes" % [
		hut.def.id, RunTrace.tile(map.world_to_tile(hut.global_position)),
		Tuning.CROSSING_WARNING])
	return true

## The index in `_held_crossings` of the held crossing on `door`'s line (the same test as
## `_crossing_is_on()`), or -1.
func _held_crossing_on(door: EventInstance) -> int:
	var axis := door.facing_now()
	for i in _held_crossings.size():
		var at: Vector2 = _held_crossings[i][0]
		var facing: Vector2 = _held_crossings[i][1]
		if absf(facing.dot(axis)) >= 0.99 and absf((door.global_position - at).dot(axis)) <= 1.0 \
				and door.global_position.distance_to(at) <= Tuning.STREET_WIDTH * Tuning.TILE_SIZE:
			return i
	return -1

## Whether `door` stands on the line of the crossing still warning her: the same cross-street line,
## within a street's width of the body she crossed.
func _crossing_is_on(door: EventInstance) -> bool:
	if not is_instance_valid(_crossing):
		return false
	var axis := _crossing.facing_now()
	return absf(door.facing_now().dot(axis)) >= 0.99 \
			and absf((door.global_position - _crossing.global_position).dot(axis)) <= 1.0 \
			and door.global_position.distance_to(_crossing.global_position) \
					<= Tuning.STREET_WIDTH * Tuning.TILE_SIZE

## One frame of the crossing still warning her: called off once she is back on the side she came
## from or held at a hut (gone through the door the lawful way), and its guard set on her once
## `Tuning.CROSSING_WARNING` has run with her still across, which is also when the crossing counts
## as crossing the door (`door_crossed`, day 9's task). Answers whether it was called off this
## frame, so the walk back that called it off starts no warning of its own.
func _run_the_crossing_warning(here: Vector2, delta: float) -> bool:
	if _crossing == null:
		return false
	if not is_instance_valid(_crossing) or not is_instance_valid(_crossing_hut):
		_crossing = null
		_crossing_hut = null
		_crossing_warning.stop()
		_held_crossings.clear()
		return false
	if door_holding_her_at(here) != null:
		_call_off_the_crossing("she is held at a door")
		return true
	if signf((here - _crossing.global_position).dot(_crossing.facing_now())) != _crossed_to:
		_call_off_the_crossing("she went back")
		return true
	_crossing_for += delta
	if not _crossing_warning.has_run(_crossing_for):
		return false
	var crossed := _crossing
	var hut := _crossing_hut
	_crossing = null
	_crossing_hut = null
	_crossing_warning.stop()
	_set_a_guard_on_her(hut, crossed, here)
	door_crossed.emit(crossed.global_position, crossed.facing_now(), false)
	for held: Array in _held_crossings:
		door_crossed.emit(held[0] as Vector2, held[1] as Vector2, false)
	_held_crossings.clear()
	return false

func _call_off_the_crossing(why: String) -> void:
	trace.note("checkpoint", "the crossing's warning is called off after %.1fs: %s"
			% [_crossing_for, why])
	_crossing = null
	_crossing_hut = null
	_crossing_warning.stop()
	# The crossings held behind it go with it: nobody comes, so none of them counts.
	_held_crossings.clear()

## One `door_guard` after her, stepping out of the wall of `hut` — the hut whose guard raised his
## hand at her when she crossed (`_crossing_hut`, the farther of the huts on the crossed body's own
## line from where she crossed) — on the side of the line she has crossed to. **The man who warned
## is the man who comes**: in the warning's 2.0s at a walk she can cross most of the street, which
## can make the other hut the farther one by then, so the hut is not asked for again.
## *(2026-09-24: "Or guards that pursue her should spawn at the huts" · "One guard is enough".)*
## The guards drawn at the huts stay at their posts; this is another man out of the door.
##
## **One at a time.** A second walk under the same boom while he is still after her sets nobody else
## on her; once he has caught her, given up or run out his chase, the next walk under sets the next
## one. A crossed alley post is its own door and its own guard, so he steps out of the post.
##
## **He charges at once** (`PursuitSpec.Start.CHARGES_AT_ONCE`): the guard at that hut raised
## his hand from her crossing for `Tuning.CROSSING_WARNING` (`_start_the_crossing_warning()`,
## `warn_at_the_doors()`), which was his warning, and he is set on her only once it has run with
## her still across. **The hut across the road, not the nearer one**: from the nearer hut's wall
## (about 57px from her as she crosses the near lane, 16px if she crosses beside it) his charge
## comes with almost no ground to answer it in. An alley's door has only its post, so its guard
## steps out of it. *The far hut is chosen while building, open to overturn.*
func _set_a_guard_on_her(hut: EventInstance, crossed: EventInstance, here: Vector2) -> void:
	if not is_instance_valid(hut) or is_instance_valid(_guard_after_her) \
			and not _guard_after_her.is_finished and not _guard_after_her.is_leaving:
		return
	var axis := crossed.facing_now()
	var side := -1.0 if (here - hut.global_position).dot(axis) < 0.0 else 1.0
	var at := hut.global_position + axis * side * hut.def.obstructs_radius
	_guard_after_her = _spawn.call(EventCatalogue.by_id("door_guard"), at)

## The hut or post on `door`'s own cross-street line nearest `here` — or, with `farthest`, the
## farthest — or null. The farthest is the one whose guard warns her and the one a guard steps out
## of (`_set_a_guard_on_her()`).
func _hut_on_the_line_nearest(door: EventInstance, here: Vector2, farthest := false) -> EventInstance:
	var axis := door.facing_now()
	var hut: EventInstance = null
	var nearest := INF
	for instance in _instances:
		if not instance.def.redetains or instance.is_finished or instance.is_leaving:
			continue
		if absf(instance.facing_now().dot(axis)) < 0.99 \
				or absf((instance.global_position - door.global_position).dot(axis)) > 1.0:
			continue
		# This door's own huts only: another door further along the same line is another street's.
		if instance.global_position.distance_to(door.global_position) \
				> Tuning.STREET_WIDTH * Tuning.TILE_SIZE:
			continue
		var range_to := instance.global_position.distance_to(here)
		if farthest:
			range_to = -range_to
		if range_to < nearest:
			nearest = range_to
			hut = instance
	return hut

## **The checkpoint's warning**: while a crossing is warning her (`_start_the_crossing_warning()`),
## the guard at the hut on its line across the road from her — the one who would come for her —
## raises his hand, or an alley's post's own guard, its post being its whole door, and the page
## counts each time he does (`EventBus.pursuit_warned`, `door-guard-warned`;
## `EventInstance.guard_warns_her`). Every other guard stands as he always does. A drawing only: it
## changes nothing a hut does.
func warn_at_the_doors() -> void:
	var warned := {}
	if is_instance_valid(_crossing_hut):
		warned[_crossing_hut.get_instance_id()] = true
	for instance in _instances:
		if instance.def.redetains:
			var warns := warned.has(instance.get_instance_id())
			# `VisitCounter`'s own "door-guard-warned", each time a guard raises his hand: the
			# warning level of the checkpoint guard, who is not in the world until she goes under.
			if warns and not instance.guard_warns_her:
				_bus.pursuit_warned.emit("door_guard")
			instance.guard_warns_her = warns

## *(2026-09-24, the player, answering whether a hold should end the chase: "we can try b. if she
## voluntarily goes to a hut the whole pursuit has been accomplished".)* Called from
## `check_detentions()` the moment any `redetains` row — a checkpoint hut or an alley post, the one
## `_guard_after_her` stepped out of included — starts a hold: he gives up exactly as
## `EventPursuit` has him give up when she outruns it, same state, same drawing, same
## telemetry, through `EventInstance.give_up_the_chase()` — the smallest reading of "the whole
## pursuit has been accomplished" once she is inside a hut of her own accord. The
## roadblock's hunting guard and the escape's masked pursuer are never `_guard_after_her`, so a hold
## never reaches them — and neither is the robber a done task sends after her
## (`ResistanceDirector._set_the_trap_on_her()`), on day 9 the one sent the moment the inspection
## lets her through: a hut is not a hiding place from him, and stepping back into one with him after
## her holds her where he can catch her. *(2026-10-04, the player: "you shouldn't try to cheat it by
## going back in the hut -- that should be fatal by the robber".)*
func _end_the_guard_for_a_hold() -> void:
	if is_instance_valid(_guard_after_her) \
			and not _guard_after_her.is_finished and not _guard_after_her.is_leaving:
		_guard_after_her.give_up_the_chase()

## Where the step from `was` to `here` crosses the line through `at` across `axis` — the door
## body's own cross-street line — if it crosses it within `reach` of `at` along the line, or
## `Vector2.INF` if it does not. Which side she is on is read the way `check_detentions()` reads
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
static func heading_name(heading: Vector2) -> String:
	if absf(heading.x) > absf(heading.y):
		return _compass_of(Vector2.RIGHT, heading.x)
	return _compass_of(Vector2.DOWN, heading.y)

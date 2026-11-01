class_name WalkerStrategy
extends LaneStrategy
## How a person in the crowd moves on the lanes: the half of a `LaneMover` that only a walker has.
##
## A walker travels the footway, a lane either side of the carriageway or the whole width of a
## precinct, and answers everything it meets in a stride: it steps round a body on its own lane,
## gets out of her way, rounds a corner where it stands, turns round in front of a wall, and queues
## at a checkpoint hut the way she is held there. None of that needs warning or a path, so a walker
## acts on a barrier only when it is the next tile and reads the bodies themselves rather than a
## street's hold. The car's half is `CarStrategy`; what both share is the mover, `LaneMover`.

## What this walker does when the street it is on crosses a region wall at a door — drawn once, in
## `draw_the_door_answer()`, at the moment it is placed. *(Playtest 58: "Held at the hut like her";
## "a small fraction can do that"; "others can turn back".)*
##
## **Drawn at placement rather than at the door**, so a walker's answer cannot change halfway down
## the street it is walking: a person who turns back at the sight of a checkpoint decided that
## before they got there, and one who is rolled again every frame would dither on the pavement.
## Cars have no answer here — a car queues for the boom, which is `Crowd._stop_for_gates()`.
enum DoorAnswer { HELD, PASSES, TURNS_BACK }

## Where a held walker is in its crossing of a door — the player's own four states, *("four states
## walking -> waiting -> inspection -> emerging on the other side (with cooldown to not go back
## again) -> walking")*. Everything but `WALKING` belongs to one particular hut, the one in
## `_door_hold`.
##
## - **WALKING** — on its way, or not crossing a door at all.
## - **WAITING** — stopped on its own lane beside the hut, in its last facing, the way a stopped
##   walker already stands. It shuffles forward as the line in front of it goes in.
## - **INSPECTION** — inside the hut and not drawn, for `Tuning.WALKER_DOOR_HOLD_SECONDS`.
## - **EMERGING** — back on the far side of the door and walking again, but carrying the cooldown
##   that keeps the same hut from taking it a second time until it has left the hut's area.
enum DoorState { WALKING, WAITING, INSPECTION, EMERGING }

## This walker's own answer at a door, from `DoorAnswer` — see that enum for why it is drawn once
## per placement.
var _door_answer := DoorAnswer.HELD

## Where this walker is in a crossing, from `DoorState`, and the hut it is doing it at. `_door_hold`
## outlives the wait itself: it is what the cooldown is measured from while the walker is
## `EMERGING`, and it is only let go once the walker is clear of the hut's own area.
var _door_state := DoorState.WALKING
var _door_hold: WalkerDoorHold = null
## Seconds left of the inspection inside the hut.
var _inspection_left := 0.0

## The hut this walker has decided against because the line at it was already as long as a line is
## allowed to get, and that door's own segment key — which is what `door_is_shut()` reads, so a
## refusal turns this walker away at the last junction exactly the way a wall does. Both are
## dropped again once that hut is out of sight, since a later approach is a later decision.
## `NO_DOOR` is "no refusal", and is a key no segment can have.
const NO_DOOR := Vector3i(-9999, -9999, -9999)
var _refused_hut: WalkerDoorHold = null
var _refused_door_key := NO_DOOR

## The answer of `_precinct_way_is_shut_cached()` and what it was asked for; dropped when a new
## look-ahead scan starts, since the bodies on the map can change under a walker that stands still.
var _way_shut_known := false
var _way_shut := false
var _way_shut_at := Vector2i.ZERO
var _way_shut_vertical := false
var _way_shut_direction := 0.0

## How long is left on a sidestep taken after being walked into (`step_aside()`); the sidestep
## itself is the mover's `_detour`, the steering offset both kinds share.
var _detour_left := 0.0
## True while `_detour` is a walker going round a solid body rather than a walker getting out of
## her way. **Held rather than timed**: a bump is over in a couple of seconds whatever else happens,
## and a body is over when the walker is past it, which no number of seconds knows. See
## `_step_around_a_body()`.
var _body_detour_held := false
## And the same for somebody *crossing* her path rather than sharing it, who has no sidestep to
## make: whether it is hurrying across or waiting, and how long is left on it.
var _yield_hurry := false
var _yield_left := 0.0

## **What today puts down in a walker's way**, the map's blocked record as a walker of the crowd
## reads it: closures, soft seals and bodies (`Mover.TODAY`). The ground itself is the lane's own
## question (`_never_a_street_here()`), and a precinct's posts are not in it, since the crowd has no
## body and walks between them (`CityMap.post_tiles()`).
static var _walker_today := Mover.of(Mover.TODAY)
## The layers `cannot_go_on()` asks one at a time, each before the next question it stands for.
static var _soft_sealed_today := Mover.of(Mover.SOFT_SEALS)
static var _bodies_today := Mover.of(Mover.BODIES)

func _init(mover: LaneMover) -> void:
	super(mover)
	acts_within = 1
	today = _walker_today

# -------------------------------------------------- the mover's questions ---

func ground_shape() -> GroundShape:
	return GroundShape.point(7.0)

func lane_offsets_at(along_tile: int) -> Array[int]:
	return CrowdLanes.walkable_offsets(_mover._map, _mover._vertical, _mover._corridor, along_tile)

func speed_range() -> Vector2:
	return Tuning.PEDESTRIAN_SPEED

## A walker is never placed in a carriageway. It matters because a precinct's lanes run the whole
## width of the corridor, and a lane is chosen before the along position that decides whether this
## stretch is a precinct at all — so the re-roll is what keeps the two in step rather than an
## ordering assumption that would be wrong once in ten.
func may_be_placed_on(tile: Vector2i) -> bool:
	return _mover._map.tile_at(tile) != GameEnums.TileType.ROAD

## **The door's carve-out is per walker**, which is the one thing about a held segment that is not a
## fact about the day: a walker whose own answer is `TURNS_BACK` gets no carve-out at all, so a door
## reads to it exactly like a wall and it turns away at the last junction with the machinery that
## already does that — the one thing a walker still turns early for, because turning back at a door
## is a decision about the door rather than about the ground. And a walker that has decided against
## one particular door's queue (`_refuse_the_door`) is the same sentence for one segment rather than
## for all of them.
func door_is_shut(key: Vector3i) -> bool:
	return _door_answer == DoorAnswer.TURNS_BACK or key == _refused_door_key

## The clocks on a sidestep and a yield run down. A bump's own sidestep runs out on its clock; one
## taken to get round a body does not, since what ends it is being past the body.
## `_stop_going_round_a_body()` is what ends that one.
##
## **Inside a checkpoint hut** there is no lane to steer to, no junction to turn at and no way ahead
## to look down — but the crowd's field still moves with the player, so a walker held at a door
## she has walked away from still has to be recycled like anybody else. That is the whole of what
## happens to it this frame. See `DoorState`.
func begin_frame(delta: float) -> bool:
	if _detour_left > 0.0:
		_detour_left = maxf(0.0, _detour_left - delta)
		if _detour_left <= 0.0 and not _body_detour_held:
			_mover._detour = 0.0
	_yield_left = maxf(0.0, _yield_left - delta)
	if not _is_inside_a_hut():
		return false
	if _mover._has_left_the_field():
		_mover._recycle()
	return true

## The two factors are asked only when they can be anything but one, since every walker's frame and
## every reading of its velocity pays for this: a walker not yielding and not at a door walks at
## its own pace.
func paced(speed: float) -> float:
	return speed * (1.0 if _yield_left <= 0.0 else _yield_factor()) \
			* (1.0 if _door_state == DoorState.WALKING else _hold_factor())

## **A walker held at a checkpoint is travelling at nothing**, which is what makes the stopped pose
## come out right for free: the stride and the facing both read `velocity()`, so a walker standing
## in a door's line holds its last facing and frame a the way every stopped walker in the crowd
## already does, and its own field stops being stretched forward by `field_scale()`.
func paced_velocity(moving: Vector2) -> Vector2:
	return moving * (1.0 if _yield_left <= 0.0 else _yield_factor()) \
			* (1.0 if _door_state == DoorState.WALKING else _hold_factor())

func after_the_step(delta: float) -> void:
	_consider_turning()
	_mover.advance_the_picture(delta)

## Going round a body is the same kind of question as the look-ahead and is answered off the same
## cache: which tile, which axis, which way. Asked before the look-ahead's own walk, because that one
## returns the moment it finds something.
func on_new_scan(here: Vector2i) -> void:
	_way_shut_known = false
	_step_around_a_body(here)

func stride_length() -> float:
	return PI / WalkerLook.GAIT_RATE

## **A walker splits its axis evenly**, deliberately — a pavement has no hierarchy for it to follow
## (a precinct is a *place*, not an axis), and the alternating roll from `Crowd._populate` is what
## stops a morning's crowd landing lopsided by chance. A car picks its axis by weight
## (`CarStrategy.choose_lane()`).
func choose_lane(roll: float) -> void:
	_mover._vertical = roll < 0.5
	_mover._corridor = CrowdLanes.pick_corridor_in_range(_mover._rng, _mover._map,
			_mover._vertical, _mover.field.corridor_range(_mover._vertical), false)
	if _mover.field.uniform_walkers:
		var corridors := _mover.field.corridor_range(_mover._vertical)
		_mover._corridor = _mover._rng.randi_range(corridors.x, corridors.y)
	var offsets := CrowdLanes.walkable_offsets(_mover._map, _mover._vertical, _mover._corridor,
			floori(_mover._along() / float(Tuning.TILE_SIZE)))
	_mover._lane = offsets[_mover._rng.randi_range(0, offsets.size() - 1)]
	_mover._direction = 1.0 if _mover._rng.randf() < 0.5 else -1.0
	_mover._speed = _mover._rng.randf_range(Tuning.PEDESTRIAN_SPEED.x, Tuning.PEDESTRIAN_SPEED.y)

## A walker is pushed toward the outer edge of its own footway, which is what leaves a gap between
## the two lanes of a pavement worth aiming at. See `CrowdLanes.SIDEWALK_LANE_SPREAD`.
func lane_centre_here() -> float:
	return CrowdLanes.walker_lane_centre(_mover._corridor, _mover._lane,
			CrowdLanes.walkable_offsets(_mover._map, _mover._vertical, _mover._corridor,
			floori(_mover._along() / float(Tuning.TILE_SIZE))))

func forget_the_detour() -> void:
	_detour_left = 0.0
	_yield_left = 0.0
	_body_detour_held = false

## A recycled walker is a fresh person walking in from the edge of the box. Resetting its stride
## cannot be wrong the way holding a stale facing would be, and doing it anyway keeps its stride
## deterministic per seed. Whatever door had hold of it is at the other end of the field now, and a
## hut left occupied by somebody who has been recycled out of it never lets anybody else in again; a
## refusal goes with it, since the door it decided against is nowhere near the street it is about to
## be standing on. And it draws a fresh answer, here, before the placement's rolls, for the reason
## `draw_the_door_answer()` gives: the entry point is checked against ground this walker may walk.
func on_recycled() -> void:
	_mover.restart_the_picture()
	_let_go_of_the_hut()
	_forget_the_refusal()
	draw_the_door_answer()

## A walker on any lane its footway has at that end, at its ordinary speed; none at an end with no
## footway.
func enter_at_an_end(along_tile: int) -> bool:
	var offsets := CrowdLanes.walkable_offsets(_mover._map, _mover._vertical, _mover._corridor,
			along_tile)
	if offsets.is_empty():
		return false
	_mover._lane = offsets[_mover._rng.randi_range(0, offsets.size() - 1)]
	_mover._speed = _mover._rng.randf_range(Tuning.PEDESTRIAN_SPEED.x, Tuning.PEDESTRIAN_SPEED.y)
	return true

# ------------------------------------------------------- checkpoint doors ---
# A walker crossing a region door is held at the hut on its own sidewalk the way she is, in the
# player's own four states — *("four states walking -> waiting -> inspection -> emerging on the
# other side (with cooldown to not go back again) -> walking")*. See `DoorState` for what each one
# is and `Crowd._hold_walkers_at_doors()` for the geometry that feeds them.
#
# **None of this is her detention.** `EventInstance`/`EventManager` hide her, ease the camera onto
# the door, charge her meter and teleport her out past the body's own `detain_radius`; a walker is
# not the one being looked for and shares only the shape of the wait. What a hut is to the crowd is
# `WalkerDoorHold` — a point, somebody inside, and a line — and nothing here reads a catalogue row.

## Rolls what this walker does at a region door, off its own RNG stream so a seed reproduces a
## day's crowd answer for answer.
##
## **Drawn before the position is, and that ordering is load-bearing.** `_stands_on_a_street()`
## refuses to place anybody on ground they treat as shut, and a walker that turns back at doors
## treats a door's whole segment as shut — so an answer drawn *after* the placement loop can land
## somebody inside a street they will not walk, where they pace between its two ends for the rest of
## the day. That is the exact trap the refusal exists to prevent; a car does not draw at all, since
## the boom is `Crowd._stop_for_gates()`'s business and a car spending a number here would turn
## differently at every junction it has ever turned at correctly.
func draw_the_door_answer() -> void:
	var roll := _mover._rng.randf()
	if roll < Tuning.WALKER_DOOR_PASS_FRACTION:
		_door_answer = DoorAnswer.PASSES
	elif roll < Tuning.WALKER_DOOR_PASS_FRACTION + Tuning.WALKER_DOOR_TURN_BACK_FRACTION:
		_door_answer = DoorAnswer.TURNS_BACK
	else:
		_door_answer = DoorAnswer.HELD

## One frame of this walker's own crossing. Called by `Crowd._hold_walkers_at_doors()` the moment
## after it has written `door_ahead`/`door_ahead_along`, so a state is always decided on this
## frame's geometry rather than on the previous one's.
func advance_the_door_hold(delta: float) -> void:
	match _door_state:
		DoorState.INSPECTION:
			_inspection_left -= delta
			if _inspection_left <= 0.0:
				_emerge_from_the_hut()
		DoorState.EMERGING:
			# The cooldown, and it is a *distance* rather than a clock on purpose: what it has to
			# rule out is this walker being turned round by the crowd's own steering a few pixels
			# past the door and inspected all over again, and how long that takes is not something
			# a number of seconds can know.
			if not _door_hold or _mover.global_position.distance_to(_door_hold.position) \
					> Tuning.WALKER_DOOR_COOLDOWN_RADIUS:
				_door_hold = null
				_door_state = DoorState.WALKING
		DoorState.WAITING:
			if _door_hold != _mover.door_ahead:
				# The hut is no longer in front of it: it turned off at the junction, was turned
				# round by a barrier, or was moved. Standing in a queue for a door it is no longer
				# walking to would hold that door's line shut against everybody behind it.
				_let_go_of_the_hut()
			elif _door_hold.admit(_mover):
				_enter_the_hut()
		DoorState.WALKING:
			_consider_the_hut_ahead()

## The walking state's own decision: commit to the hut in front, and stop once this walker has
## reached its own place in the line.
##
## **It joins the line at first sight, seven tiles off**, rather than on arrival at the hut. That
## is where the lookahead sees a shut street too, and it is the only place a walker can still
## decide against a door and turn at a junction — walking up to a full line and then about-facing
## on the sidewalk is not a move a walker has.
func _consider_the_hut_ahead() -> void:
	if _refused_hut and _refused_hut != _mover.door_ahead:
		# Out of sight of the door it turned away from — a fresh approach is a fresh decision.
		_forget_the_refusal()
	if _door_answer != DoorAnswer.HELD or _mover.door_ahead == null:
		if _door_hold:
			_let_go_of_the_hut()
		return
	if _refused_hut == _mover.door_ahead:
		return
	if _door_hold != _mover.door_ahead:
		_let_go_of_the_hut()
		if _mover.door_ahead.committed() > Tuning.WALKER_DOOR_QUEUE_MAX:
			_refuse_the_door(_mover.door_ahead)
			return
		_door_hold = _mover.door_ahead
		_door_hold.join(_mover)
	if _mover.door_ahead_along <= _door_stop_distance():
		_door_state = DoorState.WAITING

## Decides against a door whose line is already as long as it is allowed to get — the player's
## *"don't want a queue that is long"* — and does it by shutting that door's own **segment** to this
## walker, which is exactly what turning back at a door already means (`_segment_is_shut`).
##
## **Nothing here waits at the hut and then gives up.** The decision is taken where the lookahead
## first sees the door and the turn is the one a wall gets, so the ordinary case is a walker that
## takes the junction rather than one that walks up to a queue and about-faces on the sidewalk.
## Where there is no junction left between it and the door — it is already inside the door's own
## street, because seven tiles is all anybody in the crowd sees a wall from either — it turns round
## where it stands, immediately rather than at the hut, the same move a cul-de-sac gets.
func _refuse_the_door(hold: WalkerDoorHold) -> void:
	_refused_hut = hold
	_refused_door_key = NO_DOOR
	var segment := StreetNetwork.segment_containing(_mover._map.world_to_tile(hold.position))
	if segment:
		_refused_door_key = segment.key()
	# The lookahead is cached per tile and was worked out before this walker decided anything.
	_mover._scan_at = Vector2i(-9999, -9999)

func _forget_the_refusal() -> void:
	_refused_hut = null
	_refused_door_key = NO_DOOR
	_mover._scan_at = Vector2i(-9999, -9999)

## Where this walker stops short of the hut, in px along its own line of travel: beside the hut if
## it is at the front of the line, and one spacing further back for everybody behind it. Recomputed
## every frame rather than fixed on arrival, which is what makes a line *shuffle forward* when the
## walker at the front is let in.
func _door_stop_distance() -> float:
	var place := _door_hold.place_of(_mover) if _door_hold else 0
	return Tuning.WALKER_DOOR_STOP_DISTANCE \
			+ float(maxi(0, place)) * Tuning.WALKER_DOOR_QUEUE_SPACING

## Inside, and not drawn. **Standing on the hut's own ground point rather than hidden where it
## stopped**: the hut's solid body keeps her further from that point than a contact can ever fire
## from, so a walker in there cannot be walked into by somebody who cannot see it. It goes on
## making its ordinary noise, the way her own meters keep running while she is inside — the body is
## still there whether or not the player can see it.
func _enter_the_hut() -> void:
	_door_state = DoorState.INSPECTION
	_inspection_left = Tuning.WALKER_DOOR_HOLD_SECONDS
	_mover.visible = false
	_mover._set_along(_door_hold.position.y if _mover._vertical else _door_hold.position.x)
	_mover._set_cross(_door_hold.position.x if _mover._vertical else _door_hold.position.y)

## Out again on the far side of the door, back on its own lane, just past the hut's body — the same
## `WALKER_DOOR_STOP_DISTANCE` it waited at on the way in, so the two sides of a door are
## symmetric. It keeps hold of the hut for the cooldown; `EMERGING` above is what lets go.
func _emerge_from_the_hut() -> void:
	_inspection_left = 0.0
	_mover.visible = true
	_door_state = DoorState.EMERGING
	if not _door_hold:
		_door_state = DoorState.WALKING
		return
	_door_hold.release(_mover)
	var door_along: float = _door_hold.position.y if _mover._vertical else _door_hold.position.x
	_mover._set_along(door_along + Tuning.WALKER_DOOR_STOP_DISTANCE * _mover._direction)
	_mover._set_cross(_mover._lane_centre)
	# Out from the hut's middle is a jump, so it is drawn from where it comes out rather than
	# interpolated out of the hut; shown again above, so the reset is not the no-op it is on a node
	# hidden in the tree.
	_mover.reset_physics_interpolation()
	# The lookahead is a cached answer about the tile it was standing on, and it is not standing
	# there any more.
	_mover._scan_at = Vector2i(-9999, -9999)
	_mover.door_ahead = null
	_mover.door_ahead_along = INF

## Gives up whatever claim this walker has on a hut and goes back to walking. **Every way a walker
## can stop being where it was goes through here** — recycling at the edge of the field, being
## streamed out, turning away — because a hut left occupied by somebody who no longer exists never
## takes anybody again, and nothing about a walker that has gone would say so.
func _let_go_of_the_hut() -> void:
	if _door_hold:
		_door_hold.release(_mover)
	_door_hold = null
	_door_state = DoorState.WALKING
	_inspection_left = 0.0
	_mover.visible = true

## How fast this walker is going as a fraction of its own pace while a door has hold of it: nothing
## at all inside the hut or standing in its line, and its ordinary speed otherwise.
##
## A factor beside `_yield_factor()` rather than a write to `_speed`, for the reason that one is:
## nothing has to remember what the speed used to be, and a walker asked to stand still for a
## second does not ratchet itself to a standstill it never recovers from.
func _hold_factor() -> float:
	if _door_state == DoorState.INSPECTION:
		return 0.0
	if _door_state == DoorState.WAITING and _mover.door_ahead_along <= _door_stop_distance():
		return 0.0
	return 1.0

## True while this walker is being held at a door and is not walking anywhere — read by `step()`,
## which has nothing to steer, look ahead for or turn at a junction while it is inside a hut.
func _is_inside_a_hut() -> bool:
	return _door_state == DoorState.INSPECTION

## Somebody she walked into gets out of her way.
##
## **A positional separation alone is undone on the very next frame** by this agent steering back to
## `_lane_centre`, which is where she is standing — so the bump resolves and re-forms for as long as
## she stays there, with a fresh jolt each time. That is being stuck to somebody, and it loses days.
##
## What moves is the agent's own **steering target**, not the player: it aims a lane over for a
## couple of seconds and then comes back. That keeps the invariant intact — separation between
## bodies is positional, never a force — and it is also just what a person does when you walk into
## them.
##
## `away` is in world space; only the component across this agent's own corridor means anything to
## it, and the result is clamped inside the pavement band, because a walker that yields into the
## carriageway is a walker under a car.
func step_aside(away: Vector2, distance: float, seconds: float) -> void:
	var across := away.x if _mover._vertical else away.y
	var along := away.y if _mover._vertical else away.x
	if absf(across) >= absf(along):
		var band := _pavement_band()
		_mover._detour = clampf(_mover._lane_centre + _mover._detour + signf(across) * distance,
				band.x, band.y) - _mover._lane_centre
		_detour_left = maxf(_detour_left, seconds)
		return

	# **The direction she needs is this walker's own line of travel**, so there is nothing to
	# steer: it is crossing her path rather than sharing it. Measured, nine to eleven of every
	# twelve contacts on a forty-second walk are with somebody **crossing**, which is why this
	# branch exists at all — a sidestep alone leaves the contact count exactly where it found it.
	#
	# What a person does at a corner is hurry across or wait, and which one depends only on
	# whether carrying on takes them further from her line. Both are a speed for a moment; neither
	# touches the lane, the corridor or the path, so a walker that yields is still going exactly
	# where it was going.
	_yield_hurry = signf(along) == signf(_mover._direction)
	_yield_left = maxf(_yield_left, seconds)

## **Somebody coming at `here`, going `velocity`, finds this walker moved over**: her, from the
## crowd's tick (`Crowd._meet_the_player()`), and an event figure, from this walker's own step
## (`give_way_on_the_step()`), since the crowd gives way to event figures as it does to her (inbox
## #884 in minty-dolphin). Nobody steps round somebody standing still, which is what `velocity` zero
## says.
##
## The counterpart to `Crowd._bump()`, and the reason the pair of them is the whole answer: a bump is
## what happens when this fails. See `Tuning.CROWD_YIELD_DISTANCE` for why the crowd's "careful is free"
## half is a *behaviour* rather than a two-pixel line to aim at.
##
## Three things keep it from being a crowd that simply evaporates in front of her (or of a figure):
##
## - **Only people actually in the way.** Ahead of her, within a lane's width of her line, and
##   inside a second of walking. Somebody on the far side of the pavement carries on.
## - **Only a lane, and never into the road.** `step_aside()` clamps to the footway.
## - **Only if she gives them time.** The notice distance is fixed and their steering is not, so a
##   run arrives before they have cleared — which is one more thing running is bad at, and it did
##   not need a new rule to say so.
func make_way_for(here: Vector2, velocity: Vector2) -> void:
	if velocity == Vector2.ZERO:
		return
	var offset := _mover.global_position - here
	var going := velocity.normalized()
	if offset.dot(going) <= 0.0 or offset.length() > Tuning.CROWD_YIELD_DISTANCE:
		return

	# **Closest approach, not current distance from her line.** The first version asked whether a
	# walker was already within a lane's width of her path, which is the right question for
	# somebody walking the same pavement and a useless one for somebody crossing it: at 60px/s
	# they enter that window a third of a second before the contact, and a probe said nine of
	# every twelve contacts are exactly that walker. Predicting where the two of them will be is
	# the only notice that arrives in time to be acted on.
	var relative := _mover.velocity() - velocity
	var speed_squared := relative.length_squared()
	if speed_squared < 1.0:
		return
	var closest := clampf(-offset.dot(relative) / speed_squared, 0.0, Tuning.CROWD_YIELD_LEAD)
	if (offset + relative * closest).length() > Tuning.CROWD_YIELD_LATERAL:
		return

	# Whichever side of her line they are on **now**, so nobody crosses in front of her to get out
	# of the way — and so somebody already most of the way across carries on rather than reversing
	# into her. `step_aside()` reads that as a sidestep or as hurrying-or-waiting
	# depending on which of its own axes the direction lands on.
	var side := Vector2(-going.y, going.x)
	var lateral := offset.dot(side)
	# **Except for somebody already standing on her line**, who has no side to be on. Told to
	# get out of the way sideways, half of them read it as "wait" and stop dead in front of her —
	# which is the one outcome worse than carrying on. Pointed along their own travel instead,
	# they always read it as "hurry", which is the only move that clears her.
	var away := side if lateral >= 0.0 else -side
	if absf(lateral) < Tuning.BUMP_CLEAR_RADIUS:
		away = _mover.heading()
	step_aside(away, Tuning.BUMP_STEP_ASIDE, Tuning.BUMP_STEP_ASIDE_TIME)

## **A walker gives way to an event figure** (inbox #884 in plaid-raven: the crowd yields, and a
## pedestrian does not want to be overrun): to every figure under way, and to a standing one that is
## an object or a vehicle, while a person or an animal standing still may be walked through (inbox
## #905; which figures, `SeparationPass`'s class doc). It makes way for each one coming at it as it
## does for her (`make_way_for()`), so it moves over a lane within its own footway before the figure
## arrives; and its proposed step is then moved clear of every figure's body (`SeparationPass.
## clear_of_the_keepers()`), which is the guarantee, since a sidestep is an approach and an approach
## arrives late (the **crowd-traffic** skill). A walker walking into a figure slides round it, the
## same for a standing van as for a moving dog, and a figure walking into a walker pushes him out of
## its way. **Pushed, he keeps going the way he was pushed**, as her bump has him do, a lane over for
## a couple of seconds (`step_aside()`), or his own steering would walk him straight back into the
## figure; pushed along his own line, he steps to a side instead, since being driven down his own
## line separates nobody: the side he is on, unless his footway has no room on it and has more on
## the other (`_side_to_step_to()`). **Pushed toward ground he may not stand on**, squeezed against
## a wall, he cannot go aside: overtaken by a figure, he is moved on along his own line
## (`SeparationPass.clear_along()`) and hurries ahead of it; met head on by a figure under way, he
## walks on and the figure brushes past him, the one overlap this allows; and against a standing
## object or vehicle he is held behind it and waits. The mover's own check runs after
## (`LaneMover._keep_out_of_a_body()`), so he is moved only over ground he may stand on, as her bump
## moves him over nothing solid.
##
## Not startled, unlike her bump: a walker's jolt is noise the baby hears, and an event figure
## walking through the crowd is not a reason for the street to cost her more than it did.
func give_way_on_the_step(delta: float) -> void:
	var separation := _mover._map.separation
	if not separation.walker_is_near(_mover._move.from, Tuning.CROWD_YIELD_DISTANCE):
		return
	var move := _mover._move
	var near := false
	for keeper in separation.walker_keepers():
		if keeper.at.distance_squared_to(move.from) > _FIGURE_NOTICE_SQUARED:
			continue
		near = true
		make_way_for(keeper.at, keeper.step / delta)
	if not near:
		return
	var forward := _mover.heading()
	var cleared := separation.clear_of_the_keepers(move, _side_to_step_to(forward, Vector2.ZERO))
	if cleared == move.to:
		return
	var away := (cleared - move.to).normalized()
	if may_stand_on(_mover._map.world_to_tile(cleared)):
		if absf(away.dot(forward)) > 0.5:
			away = _side_to_step_to(forward, away)
	else:
		# Squeezed against ground it may not stand on — a wall, the kerb of a shut road — it cannot
		# go out to the side. Overtaken by the figure, it is moved on along its own line and hurries
		# ahead of it (`step_aside()` read along its line); met head on by one under way, it keeps
		# walking and the figure brushes past it, since pushing it back down its own street is being
		# swept along in front of the figure for as long as their two lines are one. Against a
		# standing object or vehicle nothing sweeps it along, so it is held behind it and waits
		# (`step_aside()` read back along its line).
		cleared = separation.clear_along(move, forward)
		away = (cleared - move.to).normalized()
		if away.dot(forward) <= 0.0 and not separation.overlaps_one_standing(move):
			return
	move.to = cleared
	if away != Vector2.ZERO:
		step_aside(away, Tuning.BUMP_STEP_ASIDE, Tuning.BUMP_STEP_ASIDE_TIME)

## **The side of its own line a walker pushed along that line steps out to**, as a world direction:
## the side `away` leans to (the side it already stands on of the figure), or, with no lean, the
## side with more of its footway beside it; but never one with less than half a tile of footway left
## when the other has more, since a step that the footway's edge stops short is a walker held in
## front of the figure, a step from where it started.
func _side_to_step_to(forward: Vector2, away: Vector2) -> Vector2:
	var side := Vector2(-forward.y, forward.x)
	var band := _pavement_band()
	var cross := _mover._cross()
	var toward_high := (side.x if _mover._vertical else side.y) > 0.0
	var room := (band.y - cross) if toward_high else (cross - band.x)
	var room_other := (cross - band.x) if toward_high else (band.y - cross)
	var lean := away.dot(side)
	if absf(lean) < 0.01:
		return side if room >= room_other else -side
	if lean < 0.0:
		side = -side
		var swapped := room
		room = room_other
		room_other = swapped
	if room < float(Tuning.TILE_SIZE) * 0.5 and room_other > room:
		return -side
	return side

## The squared distance beyond which a figure is too far to make way for (`make_way_for()` reaches
## `Tuning.CROWD_YIELD_DISTANCE`) and, since no body reaches that far, to touch on this step: most
## figures for most walkers, which then ask nothing more of the pass.
const _FIGURE_NOTICE_SQUARED := Tuning.CROWD_YIELD_DISTANCE * Tuning.CROWD_YIELD_DISTANCE

## The stretch of cross-axis coordinate this walker's own pavement covers, as `(low, high)`.
##
## Clamped against the **band**, not against a symmetric distance from the lane centre, because
## the pavement is not symmetric about a lane: offsets 0 and 1 are one footway and 4 and 5 are the
## other, with the carriageway in between. A walker on the kerbside lane that is asked to move
## kerbwards must stop at the kerb — the first version clamped by distance and would happily have
## put somebody 48px into the road to get out of her way, which is a pedestrian under a car.
func _pavement_band() -> Vector2:
	var offsets := CrowdLanes.walkable_offsets(_mover._map, _mover._vertical, _mover._corridor,
			floori(_mover._along() / float(Tuning.TILE_SIZE)))
	# A precinct has one footway and it is the whole street, so there is no far side to be on.
	if offsets.size() > 4:
		var slack_all := float(Tuning.TILE_SIZE) * 0.5
		return Vector2(CrowdLanes.lane_centre(_mover._corridor, offsets[0]) - slack_all,
				CrowdLanes.lane_centre(_mover._corridor, offsets[offsets.size() - 1]) + slack_all)
	var near_side: bool = _mover._lane <= offsets[1]
	var low := CrowdLanes.lane_centre(_mover._corridor, offsets[0] if near_side else offsets[2])
	var high := CrowdLanes.lane_centre(_mover._corridor, offsets[1] if near_side else offsets[3])
	# Half a tile of slack at each end: a lane centre is the middle of a tile, and the footway
	# reaches to that tile's edge.
	var slack := float(Tuning.TILE_SIZE) * 0.5
	return Vector2(low - slack, high + slack)

## How fast this walker is going right now as a fraction of its own pace: hurrying across in front
## of her, waiting for her to pass, or simply walking. See `step_aside()`.
##
## A factor rather than a write to `_speed`, so nothing has to remember what the speed used to be
## — and so a walker that is being asked to yield every frame while she approaches does not ratchet
## itself to a standstill it never recovers from.
func _yield_factor() -> float:
	if _yield_left <= 0.0:
		return 1.0
	return YIELD_HURRY if _yield_hurry else 0.0

## How much faster somebody crossing in front of her walks to get out of the way. Enough to clear
## her line inside the notice distance and not so much that a pavement breaks into a jog.
const YIELD_HURRY := 1.7

## A walker rounds a corner. Rolled once per junction, and the new lane is whichever
## pavement is nearest: someone turning a corner keeps to the side they are already on
## rather than stepping across the carriageway to do it.
func _consider_turning() -> void:
	var crossing := CrowdLanes.corridor_at(_mover._along())
	if crossing < 0:
		_mover._junction = -1
		return
	if crossing == _mover._junction:
		return
	_mover._junction = crossing
	if _mover._rng.randf() >= Tuning.PEDESTRIAN_TURN_CHANCE:
		return

	# A turn is the one move that commits without looking, and that is free only while the only
	# unwalkable thing a street can turn into is a barrier, which `divert` picks up on the next
	# frame. It is not free here: a T-junction on the edge of a calm zone has one arm that is park,
	# and a walker that turns into it is standing on grass before anything notices. So the direction
	# is chosen from the arms that go somewhere, and a junction with no such arm is one this walker
	# carries straight on through.
	#
	# **Ground only, never today's barriers** — see `_no_street_ahead()`. A street sealed further
	# along is a street to walk into as far as the seal, and refusing it here is what left every
	# offshoot of the day's route empty.
	var turning := 1.0 if _mover._rng.randf() < 0.5 else -1.0
	if _no_street_ahead(not _mover._vertical, turning, LaneMover.LOOKAHEAD):
		turning = -turning
		if _no_street_ahead(not _mover._vertical, turning, LaneMover.LOOKAHEAD):
			return

	# The two axes swap roles and the position does not move: what was the distance along
	# the old corridor is, unchanged, the distance across the new one. The lane it steers
	# to is the nearest pavement, so a walker that turns from the middle of a junction cuts
	# the corner instead of stepping back to the kerb first.
	# Which lane of the new pavement it would land on, asked **before** anything is changed, because
	# the answer may be that this arm is not one it can take: a body standing where it would land,
	# with no room left in the junction to cross to the other lane of that footway. Nothing is
	# blocking the street it is already walking, so it carries straight on — an unmade turn is
	# invisible where a walker clipping a café's tables is not.
	var lane := _sidewalk_after_a_turn(not _mover._vertical, crossing, turning)
	if lane < 0:
		return

	var kept := _mover._corridor
	_mover._vertical = not _mover._vertical
	_mover._corridor = crossing
	_mover._direction = turning
	_mover._lane = lane
	_mover._lane_centre = _mover._lane_centre_here()
	_mover._forget_the_detour()
	# It is now travelling through the corridor it just came down, so that is the junction
	# it is in — otherwise it would roll a second turn before clearing the first.
	_mover._junction = kept

## Whether the street `distance` ahead along an axis is one this agent could never travel **at all**
## — off the map, not a street, a precinct to a car — with nothing today has placed in it counted.
##
## **This is what a walker asks of an arm at a junction, and it is the whole of item 4.**
## *(2026-09-19: "they saw that a road section was closed of and never entered it. this shouldn't
## happen. they should still go into the section until they cannot continue. this should also happen
## from inside the path since right now we have offshoots that are clear because nobody attempts to
## go in".)* A walker choosing where to turn weights a street with a barrier somewhere along it
## exactly like an open one, so a side street sealed further down fills as far as its seal and the
## walkers who reach the seal turn round and walk back out. What it still refuses is ground nothing
## can travel: a T-junction on the edge of a calm zone has one arm that is park, and a walker that
## turns into it is standing on grass before anything notices. A car keeps asking the whole of
## `cannot_go_on()` instead, because an arm it cannot get out of is a car parked there for the day.
func _no_street_ahead(vertical: bool, direction: float, distance: float,
		from := Vector2.INF) -> bool:
	return _never_a_street_here(vertical, _mover._tile_ahead(vertical, direction, distance, from))

# ----------------------------------------------------- going round a body ---
# A café's tables, a construction band, a kerbed van, a stall, a skip: a stationary solid body
# standing on one lane of a street. *("yes every solid body should do that -- not necessarily force
# a turn around but at least avoid the solid".)* `CityMap.obstructed_tiles` is the record of where
# they are; this is what a walker does about one.
#
# **The walker's answer is a sidestep and not a turn.** It has two lanes of footway, so it steers
# into the other one for as long as the body is ahead of or beside it and steers back after — the
# same detour a bump gives it, aimed at a lane rather than away from a person. Only when every lane
# of its own footway is taken at one point along the street is the way actually shut (in a precinct,
# when no lane runs through the rows ahead), and that is `_footway_is_shut()`, read through
# `cannot_go_on()` so the turn at the last junction is the one a seal already produces.

## Whether the footway `tile` belongs to is shut to this walker. On an ordinary street that is every
## lane of the pavement being taken by a solid body at that point along the street. `vertical` is the
## axis being travelled, so the tile's *other* coordinate is the one across the street.
##
## **A precinct's footway is its whole width, and it is shut when no way through is left.** It has
## no carriageway, so "my own footway" is the street; one stall is stepped round across the six
## lanes (`_step_around_a_body`) and leaves it open. What shuts it is what leaves this walker no way
## past, whether one body across all six lanes or several in neighbouring rows that no lane runs
## through: see `_precinct_way_is_shut`. It then turns round in front of it as on any other street
## instead of slowing to a stop at the body with the walkers behind it queueing.
func _footway_is_shut(vertical: bool, tile: Vector2i) -> bool:
	# The cheap half first: a walker's own tile is nearly always clear, and this runs per probe.
	if _mover._map.passable(tile, _bodies_today):
		return false
	var across := tile.x if vertical else tile.y
	var offset := CityMap.corridor_offset(across)
	if offset < 0:
		return false
	var along_tile := tile.y if vertical else tile.x
	var corridor := across / CityMap.period()
	var offsets := CrowdLanes.walkable_offsets(_mover._map, vertical, corridor, along_tile)
	# On an ordinary street the carriageway is not a footway; in a precinct it is paving like the
	# rest.
	if not offsets.has(offset):
		return false
	if offsets.size() != CrowdLanes.SIDEWALK_OFFSETS.size() and vertical == _mover._vertical \
			and corridor == _mover._corridor:
		return _precinct_way_is_shut_cached(vertical, corridor)
	var base := corridor * CityMap.period()
	for lane_offset in _footway_of(offsets, offset):
		var lane_tile := Vector2i(base + lane_offset, along_tile) if vertical \
				else Vector2i(along_tile, base + lane_offset)
		if _walker_lane_is_open(lane_tile):
			return false
	return true

## `_precinct_way_is_shut()` worked out once per look-ahead scan: the answer reads only the walker's
## own tile, heading and the map, so every blocked tile the scan probes shares it.
func _precinct_way_is_shut_cached(vertical: bool, corridor: int) -> bool:
	var here := _mover._map.world_to_tile(_mover.position)
	if _way_shut_known and here == _way_shut_at and vertical == _way_shut_vertical \
			and _mover._direction == _way_shut_direction:
		return _way_shut
	_way_shut_known = true
	_way_shut_at = here
	_way_shut_vertical = vertical
	_way_shut_direction = _mover._direction
	_way_shut = _precinct_way_is_shut(vertical, corridor)
	return _way_shut

## Whether a walker in a precinct has no way past what stands in the next `BODY_SCAN_TILES` rows
## ahead of it. A precinct's lanes are 0 to 5 across, a row is one tile along the street, and a lane
## tile is open by `_walker_lane_is_open` (bodies, closed ground and soft seals are not).
##
## The lanes it can be in are walked forward a row at a time: the ones it holds that are open in the
## next row, then spread sideways through open lanes there. A lane is carried straight ahead and
## never diagonally, since a step between two blocked corners is not a gap a body fits through. When
## no lane is carried the way is shut; a row with no blocked lane in it past the first body, or
## ground that is no longer a precinct, is a way out. Run only for a probe on a blocked tile, so it
## costs nothing in a clear street.
func _precinct_way_is_shut(vertical: bool, corridor: int) -> bool:
	var step := signi(int(_mover._direction))
	var row0 := _mover._map.world_to_tile(_mover.position)
	var from_row := row0.y if vertical else row0.x
	var cross_tile := row0.x if vertical else row0.y
	var base := corridor * CityMap.period()
	var lane := cross_tile - base
	if lane < 0 or lane >= CrowdLanes.PRECINCT_OFFSETS.size():
		lane = _mover._lane
	var reach: Array[bool] = []
	reach.resize(CrowdLanes.PRECINCT_OFFSETS.size())
	reach.fill(false)
	if not _precinct_lane_open(vertical, base, from_row, lane):
		return false
	reach[lane] = true
	reach = _spread_through_open_lanes(vertical, base, from_row, reach)
	var met_a_body := false
	for i in range(1, BODY_SCAN_TILES + 1):
		var row := from_row + step * i
		if CrowdLanes.walkable_offsets(_mover._map, vertical, corridor, row).size() \
				== CrowdLanes.SIDEWALK_OFFSETS.size():
			return false
		var carried: Array[bool] = []
		carried.resize(reach.size())
		var any_carried := false
		var any_blocked := false
		for l in reach.size():
			var open := _precinct_lane_open(vertical, base, row, l)
			any_blocked = any_blocked or not open
			carried[l] = reach[l] and open
			any_carried = any_carried or carried[l]
		if not any_blocked and met_a_body:
			return false
		met_a_body = met_a_body or any_blocked
		if not any_carried:
			return true
		reach = _spread_through_open_lanes(vertical, base, row, carried)
	return false

func _precinct_lane_open(vertical: bool, base: int, row: int, lane: int) -> bool:
	return _walker_lane_is_open(Vector2i(base + lane, row) if vertical \
			else Vector2i(row, base + lane))

## `reach` grown sideways in one row through the open lanes next to a lane it already holds.
func _spread_through_open_lanes(vertical: bool, base: int, row: int,
		reach: Array[bool]) -> Array[bool]:
	var grown := reach.duplicate()
	for l in range(1, grown.size()):
		if grown[l - 1] and _precinct_lane_open(vertical, base, row, l):
			grown[l] = true
	for l in range(grown.size() - 2, -1, -1):
		if grown[l + 1] and _precinct_lane_open(vertical, base, row, l):
			grown[l] = true
	return grown

## The lanes of one footway: the pair `offset` belongs to on an ordinary street, and the whole
## width of a precinct, which has one footway and it is the street.
static func _footway_of(offsets: Array[int], offset: int) -> Array[int]:
	if offsets.size() != CrowdLanes.SIDEWALK_OFFSETS.size():
		return offsets
	if offset <= offsets[1]:
		return [offsets[0], offsets[1]]
	return [offsets[2], offsets[3]]

## Whether one lane tile is somewhere a walker may actually be: street ground in the city that
## nothing today has put down on — no closure, soft seal or body (`CityMap.passable()`, as
## `_walker_today`). Deliberately **not** `cannot_go_on`, which asks this one's own caller and
## would come back round; the segment's own state is already decided by the time anything here runs.
func _walker_lane_is_open(tile: Vector2i) -> bool:
	return _mover._map.passable(tile, _walker_today) and _mover._map.in_bounds(tile) and _mover._map.is_street(tile)

## How far a lane scan looks, in tiles: far enough past the distance a sidestep begins at that the
## lane chosen is the one with more road in it rather than the one that happens to be clear for a
## tile longer.
const BODY_SCAN_TILES := Tuning.WALKER_BODY_SIDESTEP_TILES + LaneMover.LOOKAHEAD_TILES

## Steers this walker into whichever lane of its own footway has the most open road in front of it,
## so it goes round a body standing on its own lane and comes back to that lane afterwards.
##
## Worked out **once per tile**, off `_look_ahead`'s own cache, for the reason that one is cached:
## it is a question about the tile an agent is standing on, its axis and its direction, over a map
## that is fixed for the day, and a walker crosses a tile in about twenty frames.
##
## It writes `_detour` — the steering target `step_aside()` already owns — rather than adding a
## second offset, so the clamp that keeps a yielding walker out of the carriageway keeps this one
## out of it too. While a body is ahead this wins over a bump's own sidestep, which is the right way
## round: getting out of *her* way into a café is not getting out of the way.
##
## **The lane it is measured from is `_lane`, never the tile it is standing on**, and that is the
## whole of what keeps it from dithering: a detour has already carried this walker off its own lane,
## so a scan taken from where it stands finds the clear lane it just moved into, lets go, and steers
## it straight back into the body. `_lane` is where the walker *belongs*, the detour is how far off
## it currently is, and a decision stated over the first is stable while the second is being acted
## on. Ties go to `_lane` for the same reason — that is what makes "and steps back after" happen at
## all rather than leaving a walker one lane over for the rest of the street.
func _step_around_a_body(here: Vector2i) -> void:
	if _mover._map.obstructed_tiles.is_empty():
		_stop_going_round_a_body()
		return
	var along_tile := here.y if _mover._vertical else here.x
	var offsets := CrowdLanes.walkable_offsets(_mover._map, _mover._vertical, _mover._corridor, along_tile)
	# A lane that is not one of this stretch's own is a walker that has walked out of a precinct
	# still carrying one of its six, which on an ordinary street is the carriageway. The nearest
	# sidewalk is the footway it is measured against then, so a stray is steered onto a pavement by
	# the same move that takes it round a body rather than being left to walk down the road.
	var lane := _mover._lane if offsets.has(_mover._lane) else CrowdLanes.nearest_sidewalk(_mover._corridor, _mover._cross())
	var base := _mover._corridor * CityMap.period()
	var best := lane
	var best_clear := _open_tiles_ahead(base + lane, along_tile, _mover._vertical, _mover._direction)
	if best_clear > Tuning.WALKER_BODY_SIDESTEP_TILES:
		_stop_going_round_a_body()
		return
	for lane_offset in _footway_of(offsets, lane):
		if lane_offset == lane:
			continue
		var clear := _open_tiles_ahead(base + lane_offset, along_tile, _mover._vertical, _mover._direction)
		if clear > best_clear:
			best = lane_offset
			best_clear = clear
	if best == _mover._lane:
		# Nothing on this footway is better than the lane it is already in. Where that is because
		# every lane is taken at one point, or in a precinct no lane runs through the rows ahead,
		# `_footway_is_shut` has already told `_look_ahead` and `divert` turns this walker; there is
		# no lane left to steer to.
		_stop_going_round_a_body()
		return
	var band := _pavement_band()
	var target := CrowdLanes.walker_lane_centre(_mover._corridor, best, offsets)
	_mover._detour = clampf(target, band.x, band.y) - _mover._lane_centre
	_body_detour_held = true

## How much of its own lane a walker needs in front of it to turn into an arm at all, in tiles: the
## room `Tuning.WALKER_BODY_SIDESTEP_TILES`'s own floor says a sidestep costs, rounded up to a tile
## and given one more. A walker rounding a corner lands wherever its old along coordinate left it,
## which can be a few pixels from the next street's first tile, so this is the one case where the
## sidestep has no runway at all and the answer has to be not to turn here.
const BODY_TURN_CLEARANCE_TILES := 3

## Which lane of the new footway a walker rounding a corner takes: the pavement it is already on,
## and whichever of that pavement's two lanes has the more road in front of it. `-1` means this arm
## is one this walker cannot take at all, because the lane it would land on is taken within
## `BODY_TURN_CLEARANCE_TILES` — a voluntary turn is then simply not made, and a turn forced by a
## blockage falls back to the pavement it is nearest.
##
## **Which lane it lands in has to be chosen here rather than sidestepped into afterwards**, and the
## reason is arithmetic rather than taste: a turn happens inside a junction, so the first tile of the
## new street can be a few pixels away, while crossing to the other lane of a footway takes a good
## half second — a walker that turns onto the lane a café is standing on has no room left to get off
## it. Read off `_open_tiles_ahead`, the same measure the sidestep uses, so the two cannot disagree
## about which lane is the clear one. The axis, corridor and direction must already be the new ones.
## `vertical`, `corridor` and `direction` are the ones the walker will have **after** the turn, and
## are passed rather than read off the fields because the answer decides whether the turn happens at
## all. The position does not move in a turn, so the new cross and along coordinates are this
## agent's own `position` read the other way round.
func _sidewalk_after_a_turn(vertical: bool, corridor: int, direction: float) -> int:
	var cross := _mover.position.x if vertical else _mover.position.y
	var along := _mover.position.y if vertical else _mover.position.x
	var lane := CrowdLanes.nearest_sidewalk(corridor, cross)
	if _mover._map.obstructed_tiles.is_empty():
		return lane
	var along_tile := floori(along / float(Tuning.TILE_SIZE))
	var offsets := CrowdLanes.walkable_offsets(_mover._map, vertical, corridor, along_tile)
	if not offsets.has(lane):
		return lane
	var base := corridor * CityMap.period()
	var best := lane
	var best_clear := _open_tiles_ahead(base + lane, along_tile, vertical, direction)
	if best_clear > Tuning.WALKER_BODY_SIDESTEP_TILES:
		return lane
	if best_clear < BODY_TURN_CLEARANCE_TILES:
		return -1
	for lane_offset in _footway_of(offsets, lane):
		var clear := _open_tiles_ahead(base + lane_offset, along_tile, vertical, direction)
		if clear > best_clear:
			best = lane_offset
			best_clear = clear
	return best

## How many tiles of one lane are open to a walker from `from_along` forward, counting the walker's
## own along position as the first — `0` when it is standing on a body, `BODY_SCAN_TILES + 1` when
## the lane is clear as far as this looks. Capped rather than run to the end of the street: the
## answer is only ever compared with another lane's and with the distance a sidestep begins at.
func _open_tiles_ahead(cross_tile: int, from_along: int, vertical: bool, direction: float) -> int:
	var step := signi(int(direction))
	for i in range(0, BODY_SCAN_TILES + 1):
		var at_along := from_along + step * i
		var tile := Vector2i(cross_tile, at_along) if vertical else Vector2i(at_along, cross_tile)
		if not _walker_lane_is_open(tile):
			return i
	return BODY_SCAN_TILES + 1

## Lets go of a sidestep taken to get round a body, immediately rather than on the timer a bump's
## own sidestep decays over: what ends this one is being past the body, which no number of seconds
## knows.
func _stop_going_round_a_body() -> void:
	if not _body_detour_held:
		return
	_body_detour_held = false
	_mover._detour = 0.0
	_detour_left = 0.0

## Whether the agent is far enough into a junction to turn without landing on the wrong surface.
##
## A turn makes the *along* coordinate the new *across* one, and the new across coordinate is
## the lane the agent then has to steer away from. So a walker turns while it is on one of the
## junction's pavement bands and ends the turn a few pixels from a lane it is allowed to be in
## rather than two tiles from one. Every walker crosses both bands on its way through a junction, so
## waiting costs at most a tile. **Walkers only now** — a car's turn is a planned arc that lands on
## its exit lane exactly, so where it may start from is the arc's own geometry rather than a band.
func _can_turn_here() -> bool:
	var offset := CityMap.corridor_offset(floori(_mover._along() / float(Tuning.TILE_SIZE)))
	if offset < 0:
		return false
	return not CityMap.is_road_offset(offset)

## Whether this walker's own centre may be on a tile: the per-lane answer rather than
## `cannot_go_on()`, because a walker's `cannot_go_on()` is about a whole footway being taken and
## this is about a body under its feet. A car's is its whole predicate (`CarStrategy`).
##
## **A shut segment is added here rather than left to the turn.** For a walker that is a door it has
## decided to turn back from and nothing else, since a held street is a car's warning rather than a
## walker's — but a walker committed to the heading it has just turned into (`_turn_round()`)
## cannot turn again for a stride, and the one thing that must not buy is a person standing in a
## doorway it refused. What keeps a walker out of a hard seal or a region wall is the first half:
## their bodies are in `CityMap.obstructed_tiles` like any other body.
func may_stand_on(tile: Vector2i) -> bool:
	return _walker_lane_is_open(tile) and not _mover._segment_is_shut(tile)

## Whether a *tile* is somewhere this walker may be. The predicate under the look-ahead, so "the way
## is shut" means one thing however it is asked.
##
## **It is two questions stacked and the order is the useful part.** `_never_a_street_here()` is the
## city — the lattice and the map's edge — and is true of a tile on every day of the run; everything
## after it is what *today* has placed on ground this walker could otherwise travel. The two are
## asked together here and separately where a walker picks an arm at a junction, which is the one
## place the difference matters. See `_no_street_ahead()`.
func cannot_go_on(vertical: bool, tile: Vector2i) -> bool:
	if _never_a_street_here(vertical, tile):
		return true
	if not _mover._map.passable(tile, _closed_today):
		return true
	# A street held for today has a hard seal, a region wall or a closure's barriers standing across
	# the whole of it somewhere along its length. **That is a car's warning and not a walker's** —
	# see `_segment_is_shut`: a walker walks up to the body itself, which the obstruction record
	# below knows exactly where to find, so the only segment shut to it is a door it turns back at.
	if _mover._segment_is_shut(tile):
		return true
	# A soft seal takes both pavements and leaves the carriageway to the cars.
	if not _mover._map.passable(tile, _soft_sealed_today):
		return true
	# A stationary solid body standing in the street — a café, a construction band, a kerbed van.
	# **A walker has the other lane of its own footway** and goes round (`_step_around_a_body`), so
	# the way is only really shut to it once *every* lane of that footway is taken at the same point
	# along the street; the other footway and the carriageway stay open. A precinct is one footway
	# six lanes wide, shut when no lane runs through the rows ahead (`_precinct_way_is_shut`).
	return _footway_is_shut(vertical, tile)

## Whether a tile is ground a walker could never travel, whatever today has or has not placed on
## it: off the map, or not a street at all. **Out of bounds is blocked** for every walker: only cars
## leave by the spine's tunnel and bridge, playtest 16, finding 3, *"only cars should be able to"*.
func _never_a_street_here(_vertical: bool, tile: Vector2i) -> bool:
	if not _mover._map.in_bounds(tile):
		return true
	return not _mover._map.is_street(tile)

## A walker meets the thing it cannot pass with the barrier one tile away, and turns where it
## stands: a person changes direction in a stride, has no lane to be on the correct side of and no
## length to swing round, so there is nothing for a path to be continuous about. A walker in a
## junction turns the corner it has arrived at and a walker in the street about-faces in front of
## the thing it cannot pass. Turning here rather than only in `_consider_turning` is also what
## empties the street that is shut, which reads from a block away — further than the barrier
## itself does.
func divert(_delta: float) -> void:
	var crossing := CrowdLanes.corridor_at(_mover._along())
	if crossing < 0:
		# In the street with the thing in the very next tile and no junction to turn at: a
		# cul-de-sac's plug, a seal standing across the road, a café taking the whole footway. It
		# turns round in front of it, which is the whole of what a walker does about a barrier.
		_mover._turn_round()
		return
	if not _can_turn_here():
		# Inside a junction on the carriageway strip, the wrong band to turn from, which normally
		# costs a tile of waiting. It costs everything when the wall is the next tile: a walker
		# leaving a junction straight into a cul-de-sac's plug has no tile left to wait for the
		# right band in, so it turns round instead.
		if _mover._blocked_in <= 1:
			_mover._turn_round()
		return

	var turning := _pick_an_arm(crossing, 1.0 if _mover._rng.randf() < 0.5 else -1.0)
	if turning == 0.0:
		_mover._turn_round()   # boxed in on three sides; go back the way it came
		return

	# A walker's landing lane, asked before anything moves for the reason `_consider_turning` asks
	# it there. **A refusal is only advice here**: this turn is being made because the way ahead is
	# shut, so there has to be a turn — it falls back to the pavement it is nearest, which is where
	# it would have landed anyway.
	var sidewalk := _sidewalk_after_a_turn(not _mover._vertical, crossing, turning)
	var kept := _mover._corridor
	_mover._vertical = not _mover._vertical
	_mover._corridor = crossing
	_mover._direction = turning
	_mover._lane = sidewalk if sidewalk >= 0 \
			else CrowdLanes.nearest_sidewalk(_mover._corridor, _mover._cross())
	_mover._lane_centre = lane_centre_here()
	_mover._forget_the_detour()
	_mover._junction = kept

## Which way to turn out of `crossing`, trying `first` before the other one, or `0.0` for neither.
## A walker asks only whether the arm is street at all, because it can walk in, meet whatever is
## down there and turn round (`_no_street_ahead()`), and it asks from where it stands.
func _pick_an_arm(crossing: int, first: float) -> float:
	for turning: float in [first, -first]:
		if not _no_street_ahead(not _mover._vertical, turning, LaneMover.LOOKAHEAD):
			return turning
	return 0.0

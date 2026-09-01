class_name EventInstance
extends Node2D
## One live event in the world: its lifetime, its telegraph phase, its excitement field and
## its drawing.
##
## The excitement model is entirely a *query* — `contribution_at()`. Nothing pushes a value
## at the baby, so there is no ordering to get wrong, events compose by simple addition, and
## the whole thing is testable without a scene.

signal finished(instance: EventInstance)

const CAT_CROUCHED := preload("res://assets/events/cat_crouched.svg")
const CAT_RUNNING := preload("res://assets/events/cat_running.svg")
## The only generic here, and it is not a look: it is the *walker* half of a dog walker, which is a
## picture of somebody holding a lead rather than a picture of nobody in particular. Every row draws
## something of its own.
const PERSON := preload("res://assets/events/person.svg")
const YELLER := preload("res://assets/events/yeller.svg")
const BUSKER := preload("res://assets/events/busker.svg")
const POSTER_CREW := preload("res://assets/events/poster_crew.svg")
const ROBBER_WAITING := preload("res://assets/events/robber_waiting.svg")
const ROBBER_LUNGING := preload("res://assets/events/robber_lunging.svg")
const PROTESTER := preload("res://assets/events/protester.svg")
const GUNMAN := preload("res://assets/events/gunman.svg")
const DELIVERY_VAN := preload("res://assets/events/delivery_van.svg")
const FIRE_ENGINE := preload("res://assets/events/fire_engine.svg")
const FIRE_ENGINE_END := preload("res://assets/events/fire_engine_end.svg")
const POLICE_CAR := preload("res://assets/events/police_car.svg")
const POLICE_CAR_END := preload("res://assets/events/police_car_end.svg")
const UNMARKED_VAN := preload("res://assets/events/unmarked_van.svg")
const RIOT_VAN := preload("res://assets/events/riot_van.svg")
const ARMY_TRUCK := preload("res://assets/events/army_truck.svg")
const ARMY_TRUCK_END := preload("res://assets/events/army_truck_end.svg")
const FLAME := preload("res://assets/events/flame.svg")
const BARRIER_SEGMENT := preload("res://assets/events/barrier_segment.svg")
const BARRIER_END := preload("res://assets/events/barrier_end.svg")
const RUBBLE := preload("res://assets/events/rubble.svg")
const CHECKPOINT_BLOCK := preload("res://assets/events/checkpoint_block.svg")
const BARRICADE_PILE := preload("res://assets/events/barricade_pile.svg")
const CAFE_TABLE := preload("res://assets/events/cafe_table.svg")
const CAFE_SITTER := preload("res://assets/events/cafe_sitter.svg")
const DOG := preload("res://assets/events/dog.svg")
const CYCLIST := preload("res://assets/events/cyclist.svg")
const STALL := preload("res://assets/events/stall.svg")
const LEAF_BLOWER := preload("res://assets/events/leaf_blower.svg")
const PIGEON := preload("res://assets/events/pigeon.svg")
const PIGEON_DOWN := preload("res://assets/events/pigeon_down.svg")
const ICE_CREAM_VAN := preload("res://assets/events/ice_cream_van.svg")
const LORRY := preload("res://assets/events/lorry.svg")
const CHARGING_DOG := preload("res://assets/events/charging_dog.svg")

## The one silhouette that stands for a look, at any size.
##
## It lives here rather than in `DangerEdge` for the same reason the caret lives in `Sprites`: a
## cue that belongs to the vocabulary does not belong to a class, and the screen-edge badge's whole
## job is to draw *the thing's own picture* — a second table of which picture that is, kept in the
## UI, is how a badge ends up showing a generic van for a fire engine. `tests/test_events.gd`
## asserts every visible row has one and that no two looks return the same texture, which is the
## half of the one-picture-per-row rule that a `look` field cannot enforce by itself.
static func icon_for(look: EventDef.Look) -> Texture2D:
	match look:
		EventDef.Look.CAT: return CAT_RUNNING
		EventDef.Look.YELLER: return YELLER
		EventDef.Look.DOG_WALKER: return PERSON
		EventDef.Look.CAFE: return CAFE_TABLE
		EventDef.Look.DELIVERY_VAN: return DELIVERY_VAN
		EventDef.Look.BUSKER: return BUSKER
		EventDef.Look.ROADWORKS: return BARRIER_SEGMENT
		EventDef.Look.FIRE_ENGINE: return FIRE_ENGINE
		EventDef.Look.BURNING_BUILDING: return FLAME
		EventDef.Look.BURNT_SHELL: return RUBBLE
		EventDef.Look.LOOSE_DOG: return DOG
		EventDef.Look.STALL: return STALL
		EventDef.Look.LEAF_BLOWER: return LEAF_BLOWER
		EventDef.Look.BIRDS: return PIGEON
		EventDef.Look.CYCLIST: return CYCLIST
		EventDef.Look.ICE_CREAM_VAN: return ICE_CREAM_VAN
		EventDef.Look.LORRY: return LORRY
		EventDef.Look.CHARGING_DOG: return CHARGING_DOG
		EventDef.Look.POLICE_CAR: return POLICE_CAR
		EventDef.Look.POSTER_CREW: return POSTER_CREW
		EventDef.Look.CHECKPOINT: return CHECKPOINT_BLOCK
		EventDef.Look.UNMARKED_VAN: return UNMARKED_VAN
		EventDef.Look.ROBBER: return ROBBER_LUNGING
		EventDef.Look.RIOT_VAN: return RIOT_VAN
		EventDef.Look.ARMY_TRUCK: return ARMY_TRUCK
		EventDef.Look.BARRICADE: return BARRICADE_PILE
		EventDef.Look.PROTEST: return PROTESTER
		EventDef.Look.FIREFIGHT: return GUNMAN
		_: return null

var def: EventDef
## Waypoints for a mobile event, in world space. Empty for a stationary one.
var path: PackedVector2Array = PackedVector2Array()

var age := 0.0
var is_finished := false

## Where the player is, in world space, or `INF` for nowhere.
##
## Written once per frame by `EventManager`, which is the one place that already knows. An instance
## looking her up itself would be thirty lookups a frame for one answer, and — more to the point —
## `EventInstance` has never had to know the player exists, and this keeps that true: it is handed
## a point, and everything it does with the point is a distance.
##
## Two things want it, and neither is a reference to her: a pursuer walks toward it, and anything
## that is *leaving* uses it to know when it is out of sight.
var player_at := Vector2.INF

## Whether she is running right now. Written beside `player_at` and by the same pass, because the
## one thing that reads it asks both together: a pursuer gives up because **she ran**, which is a
## fact about her and not about the gap. See `_chase`.
var player_running := false

## Facing, for art with a front and a back. Only a mobile event ever changes it.
var _heading := Vector2.RIGHT
var _path_travelled := 0.0
var _telegraph_announced := false
var _activation_announced := false

## `face` is where a *stationary* event was sited looking. A mobile one overwrites it from the
## direction it is travelling on its first step, which is why the default is harmless.
func setup(definition: EventDef, at: Vector2, route: PackedVector2Array = PackedVector2Array(),
		face := Vector2.RIGHT) -> void:
	def = definition
	path = route
	position = route[0] if route.size() > 0 else at
	_heading = face

func _ready() -> void:
	EventBus.event_telegraphed.emit(self)
	_telegraph_announced = true
	if def.obstructs_radius > 0.0:
		_build_obstruction()
	if def.flock_size > 0:
		_build_the_flock()

## Some events are physically in the way. The body is a child so it travels with a mobile
## event and disappears with the instance.
func _build_obstruction() -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = def.obstructs_radius
	shape.shape = circle
	body.add_child(shape)
	add_child(body)

func _process(delta: float) -> void:
	if is_finished:
		return
	age += delta

	if not _activation_announced and not is_telegraphing():
		_activation_announced = true
		EventBus.event_activated.emit(self)

	if is_leaving:
		_leave(delta)
		_fly_the_flock(delta)
		queue_redraw()
		return

	_fly_the_flock(delta)
	if def.pursues:
		_chase(delta)
	elif def.mobile and path.size() > 1 and not is_telegraphing_still():
		_advance_along_path(delta)

	if _has_expired():
		_be_done()
	queue_redraw()

## Whether the chase ended because she shook it off rather than because the clock ran out. Read by
## the telemetry, which is the only thing that can tell the two apart from outside.
var gave_up := false
## How long the gap to her has been opening, in seconds. The chase ends when it reaches
## `Tuning.PURSUIT_SHAKEN_OFF`; anything that closes the gap puts it back to zero. See `_chase`.
var _outrun_for := 0.0
## The gap on the previous frame, so `_chase` can tell opening from closing. `INF` before the first.
var _last_range := INF
## For a pursuer with `pursues_within`: the age at which she came close enough for it to take an
## interest, or `INF` while it is still only standing there. Its telegraph and its chase are both
## measured from here rather than from birth. See `is_waiting()`.
var _noticed_at := INF
## True once she has come inside the stand-off during the telegraph, which ends the telegraph
## there and then.
##
## **The lunge is fired by her, not by a clock**, and the two alternatives each fail in their own
## way. A pursuer reaches its stand-off in about a third of a second and then has the rest of a
## 2.4s telegraph to spend while she keeps walking into it — so *holding a distance* means backing
## away from her, and a dog that reverses down the street in front of you is not a dog that is
## about to charge. **Standing still instead** is worse: she closes the last hundred pixels
## herself, reaches it **before** the clock lets it fire, and it kills her from a standing start on
## the first lethal frame.
##
## Firing on proximity gives both halves at once: it never reverses, and the chase always starts at
## the stand-off however she approached it — which is the whole content of the contract, since
## `Tuning.pursuit_standoff()` is the distance that leaves her `PURSUIT_REACTION` to answer.
var _lunged := false

## Comes after her — the one kind of thing running is the answer to. See `EventDef.pursues` and
## `Tuning.validate_pursuit`.
##
## **It comes through its own telegraph**, the way a fire engine does, and that is the whole of
## why a pursuer can force a run at all. A telegraph it spends standing still is a head start she
## can simply walk away with: at `pursue_speed` against `WALK_SPEED` it closes about 56px a
## second, so two seconds of politeness hands her more ground than the entire chase can take
## back. The notice is *the sight of it coming*, and `Tuning.PURSUIT_MIN_NOTICE` is how much of
## that she is owed before it is allowed to end her day.
##
## **But it closes to a stand-off and holds it, rather than arriving.** The paragraph above buys the
## notice in seconds and says nothing about *where* the pursuer spends them: sited across her line a
## couple of hundred pixels ahead — which is where she was already walking — it closes the gap in
## three quarters of a second and then stands **inside its own lethal radius** for the rest of a
## telegraph it is not yet allowed to kill her during. The moment it is, it does, from a standing
## start. Every line of `validate_pursuit` passes while that happens, because every line of it is
## about speeds and durations and a pursuit is played out in distances.
##
## `Tuning.pursuit_standoff()` is the same contract restated as a distance, and holding it is what
## makes the notice real from *any* approach geometry — including the one the director produces.
##
## **And it gives up when it is being outrun, not when a gap has reached a size.** The pursuer is
## faster than a walk and slower than a run by construction, so "the gap is opening" is a statement
## the player can only make by running — which is why it can carry the whole of the design. Walking
## away cannot end a chase at any distance, and running away always ends one in
## `Tuning.PURSUIT_SHAKEN_OFF` seconds regardless of how big the thing chasing her is.
##
## A pursuer may also be a **place** before it is a moment: something that raises the meter on
## sight, and comes for her if she gets close. While
## it is waiting it emits at full strength, is not lethal and does not move; `pursues_within` is
## where that stops. Everything below then runs exactly as it does for a dog sited in front of her,
## started later.
func _chase(delta: float) -> void:
	if player_at == Vector2.INF or is_telegraphing_still():
		return
	var toward := player_at - global_position
	var range_to_her := toward.length()
	if range_to_her < 1.0:
		return
	if is_waiting():
		if range_to_her <= def.pursues_within:
			_noticed_at = age
			# It turns to face her on the frame it notices, which is the whole of the cue: a man who
			# was looking down the alley is now looking at you.
			_heading = toward.normalized()
		return
	_heading = toward.normalized()
	var standoff := Tuning.pursuit_standoff(def.pursue_speed, def.inner_radius)
	# **She ran, so it backs off.** Counting seconds of the *gap actually opening* is the same
	# sentence said about the geometry instead of about the player, and in play it is a different
	# rule: a run opens the gap at 38px/s against the day-3 dog, a fifth of a pixel a frame, so a
	# corner, a kerb, a body in the way or the 0.37s it takes to reverse a walk all reset the timer
	# and the dog keeps coming while she is plainly running from it. The rule here is the one a
	# player can state and therefore learn: **run and it gives up.**
	#
	# `_last_range` is still tracked because the leaving phase reads it; nothing decides on it.
	if player_running:
		_outrun_for += delta
	else:
		_outrun_for = 0.0
	_last_range = range_to_her
	# `PURSUIT_MIN_NOTICE` is the floor under it, so a chase can never be over before it was a
	# threat: a player already running when it lunges would otherwise shake off a thing that never
	# got to say what it was.
	if _outrun_for >= Tuning.PURSUIT_SHAKEN_OFF and chase_age() >= Tuning.PURSUIT_MIN_NOTICE:
		gave_up = true
		_be_done()
		return
	# Straight at her, and no faster than its own speed: the contract is the speed, so nothing
	# here may quietly exceed it.
	var step := minf(def.pursue_speed * delta, range_to_her)
	if is_telegraphing():
		# **It closes to the stand-off, holds it, and lunges when she reaches it.** The lunge is
		# fired by *her* rather than by the clock, whichever comes first — see `_lunged`.
		if range_to_her <= standoff:
			_lunged = true
		else:
			step = minf(step, range_to_her - standoff)
	position += _heading * step
	# Ground covered, not ground gained: backing off is still moving, and the bob is driven by
	# distance so that a thing holding its ground still reads as alive.
	_path_travelled += absf(step)

## How far along its route this instance has got, so streaming it out and back in can resume it
## instead of rewinding it. See `EventManager._stream_in`.
func path_travelled() -> float:
	return _path_travelled

## How fast and which way this thing is actually travelling, in px/s.
##
## Asked by `EventManager._warn_about_the_ground_she_is_on`, which has to know whether a lethal
## thing is coming *at her* rather than merely near her — walking orthogonally away from a cyclist
## must take the mark down, because there is no way it can reach her.
##
## Zero while a pursuer is telegraphing, and that is the interesting case rather than an omission:
## it is holding its stand-off, so it is not closing, and a mark that said otherwise would be
## warning her about a thing that is deliberately waiting.
func travel_velocity() -> Vector2:
	if is_finished or is_leaving:
		return Vector2.ZERO
	if def.pursues:
		if is_waiting() or is_telegraphing():
			return Vector2.ZERO
		return _heading * def.pursue_speed
	if def.mobile and def.speed > 0.0 and path.size() > 1 and not is_telegraphing_still():
		return _heading * def.speed
	return Vector2.ZERO

## Puts an instance back where a previous incarnation of the same plan had got to. Restores the
## age as well as the distance, so the telegraph, the pulse phase and the duration all continue
## rather than starting again — an event that streams in and out must not become immortal by
## being visited twice.
func resume(from_age: float, from_travelled: float) -> void:
	if from_age <= 0.0:
		return
	age = from_age
	_path_travelled = from_travelled
	if def.mobile and path.size() > 1:
		_advance_along_path(0.0)

# ------------------------------------------------------------------ the flock ---
# **A flock drawn as one picture repeated is a flock that freezes.** Offsets derived from the
# instance's own position keep the shape from boiling between frames, which is right for a still and
# is exactly what stops the birds ever moving apart; a single `rise` term that reaches 1.0 at the
# end of the telegraph and then holds sends the flock up in one movement and hangs it in the air,
# motionless, for the whole burst that is supposed to *be* the event.
#
# So each bird is its own body: its own place on the pavement, its own heading, its own speed, its
# own height, its own wingbeat, and its own contribution to the excitement. Three things follow and
# each is load-bearing:
#
# - **The excitement is still a pure query, and it is now a query over eleven sources.** `Baby` asks
#   the world, the world sums `contribution_at()`, and this one sums over its birds — which is the
#   invariant working exactly as written rather than an exception to it. It is also what makes the
#   flock *dangerous* in the way a route-planning game can use: the middle of it stacks four or five
#   overlapping fields and the edge of it stacks one, so walking round it is cheap and walking
#   through it is the most expensive thing on an act I pavement.
# - **The birds stay inside `flock_spread` of the middle**, which is what keeps the telegraph
#   fairness contract true. The contract is stated over `outer_radius` from the instance's own
#   position; `flock_spread + _bird_outer()` is `outer_radius`, so the union of eleven moving fields
#   is a subset of the one disc `Tuning.validate_event` checked. Widening the wheel without shrinking
#   the per-bird radius would quietly move the field the contract was written about.
# - **They wheel rather than fly straight.** A bird that flies straight leaves, and a flock that
#   leaves is a flock that is over — so being over is said with `is_leaving`, and only then do they
#   all pick the same direction.

## One bird. Deliberately not a node: eleven Node2Ds per flock, y-sorted against a city, to draw
## eleven 18px sprites that are always within 60px of each other, is a great deal of tree for a
## picture that one `_draw()` produces correctly. `RefCounted` rather than `Node` so it cannot leak.
class Bird extends RefCounted:
	## Where it is on the ground plane, relative to the flock's own origin.
	var at := Vector2.ZERO
	## How far off that ground, in px. Zero while it is standing on the pavement.
	var lift := 0.0
	var heading := Vector2.RIGHT
	var speed := 0.0
	## Radians per second, signed. What makes it wheel instead of flying out of its own event.
	var turn := 0.0
	## How high this one goes, and how fast it gets there.
	var ceiling := 0.0
	var climb := 0.0
	## Wingbeats per second, and where in one it currently is.
	var beat := 0.0
	var phase := 0.0

var _flock: Array[Bird] = []

## How fast a bird crosses the ground once it is up, and how slowly it shuffles before it is.
const BIRD_FLIGHT_SPEED := 96.0
const BIRD_GROUND_SPEED := 7.0
## How much faster a bird that is getting out of here goes than one that is wheeling.
const BIRD_DEPARTURE_GAIN := 2.1

## Scatters the flock across the pavement it is standing on.
##
## Seeded from the instance's own position rather than from an RNG, and that is not laziness: the
## determinism invariant says nothing gameplay-relevant may call the global `randi()`, and the day's
## RNG is not reachable from here — nor should it be, since streaming this event out and back in
## would then consume from it twice and move every event planned after it. A hash of where it stands
## gives the same flock every time the same flock is built, which is the property that matters.
func _build_the_flock() -> void:
	_flock.clear()
	var count := def.flock_size
	for i in count:
		var bird := Bird.new()
		# Spread round the middle rather than scattered independently, so eleven birds read as a
		# flock rather than as eleven birds who happen to be near each other.
		var angle := TAU * (float(i) + 0.35 * _flock_roll(i, 1)) / float(count)
		var reach := def.flock_spread * (0.3 + 0.7 * _flock_roll(i, 2))
		bird.at = Vector2(cos(angle), sin(angle) * GROUND_SQUASH) * reach
		bird.heading = Vector2.from_angle(TAU * _flock_roll(i, 3))
		bird.speed = BIRD_GROUND_SPEED
		# Half of them wheel each way, or the flock rotates as a body and reads as a carousel.
		bird.turn = (1.2 + 1.4 * _flock_roll(i, 4)) * (1.0 if i % 2 == 0 else -1.0)
		bird.ceiling = 20.0 + 34.0 * _flock_roll(i, 5)
		bird.climb = 34.0 + 40.0 * _flock_roll(i, 6)
		bird.beat = 6.0 + 5.0 * _flock_roll(i, 7)
		bird.phase = TAU * _flock_roll(i, 8)
		_flock.append(bird)

## The oblique view: a circle on the ground is drawn as an ellipse, so the flock's footprint is
## squashed on Y exactly as every shadow in the game is.
const GROUND_SQUASH := 0.55

## A deterministic 0..1 from the flock's own position, its index and a salt. One salt per property,
## or every bird's speed would be a function of its own heading.
func _flock_roll(index: int, salt: int) -> float:
	var mixed := int(global_position.x) * 73856093 + int(global_position.y) * 19349663 \
			+ index * 83492791 + salt * 2971215073
	return float(absi(mixed) % 4096) / 4096.0

## Steps every bird. Three phases, and they are the whole event: **on the pavement** while it
## telegraphs, which is the part she can see from down the street and walk around; **up and
## wheeling** for the duration, which is the part that costs; and **away** once it is over.
func _fly_the_flock(delta: float) -> void:
	if _flock.is_empty():
		return
	var grounded := is_telegraphing()
	for bird in _flock:
		bird.phase += bird.beat * TAU * delta
		if grounded:
			# Pecking about. It has to move — a bird standing perfectly still is the bug being
			# fixed, one phase earlier — but slowly enough that the flock is plainly still on the
			# ground and plainly still avoidable.
			bird.speed = BIRD_GROUND_SPEED
			bird.heading = bird.heading.rotated(bird.turn * 0.5 * delta)
			bird.lift = 0.0
		elif is_leaving:
			# Everybody the same way now, and climbing hard. What is over says so by leaving, and a
			# flock that was still wheeling would read as still happening.
			bird.heading = _steer(bird.heading, _heading, BIRD_TURN_IN, delta)
			bird.speed = move_toward(bird.speed, BIRD_FLIGHT_SPEED * BIRD_DEPARTURE_GAIN,
					260.0 * delta)
			bird.lift += bird.climb * delta
		else:
			bird.heading = bird.heading.rotated(bird.turn * delta)
			bird.speed = move_toward(bird.speed, BIRD_FLIGHT_SPEED, 320.0 * delta)
			bird.lift = move_toward(bird.lift, bird.ceiling, bird.climb * delta)
			# Turned back before the edge of its own event, not at it. A bird's own wheel is wider
			# than the flock at every speed either of them wants, so without this they simply fly
			# out of the field they are supposed to be, and take the fairness contract with them.
			#
			# **From half way out** rather than from the boundary, because a turn is not free: at
			# `BIRD_FLIGHT_SPEED` and `BIRD_TURN_IN` the tightest circle a bird can fly has a radius
			# of about 21px, so a bird that is still heading outwards when it reaches the edge is
			# already outside by the time it has come round. Starting at half the spread leaves it
			# the room the turn costs.
			if bird.at.length() > def.flock_spread * 0.5:
				bird.heading = _steer(bird.heading, -bird.at.normalized(), BIRD_TURN_IN, delta)
		bird.at += bird.heading * bird.speed * Vector2(1.0, GROUND_SQUASH) * delta
		if not is_leaving and bird.at.length() > def.flock_spread:
			# The steering above is what a bird turning back *looks* like; this is the line that
			# makes it a **guarantee**, and the fairness contract needs one rather than a tendency:
			# `_bird_outer()` is `outer_radius - flock_spread` precisely so that a bird at the rim
			# reaches exactly as far as the event was validated to. Steering from half way out means
			# it shaves a pixel or two when it fires at all, so nothing visible rides on it.
			bird.at = bird.at.normalized() * def.flock_spread

## Turns `heading` toward `wanted` at up to `rate` radians a second.
##
## **Rotating rather than interpolating, and that is not a style choice.** The first version was
## `heading.lerp(wanted, k)`, which cannot turn a vector round: interpolating between a unit vector
## and its opposite runs *down the same line* to zero and back out the way it came, so normalising
## the result gives the heading it started with. A bird flying directly out of its own flock was
## therefore the one case the containment could not fix, and it is the case that matters — it flew
## 202px out of a 62px wheel while the code that was supposed to hold it ran every frame.
func _steer(heading: Vector2, wanted: Vector2, rate: float, delta: float) -> Vector2:
	var difference := angle_difference(heading.angle(), wanted.angle())
	return heading.rotated(clampf(difference, -rate * delta, rate * delta))

## How hard a bird can turn, in radians a second. Fast enough that the wheel it flies fits inside
## the flock — see the note in `_fly_the_flock` — and slow enough to read as a bird banking.
const BIRD_TURN_IN := 4.6

## The radius one bird emits over. The rest of the field is the room the flock takes up: a bird at
## the far edge of the wheel reaches exactly as far as the event says it does and no further.
func _bird_outer() -> float:
	return maxf(def.inner_radius + 1.0, def.outer_radius - def.flock_spread)

# --------------------------------------------------------------- going away ---
# **Nothing vanishes while you are looking at it.** An event that ends by `_finish()` wherever it
# happens to be standing ends, for the two shortest-lived rows in the game, directly in front of
# her: the cat's route is one street wide and ends in the open, and the pigeons hang in the air for
# a fifth of a second. The end of an event is a **departure**, not a deletion.
#
# What is deliberately *not* here: a fade. A thing that fades out is still a thing that disappears,
# and it disappears in a way nothing in the world could explain. The cat runs on, the flock climbs
# away, the dog that lost interest trots off — and each of them is gone because it left.

## True once it has stopped being an event and is only getting out of shot. It emits nothing, it
## cannot end the day, and it carries no cue: whatever it was, it is over.
var is_leaving := false
var _leaving_for := 0.0

## The most it may spend on the way out. A backstop rather than a timing: with no player to be out
## of sight of — a headless rig, a streamed-out day — nothing else would ever end it.
const LEAVING_GIVES_UP := 6.0

## The end of an event: it leaves if it has anywhere to go, and stops existing if it has not.
##
## Two things never leave, and both would break something that reads the finishing position. An
## event with a `spawns_on_finish` stops **where the thing it leaves belongs** — a fire engine's
## fire is at the building, not two streets past it. And anything with no departure speed has no
## way to go anywhere; a café that closes has always simply been over.
func _be_done() -> void:
	if is_finished or is_leaving:
		return
	if def.departure_speed() <= 0.0 or def.spawns_on_finish != "":
		_finish()
		return
	is_leaving = true
	_leaving_for = 0.0
	# Something on a route carries on the way it was going; anything else goes away from her,
	# which is the only direction a flushed flock or a dog that has lost interest can mean.
	if not (def.mobile and path.size() > 1) and player_at != Vector2.INF \
			and not global_position.is_equal_approx(player_at):
		_heading = (global_position - player_at).normalized()

func _leave(delta: float) -> void:
	_leaving_for += delta
	var step := def.departure_speed() * delta
	position += _heading * step
	_path_travelled += step
	var gone := player_at != Vector2.INF \
			and global_position.distance_to(player_at) > Tuning.OUT_OF_SIGHT
	if gone or _leaving_for >= LEAVING_GIVES_UP:
		_finish()

func _advance_along_path(delta: float) -> void:
	# Movement starts when the telegraph does, so an approaching siren is audible and
	# visible while it is still far away — which is what makes the warning usable.
	_path_travelled += def.speed * delta
	var remaining := _path_travelled
	# **A beat rather than a journey.** The distance covered is folded back and forth over
	# the route, so the same walk up and down happens for ever and the end of the path is never
	# reached — which is what stops a fixture that moves from departing like something that was
	# passing through. Folded rather than reset, so streaming it out and back in resumes it mid-beat
	# exactly as `resume()` promises.
	var back := false
	if def.paces:
		var beat := _path_length()
		if beat <= 0.0:
			return
		var cycle := fmod(_path_travelled, beat * 2.0)
		back = cycle > beat
		remaining = beat * 2.0 - cycle if back else cycle
	for i in range(1, path.size()):
		var segment := path[i] - path[i - 1]
		var length := segment.length()
		if remaining <= length:
			_heading = segment.normalized()
			# Facing the way it is actually walking. Without this a man pacing a pavement moons
			# along it backwards for half of every beat, which is worse than not moving at all.
			if back:
				_heading = -_heading
			position = path[i - 1] + segment.normalized() * remaining
			return
		remaining -= length
	position = path[path.size() - 1]
	if def.paces:
		return
	# A mobile event that has driven off the end of its route is done, whatever its
	# nominal duration says — and it keeps going until it is out of sight, rather than stopping
	# dead on the pavement she is walking down. See "going away" above.
	_be_done()

## The length of the whole route, in px.
func _path_length() -> float:
	var total := 0.0
	for i in range(1, path.size()):
		total += path[i].distance_to(path[i - 1])
	return total

func _has_expired() -> bool:
	if is_waiting():
		# It has not happened yet, and it is not going to until she walks up to it.
		return false
	return def.duration > 0.0 and chase_age() >= def.telegraph_time + def.duration

func _finish() -> void:
	if is_finished:
		return
	is_finished = true
	EventBus.event_finished.emit(self)
	finished.emit(self)

# ------------------------------------------------------------------ emission ---

## True while the event is visible but has not yet reached full strength.
##
## A pursuer has a second way out of it, and it is the one that usually happens: `_lunged`, when
## she walked up to the stand-off before the clock ran out.
func is_telegraphing() -> bool:
	if is_waiting():
		return false
	if _lunged:
		return false
	return chase_age() < def.telegraph_time

## True for a pursuer that is only standing there, because she has not come near enough for it to
## take an interest. It emits at full strength, it is not lethal, and it does not move.
## See `EventDef.pursues_within`.
func is_waiting() -> bool:
	return def.pursues_within > 0.0 and _noticed_at == INF

## How long this has been *happening*, which is not always how long it has existed.
##
## For everything in the catalogue but one it is the age. For a pursuer that waits, the clock starts
## when it notices her — a telegraph spent at dawn, four streets away, is not a notice, and
## `telegraph_time` and `duration` are both promises about the encounter rather than about the day.
func chase_age() -> float:
	if def.pursues_within <= 0.0:
		return age
	return 0.0 if _noticed_at == INF else age - _noticed_at

## Current peak intensity at the centre, after the telegraph damping and the pulse envelope.
func current_intensity() -> float:
	if is_finished or is_leaving:
		# On the way out it is scenery. Emitting while it goes would mean the excitement of an
		# event trailing after her for as long as it took the thing to get off screen.
		return 0.0
	var value := def.intensity
	if not is_equal_approx(def.intensity_ramp, 1.0) and def.duration > 0.0:
		var through := clampf((age - def.telegraph_time) / def.duration, 0.0, 1.0)
		value *= lerpf(1.0, def.intensity_ramp, through)
	if def.pulse_period > 0.0:
		# 0.25..1.0, so a pulsing event is never entirely silent between beats.
		var phase := TAU * age / def.pulse_period
		value *= 0.25 + 0.75 * (0.5 - 0.5 * cos(phase))
	# The damping says *this has not started yet*. A pursuer that waits has been standing there
	# since she came round the corner — what has not started is the lunge, not the man — so its
	# notice is the only telegraph in the game that does not quieten what it is warning about.
	if is_telegraphing() and def.pursues_within <= 0.0:
		value *= Tuning.TELEGRAPH_INTENSITY_FRACTION
	return value

## Excitement per second this event contributes at a point.
func contribution_at(world_position: Vector2) -> float:
	if is_finished or is_leaving:
		return 0.0
	# A city-wide source has no falloff: there is nowhere in the city it does not reach.
	if def.city_wide:
		return current_intensity()
	if not _flock.is_empty():
		return _flock_contribution_at(world_position)
	return Tuning.falloff(global_position.distance_to(world_position),
			current_intensity(), def.inner_radius, def.outer_radius)

## A flock is its birds, summed.
##
## The same shape as `City.total_excitement_at` one level down: nothing is pushed anywhere, the
## sources compose by plain addition, and there is no ordering to get wrong. Each bird carries an
## equal share of the event's intensity over a radius that leaves room for the wheel, so the middle
## of the flock — where four or five fields overlap — comes out at about what the event says it is
## and the edge of it at a fraction. That gradient is the whole reason to do it this way: the price
## of a flock should depend on whether you walked through it or round it, and one disc centred on
## nothing in particular cannot say that.
func _flock_contribution_at(world_position: Vector2) -> float:
	var share := current_intensity() / float(_flock.size())
	var outer := _bird_outer()
	var total := 0.0
	for bird in _flock:
		total += Tuning.falloff((global_position + bird.at).distance_to(world_position),
				share, def.inner_radius, outer)
	return total

## True when a point is inside the radius that ends the day, for a hard-fail event that is
## no longer merely telegraphing.
func is_lethal_at(world_position: Vector2) -> bool:
	if is_finished or is_leaving or is_waiting() or not def.hard_fail or is_telegraphing():
		return false
	return global_position.distance_to(world_position) <= def.inner_radius

# ------------------------------------------------------------------ drawing ---

func _draw() -> void:
	if is_finished:
		return
	# **A moving event has to look like it is moving.** Without a gait a dog walker at 32px/s — a
	# tile a second, against the player's three — slides along without a leg moving and reads as
	# parked, which gets reported as *the dog walkers are not moving* when the movement is fine.
	#
	# A bob rather than a stride, because the art has legs drawn into it and a sprite cannot swing
	# its own. Driven by **distance covered**, not by time, so it is the movement itself that shows:
	# something stopped is still, and something fast bobs faster.
	var bob := 0.0
	if def.pursues or is_leaving:
		bob = -absf(sin(_path_travelled * BOB_PER_PX)) * BOB_HEIGHT
	elif def.mobile and def.speed > 0.0 and path.size() > 1 and not is_telegraphing_still():
		bob = -absf(sin(_path_travelled * BOB_PER_PX)) * BOB_HEIGHT
	draw_set_transform(Vector2(0.0, bob), 0.0, Vector2.ONE)
	_draw_body()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_mark()

## Whether it is holding still through its telegraph — a crouching cat is not walking.
func is_telegraphing_still() -> bool:
	return def.still_while_telegraphing and is_telegraphing()

## The bob a moving event rides on: a stride's worth of lift, once per stride's worth of ground.
## Sized against a walking pace rather than a running one — 34px is roughly a step.
const BOB_PER_PX := PI / 34.0
const BOB_HEIGHT := 2.5

# ------------------------------------------------------------------ the mark ---
# **Nothing draws a field.** A ring communicates a falloff radius, which is a number, and a number
# is not a threat. What stands over an entity instead is a small mark, and it earns its place by
# three rules.

## How far above the entity the mark floats, and how big it is at full strength.
const MARK_HEIGHT := 44.0
const MARK_WIDTH := 15.0
const MARK_FLASHES_PER_SECOND := 3.0

## Whether this event is worth a mark at all.
##
## **The mark is raised by what a thing costs, and by nothing else.** The rule is the player's own
## expectation, stated so a test can hold it: **if A is marked and B is not, A costs more than B.**
## `EventDef.walk_through_cost()` is the order and `Tuning.MARK_WORTH_A_DETOUR` is where the line
## falls; `tests/test_danger.gd` asserts the monotonicity over the whole catalogue, so a row cannot
## earn a mark by pulsing.
##
## **The trap is a rule like *danger that changes over time*** — lethal, telegraphing, swelling, or
## pulsing fast enough to be timed. Every clause of that is a true statement about a thing and
## **none of them is a statement about how bad it is**, so the marked set and the danger come apart:
## a fire engine (+115 to walk through) carries nothing while a burning building at half the price
## carries a caret, because one has a pulse and one does not; and a leaf blower is marked over the
## dog walker beside it because its beat is 4.0s rather than 8.0s.
##
## **A cue that marks everything says nothing**, so the cheap end of the street is left alone — a
## café, a delivery van, a poster crew, a burnt-out shell. And the mark **breathes** with current
## emission, which is the one thing a ring does that a symbol does not get for free.
##
## What is given up, and it is a decision rather than an oversight: **a crouching cat (+20) loses
## its caret.** The crouch is its own silhouette and the vocabulary's first rule is that the entity
## carries it.
func wants_a_mark() -> bool:
	if is_finished or is_leaving or def.city_wide:
		# A floor under the whole city has nothing to stand over. That is the HUD's job.
		return false
	if def.kind == GameEnums.EventKind.AMBIENT:
		# A permanent feature of a fixed map never appears, so there is no moment to mark. The
		# same reason the fairness contract exempts it.
		return false
	return def.hard_fail or def.walk_through_cost() >= Tuning.MARK_WORTH_A_DETOUR

## How hard the mark is breathing, 0..1, from what the event is emitting right now.
##
## **This is the one thing the ring did that a symbol does not get for free**, and it is
## load-bearing: a pulsing event can be timed and slipped past between beats, and a mark that
## sat there at a constant size would turn the pulse envelope from something to play against
## into something random.
func mark_swell() -> float:
	if def.intensity <= 0.0:
		return 1.0
	return clampf(current_intensity() / def.intensity, 0.0, 1.0)

## What colour the mark is, and it means exactly one thing: **how bad this is.**
##
## **Colour is the wrong channel for a *phase*.** Amber while telegraphing and red once live is a
## good sentence and a cue nobody can read, because of **streaming**: `EVENT_STREAM_RADIUS` is 900px
## and no telegraph in the catalogue is longer than four seconds, so all but the `AHEAD_OF_PLAYER`
## rows finish telegraphing before they are anywhere near the screen. In play that makes amber mean
## *near* and red mean *far*, which is a colour carrying no information and being read as something
## else.
##
## So the colour is the scale and the **flash** — visible whether or not she was there when the
## event started — is what says it has not happened yet. See `_draw_mark`.
func mark_colour() -> Color:
	return Palette.MARK_LETHAL if def.hard_fail else Palette.MARK_COSTLY

## A caret over anything worth looking at, breathing with what it is currently emitting.
##
## What is deliberately *not* here: any drawing of where the danger reaches. Nothing draws a field.
func _draw_mark() -> void:
	if not wants_a_mark():
		return
	# **The flash is the phase**, and the only channel that can carry it: it flashes while
	# telegraphing — *this has not happened yet* — and is steady once it has. The colour cannot do
	# this, because a telegraph is usually over before the event is on screen; a flash is a property
	# of the mark rather than of a moment she had to be present for.
	if is_telegraphing() and fmod(age * MARK_FLASHES_PER_SECOND, 1.0) > 0.55:
		return

	var swell := mark_swell()
	# Never all the way to nothing: between beats the mark shrinks, it does not vanish, or a
	# pulsing event would read as flickering in and out of existence.
	var scale := 0.55 + 0.45 * swell
	var at := Vector2(0.0, -(MARK_HEIGHT + 10.0 * swell))
	Sprites.draw_caret(self, at, MARK_WIDTH * scale, mark_colour())
	if def.hard_fail:
		# Doubled, so lethal reads at a glance and never has to be told apart by hue.
		Sprites.draw_caret(self, at - Vector2(0.0, MARK_WIDTH * scale * 0.85),
				MARK_WIDTH * scale, mark_colour())

func _draw_body() -> void:
	match def.look:
		EventDef.Look.CAT:
			_draw_cat()
		EventDef.Look.YELLER:
			_draw_simple(YELLER, 9.0)
		EventDef.Look.DOG_WALKER:
			_draw_dog_walker()
		EventDef.Look.CAFE:
			_draw_cafe()
		EventDef.Look.DELIVERY_VAN:
			_draw_simple(DELIVERY_VAN, 20.0)
		EventDef.Look.BUSKER:
			_draw_simple(BUSKER, 9.0)
		EventDef.Look.ROADWORKS:
			_draw_spread(BARRIER_SEGMENT, BARRIER_END)
		EventDef.Look.FIRE_ENGINE:
			_draw_vehicle(FIRE_ENGINE, FIRE_ENGINE_END, 26.0)
		EventDef.Look.BURNING_BUILDING:
			_draw_fire()
		EventDef.Look.BURNT_SHELL:
			_draw_spread(RUBBLE)
		EventDef.Look.LOOSE_DOG:
			_draw_loose_dog()
		EventDef.Look.STALL:
			_draw_spread(STALL)
		EventDef.Look.LEAF_BLOWER:
			_draw_simple(LEAF_BLOWER, 8.0)
		EventDef.Look.BIRDS:
			_draw_birds()
		EventDef.Look.CYCLIST:
			_draw_simple(CYCLIST, 12.0)
		EventDef.Look.ICE_CREAM_VAN:
			_draw_simple(ICE_CREAM_VAN, 20.0)
		EventDef.Look.LORRY:
			_draw_simple(LORRY, 26.0)
		EventDef.Look.CHARGING_DOG:
			_draw_simple(CHARGING_DOG, 13.0)
		EventDef.Look.POLICE_CAR:
			_draw_vehicle(POLICE_CAR, POLICE_CAR_END, 19.0)
		EventDef.Look.POSTER_CREW:
			_draw_simple(POSTER_CREW, 9.0)
		EventDef.Look.CHECKPOINT:
			_draw_spread(CHECKPOINT_BLOCK)
		EventDef.Look.UNMARKED_VAN:
			_draw_simple(UNMARKED_VAN, 21.0)
		EventDef.Look.ROBBER:
			_draw_robber()
		EventDef.Look.RIOT_VAN:
			_draw_simple(RIOT_VAN, 23.0)
		EventDef.Look.ARMY_TRUCK:
			_draw_vehicle(ARMY_TRUCK, ARMY_TRUCK_END, 26.0)
		EventDef.Look.BARRICADE:
			_draw_spread(BARRICADE_PILE)
		EventDef.Look.PROTEST:
			_draw_protest()
		EventDef.Look.FIREFIGHT:
			_draw_firefight()
		EventDef.Look.NONE:
			pass

## A shadow and a sprite, facing the way it is going. What most looks are, and having it once is
## what keeps a dozen near-identical three-line functions from existing.
## A vehicle, drawn from whichever of its four sides is facing the camera.
##
## **One side-on sprite mirrored east and west is not enough**: a patrol car heading north drives up
## the street showing its flank. The crowd's cars have an end-on view for the same reason
## (`car_end_body.svg`, with the note that at that angle the front and the back of a car are the
## same shape).
##
## **Each row keeps its own end-on picture rather than borrowing the crowd's.** One picture per row
## bites hardest here: the whole content of a vehicle row is *which* vehicle it is, and a police car
## that becomes a generic saloon the moment it turns north loses the one silhouette the screen-edge
## badge exists to show, at the moment it starts coming towards her.
##
## The badge itself keeps the **side** view, which is deliberate: an icon is read at 40px against a
## row of other icons, and a vehicle end-on is a box at any size.
func _draw_vehicle(side: Texture2D, end: Texture2D, shadow: float) -> void:
	Sprites.draw_shadow(self, Vector2.ZERO, shadow)
	if absf(_heading.y) > absf(_heading.x):
		Sprites.draw_standing(self, end, Vector2.ZERO, Vector2.ZERO, false)
		return
	Sprites.draw_standing(self, side, Vector2.ZERO, Vector2.ZERO, _heading_is_west())

func _draw_simple(texture: Texture2D, shadow: float) -> void:
	Sprites.draw_shadow(self, Vector2.ZERO, shadow)
	Sprites.draw_standing(self, texture, Vector2.ZERO, Vector2.ZERO, _heading_is_west())

## The dog, and the lead it is no longer on.
##
## Read against `_draw_dog_walker()`, which draws the lead *taut between two bodies*: that is
## the span it owns and the reason to cross the street. Here the same lead trails on the ground
## behind one body, and the difference between the two pictures is the whole event.
func _draw_loose_dog() -> void:
	var behind := Vector2(26.0 if _heading_is_west() else -26.0, 0.0)
	Sprites.draw_shadow(self, Vector2.ZERO, 9.0)
	# On the ground and slack, not held up at hip height. Nobody is holding it.
	draw_line(Vector2(0.0, -8.0), behind + Vector2(0.0, -2.0), Palette.OUTLINE, 2.0)
	Sprites.draw_standing(self, DOG, Vector2.ZERO, Vector2.ZERO, _heading_is_west())

## Every bird, drawn where it actually is.
##
## There is no `rise` term and no shared phase any more — see "the flock" above. What is left here
## is only the picture: each bird on its own beat, each with a shadow on the pavement under it that
## shrinks and fades as it climbs, and the whole flock painted back to front so a bird in front
## overlaps the one behind rather than fighting it for the same pixel every frame.
##
## The shadow is what sells the height, and it is the reason a bird 40px up does not simply read as
## a bird standing 40px further north.
func _draw_birds() -> void:
	var order: Array[int] = []
	for i in _flock.size():
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool: return _flock[a].at.y < _flock[b].at.y)
	for i in order:
		var bird := _flock[i]
		if bird.lift < BIRD_SHADOW_CEILING:
			# Smaller and fainter the higher it is, and gone by the time it is over the rooftops.
			var faded := 1.0 - bird.lift / BIRD_SHADOW_CEILING
			Sprites.draw_shadow(self, bird.at, 5.0 * faded)
		var wings := PIGEON if sin(bird.phase) >= 0.0 else PIGEON_DOWN
		if bird.lift <= 0.0:
			# Standing. The upstroke is a bird in flight, and a pavement full of them is a flock
			# that has already gone — which is the thing the telegraph exists to show her instead.
			wings = PIGEON_DOWN
		Sprites.draw_standing(self, wings, bird.at - Vector2(0.0, bird.lift),
				Vector2.ZERO, bird.heading.x < 0.0)

## How high a bird's shadow survives to. Roughly first-floor height: above it, there is nothing on
## the pavement to cast one onto that the player can see.
const BIRD_SHADOW_CEILING := 46.0

func _draw_cat() -> void:
	# Crouched while telegraphing, stretched out once it bolts. The crouch *is* the
	# telegraph, so the two silhouettes have to differ at a glance, not by a scale factor.
	var texture := CAT_CROUCHED if is_telegraphing() else CAT_RUNNING
	Sprites.draw_shadow(self, Vector2.ZERO, 7.0)
	Sprites.draw_standing(self, texture, Vector2.ZERO, Vector2.ZERO, _heading_is_west())

## Hood up and hands in the coat while he is only somewhere; leaning out over a forward leg once
## he has taken an interest.
##
## The same rule as the cat above, at the one row where reading it wrong ends the run: the two
## postures are the two states `EventDef.pursues_within` invented, and `is_waiting()` is exactly
## the line between them. What the player has to be able to see from an alley mouth is not "there
## is a man there" but *which of the two men that is* — so the change of posture happens on the
## frame he notices her, before the telegraph has finished and well before he moves.
func _draw_robber() -> void:
	var texture := ROBBER_WAITING if is_waiting() else ROBBER_LUNGING
	Sprites.draw_shadow(self, Vector2.ZERO, 9.0)
	Sprites.draw_standing(self, texture, Vector2.ZERO, Vector2.ZERO, _heading_is_west())

## Flames scaled by what the event is currently emitting, so a fire visibly roars.
func _draw_fire() -> void:
	var strength := 1.0
	if def.intensity > 0.0:
		strength = clampf(current_intensity() / def.intensity, 0.2, 1.0)
	Sprites.draw_shadow(self, Vector2.ZERO, 22.0)
	for i in 5:
		var offset := (i - 2.0) * 11.0
		var flicker := 1.0 + 0.25 * sin(age * 9.0 + i * 1.7)
		var height := (34.0 + i % 2 * 14.0) * strength * flicker
		Sprites.draw_standing(self, FLAME, Vector2(offset, 0.0), Vector2(18.0, height))

## A blocking object is drawn at exactly the width it obstructs, by repeating a segment
## across it. Anything else would be a lie about where the player can walk.
func _draw_spread(segment_texture: Texture2D, cap: Texture2D = null) -> void:
	var half := maxf(11.0, def.obstructs_radius)
	Sprites.draw_shadow(self, Vector2.ZERO, half * 0.9)
	var segment := segment_texture.get_size()
	var segments := maxi(1, ceili(half * 2.0 / segment.x))
	var width := half * 2.0 / segments
	for i in segments:
		Sprites.draw_standing(self, segment_texture,
				Vector2(-half + width * (i + 0.5), 0.0), Vector2(width, segment.y))
	if not cap:
		return
	for side in [-1.0, 1.0]:
		Sprites.draw_standing(self, cap, Vector2(side * half, 0.0))

## The tables, and the people at them.
##
## **Both halves have to be drawn**: the tables are what obstructs and the conversation is what it
## emits, so a café drawn as furniture alone is the loudest pleasant thing in act I looking like
## something somebody left out. The spread is `_draw_spread`'s, so the width is exactly the width in
## the way; the sitters are drawn *first* and a little behind, because the table is the part she
## cannot walk through and the picture has to agree with that.
##
## Alternate tables are mirrored, which turns a rank of clones into pairs facing each other — the
## same reason a spoiled park rolls a different def per cell.
func _draw_cafe() -> void:
	var half := maxf(11.0, def.obstructs_radius)
	Sprites.draw_shadow(self, Vector2.ZERO, half * 0.9)
	var segment := CAFE_TABLE.get_size()
	var segments := maxi(1, ceili(half * 2.0 / segment.x))
	var width := half * 2.0 / segments
	for i in segments:
		var at := Vector2(-half + width * (i + 0.5), -7.0)
		# The chair is drawn at one end of the table sprite and turns round with it.
		Sprites.draw_standing(self, CAFE_SITTER,
				at + Vector2(width * (0.26 if i % 2 == 1 else -0.26), 0.0))
	for i in segments:
		Sprites.draw_standing(self, CAFE_TABLE,
				Vector2(-half + width * (i + 0.5), 0.0), Vector2(width, segment.y), i % 2 == 1)

## A rank of placards as wide as the ground it takes.
##
## The catalogue used to say of this row: *"one person's worth, because one person is what it
## draws… the art is the fix."* This is the fix, and the body follows it rather than the other way
## round — a protest that fills a square is the whole content of the event, and it could not have
## one until there was a picture of one.
##
## Two ranks rather than one, offset, so it reads as a crowd with depth instead of a queue; the
## back rank is drawn first and higher up the screen. Nothing here grows with `intensity_ramp` —
## the caret over it already breathes with what it is emitting, and a crowd that visibly recruits
## would be a second cue saying the same thing.
func _draw_protest() -> void:
	var half := maxf(11.0, def.obstructs_radius)
	Sprites.draw_shadow(self, Vector2.ZERO, half * 0.95)
	# Spaced off the body rather than off the sprite, so the rank ends where the ground it takes
	# ends. A crowd drawn at its own natural spacing overhangs its own body by most of a person,
	# which is the lie `_draw_spread` exists to avoid in the other direction.
	var across := maxi(2, roundi(half * 2.0 / (PROTESTER.get_size().x * 0.8)))
	var step := half * 2.0 / across
	for rank in 2:
		var back := rank == 0
		var lift := -14.0 if back else 0.0
		var shift := step * 0.5 if back else 0.0
		for i in across - (1 if back else 0):
			var x := -half + step * (i + 0.5) + shift
			Sprites.draw_standing(self, PROTESTER, Vector2(x, lift))

## People behind cover, shooting at each other. Not a building on fire, which is what it drew for
## fourteen milestones — the same five flames as `burning_building`, on the one event in the
## catalogue whose content is that there are *people* doing this.
##
## The flashes are drawn rather than authored, because a muzzle flash is a light and not an object,
## and they are timed off the pulse envelope so they land on the beat the meter is already moving
## on. Between beats there is nothing but two shapes behind sandbags, which is the point: it is a
## thing to time a run past, and `can_be_timed()` already says so.
func _draw_firefight() -> void:
	var half := maxf(11.0, def.obstructs_radius)
	Sprites.draw_shadow(self, Vector2.ZERO, half)
	var strength := 1.0
	if def.intensity > 0.0:
		strength = clampf(current_intensity() / def.intensity, 0.0, 1.0)
	for side in [-1.0, 1.0]:
		var at := Vector2(side * half * 0.62, 0.0)
		Sprites.draw_standing(self, GUNMAN, at, Vector2.ZERO, side > 0.0)
		# Sized off the current emission and jittered per side, so the two are never in step.
		var flare := strength * (0.6 + 0.4 * sin(age * 17.0 + side * 2.1))
		if flare <= 0.25:
			continue
		var muzzle := at + Vector2(side * 15.0, -12.0)
		draw_circle(muzzle, 3.0 + 4.0 * flare, MUZZLE_FLASH)
		draw_circle(muzzle, 1.5 + 2.0 * flare, Color.WHITE)

## A muzzle flash is a *light*, and it must not borrow the amber the danger vocabulary uses for its
## marks. Two things that mean different things must not share a constant, or a rebalance of one
## silently repaints the other.
const MUZZLE_FLASH := Color("e8b64a")

## The person, the dog, and the lead between them.
##
## The lead is drawn because it is the mechanic: what makes a dog walker worth crossing the
## street for is the span it owns, and a span you cannot see is a span you walk into. The dog
## leads on the side the walker is heading, so the pair reads as being dragged along.
func _draw_dog_walker() -> void:
	var reach := def.inner_radius * 0.8
	var to_the_dog := Vector2(-reach if _heading_is_west() else reach, 0.0)
	Sprites.draw_shadow(self, Vector2.ZERO, 8.0)
	Sprites.draw_shadow(self, to_the_dog, 9.0)
	# Slack in the middle, so it reads as a lead rather than as a bar.
	draw_line(Vector2(0.0, -26.0), to_the_dog + Vector2(0.0, -6.0), Palette.OUTLINE, 2.0)
	Sprites.draw_standing(self, PERSON, Vector2.ZERO, Vector2.ZERO, _heading_is_west())
	Sprites.draw_standing(self, DOG, to_the_dog, Vector2.ZERO, _heading_is_west())

## Which way a mobile event is travelling, for art that has a front and a back. A
## stationary event never flips.
func _heading_is_west() -> bool:
	return _heading.x < 0.0

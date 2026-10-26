class_name EventFlock
extends EventBehaviour
## **A flock drawn as one picture repeated is a flock that freezes.** Offsets derived from the
## instance's own position keep the shape from boiling between frames, which is right for a still and
## is exactly what stops the birds ever moving apart; a single `rise` term that reaches 1.0 at the
## end of the telegraph and then holds sends the flock up in one movement and hangs it in the air,
## motionless, for the whole burst that is supposed to *be* the event.
##
## So each bird is its own body: its own place on the pavement, its own heading, its own speed, its
## own height, its own wingbeat, and its own contribution to the excitement. Three things follow and
## each is load-bearing:
##
## - **The excitement is still a pure query, and it is now a query over eleven sources.** `Baby` asks
##   the world, the world sums `contribution_at()`, and this one sums over its birds — which is the
##   invariant working exactly as written rather than an exception to it. It is also what makes the
##   flock *dangerous* in the way a route-planning game can use: the middle of it stacks four or five
##   overlapping fields and the edge of it stacks one, so walking round it is cheap and walking
##   through it is the most expensive thing on an act I pavement.
## - **The birds stay inside `flock_spread` of the middle**, which is what keeps the telegraph
##   fairness contract true. The contract is stated over `outer_radius` from the instance's own
##   position; `flock_spread + bird_outer()` is `outer_radius`, so the union of eleven moving fields
##   is a subset of the one disc `Tuning.validate_event` checked. Widening the wheel without shrinking
##   the per-bird radius would quietly move the field the contract was written about.
## - **They wheel rather than fly straight.** A bird that flies straight leaves, and a flock that
##   leaves is a flock that is over — so being over is said with `is_leaving`, and only then do they
##   all pick the same direction.

## One bird. Deliberately not a node: eleven Node2Ds per flock, y-sorted against a city, to draw
## eleven 18px sprites that are always within 60px of each other, is a great deal of tree for a
## picture that one `EventLook.draw()` produces correctly. `RefCounted` rather than `Node` so it
## cannot leak.
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
	## This bird's own held eight-view sector — one per bird rather than one shared with the
	## instance's own `EventLook._view_sector`, since a flock is eleven bodies wheeling
	## independently rather than one actor with one facing. See `EventLook._select_view()`, the same
	## hold applied per bird by `FlockLook._draw_birds()`.
	var view_sector := 2

## Its birds, each its own body.
var birds: Array[Bird] = []

## How fast a bird crosses the ground once it is up, and how slowly it shuffles before it is.
const FLIGHT_SPEED := 96.0
const GROUND_SPEED := 7.0
## How much faster a bird that is getting out of here goes than one that is wheeling.
const DEPARTURE_GAIN := 2.1

## Scatters the flock across the pavement it is standing on.
##
## Seeded from the instance's own position rather than from an RNG, and that is not laziness: the
## determinism invariant says nothing gameplay-relevant may call the global `randi()`, and the day's
## RNG is not reachable from here — nor should it be, since streaming this event out and back in
## would then consume from it twice and move every event planned after it. A hash of where it stands
## gives the same flock every time the same flock is built, which is the property that matters.
func build() -> void:
	birds.clear()
	var count: int = event.def.flock_size
	for i in count:
		var bird := Bird.new()
		# Spread round the middle rather than scattered independently, so eleven birds read as a
		# flock rather than as eleven birds who happen to be near each other.
		var angle := TAU * (float(i) + 0.35 * _roll(i, 1)) / float(count)
		var reach: float = event.def.flock_spread * (0.3 + 0.7 * _roll(i, 2))
		bird.at = Vector2(cos(angle), sin(angle) * GROUND_SQUASH) * reach
		bird.heading = Vector2.from_angle(TAU * _roll(i, 3))
		bird.view_sector = EightDirection.nearest(bird.heading)
		bird.speed = GROUND_SPEED
		# Half of them wheel each way, or the flock rotates as a body and reads as a carousel.
		bird.turn = (1.2 + 1.4 * _roll(i, 4)) * (1.0 if i % 2 == 0 else -1.0)
		bird.ceiling = 20.0 + 34.0 * _roll(i, 5)
		bird.climb = 34.0 + 40.0 * _roll(i, 6)
		bird.beat = 6.0 + 5.0 * _roll(i, 7)
		bird.phase = TAU * _roll(i, 8)
		birds.append(bird)

## The oblique view: a circle on the ground is drawn as an ellipse, so the flock's footprint is
## squashed on Y exactly as every shadow in the game is.
const GROUND_SQUASH := 0.55

## A deterministic 0..1 from the flock's own position, its index and a salt. One salt per property,
## or every bird's speed would be a function of its own heading.
func _roll(index: int, salt: int) -> float:
	var mixed: int = int(event.global_position.x) * 73856093 + int(event.global_position.y) * 19349663 \
			+ index * 83492791 + salt * 2971215073
	return float(absi(mixed) % 4096) / 4096.0

## Steps every bird. Three phases, and they are the whole event: **on the pavement** while it waits
## for her and while it telegraphs, which is the part she can see from down the street and walk
## around; **up and wheeling** for the duration, which is the part that costs; and **away** once it
## is over.
##
## **The wait is on the ground with the telegraph, not in the air with the burst**, and the two are
## separate predicates: `is_waiting()` is false for a row with no trigger and `is_telegraphing()` is
## false *while* a row waits, so a flock asked only the second question would hold its whole wait in
## the air — birds flying in place over a pavement for as long as it takes her to walk up to them,
## which is the frozen-flock bug with a longer fuse.
func _fly(delta: float) -> void:
	if birds.is_empty():
		return
	var grounded: bool = event.is_waiting() or event.is_telegraphing()
	for bird in birds:
		bird.phase += bird.beat * TAU * delta
		if grounded:
			# Pecking about. It has to move — a bird standing perfectly still is the bug being
			# fixed, one phase earlier — but slowly enough that the flock is plainly still on the
			# ground and plainly still avoidable.
			bird.speed = GROUND_SPEED
			bird.heading = bird.heading.rotated(bird.turn * 0.5 * delta)
			bird.lift = 0.0
		elif event.is_leaving:
			# Everybody the same way now, and climbing hard. What is over says so by leaving, and a
			# flock that was still wheeling would read as still happening.
			bird.heading = _steer(bird.heading, event._heading, TURN_IN, delta)
			bird.speed = move_toward(bird.speed, FLIGHT_SPEED * DEPARTURE_GAIN,
					260.0 * delta)
			bird.lift += bird.climb * delta
		else:
			bird.heading = bird.heading.rotated(bird.turn * delta)
			bird.speed = move_toward(bird.speed, FLIGHT_SPEED, 320.0 * delta)
			bird.lift = move_toward(bird.lift, bird.ceiling, bird.climb * delta)
			# Turned back before the edge of its own event, not at it. A bird's own wheel is wider
			# than the flock at every speed either of them wants, so without this they simply fly
			# out of the field they are supposed to be, and take the fairness contract with them.
			#
			# **From half way out** rather than from the boundary, because a turn is not free: at
			# `FLIGHT_SPEED` and `TURN_IN` the tightest circle a bird can fly has a radius
			# of about 21px, so a bird that is still heading outwards when it reaches the edge is
			# already outside by the time it has come round. Starting at half the spread leaves it
			# the room the turn costs.
			if bird.at.length() > event.def.flock_spread * 0.5:
				bird.heading = _steer(bird.heading, -bird.at.normalized(), TURN_IN, delta)
		bird.at += bird.heading * bird.speed * Vector2(1.0, GROUND_SQUASH) * delta
		if not event.is_leaving and bird.at.length() > event.def.flock_spread:
			# The steering above is what a bird turning back *looks* like; this is the line that
			# makes it a **guarantee**, and the fairness contract needs one rather than a tendency:
			# `bird_outer()` is `outer_radius - flock_spread` precisely so that a bird at the rim
			# reaches exactly as far as the event was validated to. Steering from half way out means
			# it shaves a pixel or two when it fires at all, so nothing visible rides on it.
			bird.at = bird.at.normalized() * event.def.flock_spread

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
## the flock — see the note in `_fly()` — and slow enough to read as a bird banking.
const TURN_IN := 4.6

## The radius one bird emits over. The rest of the field is the room the flock takes up: a bird at
## the far edge of the wheel reaches exactly as far as the event says it does and no further.
func bird_outer() -> float:
	return maxf(event.def.inner_radius + 1.0, event.def.outer_radius - event.def.flock_spread)

## A tick of the flock while its event is neither leaving nor held: pecking on the ground through
## the wait and the telegraph, up and wheeling once it has gone up.
func step(delta: float) -> void:
	_fly(delta)

## A tick while its event is leaving: everybody the same way, climbing hard.
func step_leaving(delta: float) -> void:
	_fly(delta)

## Each live bird's own ground-plane offset from the event's origin.
func offsets() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for bird in birds:
		out.append(bird.at)
	return out

## Each live bird's own `heading * speed`, parallel to `offsets()`.
func velocities() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for bird in birds:
		out.append(bird.heading * bird.speed)
	return out

## Every bird's state, as plain values.
func save() -> Dictionary:
	var out: Array = []
	for bird in birds:
		out.append([bird.at, bird.lift, bird.heading, bird.speed, bird.turn, bird.ceiling,
				bird.climb, bird.beat, bird.phase, bird.view_sector])
	return {"birds": out}

## Puts back what `save()` gave: the birds a plan carried replace the ones `build()` scattered from
## its position, which `EventInstance._ready()` has run by the time a plan streams back in.
func restore(state: Dictionary) -> void:
	var saved: Array = state.get("birds", [])
	if saved.is_empty():
		return
	birds.clear()
	for one: Array in saved:
		var bird := Bird.new()
		bird.at = one[0]
		bird.lift = one[1]
		bird.heading = one[2]
		bird.speed = one[3]
		bird.turn = one[4]
		bird.ceiling = one[5]
		bird.climb = one[6]
		bird.beat = one[7]
		bird.phase = one[8]
		bird.view_sector = one[9]
		birds.append(bird)

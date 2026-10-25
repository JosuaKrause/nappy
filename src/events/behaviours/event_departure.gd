class_name EventDeparture
extends EventBehaviour
## **Going away.** Nothing vanishes while you are looking at it: an event that is over leaves
## (`Phase.LEAVING`) — the cat runs on, the flock climbs away, the dog that lost interest trots off —
## and is gone because it left, never by a fade. Every event is composed of one; it ticks only while
## its event is leaving, on its own call (`leave()`).
##
## A departure goes down a way it was given (day 12's park people walked out through the cordon's
## last gap), back along a man's trail to the vehicle that let him out (`EventOfficer`), or on the
## way it was going; **something solid straight ahead turns it onto a way out** planned over walkable
## ground from where she is now, rather than holding it against the solid in her view.

## The most it may spend on the way out. A backstop rather than a timing: with no player to be out
## of sight of — a headless rig, a streamed-out day — nothing else would ever end it. **Not a
## backstop for a departure she is standing next to** (`_must_clear_sight`).
const LEAVING_GIVES_UP := 6.0

## How long it has been leaving, in seconds.
var _leaving_for := 0.0
## **Whether `LEAVING_GIVES_UP` may not end it while she could still be watching**: a completed
## task's departure, which starts with her beside it, a car that drives (whose body she can stand
## against, so a departure can be held up beside her), a guard walking away from his barrier, who is
## in her view as he goes, the man a vehicle let out walking back to it, and a walk down a way it was
## given.
var _must_clear_sight := false
## The way `along()` gave, each point dropped as it is reached; the way planned on from its end, the
## same, and the tiles that one never enters; whether this departure walks one; and its pace, 0 for
## the row's own.
var _way := PackedVector2Array()
var _way_on := PackedVector2Array()
var _way_avoids := Rect2i()
var _walks_a_way := false
var _way_speed := 0.0

func _init() -> void:
	steps_each_tick = false

## The departure's start, the frame its event turns to `Phase.LEAVING` (`EventInstance._be_done()`):
## something on a route carries on the way it was going, anything else goes away from her — the
## only direction a flushed flock or a dog that has lost interest can mean.
func begin() -> void:
	_leaving_for = 0.0
	var def: EventDef = event.def
	var her: Vector2 = event.player_at
	if not (def.mobile and event.path.size() > 1) and her != Vector2.INF \
			and not event.global_position.is_equal_approx(her):
		event._heading = (event.global_position - her).normalized()
	if def.drives:
		# **A car leaves the way it can, and never vanishes beside her.** Every step of a departure
		# into her is refused, and a car that has a body she can stand against is gone only once she
		# could not be watching. An investigating car reaches here only at the end of its route,
		# which it drives on to once its man is back in, so it leaves the way it was going.
		_must_clear_sight = true
	if event._is_a_guard_leaving_his_barrier():
		# **He is in her view as he goes**, and **he walks off over walkable ground**, by the way
		# planned on from here, never in a straight line across a roof — and never through his own
		# band (`_way_avoids`): she usually stands on the side she lured him from, so the nearest
		# ground out of her sight lies straight through the concrete she cannot pass. On a band
		# whose far guard leaves too, his partner at the far post goes with him.
		_must_clear_sight = true
		_walks_a_way = true
		_way = PackedVector2Array()
		_way_on = PackedVector2Array()
		_way_avoids = event._tiles_under_the_band()
		event._send_the_far_guard_off()
	if not event._trail.is_empty():
		# **A man a vehicle let out walks back to it** rather than away from her, in her view as he
		# goes, so he is gone only at its door or out of her sight.
		_must_clear_sight = true

## **A departure that is a task's answer** (`EventInstance.leave_for_a_completed_task()`): she is
## standing right next to it when it starts, so it is held to her sight, and it turns away from her
## whichever way a beat it was pacing happened to be walking.
func for_a_completed_task() -> void:
	_must_clear_sight = true
	var her: Vector2 = event.player_at
	if her != Vector2.INF and not event.global_position.is_equal_approx(her):
		event._heading = (event.global_position - her).normalized()

## **Leaves down a way chosen for it** (`EventInstance.leave_along()`): walks `way`'s points in order
## at `speed` (0 keeps the row's own departure speed), then **plans the rest from where she is
## now** and walks that at the same pace, again each time it runs out, until she could not be
## watching — `Tuning.OUT_OF_SIGHT` from her. Steering straight away from her instead runs into
## walls and the city's edge. **It never ends at the way's last point**: that point was chosen out
## of her sight from where she was when the way was planned, and she may since have walked there.
## `avoid` is ground the rest planned past the way's end never enters, nor a step away from her: the
## cordon's park, whose grass is walkable and whose tape is a body rather than a tile. Answers
## whether it is now leaving along the way: not for something finished, parked, a spent guard or a
## guard leaving his barrier, or a row that ends rather than leaving (`spawns_on_finish`).
func along(way: PackedVector2Array, speed := 0.0, avoid := Rect2i()) -> bool:
	if event.is_finished or event.is_parked or event._guard_spent \
			or event._is_a_guard_leaving_his_barrier():
		return false
	_way_speed = speed
	if not event.is_leaving:
		event._be_done(false)
	if not event.is_leaving:
		_way_speed = 0.0
		return false
	_way = way.duplicate()
	_way_on = PackedVector2Array()
	_way_avoids = avoid
	_walks_a_way = true
	_must_clear_sight = true
	return true

## What is left of the way `along()` gave, in order; empty once it is walked, or for any other
## departure. The way planned on from its end is not part of it.
func way_left() -> PackedVector2Array:
	return _way

## How fast it walks away: a pace a way was given at, a guard leaving his barrier at the pace he
## chased at (a roadblock never travelled, so has no departure speed of its own), or the row's own
## departure speed.
func speed() -> float:
	if _way_speed > 0.0:
		return _way_speed
	if event._is_a_guard_leaving_his_barrier():
		return event.def.chase_speed()
	return event.def.departure_speed()

## One tick of the departure. **It is gone once she could not be watching**: past
## `Tuning.OUT_OF_SIGHT` from her, or — only for a departure not held to her sight, or with no
## player to be out of sight of — after `LEAVING_GIVES_UP`. A guard leaving his barrier is not gone:
## his instance goes back to being the barrier (`EventInstance._stand_as_the_barrier()`).
func leave(delta: float) -> void:
	_leaving_for += delta
	var step := speed() * delta
	var her: Vector2 = event.player_at
	if _walks_a_way:
		_walk_the_way(step)
	elif not event._trail.is_empty():
		if not event._walk_back(step):
			return
	else:
		var wanted: Vector2 = event._heading * step
		var moved: Vector2 = event._step(wanted)
		if moved.is_zero_approx() and not wanted.is_zero_approx() and her != Vector2.INF:
			_walks_a_way = true
			_way = PackedVector2Array()
			_way_on = PackedVector2Array()
			_walk_the_way(step)
		else:
			event.position += moved
			event._path_travelled += step if moved == wanted else moved.length()
	var gone: bool = her != Vector2.INF \
			and event.global_position.distance_to(her) > Tuning.OUT_OF_SIGHT
	var may_give_up: bool = not _must_clear_sight or her == Vector2.INF or gone
	if gone or (may_give_up and _leaving_for >= LEAVING_GIVES_UP):
		if event._is_a_guard_leaving_his_barrier():
			event._stand_as_the_barrier()
		else:
			event._finish()

## Clears a departure that has ended in its event standing again (a guard back as his barrier).
func reset() -> void:
	_walks_a_way = false
	_way_avoids = Rect2i()
	_leaving_for = 0.0
	_must_clear_sight = false

## **The rest of a way out from `at`, planned from where she is now** (`Navigator.way_out()`): the
## tile centres to the nearest tile it may stand on more than `Tuning.OUT_OF_SIGHT` and a tile from
## her, outside the ground it avoids, square steps only. Empty when none is found. The far guard at a
## band walks off from his post by the same search.
func way_out_from(at: Vector2) -> PackedVector2Array:
	return event._navigator.way_out(at, event.player_at, Tuning.OUT_OF_SIGHT, event._mover,
			_way_avoids)

## The ground a departure from here never steps onto (`along()`'s `avoid`, a guard's own band).
func avoids() -> Rect2i:
	return _way_avoids

## Puts its event where a walk (`Navigator.walk()`) ended, facing the way it last walked toward a
## point it did not reach, and counts the ground it covered.
func take_the_walk(walked: Navigator.Walked) -> void:
	if walked.heading != Vector2.ZERO:
		event._heading = walked.heading
	event.global_position = walked.at
	event._path_travelled += walked.travelled

## Walks `step` pixels of the way it was given; past its end, of a way planned on from where it
## stands (again each time one runs out while she could still be watching); and only where none is
## found, or one is walked to its end inside this step, away from her over ground it may walk.
func _walk_the_way(step: float) -> void:
	var left := _walk_points(false, step)
	if left <= 0.0:
		return
	var her: Vector2 = event.player_at
	if _way_on.is_empty() and her != Vector2.INF:
		_way_on = way_out_from(event.global_position)
	left = _walk_points(true, left)
	if left <= 0.0:
		return
	var away: Vector2 = event._heading
	if her != Vector2.INF and not event.global_position.is_equal_approx(her):
		away = (event.global_position - her).normalized()
	var moved := _step_clear_of_the_avoided(away * left)
	if moved.is_zero_approx() and her != Vector2.INF:
		# Straight away from her is a wall or the city's edge: along it, whichever way takes it
		# farther from her.
		for side: Vector2 in [away.orthogonal(), -away.orthogonal()]:
			var along_it := _step_clear_of_the_avoided(side * left)
			if not along_it.is_zero_approx() \
					and (event.global_position + along_it).distance_to(her) \
					> (event.global_position + moved).distance_to(her):
				moved = along_it
	if moved.is_zero_approx():
		return
	event._heading = moved.normalized()
	event.position += moved
	event._path_travelled += moved.length()

## The event's step (`EventInstance._step()`) of `delta_pos`, or none where it would end on the
## ground it avoids.
func _step_clear_of_the_avoided(delta_pos: Vector2) -> Vector2:
	var moved: Vector2 = event._step(delta_pos)
	if _way_avoids.has_point(event._map.world_to_tile(event.global_position + moved)):
		return Vector2.ZERO
	return moved

## Walks up to `step` pixels down the given way, or the planned one when `planned`, dropping each
## point as it is reached; answers how much of the step is left once that way is walked, 0 while it
## is not. **A way a solid now stands across is given up** where it stops, so a body put down after
## the way was chosen turns the walker rather than holding it in front of her.
func _walk_points(planned: bool, step: float) -> float:
	var points := _way_on if planned else _way
	var walked: Navigator.Walked = event._navigator.walk(event.global_position, points, step,
			event._mover)
	take_the_walk(walked)
	if walked.stopped:
		walked.points = PackedVector2Array()
	if planned:
		_way_on = walked.points
	else:
		_way = walked.points
	return walked.left

func save() -> Dictionary:
	return {"leaving_for": _leaving_for, "must_clear_sight": _must_clear_sight, "way": _way,
			"way_on": _way_on, "way_avoids": _way_avoids, "walks_a_way": _walks_a_way,
			"way_speed": _way_speed}

func restore(state: Dictionary) -> void:
	_leaving_for = float(state.get("leaving_for", 0.0))
	_must_clear_sight = bool(state.get("must_clear_sight", false))
	_way = state.get("way", PackedVector2Array())
	_way_on = state.get("way_on", PackedVector2Array())
	_way_avoids = state.get("way_avoids", Rect2i())
	_walks_a_way = bool(state.get("walks_a_way", false))
	_way_speed = float(state.get("way_speed", 0.0))

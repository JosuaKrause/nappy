extends RefCounted
## First-horn distance and time per car speed, before and after M191: the crowd used to watch a
## car for its horn and its strike over the same reach, `Tuning.CAR_ZEBRA_SIGHT` (200px), so a
## horn capped at 200px of travel arrived later than `CAR_HORN_TIME` (1.6s) for every car in
## `Tuning.CAR_SPEED`'s range — even the slowest, at 130px/s, already wants 208px. `Crowd.
## _physics_process` now checks the horn against its own watch (`Tuning.CAR_HORN_SIGHT`, 296px)
## instead, so the horn sounds the full `CAR_HORN_TIME` out at every speed in the city.
##
## **Pure arithmetic, not a live crowd.** `Crowd._horn()`'s own cap is `speed * CAR_HORN_TIME` and
## has no watch inside it at all — the watch is entirely the distance gate in
## `_physics_process` (`distance <= watch` before `_horn()` is even called), so the first-horn
## distance a car actually gets is `min(speed * CAR_HORN_TIME, watch)` and the time is that over
## speed. Computing it directly against the two watches is honest about the same formula the code
## uses rather than a second copy of it; `tests/test_crowd.gd`'s
## `_test_the_horn_watches_further_than_the_strike_does` is the probe for the code path itself,
## driving the real `Crowd._physics_process`.
##
## Run it with `tools/test.sh probes/m191_horn_watch.gd`.

## The speeds to print: both ends of `Tuning.CAR_SPEED`, and the two the M191 TODO entry itself
## measured (157 and 181px/s).
const _SPEEDS: Array[float] = [130.0, 140.0, 150.0, 157.0, 165.0, 175.0, 181.0, 185.0]

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const _HORN_CALLS := 200000

func run(t) -> void:
	print("\n== M191 — first horn distance and time, per car speed ==")
	var old_watch := Tuning.CAR_ZEBRA_SIGHT
	var new_watch := Tuning.CAR_HORN_SIGHT
	print("CAR_HORN_TIME %.2fs, old watch (CAR_ZEBRA_SIGHT) %.0fpx, new watch (CAR_HORN_SIGHT) %.0fpx"
			% [Tuning.CAR_HORN_TIME, old_watch, new_watch])

	print("\nBEFORE — horn shared the strike's own watch:")
	print("speed(px/s)  distance(px)  time(s)")
	var clipped_before := 0
	for speed in _SPEEDS:
		var wanted: float = speed * Tuning.CAR_HORN_TIME
		var distance: float = minf(wanted, old_watch)
		var clipped := distance < wanted - 0.01
		if clipped:
			clipped_before += 1
		print("%9.0f  %10.0f  %6.2f%s" % [speed, distance, distance / speed,
				"  (clipped short of CAR_HORN_TIME)" if clipped else ""])

	print("\nAFTER — horn gets its own, wider watch:")
	print("speed(px/s)  distance(px)  time(s)")
	var clipped_after := 0
	for speed in _SPEEDS:
		var wanted: float = speed * Tuning.CAR_HORN_TIME
		var distance: float = minf(wanted, new_watch)
		var clipped := distance < wanted - 0.01
		if clipped:
			clipped_after += 1
		print("%9.0f  %10.0f  %6.2f%s" % [speed, distance, distance / speed,
				"  (clipped short of CAR_HORN_TIME)" if clipped else ""])

	t.check(clipped_before == _SPEEDS.size(),
			"the old watch clipped every speed tested (%d of %d)"
			% [clipped_before, _SPEEDS.size()])
	t.check(clipped_after == 0,
			"the new watch clips none of them (%d of %d)" % [clipped_after, _SPEEDS.size()])
	t.check(new_watch >= Tuning.CAR_SPEED.y * Tuning.CAR_HORN_TIME,
			"and covers the fastest car in the city with room to spare (%.0fpx/s)"
			% Tuning.CAR_SPEED.y)

	_measure_cost(t)

## What the wider watch actually costs. The query itself — `agent.global_position.distance_to
## (here)` in `Crowd._physics_process` — already ran for every live car every frame before M191;
## widening the horn's own comparison from `<= CAR_ZEBRA_SIGHT` to `<= CAR_HORN_SIGHT` adds no new
## query, only a wider band of cars for which `_horn()` itself now runs. So the added cost per
## frame is bounded by (live cars) × (one `_horn()` call), measured directly rather than guessed.
func _measure_cost(t) -> void:
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(4242))
	city.crowd.start_day(1, RandomNumberGenerator.new())
	var live_cars := 0
	var sample: CrowdAgent = null
	for agent in city.crowd.agents():
		if agent.kind != CrowdAgent.Kind.CAR:
			continue
		live_cars += 1
		if sample == null:
			sample = agent
	print("\n== M191 — what the wider watch costs ==")
	if sample == null:
		print("no live car to time _horn() against")
		city.free()
		return
	sample._speed = Tuning.CAR_SPEED.y
	var at: Vector2 = sample.global_position + sample.heading() * 250.0
	var start := Time.get_ticks_usec()
	for i in _HORN_CALLS:
		city.crowd._horn(sample, at)
	var per_call_us := float(Time.get_ticks_usec() - start) / float(_HORN_CALLS)
	var frame_budget_us := 1000000.0 / 60.0
	print("_horn() costs %.3fus a call (measured over %d calls)" % [per_call_us, _HORN_CALLS])
	print(("%d live cars this frame -> a worst-case added cost of %.1fus/frame against a "
			+ "%.0fus (60fps) frame budget, if every one of them were newly in range")
			% [live_cars, per_call_us * float(live_cars), frame_budget_us])
	t.check(per_call_us * float(live_cars) < frame_budget_us * 0.01,
			"the wider watch's worst case stays under 1%% of a frame's budget")
	city.free()

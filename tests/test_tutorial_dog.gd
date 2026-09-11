extends RefCounted
## The charging dog past the teaching day — M96, "the teaching day, and the dog after it".
##
## Day 3 sites it on her exact heading, unavoidable, because the run lesson depends on it. Every
## day after, the same row recurs but must never be sited that way again — *"the tutorial dog may
## appear later but not as tutorial."* See `EventDirector._crossing_ahead_of()`.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_day_3_is_still_sited_on_her_heading(t)
	_test_day_4_is_never_sited_on_her_heading(t)

func _map() -> CityMap:
	return CityGenerator.generate(4242)

## Walks a director until it hands out `charging_dog`, or returns two `Vector2.INF`s if a real
## street's worth of walking never gets one. `due()` sites relative to wherever she has walked to
## by the time it fires — `Tuning.AHEAD_INTERVAL` is up to 26s of walking, hundreds of pixels past
## the start — so the second return is her position *at the moment of siting*, which is what a
## heading has to be measured from, not the start of the walk.
func _site_the_dog(director: EventDirector, at: Vector2, heading: Vector2) -> Array:
	var due: Array = []
	var walked := at
	for i in int(round(Tuning.AHEAD_INTERVAL.y * 2.0 / STEP)):
		due = director.due(STEP, walked, heading * Tuning.WALK_SPEED)
		walked += heading * Tuning.WALK_SPEED * STEP
		if not due.is_empty():
			break
	if due.is_empty():
		return [Vector2.INF, Vector2.INF]
	var path := due[1] as PackedVector2Array
	if path.size() != 1:
		return [Vector2.INF, Vector2.INF]
	return [path[0], walked]

## Day 3: unavoidable, on her exact line — `_teach_the_run()` puts it at the head of the queue and
## nothing about its siting has changed.
func _test_day_3_is_still_sited_on_her_heading(t) -> void:
	var map := _map()
	var director := EventDirector.new(map)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var def := EventCatalogue.by_id("charging_dog")
	var plans: Array[EventScheduler.Planned] = [EventScheduler.Planned.new(def, Vector2.INF)]
	director.start_day(Tuning.RUN_TAUGHT_DAY, plans, rng)

	var at := CrowdLanes.arterial_pavement(map)
	at.y = map.world_size().y * 0.5
	var north := Vector2(0.0, -1.0)
	var result := _site_the_dog(director, at, north)
	var site: Vector2 = result[0]
	var sited_from: Vector2 = result[1]
	t.check(site != Vector2.INF, "day 3 sites the dog while she walks a real street")
	if site == Vector2.INF:
		return
	var direction := (site - sited_from).normalized()
	t.check(direction.dot(north) > 0.99,
			"and it is on her exact heading — the lesson has to be unavoidable")

## Day 4 and every day after: the same row, but never on her line — swept over several headings
## and rng streams, since a single trial passing would not rule out "usually, not always".
func _test_day_4_is_never_sited_on_her_heading(t) -> void:
	var def := EventCatalogue.by_id("charging_dog")
	var min_angle_seen := 0.0
	var trials := 0
	for seed in [3, 17, 29, 41, 53]:
		for heading in [Vector2(0.0, -1.0), Vector2(1.0, 0.0), Vector2(0.0, 1.0), Vector2(-1.0, 0.0)]:
			var map := _map()
			var director := EventDirector.new(map)
			var rng := RandomNumberGenerator.new()
			rng.seed = seed
			var plans: Array[EventScheduler.Planned] = [EventScheduler.Planned.new(def, Vector2.INF)]
			director.start_day(4, plans, rng)

			var at := CrowdLanes.arterial_pavement(map)
			at.y = map.world_size().y * 0.5
			var result := _site_the_dog(director, at, heading)
			var site: Vector2 = result[0]
			var sited_from: Vector2 = result[1]
			if site == Vector2.INF:
				continue
			trials += 1
			var direction := (site - sited_from).normalized()
			var angle := rad_to_deg(direction.angle_to(heading))
			min_angle_seen = maxf(min_angle_seen, absf(angle))
			t.check(direction.dot(heading) < 0.99,
					"day 4 does not site the dog dead ahead (seed %d, heading %s)" % [seed, heading])
			t.check(absf(angle) >= EventDirector.OFF_HEADING_MIN_DEGREES - 1.0,
					"and it keeps the off-heading floor (%.1f° >= %.1f°, seed %d)"
					% [absf(angle), EventDirector.OFF_HEADING_MIN_DEGREES, seed])
	t.check(trials >= 10, "the sweep actually sited the dog enough times to mean something (%d)"
			% trials)
	t.check(min_angle_seen > EventDirector.OFF_HEADING_MIN_DEGREES,
			"and at least one trial used a real, non-trivial offset (%.1f°)" % min_angle_seen)

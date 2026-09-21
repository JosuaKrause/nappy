extends RefCounted
## Measurement probe for M179, "the fire is on her way, guaranteed" — how long a walk takes to be
## handed the fire, and how long after that she sees it. Not a suite: it prints rather than
## asserting, so it lives here under `tests/probes/`, where the runner never discovers it, and runs
## only by name:
##
##     tools/test.sh probes/m179_fire_on_her_way.gd
##
## Day 3's fire is budgeted with no position and sited by `EventDirector.site_what_is_on_her_way()`
## once she has been walking `ON_HER_WAY_AFTER` seconds and is clear of the doorstep, on the line
## she is walking, between the far edge of the streaming band and `ON_HER_WAY_SIGHT` seconds of
## walking past the edge of the view. The two columns that matter are **sited** — how far into the
## day her heading bought her one — and **seen**, how much more walking it took to come into view.
##
## `tests/test_event_manager.gd` holds the same walk as a regression on one seed. What this adds is
## the spread over several cities and every heading, which is the shape of the question the
## thresholds were chosen against: how late in a 180s day the beat can land, and whether a heading
## with little room ahead of it is one the guarantee quietly fails on.
##
## **The rig walks through the lattice rather than round it, and turns at the map's edge.** What is
## being measured is the siting against the direction she is *travelling*; a rig that turned at
## every frontage would be measuring the collision shape instead. The turn at the border is real
## play, and it is also what puts the re-siting rule under the measurement.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS := [4242, 5150, 31337]
const STEP := 1.0 / 30.0
const WALK_SECONDS := 120.0
const WALKS := {
	"east": Vector2.RIGHT,
	"west": Vector2.LEFT,
	"north": Vector2.UP,
	"south": Vector2.DOWN,
	"north-east": Vector2(0.7071, -0.7071),
}

func run(t) -> void:
	print("seed   heading      sited at   lead px   seen after   total")
	for seed_value: int in SEEDS:
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))
		city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
		for name: String in WALKS:
			_walk_one(t, city, seed_value, name, WALKS[name])
		city.free()
	t.check(true, "m179_fire_on_her_way probe ran")

func _walk_one(t, city: City, seed_value: int, heading_name: String, heading: Vector2) -> void:
	var scars := GameState.scars.duplicate()
	var consumed: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [seed_value, Tuning.RUN_TAUGHT_DAY])
	city.events.start_day(Tuning.RUN_TAUGHT_DAY, rng, consumed)
	var plan: EventScheduler.Planned = null
	for candidate in city.events.plans():
		if candidate.def.id == "burning_building":
			plan = candidate
	if not plan:
		print("%-6d %-12s no fire planned" % [seed_value, heading_name])
		return

	var rig := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	rig.add_child(camera)
	t.add_child(rig)
	rig.set_physics_process(false)
	rig.global_position = city.map.home_world_position()

	var clock := 0.0
	var sited_at := -1.0
	var lead := 0.0
	var seen_at := -1.0
	while clock < WALK_SECONDS and seen_at < 0.0:
		if not city.map.in_bounds(city.map.world_to_tile(
				rig.global_position + heading * Tuning.TILE_SIZE * 4.0)):
			heading = -heading
		var was_placed := plan.is_placed()
		var here := rig.global_position
		rig.velocity = heading * Tuning.WALK_SPEED
		rig.global_position += heading * Tuning.WALK_SPEED * STEP
		city.events._physics_process(STEP)
		clock += STEP
		if not was_placed and plan.is_placed():
			sited_at = clock
			lead = plan.position.distance_to(here)
		if plan.is_placed() and city.events._is_on_screen(plan.position):
			seen_at = clock
	if seen_at < 0.0:
		print("%-6d %-12s never seen (sited at %.1fs)" % [seed_value, heading_name, sited_at])
	else:
		print("%-6d %-12s %7.1fs %9.0f %10.1fs %7.1fs"
				% [seed_value, heading_name, sited_at, lead, seen_at - sited_at, seen_at])
	rig.free()
	GameState.scars = scars

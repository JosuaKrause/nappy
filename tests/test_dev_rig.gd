extends RefCounted
## `DevRig` (src/dev/dev_rig.gd) is the half of the dev-flag surface that reads the live city —
## docs/TODO.md, M100, "Small, real, and nobody's": the code `--spawn`, `--follow`, `--overview`
## and `--meters` act through, once `DevFlags` has already read the argv. Moved out of `main.gd`
## so it is testable against a real `City` without booting a run — `for_spawn_target()` takes its
## target as a plain string rather than reading `--spawn` off a command line this suite does not
## control, the same seam `first_event_position()` already used for its own id before the move.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
## Step 1, "A chalk mark", is the pickup `ResistanceSteps.for_day()` selects on a fresh run from
## its own `day` — the same day `tests/test_resistance.gd`'s determinism test uses, and the
## smallest day that gives `--spawn contact` something to find.
const DAY := 6

var _city: City
var _resistance: ResistanceDirector

var _saved_completed: Array[int]
var _saved_failed: Array[int]
var _saved_progress: int
var _saved_package: bool

func run(t) -> void:
	_build_day(t)
	_test_named_tile_targets_land_on_a_walkable_tile(t)
	_test_event_target_lands_near_a_placed_event(t)
	_test_closure_target_lands_near_the_first_closure(t)
	_test_contact_target_lands_beside_the_resistance_mark(t)
	_test_an_unknown_target_warns_and_returns_home(t)
	_test_a_queue_fed_row_refuses_by_name(t)
	_test_a_waiting_row_stands_outside_its_trigger(t)
	_test_the_pavement_offset_crosses_the_streets_own_axis(t)
	_test_no_door_before_the_region_wall_starts(t)
	_test_door_target_lands_on_the_approach_side_of_a_hut(t)
	_teardown(t)

func _rng(stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [SEED, DAY, stream])
	return rng

## One day, built the way `main._start_day()` builds it — closures before events, so `closure:0`
## has one to find — with streaming off so a plan is placed without a player ever coming near it
## (the same reasoning `tests/test_event_manager.gd`'s own `_build_city()` gives), and the
## resistance run under a clean `GameState`, the way `tests/test_resistance.gd`'s own
## `_with_clean_run()` does, so day 4 always selects step 1 regardless of what an earlier suite
## left behind in the shared autoload.
func _build_day(t) -> void:
	_city = CITY_SCENE.instantiate()
	t.add_child(_city)
	_city.build(CityGenerator.generate(SEED))
	_city.events.stream_radius = INF

	var state := CityState.new()
	state.begin_day(_city.map.block_plans, DAY)
	_city.start_day(state, DAY, _rng("closures"))
	var consumed: Array[String] = []
	_city.events.start_day(DAY, _rng("events"), consumed)

	_saved_completed = GameState.completed_resistance_steps.duplicate()
	_saved_failed = GameState.failed_resistance_steps.duplicate()
	_saved_progress = GameState.resistance_progress
	_saved_package = GameState.resistance_carrying_package
	GameState.completed_resistance_steps = []
	GameState.failed_resistance_steps = []
	GameState.resistance_progress = 0
	GameState.resistance_carrying_package = false

	_resistance = ResistanceDirector.new()
	t.add_child(_resistance)
	_resistance.set_process(false)
	_resistance.setup(_city, _city.map)
	_resistance.start_day(DAY, _rng("resistance"), 300.0)

func _teardown(t) -> void:
	GameState.completed_resistance_steps = _saved_completed
	GameState.failed_resistance_steps = _saved_failed
	GameState.resistance_progress = _saved_progress
	GameState.resistance_carrying_package = _saved_package
	_resistance.free()
	_city.free()

## `park` and `alley` are plain tile-type sweeps; both have to exist in a generated city (see
## `docs/CITY.md`'s own generation guarantees) and both have to leave her somewhere she can
## actually stand, which is the whole promise `for_spawn_target()` makes for every named target.
func _test_named_tile_targets_land_on_a_walkable_tile(t) -> void:
	for target in ["park", "alley"]:
		var at := DevRig.for_spawn_target(target, _city, _resistance)
		t.check(_city.map.is_walkable(_city.map.world_to_tile(at)),
				"--spawn %s lands on a walkable tile (%s)" % [target, at])

## `event` takes the first non-ambient placed plan — `_city.events.stream_radius = INF` in
## `_build_day()` places every plan without a player to stream one in, so day 4's set is
## guaranteed to have at least one.
func _test_event_target_lands_near_a_placed_event(t) -> void:
	var at := DevRig.for_spawn_target("event", _city, _resistance)
	t.check(_city.map.is_walkable(_city.map.world_to_tile(at)),
			"--spawn event lands on a walkable tile (%s)" % at)

## `closure:0` reads the day's own closures rather than the tile grid, so what it pins is that a
## generated day actually has one and that the lookup does not fall back to the doorstep.
func _test_closure_target_lands_near_the_first_closure(t) -> void:
	t.check(not _city.closures().is_empty(), "day %d has a closure to look at" % DAY)
	var at := DevRig.for_spawn_target("closure:0", _city, _resistance)
	t.check(_city.map.is_walkable(_city.map.world_to_tile(at)),
			"--spawn closure:0 lands on a walkable tile (%s)" % at)

## `contact` reads `ResistanceDirector.contact_position()` rather than the map at all, so this is
## the one target that would return the home fallback on a wiring bug even though the city has
## plenty of walkable tiles elsewhere.
func _test_contact_target_lands_beside_the_resistance_mark(t) -> void:
	var contact := _resistance.contact_position()
	t.check(contact != Vector2.INF, "day %d has a resistance mark placed" % DAY)
	var at := DevRig.for_spawn_target("contact", _city, _resistance)
	t.check(is_equal_approx(at.distance_to(contact), Vector2(70.0, 30.0).length()),
			"--spawn contact stands off to the side of the mark rather than on top of it (%s)" % at)

## Every named branch above returns before the two warning paths at the bottom of
## `for_spawn_target()` — this is what exercises them: a target matching nothing rolls all the way
## through and lands on the doorstep, with a warning rather than a silent wrong answer.
func _test_an_unknown_target_warns_and_returns_home(t) -> void:
	var at := DevRig.for_spawn_target("not-a-real-target", _city, _resistance)
	t.check(at == _city.map.home_world_position(),
			"an unrecognised --spawn target falls back to the doorstep rather than guessing")

## `cat_dash` is `AHEAD_OF_PLAYER`, so on day 6 of seed 4242 every copy the day budgets is
## unplaced — a row the day's plan never holds a position for. `event:cat_dash` refuses rather
## than silently starting her on the doorstep as if nothing were wrong: the row and the reason
## land in the run log (`Telemetry.note("spawn", …)`, checked here) and on `stderr`
## (`push_warning`, not checked here — Godot gives a test no hook onto it; `push_warning` rather
## than `push_error` because this test feeds the bad input on purpose and has to reach it by
## return value rather than failing the run), and only then does the same doorstep fallback an
## unrecognised target reaches apply.
func _test_a_queue_fed_row_refuses_by_name(t) -> void:
	Telemetry.begin_memory_log()
	var at := DevRig.for_spawn_target("event:cat_dash", _city, _resistance)
	var lines := Telemetry.current_log().lines
	Telemetry.end_run()
	t.check(at == _city.map.home_world_position(),
			"a queue-fed row still leaves her somewhere to stand: the doorstep")
	var named := false
	for line in lines:
		if line.contains("spawn") and line.contains("cat_dash"):
			named = true
	t.check(named, "the refusal names the row in the run log (got %s)" % [lines])

## `pigeon_flock` waits (`pursues_within`) and on day 6 of seed 4242 has a copy placed whose
## `outer_radius` (168px) sits *under* its own `pursues_within` (150px is under 168, but the old
## `outer_radius * 0.6` = 100.8px offset was under both) — so the old offset stood her inside the
## trigger. The fixed offset has to clear the larger of the two plus a tile's margin.
func _test_a_waiting_row_stands_outside_its_trigger(t) -> void:
	var found: EventScheduler.Planned = null
	for plan in _city.events.plans():
		if plan.def.id == "pigeon_flock" and plan.is_placed():
			found = plan
			break
	t.check(found != null, "day %d has a placed pigeon_flock to stand outside of" % DAY)
	if found == null:
		return
	var at := DevRig.for_spawn_target("event:pigeon_flock", _city, _resistance)
	var dist := at.distance_to(found.position)
	t.check(dist > found.def.pursues_within,
			"stands outside the wait trigger, %.0fpx > pursues_within %.0fpx"
					% [dist, found.def.pursues_within])
	t.check(dist > found.def.outer_radius,
			"and outside the field itself, %.0fpx > outer_radius %.0fpx"
					% [dist, found.def.outer_radius])

## Moved from `tests/test_main.gd`, where `_pavement_offset` lived before this milestone — see
## that file's own history for the defect this pins: a fixed local-Y step left her on the same
## carriageway column on a north-south street, because the offset never asked which axis the
## street's own width ran on. `CityMap`'s `corridor_offset` is pure arithmetic on
## `Tuning.STREET_WIDTH`, so a bare `CityMap.new()` answers it without generating a city.
func _test_the_pavement_offset_crosses_the_streets_own_axis(t) -> void:
	var map := CityMap.new()
	const RADIUS := 100.0

	# x=0 sits inside the first north-south corridor's own width band; y=STREET_WIDTH sits one
	# tile past the first east-west corridor's. On a north-south street and nothing else, so its
	# width — the axis a step has to cross to clear it — is local X.
	var ns_at := map.tile_to_world(Vector2i(0, Tuning.STREET_WIDTH))
	var ns_offset := DevRig.pavement_offset(map, ns_at, RADIUS)
	t.check(not is_zero_approx(ns_offset.x) and is_zero_approx(ns_offset.y),
			"on a north-south street the offset crosses local X, the street's own width axis "
			+ "(got %s)" % ns_offset)

	# The mirror tile: on an east-west street and nothing else, whose width runs the other way.
	var ew_at := map.tile_to_world(Vector2i(Tuning.STREET_WIDTH, 0))
	var ew_offset := DevRig.pavement_offset(map, ew_at, RADIUS)
	t.check(not is_zero_approx(ew_offset.y) and is_zero_approx(ew_offset.x),
			"and on an east-west street it crosses local Y instead (got %s)" % ew_offset)

# ---------------------------------------------------------------- --spawn door[:n] ---
# M204 (the trailer): "the father walking towards a gatehouse". `_city`/DAY above is day 6,
# before `Tuning.REGION_WALL_FIRST_DAY` (9), so it doubles as the no-checkpoint-yet case; the
# door itself is checked against a separate city built on a seed `tests/test_checkpoints.gd`
# already establishes has a door structure on that day (`_test_the_manager_actually_places_the_door_structure`).

const _CHECKPOINT_SEED := 771103

## Before the region wall exists, `door_bodies` is empty every day regardless of seed — the same
## "not there yet" shape `_test_an_unknown_target_warns_and_returns_home` covers for a typo'd
## target, but reached here through a real target on a day too early for it.
func _test_no_door_before_the_region_wall_starts(t) -> void:
	t.check(DAY < Tuning.REGION_WALL_FIRST_DAY,
			"day %d is before the region wall starts (day %d)" % [DAY, Tuning.REGION_WALL_FIRST_DAY])
	var at := DevRig.for_spawn_target("door", _city, _resistance)
	t.check(at == _city.map.home_world_position(),
			"no checkpoint exists yet, so --spawn door falls back to the doorstep")

## `door:0` lands on a walkable tile `TILE_SIZE * 4` back from the first hut, along its own
## `facing` axis — the approach side a `--walk` in that same direction closes toward.
func _test_door_target_lands_on_the_approach_side_of_a_hut(t) -> void:
	var day := Tuning.REGION_WALL_FIRST_DAY
	var map := CityGenerator.generate(_CHECKPOINT_SEED)
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(map)
	city.events.stream_radius = INF
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	city.start_day(state, day, _rng("checkpoint-closures"))
	var consumed: Array[String] = []
	city.events.start_day(day, _rng("checkpoint-events"), consumed)

	var huts: Array[EventScheduler.Planned] = []
	for body in city.region_plan().door_bodies:
		if body.def.id == "checkpoint_hut":
			huts.append(body)
	t.check(not huts.is_empty(), "seed %d day %d has at least one checkpoint hut" % [_CHECKPOINT_SEED, day])
	if huts.is_empty():
		city.free()
		return

	var at := DevRig.for_spawn_target("door:0", city, _resistance)
	t.check(city.map.is_walkable(city.map.world_to_tile(at)), "--spawn door:0 lands on a walkable tile (%s)" % at)
	var hut := huts[0]
	var expected := hut.position - hut.facing * Tuning.TILE_SIZE * 4.0
	t.check(at.distance_to(expected) < Tuning.TILE_SIZE * 2.0,
			"stands close to four tiles back from the hut along its own facing axis (got %s, hut %s, facing %s)"
					% [at, hut.position, hut.facing])
	var closer := at + hut.facing * Tuning.TILE_SIZE
	t.check(closer.distance_to(hut.position) < at.distance_to(hut.position),
			"walking one tile in the hut's own facing direction closes the distance to it")
	city.free()

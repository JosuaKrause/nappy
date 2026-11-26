extends RefCounted
## `DevRig` (src/dev/dev_rig.gd) is the half of the dev-flag surface that reads the live city —
## docs/TODO.md, M100, "Small, real, and nobody's": the code `--spawn`, `--follow`, `--overview`
## and `--meters` act through, once `DevFlags` has already read the argv. Moved out of `main.gd`
## so it is testable against a real `City` without booting a run — `for_spawn_target()` takes its
## target as a plain string rather than reading `--spawn` off a command line this suite does not
## control, the same seam `first_event_position()` already used for its own id before the move.
##
## **Combined, for this reason:** the `--spawn contact` target is a promise about the *real placed
## day*: it reads where the resistance director put the day's chalk mark, which is placed by the
## city's map, its events and its streets at once, so the day the rig stands in is a real generated
## city, planned the way `main` plans it, from the cache of generated maps
## (`tests/city_map_cache.gd`); a fake that answered for those would answer for itself. The
## `--spawn` targets that read one module's answer are that module's suites': `event` in
## `tests/test_event_manager.gd`, `closure` in `tests/test_routes_closures_a.gd` and `door` in
## `tests/test_checkpoints.gd`.

const MapCache := preload("res://tests/city_map_cache.gd")
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
## Step 1, "A chalk mark", is the pickup `ResistanceSteps.for_day()` selects on a fresh run from
## its own `day` — the same day `tests/test_resistance_steps.gd`'s determinism test uses, and the
## smallest day that gives `--spawn contact` something to find.
const DAY := 6
## The seed of the run the city stands in: the day's streams come from it
## (`RunCalendar.day_rng()`, among them the one that sites the events on her route).
const RUN_SEED := 2

var _city: City
## Where `DevRig.for_spawn_target()` writes what it says, which no case reads back.
var _trace := RunTrace.new()
## The run `_city` stands in.
var _run: RunState
var _resistance: ResistanceDirector

func run(t: TestRunner) -> void:
	_build_day(t)
	_test_named_tile_targets_land_on_a_walkable_tile(t)
	_test_contact_target_lands_beside_the_resistance_mark(t)
	_test_an_unknown_target_warns_and_returns_home(t)
	_test_the_pavement_offset_crosses_the_streets_own_axis(t)
	_teardown(t)

func _rng(stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [SEED, DAY, stream])
	return rng

## One day, built the way `main._start()` builds it — closures before events, so `closure:0`
## has one to find — with streaming off so a plan is placed without a player ever coming near it
## (the same reasoning `Rig.build_city_stage()` in `tests/event_manager_rig.gd` gives the event
## manager suites' one city), and the resistance run over the city's own fresh run, so day 6
## selects step 1 on a run that has done nothing, on the seed `RUN_SEED` names.
func _build_day(t: TestRunner) -> void:
	_run = RunCity.started_run(RUN_SEED)
	_city = RunCity.new_city(CITY_SCENE)
	t.add_child(_city)
	RunCity.build(_city, _run, MapCache.of(SEED))
	RunCity.events(_city).stream_within(INF)

	var state := CityState.new()
	state.begin_day(_city.map().plans_by_block(), DAY)
	_city.start_day(state, DAY, _rng("closures"))
	var consumed: Array[String] = []
	RunCity.events(_city).start_day(DaySpec.for_day(DAY), _rng("events"), consumed)

	_resistance = ResistanceDirector.new()
	t.add_child(_resistance)
	_resistance.set_process(false)
	_resistance.setup(Shipped.rows(), _city.map(), _run, RunCity.events(_city),
			_city.streets(), _city.fronts(), _city, null, RunCity.spawn_siting(_city))
	_resistance.start_day(DAY, _rng("resistance"), 300.0)

func _teardown(t: TestRunner) -> void:
	_resistance.free()
	_city.free()

## `park` and `alley` are plain tile-type sweeps; both have to exist in a generated city (see
## `docs/CITY.md`'s own generation guarantees) and both have to leave her somewhere she can
## actually stand, which is the whole promise `for_spawn_target()` makes for every named target.
func _test_named_tile_targets_land_on_a_walkable_tile(t: TestRunner) -> void:
	for target: String in ["park", "alley"]:
		var at := DevRig.for_spawn_target(target, _city.map(), RunCity.events(_city), _city.streets(),
				_resistance, _run.header(), _trace)
		t.check(_city.map().is_walkable(_city.map().world_to_tile(at)),
				"--spawn %s lands on a walkable tile (%s)" % [target, at])

## `contact` reads `ResistanceDirector.contact_position()` rather than the map at all, so this is
## the one target that would return the home fallback on a wiring bug even though the city has
## plenty of walkable tiles elsewhere.
func _test_contact_target_lands_beside_the_resistance_mark(t: TestRunner) -> void:
	var contact := _resistance.contact_position()
	t.check(contact != Vector2.INF, "day %d has a resistance mark placed" % DAY)
	var at := DevRig.for_spawn_target("contact", _city.map(), RunCity.events(_city), _city.streets(),
			_resistance, _run.header(), _trace)
	t.check(is_equal_approx(at.distance_to(contact), Vector2(70.0, 30.0).length()),
			"--spawn contact stands off to the side of the mark rather than on top of it (%s)" % at)

## Every named branch above returns before the two warning paths at the bottom of
## `for_spawn_target()` — this is what exercises them: a target matching nothing rolls all the way
## through and lands on the doorstep, with a warning rather than a silent wrong answer.
func _test_an_unknown_target_warns_and_returns_home(t: TestRunner) -> void:
	var at := DevRig.for_spawn_target("not-a-real-target", _city.map(), RunCity.events(_city), _city.streets(),
			_resistance, _run.header(), _trace)
	t.check(at == _city.map().home_world_position(),
			"an unrecognised --spawn target falls back to the doorstep rather than guessing")

## Moved from `tests/test_main.gd`, where `_pavement_offset` lived before this milestone — see
## that file's own history for the defect this pins: a fixed local-Y step left her on the same
## carriageway column on a north-south street, because the offset never asked which axis the
## street's own width ran on. `CityMap`'s `corridor_offset` is pure arithmetic on
## `Tuning.STREET_WIDTH`, so a bare `CityMap.new()` answers it without generating a city.
func _test_the_pavement_offset_crosses_the_streets_own_axis(t: TestRunner) -> void:
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

extends RefCounted
## M98, pressure in the empty acts — "Patrols for acts III and IV, built around encounter cost."
## `EventDirector.owe_the_return()`'s own shape: what it owes per act, the pacing it switches to,
## that it never owes twice in a day, and the carriageway siting `_toward_her_on_the_road()` gives
## the row it owes. See `tests/probes/m98_return_phase.gd` for the before/after measurement this
## milestone asked for; this suite is the contract, not the measurement.

const SEED := 4242
## One sample day per act, the same days `tests/probes/m98_return_phase.gd` samples.
const ACT_SAMPLE_DAYS: Array[int] = [2, 5, 9, 13]

func run(t) -> void:
	_test_owed_count_per_act(t)
	_test_no_double_batch_in_a_day(t)
	_test_forced_queue_is_untouched(t)
	_test_pacing_switches_after_the_return_is_owed(t)
	_test_sited_on_driveable_road_toward_her(t)
	_test_empty_in_a_park(t)
	_test_constants_validate(t)

# ------------------------------------------------------------------------- rig ---

func _map() -> CityMap:
	return CityGenerator.generate(SEED)

func _director(map: CityMap) -> EventDirector:
	var director := EventDirector.new(map)
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	var no_plans: Array[EventScheduler.Planned] = []
	director.start_day(1, no_plans, rng)
	return director

# ---------------------------------------------------------------------- owing ---

## `Tuning.RETURN_PATROLS_PER_ACT` is `[0, 0, 2, 3]`: acts I and II owe nothing, so the teaching
## days and the return she learns the mechanic on are untouched; III and IV owe a small, fixed
## batch each.
func _test_owed_count_per_act(t) -> void:
	var map := _map()
	for day in ACT_SAMPLE_DAYS:
		var act := Tuning.act_for_day(day)
		var director := _director(map)
		director.owe_the_return(day, 0)
		var expected: int = Tuning.RETURN_PATROLS_PER_ACT[act - 1]
		t.check(director.owed() == expected,
				"day %d (act %d) owes %d return patrol(s), got %d"
				% [day, act, expected, director.owed()])

## The baby can wake and settle again inside one day — `EventBus.return_phase_started` firing
## twice must not owe a second batch on top of the first.
func _test_no_double_batch_in_a_day(t) -> void:
	var map := _map()
	var director := _director(map)
	var day := 13 # act IV, the largest batch
	director.owe_the_return(day, 0)
	var once := director.owed()
	director.owe_the_return(day, 0)
	t.check(director.owed() == once,
			"a second 'return started' the same day owes nothing more (%d, then %d)"
			% [once, director.owed()])
	t.check(once == Tuning.RETURN_PATROLS_PER_ACT[3], "the one batch is the whole of act IV's count")

## `--force <id>` replaces the day's own queue with nothing but the forced row — there is no
## ordinary queue left for the return to add to or re-pace, and the brief says leave it alone.
## `DevFlags` reads the real command line, with no override hook for the row it names (only for
## `--invincible`), so this reaches `_forced` directly the way other suites reach a director's
## private state (`tests/test_resistance.gd`'s own `director._rider`, `director._process`).
func _test_forced_queue_is_untouched(t) -> void:
	var map := _map()
	var director := _director(map)
	director._forced = EventCatalogue.by_id("police_patrol")
	director._forced_interval = 5.0
	var forced_only: Array[EventDef] = [director._forced]
	director._owed = forced_only
	var before := director.owed()
	director.owe_the_return(13, 0) # act IV, which would otherwise owe three
	t.check(director.owed() == before,
			"a forced day's queue is unchanged by the return (%d, then %d)"
			% [before, director.owed()])
	t.check(not director._return_pacing, "and the pacing stays the forced one, never re-rolled")

# --------------------------------------------------------------------- pacing ---

## Before the return is owed the queue rolls `Tuning.AHEAD_INTERVAL`; once it is owed, the rest of
## the day rolls the tighter `Tuning.RETURN_PATROL_INTERVAL` instead, so the extra rows have a
## chance to land inside the leg rather than after she is home.
func _test_pacing_switches_after_the_return_is_owed(t) -> void:
	var map := _map()
	var director := _director(map)
	for i in 20:
		var interval: float = director._roll_interval()
		t.check(interval >= Tuning.AHEAD_INTERVAL.x and interval <= Tuning.AHEAD_INTERVAL.y,
				"before the return, %.2fs is inside AHEAD_INTERVAL %s" % [interval, Tuning.AHEAD_INTERVAL])

	director.owe_the_return(13, 0) # act IV
	for i in 20:
		var interval: float = director._roll_interval()
		t.check(interval >= Tuning.RETURN_PATROL_INTERVAL.x
				and interval <= Tuning.RETURN_PATROL_INTERVAL.y,
				"after the return, %.2fs is inside RETURN_PATROL_INTERVAL %s"
				% [interval, Tuning.RETURN_PATROL_INTERVAL])

# --------------------------------------------------------------------- siting ---

## The road-aware sibling of `_toward_her()`: sited on the carriageway lane of her own street,
## driving opposite her own heading so it meets her rather than following her, on real driveable
## road tiles of a generated map.
func _test_sited_on_driveable_road_toward_her(t) -> void:
	var map := _map()
	var director := EventDirector.new(map)
	var def := EventCatalogue.by_id("police_patrol")

	# The arterial is a real north-south (vertical) street by construction.
	var at := CrowdLanes.arterial_pavement(map)
	at.y = map.world_size().y * 0.5
	var heading := Vector2(0.0, -1.0) # walking north

	var path: PackedVector2Array = director._toward_her_on_the_road(at, heading, def)
	t.check(path.size() == 2, "the row is given a two-point route down the carriageway")
	if path.size() != 2:
		return

	for point in [path[0], path[1]]:
		t.check(map.is_driveable_at(true, map.world_to_tile(point)),
				"%s lies on a driveable road tile of her (vertical) street" % point)

	var travel := (path[1] - path[0]).normalized()
	t.check(travel.dot(heading) < 0.0,
			"it travels opposite her heading, so it meets her rather than follows her")

	# It stays on one lane of the carriageway rather than drifting across it: both ends share the
	# same across-corridor (x) coordinate.
	t.close_to(path[0].x, path[1].x, "both ends of the route sit on the same lane", 0.5)

## `pavement_inward()` answers `Vector2i.ZERO` off a plain sidewalk edge, which is exactly what a
## park, a square or a precinct pavement is for this purpose — nothing there has a carriageway to
## drive on, or (for a precinct) a carriageway at all, so the siting must retry later rather than
## invent a road.
func _test_empty_in_a_park(t) -> void:
	var map := _map()
	var director := EventDirector.new(map)
	var def := EventCatalogue.by_id("police_patrol")
	var calm := map.calm_tiles()
	t.check(not calm.is_empty(), "the generated map has calm ground to test against")
	if calm.is_empty():
		return
	var at := map.tile_to_world(calm[0])
	var path: PackedVector2Array = director._toward_her_on_the_road(at, Vector2(0.0, -1.0), def)
	t.check(path.is_empty(), "no carriageway to drive on in a park, so the siting is empty")

# ----------------------------------------------------------------- constants ---

func _test_constants_validate(t) -> void:
	t.check(Tuning.validate_return_patrols(), "the shipped shape is fair by its own rule")
	t.check(Tuning.RETURN_PATROLS_PER_ACT.size() == 4, "one entry per act")
	for count in Tuning.RETURN_PATROLS_PER_ACT:
		t.check(count >= 0, "no act owes a negative number of patrols")
	t.check(Tuning.RETURN_PATROL_INTERVAL.x <= Tuning.RETURN_PATROL_INTERVAL.y,
			"RETURN_PATROL_INTERVAL is ordered")
	t.check(Tuning.RETURN_PATROL_INTERVAL.x < Tuning.AHEAD_INTERVAL.x
			and Tuning.RETURN_PATROL_INTERVAL.y < Tuning.AHEAD_INTERVAL.y,
			"RETURN_PATROL_INTERVAL %s is strictly shorter than AHEAD_INTERVAL %s on both ends"
			% [Tuning.RETURN_PATROL_INTERVAL, Tuning.AHEAD_INTERVAL])

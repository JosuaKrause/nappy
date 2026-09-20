extends RefCounted
## Diagnoses PLAYTEST-69's re-report of "people still come out from outside the map" — a re-report
## of the finding M120 (`DECISIONS.md`) already answered once, by giving an ordinary walker or an
## off-spine car no room past the true edge at all (`CrowdAgent._entry_room()` returns 0.0 for
## them). `TODO.md`'s M100 entry, "People still come out from outside the map", names three
## candidates to tell apart: a `_recycle()` landing that puts the agent's own **centre** legally on
## the boundary line while its **picture** — the actual texture `_draw_body()` puts on screen —
## reaches past it; a day-start placement (`Crowd.start_day()`, which places through `setup()`
## rather than through `_recycle()`'s own room check) doing the same; or an agent genuinely left
## standing past the true edge by some other path. Not a suite — it prints counts and asserts only
## that it ran — so it lives under `tests/probes/`, discovered by nobody, and run by name:
##
##     tools/test.sh probes/m100_map_edge_entries.gd
##
## "Unsafe" below means the agent's own centre is legal by every existing bounds check
## (`CityMap.in_bounds`, the invariant `tests/test_crowd.gd`'s `_test_nobody_enters_across_a_
## plain_edge` already holds) while its picture — read off the same texture sizes and anchor
## arithmetic `CrowdAgent._draw_body()` draws from, in `_picture_clearance()` below — still
## reaches past the true edge, which is exactly what none of those checks can see because they all
## ask about the centre.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
const SAMPLES := 150

func run(t) -> void:
	var map := CityGenerator.generate(SEED)
	_diagnose_recycle(map)
	_diagnose_day_start(t, map)
	t.check(true, "probe finished")

## Candidate 1: `CrowdAgent._recycle()`, driven directly the way M120's own entry test
## (`tests/test_crowd.gd`, `_test_the_entry_roll_is_kept_inside_its_own_room`) drives it, at each of
## the four plain edges `_test_nobody_enters_across_a_plain_edge` stands on — the same points, so
## this is the same scenario that test already passes (centre never out of bounds) read for the
## picture instead of the centre.
func _diagnose_recycle(map: CityMap) -> void:
	var size := map.world_size()
	# Several cross-axis offsets per edge rather than one, because a single fixed point can sit on
	# a corridor whose lane offsets happen not to carry the direction being asked about — the loop
	# below then keeps re-rolling other corridors and the recorded direction skews away from it.
	# name -> [vertical, the direction that enters across this edge, the spawn points tried]
	var edges := {
		"north": [true, 1.0, _cross_positions(size.x, Tuning.TILE_SIZE, true)],
		"south": [true, -1.0, _cross_positions(size.x, size.y - Tuning.TILE_SIZE, true)],
		"west": [false, 1.0, _cross_positions(size.y, Tuning.TILE_SIZE, false)],
		"east": [false, -1.0, _cross_positions(size.y, size.x - Tuning.TILE_SIZE, false)],
	}
	for name in edges:
		var vertical: bool = edges[name][0]
		var entering_direction: float = edges[name][1]
		var points: Array = edges[name][2]
		var limit: float = size.y if vertical else size.x
		for kind in [CrowdAgent.Kind.WALKER, CrowdAgent.Kind.CAR]:
			var clearance := _picture_clearance(kind, vertical)
			var samples := 0
			var unsafe := 0
			var out_of_bounds := 0
			for at: Vector2 in points:
				var field := CrowdField.new(map, at)
				var agent := CrowdAgent.new()
				agent.kind = kind
				agent._map = map
				agent.field = field
				for seed in SAMPLES:
					agent._rng.seed = seed
					agent._recycle()
					if agent._vertical != vertical or agent._direction != entering_direction:
						continue
					# A spine car keeps `Tuning.OUT_OF_SIGHT` past the true edge by design (M94,
					# M120) — that is the tunnel and the bridge, not this defect, so it is left out
					# of the tally rather than counted as "unsafe".
					if kind == CrowdAgent.Kind.CAR and vertical and agent._corridor == map.main_road:
						continue
					samples += 1
					var along := agent._along()
					if along < 0.0 or along > limit:
						out_of_bounds += 1
					var unsafe_here := along < clearance if entering_direction > 0.0 \
							else along > limit - clearance
					if unsafe_here:
						unsafe += 1
				agent.free()
			print(("%s edge, %s: %d/%d entries land within the picture's own clearance (%.1fpx) " +
					"of the true edge; %d/%d land with the centre itself out of bounds")
					% ["car" if kind == CrowdAgent.Kind.CAR else "walker", name, unsafe, samples,
					clearance, out_of_bounds, samples])

## Spawn points along the edge itself, holding the axis coordinate (`fixed`) and varying the
## cross-axis one across a spread of the map so at least some land on a corridor whose lane
## offsets carry the direction being asked about.
func _cross_positions(cross_extent: float, fixed: float, vertical: bool) -> Array:
	var points: Array = []
	for i in range(1, 6):
		var cross := cross_extent * float(i) / 6.0
		points.append(Vector2(cross, fixed) if vertical else Vector2(fixed, cross))
	return points

## Candidate 2: the morning's own placement. `Crowd.start_day()` places every agent through
## `CrowdAgent.setup()`, which rolls freely between `CrowdField.along_bounds()` — already clamped
## flush to the true edge near one — with no room question asked at all.
func _diagnose_day_start(t, map: CityMap) -> void:
	var size := map.world_size()
	var edges := {
		"west": Vector2(Tuning.TILE_SIZE, size.y * 0.5),
		"east": Vector2(size.x - Tuning.TILE_SIZE, size.y * 0.5),
	}
	for name in edges:
		var at: Vector2 = edges[name]
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(map)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("m100-probe-day-start:%s" % name)
		city.crowd.start_day(1, rng, at)
		var total := 0
		var unsafe := 0
		var out_of_bounds := 0
		for agent in city.crowd.agents():
			total += 1
			var limit: float = size.y if agent._vertical else size.x
			var clearance := _picture_clearance(agent.kind, agent._vertical)
			var along := agent._along()
			if along < 0.0 or along > limit:
				out_of_bounds += 1
			if along < clearance or along > limit - clearance:
				unsafe += 1
		print(("day start beside the %s edge: %d/%d agents placed within the picture's own " +
				"clearance of the true edge; %d/%d with the centre itself out of bounds")
				% [name, unsafe, total, out_of_bounds, total])
		city.free()

## How far this kind's own drawn picture reaches, along the given axis, past whichever coordinate
## `_along()` reports — read off the real texture sizes and the same anchor arithmetic
## `CrowdAgent._draw_body()`/`_car_body_anchor()` use, not a guessed number, because "the picture"
## means exactly what gets put on screen. A walker draws bottom-anchored at its own position
## (`Sprites.draw_standing` called with `Vector2.ZERO`), so its whole canvas height rises to the
## north of it and nothing at all to the south; its width is split evenly either side. A car's
## canvas is anchored south of its own position by `_car_body_anchor()`'s own reach, so both the
## north and south overhang are real and unequal; the larger one is kept so one number covers
## either edge of the axis without asking which edge this call is about. Only the cardinal (`front`,
## `side`) views are asked, since a fresh entry never lands mid-turn.
func _picture_clearance(kind: int, vertical: bool) -> float:
	if kind == CrowdAgent.Kind.CAR:
		if vertical:
			var body := AtlasLibrary.native_size(
					StringName(CrowdAgent.CAR_BODY_BY_VIEW["front"]))
			var south_reach := Tuning.CAR_STRIKE_HALF_LENGTH \
					+ float(CrowdAgent.CAR_CANVAS_BOTTOM_MARGIN["front"])
			return maxf(south_reach, float(body.y) - south_reach)
		var side := AtlasLibrary.native_size(
				StringName(CrowdAgent.CAR_BODY_BY_VIEW["side"]))
		return float(side.x) * 0.5
	var walker := AtlasLibrary.native_size(
			StringName(CrowdAgent.WALKER_BODY_BY_VIEW["front"]))
	return float(walker.y) if vertical else float(walker.x) * 0.5

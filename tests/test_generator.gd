extends RefCounted
## City generation guarantees from docs/CITY.md.
##
## A city that violates these is not merely ugly — it makes a run unwinnable in ways the
## player cannot see, so it is checked across many seeds rather than by looking at one.

## Seeds to validate. Each is one BFS over the map, so this stays quick.
const SEEDS_TO_VALIDATE := 200
## Seeds for the expensive route-redundancy sweep, which is O(segments x BFS).
const SEEDS_TO_STRESS := 3

func run(t) -> void:
	_test_rect_subtraction(t)
	_test_layout_maths(t)
	_test_guarantees_hold_across_seeds(t)
	_test_determinism(t)
	_test_buildings_tile_the_blocks(t)
	_test_home_opens_onto_the_street(t)
	_test_no_single_street_closure_isolates_the_parks(t)

# ------------------------------------------------------------------- pieces ---

func _test_rect_subtraction(t) -> void:
	var outer := Rect2i(0, 0, 8, 8)

	var untouched := CityGenerator._subtract(outer, Rect2i(20, 20, 2, 2))
	t.check(untouched.size() == 1 and untouched[0] == outer,
			"subtracting a disjoint rect changes nothing")

	# A through-alley leaves exactly the two slabs either side of it.
	var split := CityGenerator._subtract(outer, Rect2i(3, 0, 2, 8))
	t.check(split.size() == 2, "a through-cut leaves two pieces")
	t.check(_area(split) == 8 * 8 - 2 * 8, "a through-cut conserves the remaining area")
	t.check(not _overlaps(split), "subtraction pieces never overlap")

	# A corner plaza leaves an L, expressed as two rects.
	var corner := CityGenerator._subtract(outer, Rect2i(0, 0, 4, 4))
	t.check(_area(corner) == 8 * 8 - 16, "a corner cut conserves the remaining area")
	t.check(not _overlaps(corner), "corner subtraction pieces never overlap")

	# A notch in the middle of an edge leaves three pieces.
	var notch := CityGenerator._subtract(outer, Rect2i(3, 6, 2, 2))
	t.check(_area(notch) == 8 * 8 - 4, "an edge notch conserves the remaining area")
	t.check(not _overlaps(notch), "notch subtraction pieces never overlap")

func _area(rects: Array) -> int:
	var total := 0
	for rect in rects:
		total += rect.size.x * rect.size.y
	return total

func _overlaps(rects: Array) -> bool:
	for i in rects.size():
		for j in range(i + 1, rects.size()):
			if rects[i].intersects(rects[j]):
				return true
	return false

func _test_layout_maths(t) -> void:
	var period := CityMap.period()
	t.check(period == Tuning.BLOCK_SIZE + Tuning.STREET_WIDTH, "period is a block plus a street")
	t.check(CityMap.corridor_offset(0) == 0, "the map starts with a street corridor")
	t.check(CityMap.corridor_offset(Tuning.STREET_WIDTH) == -1,
			"the first block starts where the corridor ends")
	t.check(CityMap.corridor_offset(period) == 0, "corridors repeat every period")

	var lot := CityMap.block_rect(Vector2i.ZERO)
	t.check(lot.position == Vector2i.ONE * Tuning.STREET_WIDTH, "block 0 sits past the first street")
	t.check(lot.size == Vector2i.ONE * Tuning.BLOCK_SIZE, "a block is BLOCK_SIZE square")

# --------------------------------------------------------------- guarantees ---

func _test_guarantees_hold_across_seeds(t) -> void:
	var failures: Array[String] = []
	for i in SEEDS_TO_VALIDATE:
		var map := CityGenerator.generate(_seed(i))
		var reason := CityGenerator.validate(map)
		if reason != "":
			failures.append("seed %d: %s" % [_seed(i), reason])
	t.check(failures.is_empty(), "every seed satisfies the generation guarantees: %s"
			% ", ".join(failures.slice(0, 3)))

func _test_determinism(t) -> void:
	for i in 5:
		var first := CityGenerator.generate(_seed(i))
		var second := CityGenerator.generate(_seed(i))
		t.check(first.tiles == second.tiles, "seed %d regenerates the identical map" % _seed(i))
		t.check(first.home_rect == second.home_rect, "seed %d puts the home back" % _seed(i))
		t.check(first.park_blocks == second.park_blocks, "seed %d keeps its parks" % _seed(i))

	var a := CityGenerator.generate(_seed(1))
	var b := CityGenerator.generate(_seed(2))
	t.check(a.tiles != b.tiles, "different seeds produce different cities")

func _test_buildings_tile_the_blocks(t) -> void:
	for i in 12:
		var map := CityGenerator.generate(_seed(i))
		var building_tiles := map.size.x * map.size.y - map.count_walkable()
		t.check(_area(map.building_rects) == building_tiles,
				"seed %d: building rects cover every BUILDING tile exactly once" % _seed(i))
		t.check(not _overlaps(map.building_rects), "seed %d: no two buildings overlap" % _seed(i))

		var stray := 0
		for rect in map.building_rects:
			for tile in map.rect_tiles(rect):
				if map.tile_at(tile) != GameEnums.TileType.BUILDING:
					stray += 1
		t.check(stray == 0, "seed %d: no building sits on a walkable tile (%d did)" % [_seed(i), stray])

func _test_home_opens_onto_the_street(t) -> void:
	for i in 12:
		var map := CityGenerator.generate(_seed(i))
		for tile in map.rect_tiles(map.home_rect):
			t.check(map.tile_at(tile) == GameEnums.TileType.HOME,
					"seed %d: the home rect is all HOME tiles" % _seed(i))
		var doorstep := Vector2i(map.home_rect.position.x, map.home_rect.end.y)
		t.check(map.is_walkable(doorstep),
				"seed %d: the tile outside the front door is walkable" % _seed(i))

## The street lattice is never cut by generation, so closing any one street segment must
## still leave a way to a park. This is the property that lets Act IV drop barricades
## without silently making a day unwinnable.
##
## The home's own doorstep is exempt, and has to be: the home is a notch in a block with a
## single exit, so sealing the street outside the front door seals the player in no matter
## how well connected the rest of the city is. That is a constraint on where Act IV may
## place a barricade, not a flaw in the layout — see docs/CITY.md.
func _test_no_single_street_closure_isolates_the_parks(t) -> void:
	for i in SEEDS_TO_STRESS:
		var map := CityGenerator.generate(_seed(i))
		var parks := map.park_tiles()
		var doorstep := Vector2i(map.home_rect.position.x, map.home_rect.end.y)
		var worst := ""
		for segment in _street_segments(map):
			if segment.has_point(doorstep):
				continue
			var blocked := {}
			for tile in map.rect_tiles(segment):
				blocked[tile] = true
			var reachable := map.walk_distances(map.home_rect.position, blocked)
			var found := false
			for park_tile in parks:
				if reachable.has(park_tile):
					found = true
					break
			if not found:
				worst = "closing %s cuts the home off from every park" % segment
				break
		t.check(worst == "", "seed %d: no single street closure isolates the parks (%s)"
				% [_seed(i), worst])

## Each stretch of corridor running alongside one block, in both orientations — the unit a
## barricade or a checkpoint would close.
func _street_segments(map: CityMap) -> Array[Rect2i]:
	var segments: Array[Rect2i] = []
	var period := CityMap.period()
	var width := Tuning.STREET_WIDTH
	for corridor in Tuning.CITY_BLOCKS.x + 1:
		for row in Tuning.CITY_BLOCKS.y:
			var block_y := CityMap.block_rect(Vector2i(0, row)).position.y
			segments.append(Rect2i(corridor * period, block_y, width, Tuning.BLOCK_SIZE))
	for corridor in Tuning.CITY_BLOCKS.y + 1:
		for column in Tuning.CITY_BLOCKS.x:
			var block_x := CityMap.block_rect(Vector2i(column, 0)).position.x
			segments.append(Rect2i(block_x, corridor * period, Tuning.BLOCK_SIZE, width))
	return segments

func _seed(index: int) -> int:
	# Spread the seeds out; consecutive integers are what generate() retries with.
	return 1000 + index * 7919

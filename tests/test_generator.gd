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
	_test_the_home_is_in_the_middle_of_a_city_worth_walking(t)
	_test_calm_zones_are_four_blocks_of_one_thing(t)
	_test_a_calm_zone_is_a_route_rather_than_a_lap(t)
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
		t.check(first.calm_blocks == second.calm_blocks, "seed %d keeps its parks" % _seed(i))

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

## **The home is in the middle, and the walk out is still long.** *(Playtest 11, finding 4: "I spawn
## too often at the edge leaving only a few ways into the rest of the city.")*
##
## These are two rules that used to compete for the same thing — the walk out has to be long enough
## to matter — and the competition was settled by walking the home *outward* until it was far
## enough from calm ground. Measured over ten seeds on the old 7x7 lattice it landed 1.97 blocks off
## centre and was central in four of ten, which puts the doorstep against the boundary, where half
## the directions out are a wall.
##
## Asserted together and over many seeds, because that is the whole claim: an odd lattice wide
## enough that the middle is still a long walk from anywhere calm. Either one alone is easy — a home
## in the middle of a small city has a park next door, and a home a long way from a park is a home in
## a corner.
func _test_the_home_is_in_the_middle_of_a_city_worth_walking(t) -> void:
	t.check(Tuning.CITY_BLOCKS.x % 2 == 1 and Tuning.CITY_BLOCKS.y % 2 == 1,
			"the lattice is odd on both axes, so there is a middle block to put the home in")
	var middle := (Tuning.CITY_BLOCKS - Vector2i.ONE) / 2
	for i in 24:
		var map := CityGenerator.generate(_seed(i))
		t.check(map.home_block == middle,
				"seed %d: the home is in the middle block %s, not %s"
				% [_seed(i), middle, map.home_block])
		# The map's own measurement, not a second one: it is taken from inside the home rather
		# than from the doorstep, so a private version of this sum reads one tile short and fails
		# on about one seed in twenty-four while the guarantee itself holds.
		var distance := map.home_to_nearest_calm()
		t.check(distance >= Tuning.MIN_HOME_TO_PARK_TILES,
				"seed %d: and calm ground is still %d tiles away, against the %d asked for"
				% [_seed(i), distance, Tuning.MIN_HOME_TO_PARK_TILES])

## M21. A four-block calm zone is four blocks of *one* thing — one lot, one arc, one entry in
## everything that counts calm areas — and the ground under it is unbroken.
##
## The failure this is really guarding against is a zone that is four calm blocks that happen to
## be adjacent. That would count as four calm areas, so the closure planner would think a day
## with two ways into one park had four; `_ensure_one_usable_park` would protect a quarter of it;
## and M24 would spoil the corner she settled in and call the job done.
func _test_calm_zones_are_four_blocks_of_one_thing(t) -> void:
	for i in 12:
		var map := CityGenerator.generate(_seed(i))
		t.check(map.zone_rects.size() >= Tuning.MIN_CALM_ZONES
				and map.zone_rects.size() <= Tuning.MAX_CALM_ZONES,
				"seed %d has %d calm zones, wanted %d..%d" % [_seed(i), map.zone_rects.size(),
				Tuning.MIN_CALM_ZONES, Tuning.MAX_CALM_ZONES])
		for anchor: Vector2i in map.zone_rects:
			var footprint: Rect2i = map.zone_rects[anchor]
			t.check(footprint.size == Vector2i.ONE * Tuning.CALM_ZONE_BLOCKS,
					"seed %d: zone %s is %d blocks square" % [_seed(i), anchor,
					Tuning.CALM_ZONE_BLOCKS])

			# One lot: the anchor has the arc and the layout, and the other three have neither.
			var members := 0
			for y in range(footprint.position.y, footprint.end.y):
				for x in range(footprint.position.x, footprint.end.x):
					var block := Vector2i(x, y)
					members += 1
					t.check(map.anchor_of(block) == anchor,
							"seed %d: block %s belongs to zone %s" % [_seed(i), block, anchor])
					t.check((block == anchor) == map.block_plans.has(block),
							"seed %d: only the anchor of zone %s has an arc" % [_seed(i), anchor])
			t.check(members == Tuning.CALM_ZONE_BLOCKS * Tuning.CALM_ZONE_BLOCKS,
					"seed %d: zone %s covers %d blocks" % [_seed(i), anchor, members])

			# One piece of ground: every tile of the lot, streets between the blocks included.
			var kinds := {}
			for tile in map.rect_tiles(map.lot_rect(anchor)):
				kinds[map.tile_at(tile)] = true
				t.check(map.is_walkable(tile),
						"seed %d: zone %s is walkable throughout, at %s" % [_seed(i), anchor, tile])
			for kind: GameEnums.TileType in kinds:
				t.check(kind == GameEnums.TileType.PLAYGROUND or Tile.is_calm(kind),
						"seed %d: zone %s is calm ground and nothing else (found %s)"
						% [_seed(i), anchor, GameEnums.TileType.keys()[kind]])

		# The arterial is the street the city cannot afford to lose a stretch of: it is the
		# noise floor, it is the thing that has to be crossed, and it is what a player learns
		# first. A zone may take any corridor but that one.
		for key: Vector3i in map.absent_segments:
			var corridor: int = key.y if key.z == 0 else key.x
			# Which corridor that is comes from the **map** since playtest 14, because the spine
			# is rolled per city rather than always being the middle one. The east-west number is
			# still a constant and is not an arterial — it is the corridor the city's east and
			# west exits open onto. See `CityGenerator._zone_fits`.
			var protected: int = map.main_road if key.z != 0 \
					else CrowdLanes.arterial_index(Tuning.CITY_BLOCKS.y)
			t.check(corridor != protected,
					"seed %d: no zone swallowed a stretch of the arterial (%s did)"
					% [_seed(i), key])

## The claim M21 exists to make good, as a relationship rather than a number.
##
## Playtest 03 watched the traced player walk in a circle inside a courtyard for twenty seconds.
## That is what the rules ask for and no balance pass removes it: standing still *drains*
## sleepiness, so progress requires motion, and a calm block is eight tiles across. The fix has
## to be geometric — the calm has to be big enough that filling the meter is a matter of walking
## somewhere rather than of walking round.
##
## So: crossing a zone corner to corner has to be worth a real share of a full meter, and a
## single block must not be. Both halves matter — if a block were enough, the zone would be
## decoration; if the zone were enough on its own, arriving would be the whole of it.
func _test_a_calm_zone_is_a_route_rather_than_a_lap(t) -> void:
	var fill := Tuning.METER_MAX / Tuning.sleepiness_gain_calm()
	var zone_px := (Tuning.CALM_ZONE_BLOCKS * Tuning.BLOCK_SIZE
			+ (Tuning.CALM_ZONE_BLOCKS - 1) * Tuning.STREET_WIDTH) * Tuning.TILE_SIZE
	var block_px := Tuning.BLOCK_SIZE * Tuning.TILE_SIZE
	var zone_cross := sqrt(2.0) * zone_px / Tuning.WALK_SPEED
	var block_cross := sqrt(2.0) * block_px / Tuning.WALK_SPEED
	t.check(zone_cross > fill * 0.25,
			"crossing a calm zone (%.1fs) is a quarter of a full meter (%.1fs) or better"
			% [zone_cross, fill])
	t.check(block_cross < fill * 0.25,
			"crossing a single calm block (%.1fs) is not, which is why one is a lap"
			% block_cross)
	t.check(zone_cross < fill,
			"and a zone is still not a whole meter in one traverse (%.1fs of %.1fs)"
			% [zone_cross, fill])

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
		var parks := map.calm_tiles()
		var doorstep := Vector2i(map.home_rect.position.x, map.home_rect.end.y)
		var worst := ""
		for segment in _street_segments(map):
			if segment.has_point(doorstep):
				continue
			var blocked := {}
			for tile in map.rect_tiles(segment):
				blocked[tile] = true
			var reachable := map.walk_field(map.home_rect.position, blocked)
			var found := false
			for park_tile in parks:
				if map.reaches(reachable, park_tile):
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

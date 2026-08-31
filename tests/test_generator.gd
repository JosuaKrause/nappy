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
	_test_calm_is_never_at_the_edge_or_beside_the_spine(t)
	_test_no_two_calm_areas_are_in_each_others_ring(t)
	_test_a_calm_zone_is_a_route_rather_than_a_lap(t)
	_test_a_dead_end_is_a_dead_end(t)
	_test_a_big_building_joins_two_blocks(t)
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

		# The main road is the street the city cannot afford to lose a stretch of: it is the
		# noise floor, it is the thing that has to be crossed, and it is what a player learns
		# first. A zone may take any corridor but that one.
		#
		# **It is one street and one axis, which is the half this used to get wrong.** Until M52 it
		# also protected `CrowdLanes.arterial_index` on the east-west axis, which is not an arterial
		# — there is one main road and it runs north to south. That guard was written when the city
		# had east and west exits opening onto that corridor; playtest 14 deleted them, and what was
		# left was a rule nobody had taken, asserted here against a constant rather than against the
		# map. It is gone from `_zone_fits` and gone from here with it.
		for key: Vector3i in map.absent_segments:
			# Zone-absorbed streets only. `absent_segments` stopped being the zone set in M50 —
			# a dead end is absent too, for the opposite reason — and this sentence is about
			# zones. Asserting it over the whole set was the identity standing in for the
			# property, which is a mistake this project has made before and can now name.
			if map.is_hard_blocker(key) or key.z == 0:
				continue
			t.check(key.x != map.main_road,
					"seed %d: no zone swallowed a stretch of the main road (%s did)"
					% [_seed(i), key])

## The claim M21 exists to make good, as a relationship rather than a number.
##
## Playtest 03 watched the traced player walk in a circle inside a courtyard for twenty seconds.
## That is what the rules ask for and no balance pass removes it: standing still *drains*
## sleepiness, so progress requires motion, and a calm block is eight tiles across. The fix has
## to be geometric — the calm has to be big enough that filling the meter is a matter of walking
## somewhere rather than of walking round.
##
## So: crossing a zone corner to corner has to be worth a real share of a full meter, and it must
## not be the whole of it — if a traverse filled the meter, arriving would be the whole game.
##
## **And the other half of this test was rewritten in M52 rather than repaired.** It used to say a
## single block is *not* worth that share — "which is why one is a lap" — and that was the right
## sentence while every calm area filled at one rate. The rate is a curve over the lot's width now
## (`Tuning.sleepiness_calm_multiplier`), and the whole point of the curve is that **a small area
## pays about as much per traverse of itself as a big one does**. Restating the old assertion
## against the new rate would have been asserting the thing that was just deliberately removed, so
## what is checked instead is the property the curve is *for*: the two sizes are within half of each
## other in traverses-per-meter, where before the change they were 2.75x apart.
##
## Note what did **not** move, because it is the reason M21 exists and the curve does not repeal it:
## a block is still a lap and a zone is still a route. The curve pays for the lap; it does not make
## the block bigger.
func _test_a_calm_zone_is_a_route_rather_than_a_lap(t) -> void:
	var zone_blocks := Tuning.CALM_ZONE_BLOCKS * Tuning.CALM_ZONE_BLOCKS
	var fill := Tuning.METER_MAX / Tuning.sleepiness_gain_calm(zone_blocks)
	var block_fill := Tuning.METER_MAX / Tuning.sleepiness_gain_calm(1)
	var zone_px := (Tuning.CALM_ZONE_BLOCKS * Tuning.BLOCK_SIZE
			+ (Tuning.CALM_ZONE_BLOCKS - 1) * Tuning.STREET_WIDTH) * Tuning.TILE_SIZE
	var block_px := Tuning.BLOCK_SIZE * Tuning.TILE_SIZE
	var zone_cross := sqrt(2.0) * zone_px / Tuning.WALK_SPEED
	var block_cross := sqrt(2.0) * block_px / Tuning.WALK_SPEED
	t.check(zone_cross > fill * 0.25,
			"crossing a calm zone (%.1fs) is a quarter of a full meter (%.1fs) or better"
			% [zone_cross, fill])
	t.check(zone_cross < fill,
			"and a zone is still not a whole meter in one traverse (%.1fs of %.1fs)"
			% [zone_cross, fill])

	# Traverses of itself to fill the meter, for each size. The curve exists to bring these
	# together; a ratio far from 1 in either direction is a size that is the obviously right or
	# obviously wrong destination for a reason that is not about what it is.
	var zone_laps := fill / zone_cross
	var block_laps := block_fill / block_cross
	t.check(maxf(zone_laps, block_laps) / minf(zone_laps, block_laps) < 1.5,
			"a small calm area costs about what a zone does per traverse of itself "
			+ "(%.1f laps against %.1f)" % [block_laps, zone_laps])
	t.check(block_laps > 1.0 and zone_laps > 1.0,
			"and neither size is filled by one traverse (%.1f, %.1f)" % [block_laps, zone_laps])

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

## Hard blockers. *(M50 step 1.)*
##
## The thing that makes this worth a test of its own is that a dead end is a claim made on the
## **lattice** and paid for on the **tiles**, and the two can disagree in both directions. A
## street missing from the graph whose ground still goes through is not a dead end, it is a
## routing bug the player walks straight past; a street whose ground stops but which the graph
## still offers is a route into a wall. So every clause below is checked on the tiles, against a
## fact stated on the graph.
##
## The counts are the other half: a city with no dead ends in it silently loses the whole
## milestone, and every check here would still pass.
func _test_a_dead_end_is_a_dead_end(t) -> void:
	var total := 0
	var seeds := 12
	for i in seeds:
		var map := CityGenerator.generate(_seed(i))
		var home := ClosurePlanner.home_street(map)
		var calm := {}
		for anchor in map.calm_blocks:
			var lot := map.lot_blocks(anchor)
			for y in range(lot.position.y, lot.end.y):
				for x in range(lot.position.x, lot.end.x):
					calm[Vector2i(x, y)] = true

		t.check(not map.dead_ends.is_empty(), "seed %d has dead ends at all" % _seed(i))
		t.check(map.dead_ends.size() <= Tuning.MAX_CUL_DE_SACS,
				"seed %d has at most %d of them (%d)"
				% [_seed(i), Tuning.MAX_CUL_DE_SACS, map.dead_ends.size()])
		total += map.dead_ends.size()

		for key: Vector3i in map.dead_ends:
			var segment := StreetNetwork.by_key(key)
			t.check(map.absent_segments.has(key),
					"seed %d: dead end %s is out of the lattice too" % [_seed(i), key])
			t.check(key != home.key(),
					"seed %d: and is not the street outside the front door" % _seed(i))

			# The ground stops. One strip across the corridor is built over, and it is at an end
			# rather than in the middle — a wall in the middle would be two dead ends and a street
			# nobody can see the shape of.
			var rect := segment.tile_rect()
			var blocked_rows := 0
			var along := rect.size.x if segment.horizontal else rect.size.y
			for step in along:
				var walkable := 0
				for across in (rect.size.y if segment.horizontal else rect.size.x):
					var tile := rect.position + (Vector2i(step, across) if segment.horizontal
							else Vector2i(across, step))
					if map.is_walkable(tile):
						walkable += 1
				if walkable == 0:
					blocked_rows += 1
					t.check(step < Tuning.CUL_DE_SAC_WALL_TILES
							or step >= along - Tuning.CUL_DE_SAC_WALL_TILES,
							"seed %d: the wall in %s is at one end of it" % [_seed(i), key])
			t.check(blocked_rows == Tuning.CUL_DE_SAC_WALL_TILES,
					"seed %d: dead end %s is walled %d tiles deep (found %d)"
					% [_seed(i), key, Tuning.CUL_DE_SAC_WALL_TILES, blocked_rows])
			t.check(blocked_rows < along,
					"seed %d: and is still a street you can walk into" % _seed(i))

			# And it is none of the three things a dead end would stop being. The spine has to go
			# through, a precinct is a place rather than a road, and a street with calm down one
			# side of it is a doorway whatever the graph says.
			t.check(map.street_kind_at(not segment.horizontal,
					rect.position + rect.size / 2) == GameEnums.StreetKind.ORDINARY,
					"seed %d: %s is an ordinary street, not the spine or a precinct"
					% [_seed(i), key])
			var block := Vector2i(key.x, key.y)
			var opposite := block + (Vector2i.UP if segment.horizontal else Vector2i.LEFT)
			t.check(not calm.has(block) and not calm.has(opposite),
					"seed %d: %s does not run alongside calm ground" % [_seed(i), key])

	# Measured at 5.9 a city against a rolled 4-8. A floor rather than the number, because the
	# gate may legitimately refuse one; a city averaging below the minimum means the placement has
	# stopped working rather than that a seed was unlucky.
	t.check(float(total) / seeds >= float(Tuning.MIN_CUL_DE_SACS),
			"a city gets %.1f dead ends, wanting at least %d"
			% [float(total) / seeds, Tuning.MIN_CUL_DE_SACS])

## The other hard blocker: two blocks joined into one mass, with the street between them built
## over. *(M50, corrected 2026-08-31: "a big building just connects two blocks… I want one that
## just connects two blocks (closes one road)".)*
##
## Three clauses, and the first two are the ones a picture would not settle. **The mass is solid
## from lot to lot across the street between** — a landmark with a walkable strip left through the
## middle of it is two buildings with a road between them, which is every other pair in the city.
## **Every other street round the pair survives**, which is the correction itself: the first
## version took the whole ring, so one roll of the dice removed four streets and made an island.
## And a big building **is not a dead end**, so the two are told apart in `built_over`, because
## they are absent for opposite reasons and the picture draws them differently.
##
## Its lots never re-open either. `tests/test_blocks.gd` holds that in general — the walkable set
## is identical tile for tile across every block arc — and here the mechanism is that each block's
## `BlockLayout` is empty, so a repaint finds nothing to paint back.
func _test_a_big_building_joins_two_blocks(t) -> void:
	var seeds := 12
	var total := 0
	for i in seeds:
		var map := CityGenerator.generate(_seed(i))
		t.check(not map.big_buildings.is_empty(), "seed %d has a landmark in it" % _seed(i))
		t.check(map.big_buildings.size() <= Tuning.MAX_BIG_BUILDINGS,
				"seed %d has at most %d (%d)"
				% [_seed(i), Tuning.MAX_BIG_BUILDINGS, map.big_buildings.size()])
		total += map.big_buildings.size()

		for pair: Rect2i in map.big_buildings:
			t.check(pair.size == Vector2i(2, 1) or pair.size == Vector2i(1, 2),
					"seed %d: the landmark %s is two neighbouring blocks" % [_seed(i), pair])
			for block in [pair.position, pair.end - Vector2i.ONE]:
				t.check(map.starting_purpose(block) == GameEnums.BlockPurpose.BIG_BUILDING,
						"seed %d: block %s is a big building for the whole run" % [_seed(i), block])
				var layout: BlockLayout = map.block_layouts.get(block)
				t.check(layout != null and not BlockLayout.has(layout.open_rect),
						"seed %d: and has nothing carved into it to repaint" % _seed(i))

			# Solid across the whole footprint, the street between included.
			for tile in map.rect_tiles(CityMap.blocks_tile_rect(pair)):
				t.check(not map.is_walkable(tile),
						"seed %d: the mass at %s is solid at %s" % [_seed(i), pair, tile])

			# One street gone, and it is the one between them — derived here as the street both
			# blocks' own rings have in common, rather than restated from the generator's rule.
			var ring := {}
			for segment in StreetNetwork.around_blocks(Rect2i(pair.position, Vector2i.ONE)):
				ring[segment.key()] = true
			var between := Vector3i.ZERO
			for segment in StreetNetwork.around_blocks(Rect2i(pair.end - Vector2i.ONE,
					Vector2i.ONE)):
				if ring.has(segment.key()):
					between = segment.key()
			t.check(not map.has_street(between),
					"seed %d: the street %s between them is out of the lattice"
					% [_seed(i), between])
			t.check(map.is_hard_blocker(between),
					"seed %d: and out of it because it was built over" % _seed(i))
			t.check(not map.dead_ends.has(between),
					"seed %d: and is not counted as a dead end" % _seed(i))

			# And nothing else round the pair was taken *by the landmark*. A dead end may still sit
			# on one of them, which is legitimate city and is why the exception is named.
			for segment in StreetNetwork.around_blocks(pair):
				t.check(map.has_street(segment.key()) or map.dead_ends.has(segment.key()),
						"seed %d: %s round the landmark %s is still a street"
						% [_seed(i), segment.key(), pair])

			# Every junction round the pair is still a crossroads: what was removed is the road
			# between two of them and not the grid around it.
			for corner in map.rect_tiles(Rect2i(pair.position, pair.size + Vector2i.ONE)):
				var junction: Vector2i = corner * CityMap.period()
				t.check(map.is_street(junction + Vector2i.ONE * (Tuning.STREET_WIDTH / 2)),
						"seed %d: the junction at %s is still a junction" % [_seed(i), corner])
	t.check(float(total) / seeds >= float(Tuning.MIN_BIG_BUILDINGS),
			"a city gets %.1f big buildings, wanting at least %d"
			% [float(total) / seeds, Tuning.MIN_BIG_BUILDINGS])

func _seed(index: int) -> int:
	# Spread the seeds out; consecutive integers are what generate() retries with.
	return 1000 + index * 7919

## **No calm area touches the outer ring of blocks, and none sits in either block column beside the
## main road.** *(M52, built from M47's entry; playtest 16 finding 4: "this map shows multiple calm
## zones at the edge of the map which should be impossible".)*
##
## Stated over `map.calm_blocks` and every block of every lot, for the same reason the ring test
## below is: that list is what the telemetry map outlines, and the outlines in the outer column are
## what the player was looking at when they said it. A rule checked over the *placement* path would
## have agreed with the placement path — three of them place calm and it took one shared question
## over a footprint to stop them drifting.
##
## Measured over 40 seeds: **4.42 calm areas per city touched the edge and 1.50 sat beside the
## spine** before the rule, both zero after, with open calm per city unmoved inside its 5–7 band
## (8.85 areas of which 3.00 courtyards → 8.43 of which 2.55) and generation retries per city
## falling 0.50 → 0.00 — because a courtyard beside the front door used to fail the home-distance
## guarantee and roll the whole map again.
func _test_calm_is_never_at_the_edge_or_beside_the_spine(t) -> void:
	var last := Tuning.CITY_BLOCKS - Vector2i.ONE
	for i in 24:
		var map := CityGenerator.generate(_seed(i))
		for anchor in map.calm_blocks:
			var lot := map.lot_blocks(anchor)
			for block in CityGenerator._blocks_in(lot):
				t.check(block.x > 0 and block.y > 0 and block.x < last.x and block.y < last.y,
						"seed %d: calm area %s has a block at the map edge (%s)"
						% [_seed(i), anchor, block])
				t.check(block.x != map.main_road and block.x != map.main_road - 1,
						"seed %d: calm area %s has a block beside the main road (%s, spine %d)"
						% [_seed(i), anchor, block, map.main_road])

## **No two calm areas are anywhere in each other's eight-block ring, corners included, whatever
## kind of calm they are.** *(Playtest 14 finding 7, and the 2026-08-31 re-report off a telemetry
## map: "I see two diagonally adjacent parks — that bug is still not fixed?")*
##
## Asserted here rather than only inside `CityGenerator.validate()`, and that is the point of it
## existing at all: validate() was **both** of the things that were wrong. It skipped every lot
## that was not `_OPEN_CALM`, so a courtyard was not a calm area as far as the guarantee went, and
## it stepped `RIGHT` and `DOWN` only, so it had never looked at a diagonal — including through
## M49, which fixed the diagonal in the placement rule and left the guarantee checking the old
## shape. A test that calls validate() would have agreed with it about both.
##
## So this walks the whole ring itself, over `map.calm_blocks` — the list the closure planner, the
## park rules and the telemetry picture all use, which is the list the player is looking at.
##
## Measured before the fix: 10 cities in 40 had at least one pair, 12 side by side and 8 diagonal,
## and every one of them was courtyard-to-courtyard. It costs one extra generation attempt in
## forty and takes calm areas per city from 9.22 to 9.18.
func _test_no_two_calm_areas_are_in_each_others_ring(t) -> void:
	for i in 24:
		var map := CityGenerator.generate(_seed(i))
		var owner := {}
		for block in map.calm_blocks:
			var lot := map.lot_blocks(block)
			for y in range(lot.position.y, lot.end.y):
				for x in range(lot.position.x, lot.end.x):
					owner[Vector2i(x, y)] = block
		for member: Vector2i in owner:
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var neighbour: Vector2i = member + Vector2i(dx, dy)
					if not owner.has(neighbour) or owner[neighbour] == owner[member]:
						continue
					t.check(false,
							"seed %d: calm areas %s (%s) and %s (%s) meet at %s"
							% [_seed(i), owner[member],
							GameEnums.BlockPurpose.keys()[map.starting_purpose(owner[member])],
							owner[neighbour],
							GameEnums.BlockPurpose.keys()[map.starting_purpose(owner[neighbour])],
							member])

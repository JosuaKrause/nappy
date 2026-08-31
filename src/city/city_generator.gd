class_name CityGenerator
extends RefCounted
## Builds a CityMap deterministically from a run seed. See docs/CITY.md.
##
## Pure data, no nodes, so a test can hammer it across hundreds of seeds headlessly.
##
## The street lattice is cut in exactly two places and both are deliberate: a calm zone absorbs
## the streets between its own blocks (M21), and a hard blocker takes one (M50). Everything else —
## alleys, plazas, the home — is carved *inside* a block, so the grid a player learns is the grid.
##
## That used to guarantee *"at least two distinct routes to every park"* by construction, because a
## full lattice cannot be disconnected by removing any single corridor. It is checked by search
## now, and what is checked is weaker on purpose: **every calm area stays reachable**, with the
## second route an offer rather than a promise. See `Tuning.MIN_CALM_AREAS_REACHABLE`.

## How many seeds to try before accepting a map that fails the soft guarantees.
const MAX_ATTEMPTS := 64

## How many of the non-calm blocks get each built purpose. Whatever is left over is
## residential, which is what most of a city is.
const _BUILT_TARGETS := {
	GameEnums.BlockPurpose.CIVIC: 2,
	GameEnums.BlockPurpose.COMMERCIAL: 8,
	GameEnums.BlockPurpose.INDUSTRIAL: 6,
}

## The calm kinds a whole block can be. A courtyard is not here: it is a residential block
## with a court cut into it, which is what makes it *hidden* calm — you have to know it is
## there, and that is exactly the knowledge a fixed city is supposed to reward.
const _OPEN_CALM: Array[GameEnums.BlockPurpose] = [
	GameEnums.BlockPurpose.PARK,
	GameEnums.BlockPurpose.FOREST,
	GameEnums.BlockPurpose.QUIET_SQUARE,
]

## Every purpose that makes a block a **calm area**, which is what the spread guarantee is stated
## over and what `map.calm_blocks` contains.
##
## **It is not `_OPEN_CALM`, and reading one for the other is a bug this project has now shipped.**
## *(2026-08-31: "I see two diagonally adjacent parks — that bug is still not fixed?", off a
## telemetry map. See `docs/PLAYTEST-14.md`, finding 7.)* `_OPEN_CALM` is the list of purposes laid
## as *open ground*, which is a fact about what a generator paints; the spread rule is about what
## the player can see from a pavement, and a courtyard is calm she can settle in like any other. So
## the M49 fix that added the corners to the ring was checking three of the four kinds of calm, and
## 10 cities in 40 had a pair of courtyards touching — 12 side by side and 8 diagonal.
const _CALM_PURPOSES: Array[GameEnums.BlockPurpose] = [
	GameEnums.BlockPurpose.PARK,
	GameEnums.BlockPurpose.FOREST,
	GameEnums.BlockPurpose.QUIET_SQUARE,
	GameEnums.BlockPurpose.COURTYARD,
]

## Generates a city, retrying with adjacent seeds until the guarantees hold.
static func generate(seed_value: int) -> CityMap:
	var last: CityMap = null
	for attempt in MAX_ATTEMPTS:
		var map := _attempt(seed_value + attempt)
		last = map
		if validate(map) == "":
			return map
	push_warning("CityGenerator: no seed near %d satisfied every guarantee (%s)"
			% [seed_value, validate(last)])
	return last

static func _attempt(seed_value: int) -> CityMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var map := CityMap.new()
	map.seed_used = seed_value

	_assign_street_kinds(map)
	_lay_streets(map)
	var purposes := _assign_purposes(map, rng)
	var block_rects := _build_blocks(map, purposes, rng)
	_place_home(map, block_rects)
	_plan_arcs(map, purposes, rng)

	# The map starts on day 1, which is every block at step 0 of its arc.
	var state := CityState.new()
	map.repaint(state)
	# **After the repaint, and that is not an ordering detail.** Hard blockers are placed against
	# where the calm is, which is what `repaint` works out, and they close street ground — which
	# `repaint` never touches, so no later day can undo one. A big building also *replaces* a
	# block's carved rects, which is why the buildings are collected afterwards rather than before.
	_place_hard_blockers(map, purposes, block_rects, rng)
	for rects in block_rects.values():
		map.building_rects.append_array(rects)
	return map

# ------------------------------------------------------------------ streets ---

## Decides where the main road and the precincts are, before a tile is laid.
##
## Seeded from the map seed with an RNG of its own rather than drawn from the generator's, the
## same trick `CrowdLanes.busyness` uses: the hierarchy is a property of the city, and taking it
## out of the shared stream means adding it moves nothing else that a seed already decided.
##
## There is **only** one main road and it is the north-south one. *(Playtest 12, finding 2.)*
##
## **Where it runs is rolled, and until playtest 14 it was always the middle corridor.** It was
## `CrowdLanes.arterial_index` — the centre of the map, on every seed — so the one landmark the
## city has stood in the same place relative to the home in every run anybody had ever played:
## *"I have the feeling the main road is now always left to home. It should move around more."*
## A fixed city is worth learning; a city that is the same city every time is not, and the spine
## is the largest single thing a player navigates by.
##
## Kept **three corridors clear of either boundary**, which is the one constraint that is not
## taste. The spine divides the city in two and both halves have to be worth being in — M47 makes
## crossing it a soft block — so a main road near the edge is a wall with a corner behind it rather
## than a division. It also cannot be a boundary corridor at all: those have buildings on one side
## only, and the tunnel and the bridge are holes punched through the ring of frontages.
##
## Two was tried first and is too near. At corridor 9 of eleven the city east of the spine is two
## block-columns, and `tests/test_crowd.gd` saw it before a player could: 256 overlapping
## crossing-axis pairs in a junction box over a minute against a tolerance of 180, where the same
## city with a central spine gives well under it. A sliver has the spine's whole traffic funnelling
## through junctions that have nowhere to spread to.
##
## `map.main_road` is the answer everywhere. `CrowdLanes.arterial_index` is now only the *default*
## the map is built from, and anything asking "which corridor is the main road" that reaches for it
## instead is the M46 defect — a fact about a city answered from a constant.
static func _assign_street_kinds(map: CityMap) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("street:%d" % map.seed_used)
	var corridors := CrowdLanes.corridor_count(Tuning.CITY_BLOCKS.x)
	map.main_road = rng.randi_range(3, corridors - 4)
	_place_precincts(map, rng)

## The two precincts, three blocks each. *(Playtest 12, findings 1 and 7: "a stretch of three
## blocks at the shore, like a coney island beach walk, and three blocks in the city somewhere —
## no more.")*
##
## One is always the **shore**: the southern boundary street, which is the one corridor in the
## city with buildings on a single side, so a promenade there has a front and a back the way a
## sea front does. The other is inland and may be on either axis.
##
## They are stretches rather than corridors because that is what makes a precinct a *place*. A
## whole corridor of it is a kind of street, and a kind of street you meet every third block is
## simply what a street is — which is the version this replaced.
static func _place_precincts(map: CityMap, rng: RandomNumberGenerator) -> void:
	map.precinct_spans.clear()
	var length := Tuning.PRECINCT_BLOCKS

	var shore := CrowdLanes.corridor_count(Tuning.CITY_BLOCKS.y) - 1
	var along := rng.randi_range(0, Tuning.CITY_BLOCKS.x - length)
	map.precinct_spans.append(Vector4i(0, shore, along, along + length - 1))

	# Inland: never the spine, never beside it — a car diverted off the main road needs the
	# street next to it to be a street — and never the boundary, which is either the shore itself
	# or the far side of the city from it.
	for _attempt in 24:
		var vertical := rng.randf() < 0.5
		var blocks: int = Tuning.CITY_BLOCKS.x if vertical else Tuning.CITY_BLOCKS.y
		var across: int = Tuning.CITY_BLOCKS.y if vertical else Tuning.CITY_BLOCKS.x
		var corridor := rng.randi_range(1, CrowdLanes.corridor_count(blocks) - 2)
		if vertical and absi(corridor - map.main_road) <= 1:
			continue
		var start := rng.randi_range(0, across - length)
		map.precinct_spans.append(
				Vector4i(1 if vertical else 0, corridor, start, start + length - 1))
		return

static func _lay_streets(map: CityMap) -> void:
	# The offsets are a modulo and the kinds are a short scan of the precinct list, so both are
	# hoisted per row and per column rather than asked once per tile of a lattice this size.
	var x_offsets := PackedInt32Array()
	x_offsets.resize(map.size.x)
	for x in map.size.x:
		x_offsets[x] = CityMap.corridor_offset(x)
	for y in map.size.y:
		var y_offset := CityMap.corridor_offset(y)
		# The kind of each corridor *at this row*: a precinct is three blocks of a street, so a
		# vertical corridor's kind changes as the row moves down it.
		var x_kinds := PackedByteArray()
		x_kinds.resize(map.size.x)
		for x in map.size.x:
			x_kinds[x] = map.street_kind_at(true, Vector2i(x, y))
		for x in map.size.x:
			var x_offset := x_offsets[x]
			if x_offset < 0 and y_offset < 0:
				map.set_tile(Vector2i(x, y), GameEnums.TileType.BUILDING)
			else:
				map.set_tile(Vector2i(x, y), _street_tile(x_offset,
						x_kinds[x] as GameEnums.StreetKind, y_offset,
						map.street_kind_at(false, Vector2i(x, y))))

## Sidewalk | road | sidewalk across a corridor. Where a road crosses the *other*
## corridor's sidewalk band you get a pedestrian crossing, which is exactly where a
## crossing belongs.
##
## Two kinds change what that produces, and both changes are the kind saying what the street is
## rather than a new rule about geometry:
##
## - **A pedestrianised corridor has no carriageway**, so its own band is paving all the way
##   across and a driveable street crossing it does so over a zebra six tiles deep.
## - **A main road's crossing is signalled rather than negotiated, and since M51 it is not a
##   zebra.** *(Playtest 15, finding 2: "the main road shouldn't have zebra crossings (since they
##   have traffic lights) it should be two dotted lines demarking the pedestrian safe zone".)*
##   Traffic on a main road does not give way to somebody at the kerb — it obeys the light — so
##   the crossing is a *timing* problem where an ordinary one is a gap-hunting problem, and a
##   zebra was the paint promising the wrong one of those at every junction of the one street
##   where getting it wrong ends the day. See `CrowdAgent._give_way` and `TrafficSignals`.
##
##   **The tile type does not change and that is the point.** Painting the crossing away was tried
##   in M41 and is worse — a walker crossing a side street would then be standing on open
##   carriageway, and the one thing a crossing is for is saying where a person on a road is meant
##   to be — so what moved is the picture and nothing else. Every rule that reads `CROSSING`, from
##   the traffic's give-way scan to where an event may stand, goes on meaning what it meant.
##   `GroundTiles._crossing_variant` is where the two dotted lines are drawn.
static func _street_tile(x_offset: int, x_kind: GameEnums.StreetKind,
		y_offset: int, y_kind: GameEnums.StreetKind) -> GameEnums.TileType:
	var x_road := x_offset >= 0 and x_kind != GameEnums.StreetKind.PEDESTRIAN \
			and CityMap.is_road_offset(x_offset)
	var y_road := y_offset >= 0 and y_kind != GameEnums.StreetKind.PEDESTRIAN \
			and CityMap.is_road_offset(y_offset)

	if x_offset >= 0 and y_offset >= 0:
		if x_road and y_road:
			return GameEnums.TileType.ROAD
		if x_road or y_road:
			return GameEnums.TileType.CROSSING
		return GameEnums.TileType.SIDEWALK

	return GameEnums.TileType.ROAD if (x_road or y_road) else GameEnums.TileType.SIDEWALK

# ----------------------------------------------------------------- purposes ---

## Decides what each block starts as. **Four-block calm zones first**, because they are the
## only thing here that needs a shape rather than a slot and every later choice can work round
## one; then single calm blocks, never side by side with anything calm, so the calm is spread
## across the map; then the built kinds; then courtyards, cut into residential blocks that are
## not already next to open calm.
##
## The dictionary that comes back is keyed by **lot anchors**, not by blocks: the three blocks a
## zone absorbed are removed at the end and live in `map.zone_anchor` instead. They carry the
## zone's purpose while this function runs, though, because that is what makes the "never side
## by side" rule see a zone as calm ground without a special case for it.
static func _assign_purposes(map: CityMap, rng: RandomNumberGenerator) -> Dictionary:
	var blocks: Array[Vector2i] = []
	for y in Tuning.CITY_BLOCKS.y:
		for x in Tuning.CITY_BLOCKS.x:
			blocks.append(Vector2i(x, y))

	var shuffled := blocks.duplicate()
	_shuffle(shuffled, rng)

	var purposes := {}
	var zones := {}
	# **The middle block is claimed for the home before anything else is decided.** Claiming it
	# rather than preferring it is what makes the home central *mandatorily*: a claimed block cannot
	# be swallowed by a calm zone (`_zone_fits` requires a wholly unclaimed footprint), cannot be
	# rolled as calm below, and is not in `remaining`, so no courtyard is cut into it either.
	purposes[home_block()] = GameEnums.BlockPurpose.RESIDENTIAL

	var areas := _place_calm_zones(purposes, zones, shuffled, rng, map.main_road)
	_place_apartment_complexes(purposes, zones, shuffled, rng, map.main_road)

	var calm_target := rng.randi_range(Tuning.MIN_CALM_BLOCKS, Tuning.MAX_CALM_BLOCKS)
	for block in shuffled:
		if areas >= calm_target:
			break
		if purposes.has(block) or _has_calm_neighbour(purposes, Rect2i(block, Vector2i.ONE)):
			continue
		if not _calm_may_sit_here(Rect2i(block, Vector2i.ONE), map.main_road):
			continue
		purposes[block] = _OPEN_CALM[rng.randi_range(0, _OPEN_CALM.size() - 1)]
		areas += 1

	var remaining: Array[Vector2i] = []
	for block in shuffled:
		if not purposes.has(block):
			remaining.append(block)

	var index := 0
	for purpose: GameEnums.BlockPurpose in _BUILT_TARGETS:
		for i in _BUILT_TARGETS[purpose]:
			if index >= remaining.size():
				break
			purposes[remaining[index]] = purpose
			index += 1
	while index < remaining.size():
		purposes[remaining[index]] = GameEnums.BlockPurpose.RESIDENTIAL
		index += 1

	_cut_courtyards(purposes, remaining, rng, map.main_road)
	_record_zones(map, purposes, zones)
	return purposes

# ------------------------------------------------------- four-block calm zones ---

## Picks the multi-block calm zones and marks every block of each. Returns how many calm areas it
## made, which is what the single-block pass counts on from.
##
## **The first one is the square and the rest are rolled from `Tuning.CALM_ZONE_SHAPES`.** *(M52.)*
## That ordering is the whole of how variety was added without repealing anything: M21's guarantee
## is that every city has a four-block zone, because the lap is what it exists to remove, and a
## shape rolled for the *first* zone would have made that guarantee a matter of luck. So the square
## is placed first and unconditionally, and every zone after it may be a 2x1 either way up.
##
## A shape that fits nowhere falls through to the next one rather than costing the city a zone —
## the rectangles are two thirds of the list and the square is the hardest thing to fit, so a run of
## unlucky rolls would otherwise show up as a slower generator, which is the failure mode M47
## warned about for the placement rules.
##
## Two constraints beyond "does it fit", and both are the same rules a single calm block obeys,
## asked of the whole footprint:
##
## - **Somewhere calm ground may go at all** — `_calm_may_sit_here`, which is the home clearance,
##   the boundary ring and the two columns beside the spine. The last of those is also what keeps a
##   zone from swallowing a stretch of the main road, which used to be a guard of its own here.
## - **Never beside other calm.** A four-block park with a quiet square across the road from it is
##   one calm area with an awkward middle, and the point of several is that they are somewhere else.
static func _place_calm_zones(purposes: Dictionary, zones: Dictionary,
		shuffled: Array[Vector2i], rng: RandomNumberGenerator, main_road: int) -> int:
	var wanted := rng.randi_range(Tuning.MIN_CALM_ZONES, Tuning.MAX_CALM_ZONES)
	var made := 0
	for index in wanted:
		var shapes := _shapes_to_try(index, rng)
		for shape in shapes:
			if _place_one_zone(purposes, zones, shuffled, rng, main_road, shape):
				made += 1
				break
	return made

## The footprints this zone will try, in order. The first zone of a city tries the square and
## nothing else; every later one tries all of them, starting from a rolled shape.
static func _shapes_to_try(index: int, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var square := Vector2i.ONE * Tuning.CALM_ZONE_BLOCKS
	if index == 0:
		var only: Array[Vector2i] = [square]
		return only
	var shapes := Tuning.CALM_ZONE_SHAPES.duplicate()
	_shuffle(shapes, rng)
	return shapes

## Puts one zone of exactly this shape down, at the first anchor that will take it. False when
## nowhere in the city will.
static func _place_one_zone(purposes: Dictionary, zones: Dictionary, shuffled: Array[Vector2i],
		rng: RandomNumberGenerator, main_road: int, shape: Vector2i) -> bool:
	for anchor in shuffled:
		var footprint := Rect2i(anchor, shape)
		if not _zone_fits(purposes, footprint, main_road):
			continue
		var purpose := _OPEN_CALM[rng.randi_range(0, _OPEN_CALM.size() - 1)]
		for block in _blocks_in(footprint):
			purposes[block] = purpose
		zones[anchor] = footprint
		return true
	return false

## The apartment complexes: courtyard lots four blocks across. *(M52, from M47's entry.)*
##
## **The same pass as a calm zone and the opposite ground.** A zone absorbs the streets between its
## blocks and paints park over them; this absorbs them and *builds over* them, so what comes out is
## a mass twenty-two tiles square with a court in the middle and one archway in. Nothing here is a
## new mechanism — the footprint test, the absorb, the lot rect and the daily repaint are all M21's
## — which is why the entry that asked for it says the mechanism is M21's.
##
## Three things about it that are decisions rather than consequences:
##
## - **It is a `COURTYARD` and not a purpose of its own.** What a block purpose says is what the
##   ground *is*, and this is a courtyard: buildings with a court cut into them. What is new is the
##   size of the lot, which is a fact about the footprint, and adding an enum value for it would be
##   the `EventDef.Look` mistake — a category is a thing you can always put one more row into.
## - **It does not count toward the calm target.** Like a single-block courtyard, it is *hidden*
##   calm placed on top of the 5–7 areas the player asked to keep, rather than one of them. Placing
##   it here rather than in `_cut_courtyards` is only because it needs a whole unclaimed footprint,
##   which is a thing to ask for before the single blocks are handed out.
## - **Its absorbed streets are hard blockers.** They are solid ground for the whole run, which is
##   exactly what `built_over` means, and saying so is what makes the crowd, the telemetry map and
##   the big-building placement all treat them correctly without any of them learning about
##   apartment complexes. See `_record_zones`.
static func _place_apartment_complexes(purposes: Dictionary, zones: Dictionary,
		shuffled: Array[Vector2i], rng: RandomNumberGenerator, main_road: int) -> void:
	var span := Vector2i.ONE * Tuning.CALM_ZONE_BLOCKS
	for _made in Tuning.MAX_APARTMENT_COMPLEXES:
		for anchor in shuffled:
			var footprint := Rect2i(anchor, span)
			if not _zone_fits(purposes, footprint, main_road):
				continue
			for block in _blocks_in(footprint):
				purposes[block] = GameEnums.BlockPurpose.COURTYARD
			zones[anchor] = footprint
			break

## The middle of the lattice, which is the home's block. Odd on both axes by constraint, so there
## is exactly one — see `Tuning.CITY_BLOCKS`.
static func home_block() -> Vector2i:
	return (Tuning.CITY_BLOCKS - Vector2i.ONE) / 2

## Whether a footprint is close enough to the home that putting calm ground in it would undo the
## thing the walk out is for.
##
## The two rules about the home compete — it is central, and it is `MIN_HOME_TO_PARK_TILES` of
## walking from calm ground — and with the home pinned to the middle this is the only remaining
## place to settle that.
##
## Stated in blocks because the lattice is what it constrains, and **derived from the tile guarantee
## rather than authored beside it**, or the two drift apart the first time either moves. A block `d`
## away starts `d * period()` tiles from the home block's own origin, of which `BLOCK_SIZE` is the
## home's lot — so the shortest walk to it is about `d * period() - BLOCK_SIZE`, and the clearance is
## the smallest `d` that clears the guarantee.
##
## It is a floor rather than the guarantee itself: walking distance is not straight-line, and the
## home sits in the *south* edge of its block, so real distances come out longer. `validate()` still
## checks the tile guarantee, which is what catches the case this approximation is wrong about.
static func _too_near_the_home(footprint: Rect2i) -> bool:
	var home := home_block()
	var clearance := ceili(float(Tuning.MIN_HOME_TO_PARK_TILES + Tuning.BLOCK_SIZE)
			/ float(CityMap.period()))
	for block in _blocks_in(footprint):
		var away: Vector2i = (block - home).abs()
		if maxi(away.x, away.y) < clearance:
			return true
	return false

## Where calm ground may go, as one question asked of a **footprint**, so a single block, a
## multi-block zone and a courtyard obey one rule rather than three that drift apart. *(M52, built
## from M47's entry; playtest 16, finding 4: "this map shows multiple calm zones at the edge of the
## map which should be impossible".)*
##
## Three clauses, and the first is older than the other two:
##
## - **Never near the home**, which is the walk out being worth walking. See `_too_near_the_home`.
## - **Never in the outer ring of blocks.** *"Another way to get density is to make a rule to not
##   have a calm area at the edge of the map or next to the main road."* A calm area against the
##   boundary has the ring of frontages behind it and half its approaches are a wall, so it is a
##   destination you can only arrive at from one side — and the density argument is almost all this
##   clause: the ring is 40 of the lattice's 121 blocks.
## - **Never in either block column beside the main road.** This one is not about density — it adds
##   only eight blocks on top of the ring, because the spine runs down the middle where the home
##   clearance has already taken a 5x5 out. It is about what crossing the spine is *for*:
##   `decay_multiplier` is 0.6 there, so a park you can hear the main road from is not calm ground,
##   and if calm never sits beside it then **crossing it always leads somewhere worth crossing
##   for**, which is what makes it a soft block rather than a wall. It is also the expendable one by
##   the player's own words — *"the not next to main road rule is not that important, you can remove
##   it if it loses too much freedom"* — so if the field ever gets too tight this is what comes out,
##   before `MIN_CALM_BLOCKS` or the non-adjacency rule are touched.
##
## The spine clause is stated over **`map.main_road`**, which is the only thing that knows where the
## spine is. `CrowdLanes.arterial_index` is a *default* a map is built from, and reaching for it to
## answer a question about a city is the M46 defect — the one that put a phantom east-west arterial
## in `CrowdLanes.busyness`. `_zone_fits` used to carry a copy of it for exactly that reason and
## does not any more.
static func _calm_may_sit_here(footprint: Rect2i, main_road: int) -> bool:
	if _too_near_the_home(footprint):
		return false
	var outer := Rect2i(Vector2i.ONE, Tuning.CITY_BLOCKS - Vector2i.ONE * 2)
	if not outer.encloses(footprint):
		return false
	# A corridor runs between the block column of the same index and the one before it, so the two
	# columns beside corridor `main_road` are `main_road - 1` and `main_road`. Refusing both is also
	# what keeps a zone from *absorbing* a stretch of the spine, which is the guard this replaced.
	return footprint.position.x > main_road or footprint.end.x <= main_road - 1

## Whether a calm zone's footprint is inside the map, somewhere calm ground may go, wholly
## unclaimed and clear of other calm.
static func _zone_fits(purposes: Dictionary, footprint: Rect2i, main_road: int) -> bool:
	if footprint.end.x > Tuning.CITY_BLOCKS.x or footprint.end.y > Tuning.CITY_BLOCKS.y:
		return false
	if not _calm_may_sit_here(footprint, main_road):
		return false
	for block in _blocks_in(footprint):
		if purposes.has(block):
			return false
	return not _has_calm_neighbour(purposes, footprint)

static func _blocks_in(footprint: Rect2i) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for y in range(footprint.position.y, footprint.end.y):
		for x in range(footprint.position.x, footprint.end.x):
			found.append(Vector2i(x, y))
	return found

## Writes the zones onto the map and takes the absorbed blocks out of `purposes`, so that from
## here on a lot is one entry however many blocks of ground it owns.
##
## **Whether the streets it took are ground or wall is read off the purpose**, which is the one
## place that decides it: open calm walks over them and an apartment complex is built on them. Two
## multi-block lots, one absorb, and no caller anywhere else has to know which kind it is looking
## at — a solid one says so in `built_over` and every rule about hard blockers picks it up for free.
static func _record_zones(map: CityMap, purposes: Dictionary, zones: Dictionary) -> void:
	for anchor: Vector2i in zones:
		var footprint: Rect2i = zones[anchor]
		map.zone_rects[anchor] = footprint
		for block in _blocks_in(footprint):
			map.zone_anchor[block] = anchor
			if block != anchor:
				purposes.erase(block)
		_absorb_streets(map, footprint,
				purposes[anchor] == GameEnums.BlockPurpose.COURTYARD)

## Turns some residential blocks into courtyard blocks. Never one that touches open calm:
## a hidden court is worth finding, and a court across the street from a park is not.
##
## **And it obeys `_calm_may_sit_here` like every other calm area.** *(M52.)* M47 left this open —
## *"decide courtyards separately: a courtyard is hidden calm you have to know about, and an argument
## can be made either way for one against the boundary"* — and the answer is the finding's own
## evidence: the map the player marked up outlines `calm_blocks`, which is where a courtyard appears,
## so a court in the outer ring is one of the green outlines the complaint was about. The home
## clearance comes with it, and that half was never a decision at all: a courtyard is calm ground, so
## `validate()`'s `MIN_HOME_TO_PARK_TILES` check has always been able to fail a city for one cut
## beside the front door — this refuses the block rather than rolling the whole map again.
static func _cut_courtyards(purposes: Dictionary, remaining: Array[Vector2i],
		rng: RandomNumberGenerator, main_road: int) -> void:
	var cut := 0
	for block in remaining:
		if cut >= Tuning.MAX_COURTYARD_BLOCKS:
			return
		if purposes[block] != GameEnums.BlockPurpose.RESIDENTIAL:
			continue
		if not _calm_may_sit_here(Rect2i(block, Vector2i.ONE), main_road):
			continue
		if _has_calm_neighbour(purposes, Rect2i(block, Vector2i.ONE)):
			continue
		if rng.randf() >= Tuning.COURTYARD_CHANCE:
			continue
		purposes[block] = GameEnums.BlockPurpose.COURTYARD
		cut += 1

## Whether any calm area sits anywhere around this footprint. Stated over a rect of blocks rather
## than one block so that a single block and a four-block zone are the same question asked twice,
## rather than one rule and one special case.
##
## **The whole ring, corners included.** *(Playtest 14: "calm zones shouldn't be possible diagonal
## from each other — we said they should not be next to each other, this includes the entire
## surrounding".)* It used to walk the four edges and skip the four corners, so two calm areas
## could meet at a junction: not across a street from each other but across a *crossroads*, which
## from the pavement is the same sight and is exactly what the rule exists to stop. `docs/TODO.md`
## had it as an open question in M47 — *"probably right, but it is currently an accident of the
## loop bounds rather than a decision"* — and this is the decision.
##
## Grown by one and tested by containment, rather than by four loops with the corners bolted on:
## the shape being asked about is a ring, and a ring is what `grow(1)` makes.
##
## **And every calm purpose, which is the half M49 left out.** It asked about `_OPEN_CALM` and was
## named for it, so a courtyard was invisible to it and two courtyards could meet at a corner — the
## same sight from the pavement, reported off a telemetry map on 2026-08-31. The only caller this
## changes is `_cut_courtyards`: zones and open calm are placed before a courtyard exists, so for
## them the two lists are the same list.
static func _has_calm_neighbour(purposes: Dictionary, footprint: Rect2i) -> bool:
	var ring := footprint.grow(1)
	for y in range(ring.position.y, ring.end.y):
		for x in range(ring.position.x, ring.end.x):
			var block := Vector2i(x, y)
			if footprint.has_point(block):
				continue
			if _CALM_PURPOSES.has(purposes.get(block, -1)):
				return true
	return false

## Takes the streets inside a zone out of the lattice: the two horizontal segments between its
## rows and the two vertical ones between its columns.
##
## That is the whole of it, and the graph half of `StreetNetwork` needs no other change —
## `map.absent_segments` is added to the closed set of every route search, the four junctions
## around the removed cross become T-junctions for free, and the one in the middle of the zone
## is left with nothing reaching it at all.
##
## Then the **stub**. Each of the four surviving junctions on the zone's edge is a T now, and
## the quarter of it on the zone's side is a two-tile spur of carriageway and zebra that leads
## out of the junction and stops in the grass. Nothing drives there — a car diverting turns on
## the junction's own road band, a whole tile before it — and nothing has to be crossed there
## either, so it becomes pavement and the road visibly ends at the junction rather than poking
## into the park.
##
## `grow(SIDEWALK_WIDTH)` is exactly that spur and nothing else: the band it adds is one
## pavement deep, which alongside a block is pavement already and inside a junction is precisely
## the quarter beyond the crossroads. Getting the turn wrong makes this repaint *look* wrong —
## the first build turned late, so cars drove down the spur and stood on the new pavement, which
## reads as a bug in the paint rather than as a bug in the turn.
## `solid` is the apartment complex: the same streets leave the lattice, and the ground where they
## were is building rather than park. Saying so in `built_over` is what tells every rule about hard
## blockers — the crowd's walls, the telemetry legend, where a big building may go — that this is
## not a park to walk across, without any of them learning what an apartment complex is.
static func _absorb_streets(map: CityMap, footprint: Rect2i, solid := false) -> void:
	for y in range(footprint.position.y + 1, footprint.end.y):
		for x in range(footprint.position.x, footprint.end.x):
			_absorb_one(map, Vector3i(x, y, 0), solid)
	for x in range(footprint.position.x + 1, footprint.end.x):
		for y in range(footprint.position.y, footprint.end.y):
			_absorb_one(map, Vector3i(x, y, 1), solid)

	var zone := CityMap.blocks_tile_rect(footprint)
	for tile in map.rect_tiles(zone.grow(Tuning.SIDEWALK_WIDTH)):
		if zone.has_point(tile):
			continue
		if map.tile_at(tile) == GameEnums.TileType.CROSSING:
			map.set_tile(tile, GameEnums.TileType.SIDEWALK)

static func _absorb_one(map: CityMap, key: Vector3i, solid: bool) -> void:
	map.absent_segments[key] = true
	if solid:
		map.built_over[key] = StreetNetwork.by_key(key).tile_rect()

# --------------------------------------------------------------------- arcs ---

## Plans every block's arc, up front, for the whole run.
##
## The one hard rule: at least `MIN_CALM_BLOCKS_AT_END` blocks must still be calm on the
## last day. A day can only be won on calm ground (M14), so an arc set that requisitions
## everything is not a hard run, it is an unwinnable one — and because arcs are planned here
## rather than rolled day by day, that is a property this function can simply guarantee
## instead of a property the scheduler has to keep rescuing.
static func _plan_arcs(map: CityMap, purposes: Dictionary,
		rng: RandomNumberGenerator) -> void:
	var calm: Array[Vector2i] = []
	for block: Vector2i in purposes:
		if BlockPlan.is_calm(purposes[block]):
			calm.append(block)
	calm.sort()
	_shuffle(calm, rng)
	var may_be_taken := maxi(0, calm.size() - Tuning.MIN_CALM_BLOCKS_AT_END)

	var taken := 0
	for block: Vector2i in purposes:
		var purpose: GameEnums.BlockPurpose = purposes[block]
		var plan := BlockPlan.of(purpose)
		if BlockPlan.is_calm(purpose):
			var index := calm.find(block)
			if index >= 0 and index < may_be_taken and rng.randf() < Tuning.REQUISITION_CHANCE:
				plan.then(GameEnums.BlockPurpose.REQUISITIONED,
						rng.randi_range(Tuning.REQUISITION_FIRST_DAY, Tuning.RUN_LENGTH_DAYS - 1),
						GameEnums.BlockCause.SCHEDULED)
				taken += 1
		else:
			_plan_built_arc(plan, purpose, rng)
		map.block_plans[block] = plan

## A built block goes dark before it burns, and only a commercial one goes dark at all.
## The fire step is event-caused: it waits for something to actually burn there, so a block
## whose arc ends in ashes may finish the run untouched.
static func _plan_built_arc(plan: BlockPlan, purpose: GameEnums.BlockPurpose,
		rng: RandomNumberGenerator) -> void:
	if purpose == GameEnums.BlockPurpose.COMMERCIAL and rng.randf() < Tuning.BOARDING_CHANCE:
		plan.then(GameEnums.BlockPurpose.BOARDED_UP,
				rng.randi_range(Tuning.BOARDING_FIRST_DAY, Tuning.RUN_LENGTH_DAYS - 1),
				GameEnums.BlockCause.SCHEDULED)
	if rng.randf() < Tuning.BURN_CHANCE:
		plan.then(GameEnums.BlockPurpose.BURNT_OUT, Tuning.BURN_FIRST_DAY,
				GameEnums.BlockCause.FIRE)

static func _shuffle(array: Array, rng: RandomNumberGenerator) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: Variant = array[i]
		array[i] = array[j]
		array[j] = swap

# ------------------------------------------------------------------- blocks ---

## Carves every block and returns the building rects it left behind, keyed by block, so the
## home can be carved out of its block afterwards without re-deriving anything.
##
## The carves are recorded in a `BlockLayout` as well as painted, because the painting is
## redone every day from the block's current purpose and must not re-roll anything. The
## tiles this lays down are day 1's; `CityMap.repaint()` owns every day after that.
static func _build_blocks(map: CityMap, purposes: Dictionary,
		rng: RandomNumberGenerator) -> Dictionary:
	var block_rects := {}
	# Iterate in a fixed order; `purposes` is keyed by an unordered shuffle. Blocks a calm zone
	# absorbed are not in it at all — their ground belongs to the anchor and is built with it.
	for y in Tuning.CITY_BLOCKS.y:
		for x in Tuning.CITY_BLOCKS.x:
			var block := Vector2i(x, y)
			if purposes.has(block):
				block_rects[block] = _build_block(map, block, purposes[block], rng)
	return block_rects

static func _build_block(map: CityMap, block: Vector2i, purpose: GameEnums.BlockPurpose,
		rng: RandomNumberGenerator) -> Array[Rect2i]:
	# The whole lot, which for a four-block calm zone is 22 tiles square and takes in the
	# corridors between its own blocks. Everything below is written against the lot rather than
	# the block, so a zone is a big park and not a special case.
	var lot := map.lot_rect(block)
	var layout := BlockLayout.new()
	map.block_layouts[block] = layout

	if _OPEN_CALM.has(purpose):
		layout.open_rect = lot
		map.fill_rect(lot, CityMap.open_tile_for(purpose))
		# Only a park has a playground: a forest with a swing frame in it is a park, and a
		# quiet square with one is not quiet.
		if purpose == GameEnums.BlockPurpose.PARK:
			layout.playground = _inset_rect(lot, 3, rng)
			map.fill_rect(layout.playground, GameEnums.TileType.PLAYGROUND)
		return []

	map.fill_rect(lot, GameEnums.TileType.BUILDING)
	var rects: Array[Rect2i] = [lot]

	if purpose == GameEnums.BlockPurpose.COURTYARD:
		# The court is sized from the **lot**, not from a constant: a four-block apartment complex
		# is a mass twenty-two tiles square, and a hole four tiles wide in it is a light well
		# rather than somewhere to stand. See `Tuning.APARTMENT_COURT_TILES`.
		var court := Tuning.COURTYARD_SIZE_TILES if lot.size.x <= Tuning.BLOCK_SIZE \
				else Tuning.APARTMENT_COURT_TILES
		layout.open_rect = _inset_rect(lot, court, rng)
		layout.passage = _passage_rect(lot, layout.open_rect, rng)
		map.fill_rect(layout.open_rect, GameEnums.TileType.COURTYARD)
		map.fill_rect(layout.passage, GameEnums.TileType.ALLEY)
		map.courtyard_rects.append(layout.open_rect)
		rects = _subtract_all(rects, layout.open_rect)
		rects = _subtract_all(rects, layout.passage)

	if purpose == GameEnums.BlockPurpose.COMMERCIAL:
		layout.square = _corner_rect(lot, Tuning.SQUARE_SIZE_TILES, rng)
		map.fill_rect(layout.square, GameEnums.TileType.SQUARE)
		map.square_rects.append(layout.square)
		rects = _subtract_all(rects, layout.square)

	if rng.randf() < float(Tuning.ALLEY_CHANCE[purpose]):
		layout.alley = _alley_rect(lot, rng)
		map.fill_rect(layout.alley, GameEnums.TileType.ALLEY)
		map.alley_rects.append(layout.alley)
		rects = _subtract_all(rects, layout.alley)

	return _keep_nonempty(rects)

## A rect of `size` tiles somewhere inside `lot`, never touching its edge.
##
## **Both spans are the lot's own, which they were not until M52.** The offset was rolled twice
## against `lot.size.x`, which is the same number on both axes for as long as every lot is square —
## and a 2x1 calm zone is 22 tiles by 8, so a playground would have been placed up to fourteen tiles
## south of a lot eight tiles deep. That is the shape of thing a square-only city hides.
static func _inset_rect(lot: Rect2i, size: int, rng: RandomNumberGenerator) -> Rect2i:
	var span := lot.size - Vector2i.ONE * (size + 2)
	var offset := Vector2i(rng.randi_range(1, maxi(1, span.x)), rng.randi_range(1, maxi(1, span.y)))
	return Rect2i(lot.position + offset, Vector2i.ONE * size)

## The archway out of a courtyard: one tile wide, from the court to the nearest point on one
## of the lot's four edges. Without it the court is a sealed hole in the map — which is how
## the first version of courtyards failed, on every seed, at the connectivity check.
static func _passage_rect(lot: Rect2i, court: Rect2i, rng: RandomNumberGenerator) -> Rect2i:
	var side := rng.randi_range(0, 3)
	var middle := court.position + court.size / 2
	match side:
		0:  # north
			return Rect2i(Vector2i(middle.x, lot.position.y),
					Vector2i(1, court.position.y - lot.position.y))
		1:  # south
			return Rect2i(Vector2i(middle.x, court.end.y),
					Vector2i(1, lot.end.y - court.end.y))
		2:  # west
			return Rect2i(Vector2i(lot.position.x, middle.y),
					Vector2i(court.position.x - lot.position.x, 1))
		_:  # east
			return Rect2i(Vector2i(court.end.x, middle.y),
					Vector2i(lot.end.x - court.end.x, 1))

## A rect of `size` tiles pinned to one of the lot's four corners, so it opens onto the
## streets on two sides.
static func _corner_rect(lot: Rect2i, size: int, rng: RandomNumberGenerator) -> Rect2i:
	var right := rng.randf() < 0.5
	var bottom := rng.randf() < 0.5
	var position := lot.position
	if right:
		position.x = lot.end.x - size
	if bottom:
		position.y = lot.end.y - size
	return Rect2i(position, Vector2i.ONE * size)

## A through-alley spanning the lot, leaving at least two tiles of building either side.
static func _alley_rect(lot: Rect2i, rng: RandomNumberGenerator) -> Rect2i:
	var width := Tuning.ALLEY_WIDTH_TILES
	var offset := rng.randi_range(2, maxi(2, lot.size.x - width - 2))
	if rng.randf() < 0.5:
		return Rect2i(Vector2i(lot.position.x + offset, lot.position.y),
				Vector2i(width, lot.size.y))
	return Rect2i(Vector2i(lot.position.x, lot.position.y + offset),
			Vector2i(lot.size.x, width))

## Every non-degenerate piece is kept, including one-tile slivers left beside a hole.
## Dropping them instead would leave BUILDING tiles with no Building node over them — an
## invisible wall the player walks straight through. A sliver renders as a low wall, which
## is what a 32px-wide building should look like anyway.
static func _keep_nonempty(rects: Array[Rect2i]) -> Array[Rect2i]:
	var kept: Array[Rect2i] = []
	for rect in rects:
		if rect.size.x > 0 and rect.size.y > 0:
			kept.append(rect)
	return kept

# ---------------------------------------------------------- rect subtraction ---

static func _subtract_all(rects: Array[Rect2i], hole: Rect2i) -> Array[Rect2i]:
	var result: Array[Rect2i] = []
	for rect in rects:
		result.append_array(_subtract(rect, hole))
	return result

## `outer` minus `hole`, as up to four rects: a band above, a band below, then the left and
## right slivers of the row the hole occupies.
static func _subtract(outer: Rect2i, hole: Rect2i) -> Array[Rect2i]:
	if not outer.intersects(hole):
		return [outer]
	var overlap := outer.intersection(hole)
	var pieces: Array[Rect2i] = []

	if overlap.position.y > outer.position.y:
		pieces.append(Rect2i(outer.position,
				Vector2i(outer.size.x, overlap.position.y - outer.position.y)))
	if overlap.end.y < outer.end.y:
		pieces.append(Rect2i(Vector2i(outer.position.x, overlap.end.y),
				Vector2i(outer.size.x, outer.end.y - overlap.end.y)))
	if overlap.position.x > outer.position.x:
		pieces.append(Rect2i(Vector2i(outer.position.x, overlap.position.y),
				Vector2i(overlap.position.x - outer.position.x, overlap.size.y)))
	if overlap.end.x < outer.end.x:
		pieces.append(Rect2i(Vector2i(overlap.end.x, overlap.position.y),
				Vector2i(outer.end.x - overlap.end.x, overlap.size.y)))
	return pieces

# --------------------------------------------------------------------- home ---

## Notches the home into the south edge of the middle block.
##
## **The middle, not the most central block that happens to work.** The home used to be chosen by
## sorting residential blocks by distance to the centre and taking the first that was
## `MIN_HOME_TO_PARK_TILES` from calm ground — two rules competing for the same thing, which the
## walk out settled by walking the home outward until it was far enough. Measured over ten seeds at
## 7x7 it landed about two blocks off centre and was central in four, which puts the doorstep near
## the boundary: *"I spawn too often at the edge, leaving only a few ways into the rest of the
## city."* Half the directions out of a corner block are a wall, and a city you can only leave two
## ways is a smaller city than the one that was generated.
##
## The competition is settled in `_assign_purposes` instead, by keeping calm ground away from the
## middle (`_too_near_the_home`) — so the distance guarantee holds where the home *is* rather than
## deciding where it goes. `validate()` still checks it, because a clearance stated in blocks is an
## approximation of a guarantee stated in tiles.
static func _place_home(map: CityMap, block_rects: Dictionary) -> void:
	var block := home_block()
	_carve_home(map, block_rects, block, _home_rect(map, block))

## The home notch: `HOME_SIZE_TILES` in the south edge of the lot, slid sideways if that
## would land it in an alley.
static func _home_rect(map: CityMap, block: Vector2i) -> Rect2i:
	var lot := CityMap.block_rect(block)
	var size := Tuning.HOME_SIZE_TILES
	var top_left := Vector2i(lot.position.x + (lot.size.x - size.x) / 2, lot.end.y - size.y)
	for shift in range(0, lot.size.x - size.x):
		# Alternate right and left of centre until the notch clears any alley.
		var offset: int = (shift + 1) / 2 * (1 if shift % 2 == 0 else -1)
		var candidate := Rect2i(top_left + Vector2i(offset, 0), size)
		if not lot.encloses(candidate):
			continue
		if _is_all_building(map, candidate):
			return candidate
	return Rect2i(top_left, size)

static func _is_all_building(map: CityMap, rect: Rect2i) -> bool:
	for tile in map.rect_tiles(rect):
		if map.tile_at(tile) != GameEnums.TileType.BUILDING:
			return false
	return true

static func _carve_home(map: CityMap, block_rects: Dictionary, block: Vector2i,
		home: Rect2i) -> void:
	map.fill_rect(home, GameEnums.TileType.HOME)
	map.home_rect = home
	map.home_block = block
	block_rects[block] = _keep_nonempty(_subtract_all(block_rects[block], home))

# ----------------------------------------------------------- hard blockers ---

## The streets this city does not go down, fixed for the whole run. *(M50 step 1.)*
##
## **The soft blockers re-cut the map every morning; these are what the player learns.** A route
## to a calm area is not stable across days and that is the mechanism rather than a side effect —
## a city worth knowing plus a day worth reading — so the permanent half has to exist before the
## per-day half can mean anything.
##
## **They are placed against a tree, not before one.** *"First construct an example tree from the
## initial map, then place the hard blockers — that way we can't block off regions entirely."* The
## reference tree is a **witness**: it reaches every calm area the run will ever use, so a blocker
## that takes no street off it cannot have made any of them unreachable. That is why the candidate
## list excludes the tree rather than the gate below merely checking afterwards — a gate that
## rejects most of what it is offered is a slow way of getting a worse answer.
##
## Day 1's calm is *all* the calm, which is worth stating because it is not obvious and it is what
## makes "every calm area the run will ever use" a thing this function can hold in its hand: arcs
## only ever take calm ground away (`REQUISITIONED`), never add it, so the set only shrinks.
static func _place_hard_blockers(map: CityMap, purposes: Dictionary, block_rects: Dictionary,
		rng: RandomNumberGenerator) -> void:
	var home := ClosurePlanner.home_street(map)
	var areas := ClosurePlanner.calm_areas(map)
	if not home or areas.is_empty():
		return
	# Grown once, before either kind is placed, and used by both. It is the *initial* map's tree,
	# which is the whole idea: a witness taken before anything was taken away.
	var reference := RouteTree.for_the_run(map)
	var calm := _calm_blocks_set(map)
	_place_dead_ends(map, home, areas, reference, calm, rng)
	_place_big_buildings(map, purposes, block_rects, home, areas, reference, calm, rng)

## Every block of every calm lot, as a set. A four-block zone is four entries: what the rules
## below are about is *ground you could step onto*, not which block anchors a lot.
static func _calm_blocks_set(map: CityMap) -> Dictionary:
	var calm := {}
	for anchor in map.calm_blocks:
		for block in _blocks_in(map.lot_blocks(anchor)):
			calm[block] = true
	return calm

## Streets that stop. One segment out of the lattice, one end of it built over.
static func _place_dead_ends(map: CityMap, home: StreetNetwork.Segment,
		areas: Array[ClosurePlanner.CalmArea], reference: RouteTree, calm: Dictionary,
		rng: RandomNumberGenerator) -> void:
	var wanted := rng.randi_range(Tuning.MIN_CUL_DE_SACS, Tuning.MAX_CUL_DE_SACS)
	var made := 0
	for segment in _dead_end_candidates(map, home, reference, calm, rng):
		if made >= wanted:
			break
		map.absent_segments[segment.key()] = true
		if _the_calm_survives(map, home, areas):
			map.built_over[segment.key()] = _wall_off_one_end(map, segment, rng)
			map.dead_ends[segment.key()] = true
			made += 1
		else:
			map.absent_segments.erase(segment.key())

## Every street a dead end could be made of, in the order this city will try them.
##
## Four exclusions, and each is a thing that would stop being itself:
##
## - **The street outside the front door**, which is the oldest exemption in the project: the home
##   is a notch with one exit, so sealing that street seals the player in.
## - **The main road.** There is one of it, it is the thing that has to be crossed and the first
##   landmark anybody learns, and a spine with a hole in it is not a spine.
## - **A precinct**, which is a *place* — three blocks of paving somebody can be told how to find —
##   rather than a stretch of road, and a dead end in the middle of one is a broken place.
## - **Anything on the reference tree.** See above: this is what makes the gate a formality rather
##   than a search.
## - **Anything running alongside calm ground**, and this one was found by building it. A dead end
##   is a claim about where you can get to, and the claim is made on the **lattice** while the
##   player walks on **tiles** — so a street with a park down one side of it is a street you walk
##   into and then step sideways out of, whatever the graph says. It is M21's rule read backwards:
##   an absorbed street is calm ground rather than a closure, and calm ground beside a dead end
##   makes the dead end a doorway. `tests/test_routes.gd` caught it as *"the way in is a real
##   street"* on a four-block zone, which is exactly what it looked like from the outside.
static func _dead_end_candidates(map: CityMap, home: StreetNetwork.Segment, reference: RouteTree,
		calm: Dictionary, rng: RandomNumberGenerator) -> Array[StreetNetwork.Segment]:
	var pool: Array[StreetNetwork.Segment] = []
	for segment in StreetNetwork.segments():
		if not map.has_street(segment.key()) or segment.key() == home.key():
			continue
		if reference.is_on_the_tree(segment.key()) or _runs_beside_calm(segment, calm):
			continue
		var rect := segment.tile_rect()
		if map.street_kind_at(not segment.horizontal, rect.position + rect.size / 2) \
				!= GameEnums.StreetKind.ORDINARY:
			continue
		pool.append(segment)
	_shuffle(pool, rng)
	return pool

## Whether either of the two blocks a street runs between is calm ground.
##
## A segment key names the block it runs along the **north or west edge of**, so the other side is
## one step back along the crossing axis.
static func _runs_beside_calm(segment: StreetNetwork.Segment, calm: Dictionary) -> bool:
	var key := segment.key()
	var block := Vector2i(key.x, key.y)
	var opposite := block + (Vector2i.UP if segment.horizontal else Vector2i.LEFT)
	return calm.has(block) or calm.has(opposite)

## Two blocks built together as one mass, with the street between them gone. *(M50 step 1.)*
##
## **The bigger of the two hard blockers, and the one that is a landmark.** A dead end takes a
## street out of the lattice and walls one end of it; this takes one out and builds over the whole
## of it, joining the blocks either side into a mass twenty-two tiles long that a player navigates
## by and walks round. Everything else about the grid there is untouched: the four streets round
## each block, and every junction, still exist and still turn.
##
## **It joins two blocks, and a building that closes all four of its streets would be a different
## kind of thing.** *(2026-08-31: "why do big buildings close off four streets each? a big building
## just connects two blocks… we can add a building type with all four roads closed but that's a
## different building type. but I want one that just connects two blocks (closes one road)".)* The
## first version took the whole ring, which made every one of them an island in the lattice and put
## four streets' worth of hard blocking behind a single roll. The four-sided one is recorded in
## `docs/TODO.md` as its own type and is not this one.
##
## It is a `BlockPurpose` so that the blocks stay solid for the whole run: an empty `BlockLayout`
## means `CityMap._repaint_block` has nothing to paint, so every later day's repaint leaves the lot
## exactly as the clearing pass left it, which is building. The arc is the trivial one — a
## landmark has nowhere to go — and that is the shape the recipe asks for rather than a special
## case beside it.
##
## **Chosen late and converted, rather than assigned with the other purposes.** The choice needs
## the reference tree, and the tree needs the calm areas, and those need the block layouts — so by
## the time this can be decided the blocks have already been carved. Converting them is a few lines
## and keeps the ordering honest; deciding it early would have meant deciding it blind.
static func _place_big_buildings(map: CityMap, purposes: Dictionary, block_rects: Dictionary,
		home: StreetNetwork.Segment, areas: Array[ClosurePlanner.CalmArea], reference: RouteTree,
		calm: Dictionary, rng: RandomNumberGenerator) -> void:
	var wanted := rng.randi_range(Tuning.MIN_BIG_BUILDINGS, Tuning.MAX_BIG_BUILDINGS)
	var made := 0
	for pair in _big_building_candidates(map, purposes, home, reference, calm, rng):
		if made >= wanted:
			break
		# Asked **again**, here, and not only when the pool was built. The pool is enumerated
		# before anything is placed, so the first big building's blocks are news to the second
		# one's check — which is how two of them ended up sharing a street and drawing two
		# buildings on the same tiles. A candidate list is a snapshot; a placement is a change.
		if not _the_pair_is_free(map, purposes, pair, home, reference, calm):
			continue
		var between := _street_between(pair)
		map.absent_segments[between.key()] = true
		if _the_calm_survives(map, home, areas):
			_make_the_pair_solid(map, purposes, block_rects, pair, between)
			made += 1
		else:
			map.absent_segments.erase(between.key())

## Every pair of neighbouring blocks that could be one, in the order this city will try them.
##
## Each block is offered with the neighbour to its east and the one to its south, so every
## adjacent pair is enumerated exactly once.
static func _big_building_candidates(map: CityMap, purposes: Dictionary,
		home: StreetNetwork.Segment, reference: RouteTree, calm: Dictionary,
		rng: RandomNumberGenerator) -> Array[Rect2i]:
	var pool: Array[Rect2i] = []
	for y in range(1, Tuning.CITY_BLOCKS.y - 1):
		for x in range(1, Tuning.CITY_BLOCKS.x - 1):
			for size: Vector2i in [Vector2i(2, 1), Vector2i(1, 2)]:
				var pair := Rect2i(Vector2i(x, y), size)
				if _the_pair_is_free(map, purposes, pair, home, reference, calm):
					pool.append(pair)
	_shuffle(pool, rng)
	return pool

## Whether two neighbouring blocks and the street between them are something a landmark may be
## built out of.
##
## The exclusions are the dead end's, restated over a pair, plus two that only a big building
## needs:
##
## - **Interior blocks only.** A block on the outer ring has boundary corridors round it, and the
##   edge of the world is a ring of frontages with a tunnel and a bridge punched through it — not
##   somewhere to put a wall.
## - **Single-block lots.** A four-block calm zone is already a lot of its own, and there is no
##   sense in which a zone could also be a building.
##
## The "nothing beside calm" rule applies here too, and for a *different* reason than it does to a
## dead end. There the worry is that the blocker is a lie — you step sideways into the park. Here
## the ground really is solid, and what a big building beside a zone would do is take one of the
## zone's ways in **away**, frontage and all. That is legitimate city and it is also a deliberate
## narrowing of an M21 guarantee, so it is not something to acquire while adding landmarks.
## `tests/test_routes.gd` says so out loud: *"the way in is a real street."*
static func _the_pair_is_free(map: CityMap, purposes: Dictionary, pair: Rect2i,
		home: StreetNetwork.Segment, reference: RouteTree, calm: Dictionary) -> bool:
	if pair.end.x > Tuning.CITY_BLOCKS.x - 1 or pair.end.y > Tuning.CITY_BLOCKS.y - 1:
		return false
	if _too_near_the_home(pair):
		return false
	for block in _blocks_in(pair):
		if map.lot_blocks(block) != Rect2i(block, Vector2i.ONE):
			return false
		if BlockPlan.is_calm(purposes.get(block, GameEnums.BlockPurpose.RESIDENTIAL)):
			return false
		if purposes.get(block) == GameEnums.BlockPurpose.BIG_BUILDING:
			return false

	var between := _street_between(pair)
	if not between or not map.has_street(between.key()) or between.key() == home.key():
		return false
	if reference.is_on_the_tree(between.key()) or map.is_hard_blocker(between.key()):
		return false
	if _runs_beside_calm(between, calm):
		return false
	var rect := between.tile_rect()
	return map.street_kind_at(not between.horizontal, rect.position + rect.size / 2) \
			== GameEnums.StreetKind.ORDINARY

## The one street a pair of neighbouring blocks has between them. A segment key names the block it
## runs along the north or west edge of, so it is the far block's own western or northern street.
static func _street_between(pair: Rect2i) -> StreetNetwork.Segment:
	var far := pair.position + pair.size - Vector2i.ONE
	return StreetNetwork.beside_block(far,
			StreetNetwork.Side.WEST if pair.size.x == 2 else StreetNetwork.Side.NORTH)

## Turns two carved blocks and the street between them into one solid mass.
##
## The blocks' carved rects are **replaced** rather than added to: whatever plaza or alley they had
## is gone, and leaving the old rects behind would draw buildings inside a building. The mass goes
## down as **one** rect covering both lots and the street, so what gets built is a single landmark
## rather than two buildings with a seam where the road used to be.
static func _make_the_pair_solid(map: CityMap, purposes: Dictionary, block_rects: Dictionary,
		pair: Rect2i, between: StreetNetwork.Segment) -> void:
	for block in _blocks_in(pair):
		purposes[block] = GameEnums.BlockPurpose.BIG_BUILDING
		map.block_plans[block] = BlockPlan.of(GameEnums.BlockPurpose.BIG_BUILDING)
		# Nothing carved, so nothing to repaint: the daily clearing pass leaves the lot as building
		# and `_repaint_block` returns having found no rects to fill.
		map.block_layouts[block] = BlockLayout.new()
		var nothing: Array[Rect2i] = []
		block_rects[block] = nothing
	map.big_buildings.append(pair)

	var mass := CityMap.blocks_tile_rect(pair)
	map.fill_rect(mass, GameEnums.TileType.BUILDING)
	var solid: Array[Rect2i] = [mass]
	block_rects[pair.position] = solid
	map.built_over[between.key()] = between.tile_rect()

## The gate: **every calm area the run will ever use can still be walked to.**
##
## *(M50 built this as the strong gate — two edge-disjoint routes to every area — deliberately,
## because weakening a winnability guarantee as a side effect of adding dead ends is the shape of
## overturn this project has a rule about. It was moved on purpose on 2026-08-31: "I already
## clarified that the two routes guarantee is not a hard rule." See
## `Tuning.MIN_CALM_AREAS_REACHABLE`.)*
##
## **Reachability rather than redundancy is the right gate here for a reason of its own**, and it
## is the one the design gives: cul-de-sacs are the *point* of a hard blocker, and a two-routes
## rule fights them — every dead end takes one of an area's ways in, so the strong gate refused
## exactly the interesting ones. What it may never do is make a calm area unreachable, because a
## hard blocker holds for the whole run: a day can be bad, a run cannot be dead.
##
## It stays stated over **every** area rather than over a count, unlike the day-level invariant,
## for the same reason: a closure is gone tomorrow and this is not.
static func _the_calm_survives(map: CityMap, home: StreetNetwork.Segment,
		areas: Array[ClosurePlanner.CalmArea]) -> bool:
	var blocked := map.blocked_segments()
	for area in areas:
		if StreetNetwork.route_count(home, area.access, blocked, 1) < 1:
			return false
	return true

## Builds the wall that makes an absent street a *dead end* rather than a hole in the map.
##
## **The ground has to stop, and that is the whole difference from M21's absorbed streets.** A
## calm zone's absorbed corridor is park: gone from the lattice and walked over quite happily,
## which is right for a shortcut and wrong for a hard blocker — *"a cul-de-sac must be a street
## that genuinely stops, not a park to walk through."* So one end is built over, and the street
## keeps its pavement, its kerbs and its buildings: you can walk in, and then you have to come
## back out.
##
## Which end is rolled. A dead end that always faced the same way would be a rule the player
## learns once instead of a city they learn.
static func _wall_off_one_end(map: CityMap, segment: StreetNetwork.Segment,
		rng: RandomNumberGenerator) -> Rect2i:
	var at_a := rng.randf() < 0.5
	var wall := segment.mouth_rect(at_a)
	# Grown *into* the street, never into the junction: the crossroads keeps its zebras and its
	# lights, and what is walled is the road beyond it. A wall inside the junction would take the
	# crossing with it, which is a pedestrian route that has nothing to do with this street.
	var into := Tuning.CUL_DE_SAC_WALL_TILES - 1
	var along := Vector2i.RIGHT if segment.horizontal else Vector2i.DOWN
	if not at_a:
		wall.position -= along * into
	wall.size += along * into
	map.fill_rect(wall, GameEnums.TileType.BUILDING)
	map.building_rects.append(wall)
	return wall

# --------------------------------------------------------------- validation ---

## Returns "" when the map satisfies every guarantee in docs/CITY.md, else why it does not.
static func validate(map: CityMap) -> String:
	if map.home_rect.size == Vector2i.ZERO:
		return "no home was placed"

	if map.calm_blocks.size() < Tuning.MIN_CALM_BLOCKS:
		return "only %d calm blocks, need %d" % [
			map.calm_blocks.size(), Tuning.MIN_CALM_BLOCKS]

	# Stated over every block of every calm lot, not over the anchors: two four-block zones whose
	# anchors are three apart can still have their footprints touching.
	#
	# **Two things about it were wrong until 2026-08-31 and neither could have been caught by this
	# check, because this check was both of them.** It skipped every lot that was not `_OPEN_CALM`,
	# so a courtyard was not a calm area as far as the guarantee was concerned; and it stepped
	# `RIGHT` and `DOWN` only, so it had never once looked at a diagonal — including through M49,
	# which fixed the diagonal in the *placement* rule and left the thing that is supposed to hold
	# it checking the old shape. A guarantee that is narrower than the rule it guards will agree
	# with the rule for as long as the rule is right and say nothing on the day it is not.
	var owner := {}
	for block in map.calm_blocks:
		for member in _blocks_in(map.lot_blocks(block)):
			owner[member] = block
	for member: Vector2i in owner:
		for step in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, -1)]:
			var neighbour: Vector2i = member + step
			if owner.has(neighbour) and owner[neighbour] != owner[member]:
				return "calm areas %s and %s are in each other's ring" % [
					owner[member], owner[neighbour]]

	# **The open ones only, and one of them is the square.** *(M52.)* `zone_rects` is every
	# multi-block lot, which since apartment complexes is not the same thing as every multi-block
	# *park* — a complex is four blocks of building — so counting the dictionary would let a city
	# satisfy M21's guarantee with a thing you cannot walk across. And the guarantee is not
	# "multi-block calm" in general: it is that every city has somewhere with a *route* through it
	# rather than a lap round it, which is what the four-block open footprint is for. The placement
	# pass makes both true by placing the square first; this asks the city that came out, which is
	# the only way either survives that ordering being changed.
	var square := Vector2i.ONE * Tuning.CALM_ZONE_BLOCKS
	var open_zones := 0
	var squares := 0
	for anchor: Vector2i in map.zone_rects:
		if not _OPEN_CALM.has(map.starting_purpose(anchor)):
			continue
		open_zones += 1
		if (map.zone_rects[anchor] as Rect2i).size == square:
			squares += 1
	if open_zones < Tuning.MIN_CALM_ZONES:
		return "only %d open multi-block calm zones, need %d" % [
			open_zones, Tuning.MIN_CALM_ZONES]
	if squares < 1:
		return "no open calm zone is %d blocks square" % Tuning.CALM_ZONE_BLOCKS

	# The arcs are planned for the whole run, so the end of it can be checked here rather
	# than hoped for. A run that requisitions its way to nothing is unwinnable, not hard.
	var lasting := 0
	for block: Vector2i in map.block_plans:
		if (map.block_plans[block] as BlockPlan).stays_calm():
			lasting += 1
	if lasting < Tuning.MIN_CALM_BLOCKS_AT_END:
		return "only %d blocks stay calm for the whole run, need %d" % [
			lasting, Tuning.MIN_CALM_BLOCKS_AT_END]

	# The two sweeps of the map come last, and the order is the whole reason this is affordable:
	# `generate` calls it on every attempt and about a third of them fail, so a rejection that
	# can be seen by counting calm blocks must not first walk eleven thousand tiles twice.
	# Which reason comes back when several are true changes; whether a map is accepted does not.
	var reached := map.reach_count(map.walk_field(map.home_rect.position))
	if reached != map.count_walkable():
		return "%d of %d walkable tiles are cut off from the home" % [
			map.count_walkable() - reached, map.count_walkable()]

	var calm_distance := map.home_to_nearest_calm()
	if calm_distance < Tuning.MIN_HOME_TO_PARK_TILES:
		return "home is only %d tiles from calm ground, need %d" % [
			calm_distance, Tuning.MIN_HOME_TO_PARK_TILES]

	# The hard blockers' own condition. *(M50 step 1.)* They are the only thing in generation that
	# takes a street out of the lattice for a reason of its own, and the placement gate is what
	# stops one cutting the calm off — so this is the same guarantee asked a second time, by
	# something that did not place it. A gate is a promise about each candidate; this is a
	# statement about the city that came out, and the two are only the same while the gate is
	# right. `route_count` is capped at one here because reachability is the floor that must never
	# fail; the two-routes half is a property of the day and lives in `ClosurePlanner`.
	var home := ClosurePlanner.home_street(map)
	if not home:
		return "the front door does not open onto a street"
	for area in ClosurePlanner.calm_areas(map):
		if StreetNetwork.route_count(home, area.access, map.blocked_segments(), 1) < 1:
			return "calm area %s cannot be reached from the home street" % area.block

	return ""

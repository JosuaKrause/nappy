class_name TelemetryMap
extends RefCounted
## A picture of the whole tile grid, written beside the run log.
##
## *(Playtest 13, finding 4: "for telemetry render out the entire city grid into a picture in the
## telemetry folder".)*
##
## **A trace says where she was and cannot say what she was walking around.** Every question this
## project has asked of a log in the last five milestones has been a question about the layout —
## how far the nearest calm area is, whether a closure cut anything, which street the spine is,
## why a park was never reached — and answering any of them from a list of tile coordinates is a
## thing nobody does twice. It is a `Vector2i` in the log and a place in the picture.
##
## It is **not** `--overview`, which is a dev flag on a run somebody has to take and which
## photographs the *rendered* city — buildings, props, dusk, an act's colour cast. This is the grid
## itself, so it says what the generator decided rather than what the renderer drew, and it is
## written without anybody asking.
##
## Three constraints, and the first is the one every file in this directory is built on:
##
## - **It must not touch gameplay.** It reads the map and writes a file. No RNG, no `day_rng()`
##   stream, nothing that can move a placement. See `Telemetry`.
## - **One picture per day, not one per run.** The lattice is fixed for the run but what a block
##   *is* is not — an arc requisitions a park, a fire leaves a shell, and today's closures are
##   down — so a single map taken at dawn on day 1 would be a lie by day 12.
## - **It has to be readable at a glance, in a directory listing, by a person.** Hence the scale
##   below and the marks: a picture that needs a key is a picture that gets opened once.

## Pixels per tile. Four is chosen against the thing that has to be legible at the smallest scale
## in the picture — a **street** is `STREET_WIDTH` tiles, so a corridor is 24px and the two
## pavements either side of the carriageway are still distinct bands. At two it is a smear; at
## eight the map is 1280px square and stops fitting on a screen next to the log.
const SCALE := 4

## The marks laid over the ground, none of which is a tile type.
##
## They are drawn as **outlines and crosses rather than fills**, so nothing here can hide the
## ground it is describing — the commonest way a debug overlay lies is by covering the thing that
## was going to answer the question.
## They are written as **hex rather than as floats**, like everything in `Palette`, and that is
## not a style choice: the image is `FORMAT_RGB8`, so a float component is quantised on the way in
## and comes back a fraction off. A test that asks "is this mark in the picture" then fails against
## the constant it drew with, which is a test failing for a reason that has nothing to do with the
## thing it is checking.
const HOME_MARK := Color("ff4059")
const CALM_MARK := Color("33ff73")
const SPINE_MARK := Color("ff8c1a")
const PRECINCT_MARK := Color("73a6ff")
const CLOSURE_MARK := Color("ff2626")
const CORRIDOR_MARK := Color("b366ff")
const BUNDLE_MARK := Color("ffffff")
const DEAD_END_MARK := Color("2ee6d0")

## What a building is drawn as here.
##
## `Tile.ground_colour` deliberately has no answer for `BUILDING` — its `_:` arm returns
## `Palette.OUTLINE` under a comment saying the case "only shows through bugs", because in the game
## a building is a `Building` node standing on the tile rather than a colour. This picture has no
## nodes in it, so it needs its own answer rather than borrowing that one: leaning on a fallback
## whose stated purpose is *this should never be seen* is how a contract quietly becomes untrue.
const BUILDING_GROUND := Color("211f26")

## The grid as an image: one `SCALE`-square block of flat colour per tile, then the marks.
##
## `closed_today` is the day's closures rather than `map.closed_tiles`, because the caller has them
## as objects and the mouths are what a reader is looking for — a closed street reads as a street
## with two crosses on it, which is what it looks like from the junction.
##
## `tree` is the day's corridor, and it is the one mark here that is a **plan** rather than a fact
## about the ground. It is optional because everything else in the picture is true without it.
static func render(map: CityMap, closures: Array[RoadClosure] = [],
		tree: RouteTree = null) -> Image:
	var image := Image.create_empty(map.size.x * SCALE, map.size.y * SCALE, false, Image.FORMAT_RGB8)
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			var type := map.tile_at(tile)
			var colour := BUILDING_GROUND if type == GameEnums.TileType.BUILDING \
					else Tile.ground_colour(type)
			# A closed tile is ground she cannot use, and it is the one thing here that is true of
			# a *day* rather than of the city. Darkened rather than recoloured, so the street
			# underneath still reads as a street.
			if map.is_closed(tile):
				colour = colour.darkened(0.55)
			image.fill_rect(Rect2i(tile * SCALE, Vector2i.ONE * SCALE), colour)

	_mark_the_spine(image, map)
	_mark_the_precincts(image, map)
	# Under the calm, the closures and the home on purpose: those three are what the corridor is
	# drawn to be read *against* — where it arrives, what it had to go round, where it starts —
	# and a plan that covers them would be answering its own question.
	_mark_the_corridor(image, tree)
	_mark_the_dead_ends(image, map)
	_mark_the_calm(image, map)
	_mark_the_closures(image, closures)
	_mark_the_home(image, map)
	return image

# ------------------------------------------------------------------- the marks ---

## The main road, as a line down each of its pavements.
##
## Drawn on the **pavements** rather than on the carriageway, because the asphalt is already the
## darkest thing in the picture and a line on it would be invisible — and because what the reader
## is looking for is the *edge* of the barrier the spine is, which is where she walks.
static func _mark_the_spine(image: Image, map: CityMap) -> void:
	if map.main_road < 0:
		return
	var corridor := map.main_road * CityMap.period()
	for offset in [0, Tuning.STREET_WIDTH - 1]:
		_fill_tiles(image, Rect2i(Vector2i(corridor + offset, 0), Vector2i(1, map.size.y)),
				SPINE_MARK)

## The two precincts, as a line along the middle of each. `precinct_spans` is
## `(vertical, corridor, first block, last block)`; see `CityMap.precinct_spans`.
static func _mark_the_precincts(image: Image, map: CityMap) -> void:
	for span in map.precinct_spans:
		var vertical := span.x == 1
		var across: int = span.y * CityMap.period() + Tuning.STREET_WIDTH / 2
		var from: int = span.z * CityMap.period()
		var to: int = (span.w + 1) * CityMap.period()
		_fill_tiles(image, Rect2i(Vector2i(across, from), Vector2i(1, to - from)) if vertical
				else Rect2i(Vector2i(from, across), Vector2i(to - from, 1)), PRECINCT_MARK)

## The day's corridor, as the path it is: a line down the middle of every street on the tree,
## drawn white and twice as wide where more than one calm area is reached that way.
##
## *(M50, and the reason this tooling went first: the thing being built is a **placement**, and a
## placement is exactly what a trace in words cannot show. "Is anything guiding her" is the open
## question the whole milestone exists for, and it cannot be answered from a log line.)*
##
## Each stroke runs from the middle of one junction to the middle of the next rather than over the
## street alone, so consecutive streets meet and a turn crosses — the picture is a **path** rather
## than a set of dashes, which is the difference between reading a route and inferring one. The
## bundles being the wide white ones is most of what there is to see: where they run is where a
## wall is cheap and a set piece is worth siting, and a picture in which everything is thin violet
## is a tree that has quietly become a star.
static func _mark_the_corridor(image: Image, tree: RouteTree) -> void:
	if not tree:
		return
	for key in tree.streets():
		var segment := StreetNetwork.by_key(key)
		if not segment:
			continue
		var bundled := tree.colours_on(key) >= 2
		_fill_tiles(image, _corridor_stroke(segment, bundled),
				BUNDLE_MARK if bundled else CORRIDOR_MARK)

## One street's stroke, junction centre to junction centre.
static func _corridor_stroke(segment: StreetNetwork.Segment, wide: bool) -> Rect2i:
	var thickness := 2 if wide else 1
	var across := Tuning.STREET_WIDTH / 2 - (1 if wide else 0)
	var from := segment.a * CityMap.period()
	var length := CityMap.period() + Tuning.STREET_WIDTH
	if segment.horizontal:
		return Rect2i(Vector2i(from.x, from.y + across), Vector2i(length, thickness))
	return Rect2i(Vector2i(from.x + across, from.y), Vector2i(thickness, length))

## Every street a hard blocker built over: the wall at the end of a dead end, and all four sides
## of a big building. *(M50 step 1.)*
##
## **Filled, which is the one exception to "outlines, never fills".** That rule exists because a
## mark that covers the ground stops the picture answering the question it was opened for — and
## here the ground *is* the mark: the tiles under it were built over, and drawing an outline round
## a wall would leave the middle of it reading as the street it used to be.
##
## It earns its own colour rather than being left to show through as building, which was the first
## version and was invisible: a two-tile slab of dark building inside a dark street is exactly the
## thing nobody spots, and a hard blocker nobody can spot in the one picture built to check
## placements might as well not have been placed.
static func _mark_the_dead_ends(image: Image, map: CityMap) -> void:
	for key: Vector3i in map.built_over:
		_fill_tiles(image, map.built_over[key] as Rect2i, DEAD_END_MARK)

## Every calm area, outlined at its lot. Outlined rather than tinted because *how big it is* is
## most of what this picture is being asked, and a tint over grass answers that worse than a box.
static func _mark_the_calm(image: Image, map: CityMap) -> void:
	for block in map.calm_blocks:
		_outline_tiles(image, map.lot_rect(block), CALM_MARK)

## Both mouths of every street closed today, where the barriers actually stand.
##
## The body of a closed street is already dark, so this is the *ends* — which is where a closure is
## read from in the game too, and the reason `RoadClosure` puts barriers at both mouths rather than
## one sign in the middle. `mouth_rect` is one tile thick across the corridor, so it marks the
## street without covering it.
static func _mark_the_closures(image: Image, closures: Array[RoadClosure]) -> void:
	for closure in closures:
		for at_a in [true, false]:
			_fill_tiles(image, closure.segment.mouth_rect(at_a), CLOSURE_MARK)

## The home, filled at exactly its own size.
##
## It is the one thing in the picture that is a point rather than an area, and every distance in
## the log is measured from it. A crosshair reaching a block either way was tried and taken back
## out: it is the only red in a picture with no other red in it, and it was already the first thing
## the eye lands on — so the reach was buying nothing and covering two streets to buy it.
static func _mark_the_home(image: Image, map: CityMap) -> void:
	_fill_tiles(image, map.home_rect, HOME_MARK)

# ------------------------------------------------------------------ tile drawing ---
# All three take a rect in **tiles** and scale it here, so nothing above multiplies by SCALE and
# gets it wrong once.

static func _fill_tiles(image: Image, rect: Rect2i, colour: Color) -> void:
	var clipped := rect.intersection(Rect2i(Vector2i.ZERO, image.get_size() / SCALE))
	if clipped.size.x <= 0 or clipped.size.y <= 0:
		return
	image.fill_rect(Rect2i(clipped.position * SCALE, clipped.size * SCALE), colour)

static func _outline_tiles(image: Image, rect: Rect2i, colour: Color) -> void:
	_fill_tiles(image, Rect2i(rect.position, Vector2i(rect.size.x, 1)), colour)
	_fill_tiles(image, Rect2i(Vector2i(rect.position.x, rect.end.y - 1), Vector2i(rect.size.x, 1)),
			colour)
	_fill_tiles(image, Rect2i(rect.position, Vector2i(1, rect.size.y)), colour)
	_fill_tiles(image, Rect2i(Vector2i(rect.end.x - 1, rect.position.y), Vector2i(1, rect.size.y)),
			colour)

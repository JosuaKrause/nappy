class_name TelemetryMap
extends RefCounted
## A picture of the whole tile grid, written beside the run log.
##
## **A trace says where she was and cannot say what she was walking around.** Most of what gets
## asked of a log is a question about the layout — how far the nearest calm area is, whether a
## closure cut anything, which street the spine is, why a park was never reached — and answering any
## of them from a list of tile coordinates is a thing nobody does twice. It is a `Vector2i` in the
## log and a place in the picture.
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
##
## **There is no precinct mark and that is the correction, not an omission.** *(2026-08-31: "why
## blue? why not just take the sidewalk colour and use it for those road segments".)* A precinct
## has no carriageway — `CityGenerator._street_tile` lays its whole six-tile corridor as
## `SIDEWALK` — so the ground pass already draws it as an unbroken pale band where every other
## street has a dark stripe down the middle. The blue line was an overlay standing in for a fact
## the picture was already telling, and an overlay that repeats the ground is the one kind that can
## go out of date without anybody noticing.
const HOME_MARK := Color("ff4059")
const CALM_MARK := Color("33ff73")
const SPINE_MARK := Color("ff8c1a")
const CLOSURE_MARK := Color("ff2626")
const CORRIDOR_MARK := Color("b366ff")
const DEAD_END_MARK := Color("2ee6d0")

## What the day placed a thing **for**, as a colour. See `GameEnums.BlockerRole` and `docs/CITY.md`,
## "The words for it".
##
## **The role is the colour and not the shape, because the role is the question.** A wall drawn on
## the corridor instead of beside it is the central defect a placement can have, and it is one
## glance to see in a picture and invisible in every other tool — so it gets the channel the eye
## reads first, and the effect below gets the weaker one.
##
## `NONE` is deliberately the dullest thing in the picture. It is not a fourth kind of placement, it
## is everything the day put down for a reason that is not about the route — an ambient playground,
## a scar the run left, a cat the director will site in front of her later — and a grey blob is the
## right amount of attention for something the corridor had no say in.
const WALL_MARK := Color("ffe14d")
const FRICTION_MARK := Color("4db8ff")
const SET_PIECE_MARK := Color("ff5ce0")
const NO_ROLE_MARK := Color("8c93a1")

## How much of the ground a corridor stroke lets through.
##
## *(2026-08-31: "keep the violet lines transparent".)* It is the one mark that runs the length of
## a street rather than sitting on a tile or outlining a lot, so it is the one that can hide a
## city. Blended rather than drawn, because the image is `FORMAT_RGB8` and has no alpha channel to
## carry it — what is stored is the mix.
const CORRIDOR_ALPHA := 0.55

## The single tile put through the middle of an event that has been in the world, which is what
## tells a placement she reached from one she never did.
##
## **It is a mark added rather than strength taken away, and the first version was the other way
## round.** Fading what she never reached is the obvious design and it answers the wrong question:
## a wall placed in the far corner of a map she never walked into is still a wall in the wrong
## place, and it is the placement no trace can report — so the picture would have whispered exactly
## the thing it exists to shout. Drawn instead, every mark stays at full strength and the ones she
## met carry a white pip, which also gives the picture something it was not asked for and is worth
## keeping: the pips are a trail of **where she actually went**, against the corridor the day
## planned for her.
const MET_MARK := Color("ffffff")

## How much of the ground the line of a routed event lets through.
##
## Much fainter than the mark it belongs to, and the number was set by looking rather than chosen:
## a fire engine's route is 1920px of street and a day places a hundred and seventy-five events, so
## at 0.3 the routes were the loudest thing in the picture and read as **corridor** — thin coloured
## lines down the middle of streets, which is exactly what the violet is. A mark that can be
## mistaken for the one thing it has to be compared against is worse than no mark.
##
## It is kept rather than dropped because leaving it out is its own lie: a van that sweeps a whole
## street would be drawn as a point, and *how much ground a placement covers* is half of what makes
## a wall a wall. At 0.18 it is a shadow you find when you look for it, which is the right weight
## for a fact about an event you have already found.
const ROUTE_ALPHA := 0.18

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
##
## `plans` is what the day placed, and it is the corridor's other half: a corridor with nothing
## drawn against it says where the routes went and not whether anything was placed *for* them. See
## `_mark_the_events`.
static func render(map: CityMap, closures: Array[RoadClosure] = [],
		tree: RouteTree = null, plans: Array[EventScheduler.Planned] = []) -> Image:
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
	# Under the calm, the closures and the home on purpose: those three are what the corridor is
	# drawn to be read *against* — where it arrives, what it had to go round, where it starts —
	# and a plan that covers them would be answering its own question.
	_mark_the_corridor(image, tree)
	# Over the corridor, because a placement is read *against* it and the pair has to be seen at
	# once — and under the four below for the same reason the corridor is: where she arrives, what
	# was shut and where she starts are the picture's fixed points, and a hundred and twenty event
	# marks laid over them would bury the frame everything else is measured in.
	_mark_the_events(image, map, plans)
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

## The day's corridor, as the path it is: one translucent line down the middle of every street on
## the tree.
##
## A **placement** is exactly what a trace in words cannot show, and *is anything guiding her* is
## the question the corridor exists to answer — so it is answered here or nowhere.
##
## Each stroke runs from the middle of one junction to the middle of the next rather than over the
## street alone, so consecutive streets meet and a turn crosses — the picture is a **path** rather
## than a set of dashes, which is the difference between reading a route and inferring one.
##
## **Every street on the tree is drawn the same, and the bundles are not picked out.** *(2026-08-31:
## "don't draw the bundles white — don't make a distinction between path and bundle".)* The first
## version drew a bundled street solid white and two tiles wide, which was a third of the map under
## a colour that hides everything beneath it, and it made the shared trunk read as the subject of
## the picture rather than as a property of it. What is lost with it is a diagnostic — *a picture
## in which nothing is shared is a tree that has quietly become a star* — and that has to be read
## somewhere else now: `RouteTree.bundles()` and `tests/test_route_tree.gd`, which assert the
## sharing directly rather than by eye.
static func _mark_the_corridor(image: Image, tree: RouteTree) -> void:
	if not tree:
		return
	for key in tree.streets():
		var segment := StreetNetwork.by_key(key)
		if not segment:
			continue
		_blend_tiles(image, _corridor_stroke(segment), CORRIDOR_MARK, CORRIDOR_ALPHA)

## One street's stroke, junction centre to junction centre.
static func _corridor_stroke(segment: StreetNetwork.Segment) -> Rect2i:
	var across := Tuning.STREET_WIDTH / 2
	var from := segment.a * CityMap.period()
	var length := CityMap.period() + Tuning.STREET_WIDTH
	if segment.horizontal:
		return Rect2i(Vector2i(from.x, from.y + across), Vector2i(length, 1))
	return Rect2i(Vector2i(from.x + across, from.y), Vector2i(1, length))

## Everything the day sited, each carrying what it is: **colour is the role, shape is the effect,
## and a white pip is whether she ever got to it.**
##
## Three channels because the vocabulary has three axes and reading two of them off a log means
## joining a `plan` line to a `near` line by hand, which is the thing nobody does twice. The
## permanence axis is the one deliberately not drawn: a dead end and a big building are already
## teal, and everything here is by definition soft.
##
## **An unplaced plan is skipped and that is the honest answer, not a gap.** An `AHEAD_OF_PLAYER`
## row has no position — the day budgets one more cat and the director decides where out of where
## she turns out to walk — so drawing it anywhere would be the picture claiming a placement that
## nothing made. `_role_for` gives it `NONE` for the same reason.
##
## A **spent** offer is drawn like any other: a set piece is planned at every site of a covering set
## and exactly one happens, so the sites that did not are what makes the covering set visible at
## all. They come out without a pip, which is right — she never reached them.
static func _mark_the_events(image: Image, map: CityMap,
		plans: Array[EventScheduler.Planned]) -> void:
	for plan in plans:
		if not plan.is_placed():
			continue
		var colour := role_mark(plan.role)
		if plan.path.size() >= 2:
			_blend_tiles(image, _route_stroke(map, plan.path), colour, ROUTE_ALPHA)
		_mark_one_event(image, map.world_to_tile(plan.position), colour,
				plan.def.effect() == GameEnums.BlockerEffect.LETHAL, plan.was_live)

## One event's glyph, three tiles across whatever it is.
##
## **A lethal one is filled and everything else is a cross**, which is the game's own vocabulary
## rather than a new one: the caret over an entity is doubled and solid for a thing that ends the
## day, and single for a thing that merely costs. Both fit the same three-tile box on purpose — the
## picture is about *where* things went, so a mark that grew with its severity would make a lethal
## row look like it took more ground than it does, and on a six-tile street that is most of a
## pavement.
##
## The cross is the shape the rule above asks for; the filled square is the second exception to it,
## after the hard blockers, and it is bounded rather than argued: nine tiles of a six-tile street,
## on the handful of rows a day that end it.
##
## The pip goes on last and takes the centre tile of either shape, so it never changes a glyph's
## footprint and cannot be mistaken for a fourth kind of mark.
static func _mark_one_event(image: Image, at: Vector2i, colour: Color, lethal: bool,
		met: bool) -> void:
	if lethal:
		_fill_tiles(image, Rect2i(at - Vector2i.ONE, Vector2i(3, 3)), colour)
	else:
		_fill_tiles(image, Rect2i(Vector2i(at.x - 1, at.y), Vector2i(3, 1)), colour)
		_fill_tiles(image, Rect2i(Vector2i(at.x, at.y - 1), Vector2i(1, 3)), colour)
	if met:
		_fill_tiles(image, Rect2i(at, Vector2i.ONE), MET_MARK)

## The role a placement carries, as the colour it is drawn in.
##
## Public because the test asserts against these by name, and a test that hard-codes the hex of a
## mark is a test that passes when the drawing and the legend have come apart.
static func role_mark(role: GameEnums.BlockerRole) -> Color:
	match role:
		GameEnums.BlockerRole.WALL:
			return WALL_MARK
		GameEnums.BlockerRole.FRICTION:
			return FRICTION_MARK
		GameEnums.BlockerRole.SET_PIECE:
			return SET_PIECE_MARK
	return NO_ROLE_MARK

## The ground a routed event covers, as the one-tile band between its ends.
##
## Every path in the catalogue is **two axis-aligned points** — a van down a street, a cat across
## one — so the band between them is the route itself rather than an approximation of it, and
## `tests/test_telemetry.gd` holds that over the whole catalogue rather than leaving it as an
## assumption in a comment. It has to, because the failure is silent: a route that ever bent would
## be drawn here as its bounding box, which is a picture of ground the event never covers.
static func _route_stroke(map: CityMap, path: PackedVector2Array) -> Rect2i:
	var from := map.world_to_tile(path[0])
	var to := map.world_to_tile(path[path.size() - 1])
	var low := Vector2i(mini(from.x, to.x), mini(from.y, to.y))
	var high := Vector2i(maxi(from.x, to.x), maxi(from.y, to.y))
	return Rect2i(low, high - low + Vector2i.ONE)

## Every street a hard blocker built over: the wall at the end of a dead end, and all four sides
## of a big building.
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

## A mark mixed into the ground rather than laid over it, tile by tile.
##
## **The picture has no alpha channel, so "transparent" has to mean *mixed on the way in*.** It is
## `FORMAT_RGB8` — chosen so the file is small enough to sit in a directory listing — and a colour
## with an alpha component written into one is simply stored opaque. What is blended here is the
## ground already in the image, so a stroke crossing a junction, a kerb and a lot boundary picks up
## all three rather than flattening them.
static func _blend_tiles(image: Image, rect: Rect2i, colour: Color, alpha: float) -> void:
	var clipped := rect.intersection(Rect2i(Vector2i.ZERO, image.get_size() / SCALE))
	for y in range(clipped.position.y, clipped.end.y):
		for x in range(clipped.position.x, clipped.end.x):
			var under := image.get_pixel(x * SCALE, y * SCALE)
			_fill_tiles(image, Rect2i(Vector2i(x, y), Vector2i.ONE), under.lerp(colour, alpha))

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

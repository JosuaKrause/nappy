class_name WalkSiting
extends RefCounted
## **Lays the rows her walk places** (a *beat*: the fire, the poster crews, the route mast, day 11's
## mast near the mark, and the fire lit at dusk): offers a beat the free locations on her way and
## stands it on the first tile of the first location the day's rules leave valid, through the judge
## a unit's own draw uses (`LocationGround.offer_on()`). Nothing rolls a tile and nothing ranks tiles
## by room (docs/EVENTS.md, "A set piece happens where she is going"). The location is taken for the
## day (`DayLocations.take_for_her_walk()`), so no draw fills it and no other beat stands on it; the
## location says the beat stands on it (`Location.beat()`), so the unit's draw and the draws of the
## units touching it are judged among the beat (`PlacementUnit.beats()`, `UnitDraw`). *(The player:
## "beats are marbles, yes", inbox #1521 in breezy-magpie.)* Day 6's man shouting and day 7's van a mark rigs are laid
## the same way, just ahead of her (`lay_just_ahead()`).
##
## **A free location** is one nothing stands on and no fixed part holds
## (`Location.is_available()`, not `Location.is_taken()`).
##
## **Which locations are offered** is the beat's: one laid ahead of her (`lay_ahead()`) is offered
## the free locations holding tiles of its ground on the cells of the day's route tree ahead of her
## on the branch she walks (`RouteTree.cells_ahead()`), **those of units that have not drawn first**
## (the nearest unit on her way that has not drawn, before it draws, so the unit draws round the
## beat), nearest to walk to first, and then those a drawn unit left empty; a row a mark rigs
## (`lay_just_ahead()`) the free locations on her path just ahead of her and out of her view,
## nearest to walk to first; a mast near the mark the locations holding the tiles the resistance
## offers; the fire lit at dusk the locations off her path first, then any, away from where she
## finished.
##
## **Nothing placed while she walks is asked whether she can still get away.** The day's safe routes
## are fixed before the day starts, and nothing placed during the walk may close one, so there is
## nothing to check live (inbox #1173 in gray-dolphin: "there should be no live reachability
## check. that's a hard no"). What is laid here is what the day's own placement rules
## (`StreetInvalidation`, asked by the judge) accept and no more.
##
## **A beat that has never been in the world may be laid again, and one that has never** (the
## director's rule, `EventDirector`): a placed plan is asked without its own body and gives its old
## location back only once a new one is found.
##
## Handed everything it asks; its constructor derives nothing, so a test hands in stand-ins.

## No beat is laid ahead of her nearer than this, straight from her: the stream radius and its
## hysteresis, so it is never in the world on the frame it is laid. The near end is a distance
## across the block, since streaming is a radius, and a site 1,200px along a route that doubles back
## can be 500px from her and so real, and unmovable, on the frame it was placed.
const NOT_YET_REAL := Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
## How far from where she finished the day a fire lit at dusk stands: the stream radius, so the site
## is ground she was never near enough to have it exist in front of her.
const DUSK_CLEAR_OF_HER := Tuning.EVENT_STREAM_RADIUS
## **How far ahead of her a row a mark rigs may be laid** (`lay_just_ahead()`), down her branch and
## straight from her: the stream radius. Inside it every unit has drawn
## (`EventsAhead.draw_what_comes_near()`), so the place is one a drawn unit left empty; what is laid
## there is in the world on the frame it is laid, out of her view, so nothing moves it again; and it
## is ground she walks into within ten seconds at `Tuning.WALK_SPEED`, before the way she takes can
## part from it. *(The player, of day 6's man shouting and day 7's van: "you would draw only for the
## path and only just ahead", inbox #1549.)*
const JUST_AHEAD := Tuning.EVENT_STREAM_RADIUS
## How far to either side of the cells her branch runs through, and of her line of travel, her path
## reaches for a row a mark rigs: from the sidewalk a route walks to the far kerb, so the far sidewalk
## of her street is on her path, where a van stands (the day's rules keep a van off the sidewalk a
## route walks, `RouteSidewalkRule`).
const PATH_HALF_WIDTH := 5.0 * Tuning.TILE_SIZE
## How many locations one ask offers before it waits.
const LOCATIONS_A_LOOK := 8
## How many locations a fire lit at dusk is offered in each of its two passes.
const DUSK_LOCATIONS := 24

## Why an ask laid nothing, as `waits()` counts it.
const _BROKE_A_RULE := "every location offered broke a placement rule"
const _OFF_THE_ROUTES := "she is off the day's routes"
const _NO_GROUND_ON_THE_BRANCH := "no free ground of its own on the branch ahead of her"
const _NO_GROUND_JUST_AHEAD := "no free ground of its own on her path just ahead of her, out of her view"

var _map: CityMap
## The day's routes themselves: a siting on the branch she is walking needs the ordered chain of
## cells (`RouteTree.cells_ahead()`).
var _tree: RouteTree
var _walk: WalkEvents
var _locations: DayLocations
## The judge of a location (`LocationGround.offer_on()`): the day's rules, with a candidate built on
## each tile handed, the first none refuses.
var _judge: LocationGround
## The tiles a row may stand on (`SitedGround`).
var _ground: SitedGround
## Where she is and which way she is going, as `begin_look()` was told.
var _at := Vector2.ZERO
var _heading := Vector2.ZERO
## The cells ahead of her in walking order, asked of the tree on the first branch ask of a look.
var _cells: Array[Vector2i] = []
## The same cells -> how far she walks down her branch to reach each (`RouteTree.cells_ahead()`).
var _walked_to := {}
var _cells_asked := false
## A row -> its ground by cell of the route tree (`cell -> its tiles, in row-then-column order`), worked
## out once a row, so a look walks the cells of her branch and asks only the tiles of the row's
## ground in each.
var _by_cell := {}
## The rows refused in this look while unplaced, cleared when a look begins or ends and whenever a
## plan is laid.
var _nowhere := {}
## The beats laid and not given back -> the location each took.
var _laid := {}
## Why asks laid nothing, as `reason -> how many asks`.
var _waits := {}

## `tree` is the day's route tree, `walk` the walk's events (its plans,
## which every beat is spaced and judged among, its doors and its calm), `locations` the day's
## locations, `judge` the day's rules over them and `ground` the tiles a row may stand on.
func _init(map: CityMap, tree: RouteTree, walk: WalkEvents, locations: DayLocations,
		judge: LocationGround, ground: SitedGround) -> void:
	_map = map
	_tree = tree
	_walk = walk
	_locations = locations
	_judge = judge
	_ground = ground

## Does at a day's start the scan the first ask for `def` would do mid-walk (`SitedGround.prepare()`).
func prepare(def: EventDef) -> void:
	_ground.prepare(def)
	_ground_by_cell(def)

## **Starts a look from where she is**: every `lay_ahead()` until `end_look()` reads one way ahead,
## asked of the route tree once, and a row refused in it is not judged again in it.
func begin_look(at: Vector2, heading: Vector2) -> void:
	_at = at
	_heading = heading
	_cells.clear()
	_walked_to.clear()
	_cells_asked = false
	_nowhere.clear()

## Ends a look; nothing is kept past it.
func end_look() -> void:
	_cells.clear()
	_walked_to.clear()
	_cells_asked = false
	_nowhere.clear()

## **Lays `plan` ahead of her** on the branch she walks, in a unit that has not drawn where her way
## has one, or answers false and leaves it as it is, with the reason in `waits()`: a wait is ordinary
## (she is off the day's routes, or walking home inside the streaming band of the branch's end) and
## the answer is to ask again a look later, from wherever she has got to, never to place it somewhere
## illegal. A placed plan is judged without its own body (what the day's plans are judged among
## leaves it out) and gives its old location back only once it has another. Nothing is drawn round
## a pick first: a unit that has not drawn draws round the beat, and one that has is part of what
## the beat is judged among. Inside a look.
func lay_ahead(plan: EventPlan) -> bool:
	var def := plan.row()
	if not plan.is_placed() and _nowhere.has(def):
		return _waited(_BROKE_A_RULE)
	return _lay_on_the_first(plan, _on_her_branch(def))

## **Lays `plan`, a row a mark rigs (day 6's man shouting, day 7's van), on her path just ahead of
## her**, or answers false and leaves it as it is, with the reason in `waits()`: on the first free
## location, nearest to walk to first, that holds tiles of its ground within `JUST_AHEAD` of her
## down the branch she walks and straight from her, within `PATH_HALF_WIDTH` of that branch,
## straight ahead of her (ahead along her heading, within `PATH_HALF_WIDTH` of her line of travel)
## and out of her view, which the day's rules accept. Straight ahead, because the view is wider than
## it is tall: ground beside her leaves the view sooner than ground ahead, so without it the nearest
## place out of view is often round the corner of a fork or a turn she does not take. The ground
## there has drawn, so the location is one a drawn unit left empty, the way a beat is laid on one
## where her way has no undrawn unit; its location says the beat stands on it, so the units touching
## it that draw later are judged among it. *(The player: "you
## would draw only for the path and only just ahead", inbox #1549.)* A wait is ordinary (she is off
## the day's routes, or the stretch just ahead has no free ground of the row's out of her view) and
## the answer is to ask again a look later, from wherever she has got to. Inside a look.
func lay_just_ahead(plan: EventPlan) -> bool:
	var def := plan.row()
	if not plan.is_placed() and _nowhere.has(def):
		return _waited(_BROKE_A_RULE)
	return _lay_on_the_first(plan, _just_ahead_on_her_path(def))

## Stands `plan` on the first location of `offers` (`location -> its tiles`, in the order offered)
## the day's rules accept a tile of, judged without its own body, or answers false; a row refused
## everywhere while unplaced is not judged again in the look.
func _lay_on_the_first(plan: EventPlan, offers: Dictionary) -> bool:
	if offers.is_empty():
		return false
	var def := plan.row()
	var among := _walk.everything_but(plan)
	for location: Location in offers:
		var sited := _judge.offer_on(def, location, _tiles_of(offers, location), among)
		if not sited:
			continue
		_stand(plan, sited, location)
		return true
	if not plan.is_placed():
		_nowhere[def] = true
	return _waited(_BROKE_A_RULE)

## **Lays `plan` on one of `offered`**, tiles a caller chose, in the first free location that takes
## one of them in the order offered: day 11's mast near the mark, among the tiles the resistance
## found near her and out of her view.
func lay_among(plan: EventPlan, offered: Array[Vector2i]) -> bool:
	var def := plan.row()
	var grouped := {}
	for tile in offered:
		var location := _locations.holding(tile, _map.tile_at(tile))
		if _is_free(location):
			_group(grouped, location, tile)
	var among := _walk.everything_but(plan)
	for location: Location in grouped:
		var sited := _judge.offer_on(def, location, _tiles_of(grouped, location), among)
		if sited:
			_stand(plan, sited, location)
			return true
	return false

## **Stands `plan` away from her and off the day's routes**, for the one case a walk can end without
## the guarantee having been met: a day 3 she wins on which every siting was refused, so the day
## lights its fire at dusk instead (PLAYTEST-121: "I agree with the fire fix"). At least
## `DUSK_CLEAR_OF_HER` from `away_from`, so nothing is lit where she could have seen it; off the
## ground the day's routes run along first, so the street she walked is not the one that burns, else
## merely away, since a run that owes a fire and has nowhere ideal to put it should still have its
## fire. The locations of each pass are taken in an order of `rng`, at most `DUSK_LOCATIONS` of
## them. Takes no location: the day is over, and the fire is lit and taken out of the world at once.
func lay_off_her_path(plan: EventPlan, away_from: Vector2, rng: RandomNumberGenerator) -> bool:
	var def := plan.row()
	var clear_of_the_routes := {}
	var merely_away := {}
	for tile: Vector2i in _ground.tiles_of(def):
		if _map.tile_to_world(tile).distance_to(away_from) < DUSK_CLEAR_OF_HER:
			continue
		var location := _locations.holding(tile, _map.tile_at(tile))
		if not _is_free(location):
			continue
		_group(merely_away, location, tile)
		if not _tree.carries_a_route(tile):
			_group(clear_of_the_routes, location, tile)
	var among := _walk.everything_but(plan)
	for pass_offers: Dictionary in [clear_of_the_routes, merely_away]:
		var in_order: Array[Location] = []
		for location: Location in pass_offers:
			in_order.append(location)
		for k in range(in_order.size() - 1, 0, -1):
			var j := rng.randi_range(0, k)
			var kept := in_order[k]
			in_order[k] = in_order[j]
			in_order[j] = kept
		for i in mini(in_order.size(), DUSK_LOCATIONS):
			var location := in_order[i]
			var sited := _judge.offer_on(def, location, _tiles_of(pass_offers, location), among)
			if sited:
				plan.stand_where(sited)
				return true
	return false

## **Whether `position` is still somewhere ahead of her along the branch she is walking**
## (`RouteTree.is_ahead()`): the question `EventDirector` asks of a placement already made, once a
## look, to find the fire she left behind on a fork she did not take. True when the answer cannot be
## had, so a place is left alone for a corner she is cutting.
func still_ahead_of(at: Vector2, heading: Vector2, position: Vector2) -> bool:
	return _tree.is_ahead(at, heading, position)

## Why asks laid nothing, as `reason -> how many asks ended that way`. What the run log says of a
## fire she never met (`EventsAhead.light_what_she_never_met()`), and what a probe reports of a long
## wait: the difference between a branch with no frontage on it and a day whose every site breaks a
## placement rule.
func waits() -> Dictionary:
	return _waits.duplicate()

# ---------------------------------------------------------------- the offers ---

## **The free locations holding tiles of `def`'s ground on her branch**, as `location -> its tiles`,
## at most `LOCATIONS_A_LOOK`: those of units that have not drawn first, nearest to walk to first,
## then those a drawn unit left empty, nearest first; empty with the reason in `waits()`. So a beat
## takes a location of the nearest unit on her way before it draws where there is one, and falls
## back to drawn ground only where none takes it: near a branch's end, and on a walk whose units all
## drew as it started. A tile counts when the tree itself carries it (a cell is not always one
## piece: `ReachabilityGrid` splits it into a node per connected component and a route carries
## nodes, so a second node the route never touches is no site) and it is at least `NOT_YET_REAL`
## from her. A free location is of a unit that has not drawn exactly while it is open
## (`Location.is_open()`): a draw records every open location of its unit as it fills in.
func _on_her_branch(def: EventDef) -> Dictionary:
	var undrawn := {}
	var drawn := {}
	if not _cells_asked:
		_cells_asked = true
		_cells = _cells_in_walking_order()
	if _cells.is_empty():
		_waited(_OFF_THE_ROUTES)
		return undrawn
	var ground_by_cell := _ground_by_cell(def)
	for cell in _cells:
		if ground_by_cell.has(cell):
			for tile: Vector2i in (ground_by_cell[cell] as Array[Vector2i]):
				if not _ground.takes(def, tile):
					continue
				if _map.tile_to_world(tile).distance_to(_at) < NOT_YET_REAL:
					continue
				var location := _locations.holding(tile, _map.tile_at(tile))
				if not _is_free(location):
					continue
				var tier := undrawn if location.is_open() else drawn
				if not tier.has(location) and tier.size() >= LOCATIONS_A_LOOK:
					continue
				if _tree.branches_on(tile).is_empty():
					continue
				_group(tier, location, tile)
		if undrawn.size() >= LOCATIONS_A_LOOK:
			break
	for location: Location in drawn:
		if undrawn.size() >= LOCATIONS_A_LOOK:
			break
		undrawn[location] = drawn[location]
	if undrawn.is_empty():
		_waited(_NO_GROUND_ON_THE_BRANCH)
	return undrawn

## **The free locations holding tiles of `def`'s ground on her path just ahead of her**, as
## `location -> its tiles`, at most `LOCATIONS_A_LOOK`, the nearest to walk to first: a tile counts
## when it lies within `PATH_HALF_WIDTH` of the centre of a cell of her branch she reaches within
## `JUST_AHEAD` (`RouteTree.cells_ahead()`), within `JUST_AHEAD` of her, ahead of her along her
## heading and within `PATH_HALF_WIDTH` of her line of travel, and none of what
## `def` draws standing on it could be in her view (`_could_be_in_her_view()`); how near is how far
## down her branch the nearest such cell lies. Empty with the reason in `waits()`.
func _just_ahead_on_her_path(def: EventDef) -> Dictionary:
	var offers := {}
	if not _cells_asked:
		_cells_asked = true
		_cells = _cells_in_walking_order()
	if _cells.is_empty():
		_waited(_OFF_THE_ROUTES)
		return offers
	# Each tile of the row's ground near the branch -> how far down the branch its nearest cell is.
	var walked_to := {}
	var found: Array[Vector2i] = []
	var reach := ceili(PATH_HALF_WIDTH / Tuning.TILE_SIZE)
	for cell in _cells:
		var down := float(_walked_to[cell])
		if down > JUST_AHEAD:
			break
		var centre := _tree.cell_centre(cell)
		var middle := _map.world_to_tile(centre)
		for dy in range(-reach, reach + 1):
			for dx in range(-reach, reach + 1):
				var tile := middle + Vector2i(dx, dy)
				if walked_to.has(tile):
					continue
				var feet := _map.tile_to_world(tile)
				if feet.distance_to(centre) > PATH_HALF_WIDTH \
						or feet.distance_to(_at) > JUST_AHEAD or not _ground.takes(def, tile):
					continue
				var offset := feet - _at
				if offset.dot(_heading) <= 0.0 or absf(offset.cross(_heading)) > PATH_HALF_WIDTH:
					continue
				walked_to[tile] = down
				found.append(tile)
	for tile in found:
		var location := _locations.holding(tile, _map.tile_at(tile))
		if not _is_free(location):
			continue
		if not offers.has(location) and offers.size() >= LOCATIONS_A_LOOK:
			continue
		if _could_be_in_her_view(def, _map.tile_to_world(tile), _at):
			continue
		_group(offers, location, tile)
	if offers.is_empty():
		_waited(_NO_GROUND_JUST_AHEAD)
	return offers

## Whether any of what `def` draws, standing at `feet`, could be in the camera's view while she
## stands at `her`: its footprint where it is drawn (`EventFootprints.footprint_of()`, a van's
## reaching 56.5px up from its feet and 28.5px down) against the 640x360 view round her
## (`Tuning.VIEW_HALF_EXTENT`), grown on every side by the camera's lead
## (`Stroller.CAMERA_LOOK_AHEAD` along her facing, `Stroller.OBLIQUE_Y` of it up or down), since the
## lead eases toward a new facing over a turn, and by a tile to spare.
func _could_be_in_her_view(def: EventDef, feet: Vector2, her: Vector2) -> bool:
	var box := EventFootprints.footprint_of(def)
	var drawn := Rect2(feet + box.position, box.size) if box.has_area() \
			else Rect2(feet, Vector2.ZERO)
	var lead := Vector2(Stroller.CAMERA_LOOK_AHEAD,
			Stroller.CAMERA_LOOK_AHEAD * Stroller.OBLIQUE_Y) + Vector2.ONE * Tuning.TILE_SIZE
	var view := Rect2(her - Tuning.VIEW_HALF_EXTENT - lead,
			(Tuning.VIEW_HALF_EXTENT + lead) * 2.0)
	return view.intersects(drawn, true)

## **`def`'s ground by the cell of the route tree each tile lies in**, each cell's tiles in row-then-
## column order, worked out once a row: a tree has far more tiles than a row's ground, so a look asks
## only the tiles a row may stand on, cell by cell, instead of every tile of every cell.
func _ground_by_cell(def: EventDef) -> Dictionary:
	if not _by_cell.has(def):
		var found := {}
		for tile: Vector2i in _ground.tiles_of(def):
			var cell := Vector2i(floori(tile.x / float(ReachabilityGrid.CELL)),
					floori(tile.y / float(ReachabilityGrid.CELL)))
			if not found.has(cell):
				found[cell] = [] as Array[Vector2i]
			(found[cell] as Array[Vector2i]).append(tile)
		for cell: Vector2i in found:
			(found[cell] as Array[Vector2i]).sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
					return a.y < b.y or (a.y == b.y and a.x < b.x))
		_by_cell[def] = found
	var kept: Dictionary = _by_cell[def]
	return kept

## The cells of the tree ahead of her, nearest to walk to first, each with how far she walks down
## her branch to reach it recorded in `_walked_to`.
func _cells_in_walking_order() -> Array[Vector2i]:
	var ahead := _tree.cells_ahead(_at, _heading, INF)
	var cells: Array[Vector2i] = []
	for cell: Vector2i in ahead:
		cells.append(cell)
		_walked_to[cell] = float(ahead[cell])
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return float(ahead[a]) < float(ahead[b]))
	return cells

# --------------------------------------------------------------------- laying ---

## Whether `location` is free: it exists, a fixed part does not hold it and nothing stands on it.
func _is_free(location: Location) -> bool:
	return location != null and location.is_available() and not location.is_taken()

## Adds `tile` to the tiles of `location` in `grouped` (`location -> tiles`), after the locations
## and tiles already there.
func _group(grouped: Dictionary, location: Location, tile: Vector2i) -> void:
	if not grouped.has(location):
		grouped[location] = [] as Array[Vector2i]
	(grouped[location] as Array[Vector2i]).append(tile)

## The tiles of `location` in `grouped`.
func _tiles_of(grouped: Dictionary, location: Location) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = grouped[location]
	return tiles

## **Stands `plan` where `sited` was judged, on `location`**: gives its old location back (only now
## that another is found), takes the new for the day and turns a crew to face the wall it pastes,
## its back to the street (`PlanBuilder.build()` turned it by the dawn's own side, out of a wall it
## was never going to stand at).
func _stand(plan: EventPlan, sited: EventPlan, location: Location) -> void:
	_give_back(plan)
	plan.stand_where(sited)
	if plan.stands_at_a_front():
		plan.face(Vector2.UP)
	_locations.take_for_her_walk(location, plan)
	_laid[plan] = location
	_nowhere.clear()

## **Gives back the location `plan` took**, where it took one. A location whose unit drew while the
## beat stood there was left drawn by that draw (`MarbleDraw.draw()`), so it reads drawn with nothing
## on it, not open, in a unit that will not draw again; what the unit drew round the beat stays as
## drawn.
func _give_back(plan: EventPlan) -> void:
	if not _laid.has(plan):
		return
	var location: Location = _laid[plan]
	_locations.give_back(location, plan)
	_laid.erase(plan)

## Records why an ask laid nothing and answers false. See `waits()`.
func _waited(reason: String) -> bool:
	_waits[reason] = int(_waits.get(reason, 0)) + 1
	return false

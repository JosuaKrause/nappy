class_name WalkSiting
extends RefCounted
## **Lays the rows her walk places** (a *beat*: the fire, the poster crews, the route mast, day 6's
## man shouting, day 7's van, day 11's mast near the mark, and the fire lit at dusk): offers a beat
## the free locations on her way and stands it on the first tile of the first location the day's
## rules leave valid, through the judge a unit's own draw uses (`LocationGround.offer_on()`).
## Nothing rolls a tile and nothing ranks tiles by room (docs/EVENTS.md, "A set piece happens where
## she is going"). The location is taken for the day (`DayLocations.take_for_her_walk()`), so no
## draw fills it and no other beat stands on it.
##
## **A free location** is one nothing stands on and no fixed part holds
## (`Location.is_available()`, not `Location.is_taken()`).
##
## **Which locations are offered** is the row's: a *branch beat* (every row but the two below) is
## offered the free locations holding tiles of its ground on the cells of the day's route tree ahead
## of her on the branch she walks (`RouteTree.cells_ahead()`), nearest to walk to first; a *street
## beat* (a row met on her street, `EventDef.is_met_on_her_street()`, and a wall by its fit alone)
## the free locations holding tiles of its ground ahead of her on the street she is walking, just out
## of the camera's view; a mast near the mark the locations holding the tiles the resistance offers;
## the fire lit at dusk the locations off her path first, then any, away from where she finished.
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

## No branch beat is laid nearer than this, straight from her: the stream radius and its
## hysteresis, so it is never in the world on the frame it is laid. The near end is a distance
## across the block, since streaming is a radius, and a site 1,200px along a route that doubles back
## can be 500px from her and so real, and unmovable, on the frame it was placed.
const NOT_YET_REAL := Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
## How far from where she finished the day a fire lit at dusk stands: the stream radius, so the site
## is ground she was never near enough to have it exist in front of her.
const DUSK_CLEAR_OF_HER := Tuning.EVENT_STREAM_RADIUS
## How far either side of her line of travel her street reaches: from her sidewalk to the far kerb,
## and no further, since a block's frontage is past it.
const STREET_HALF_WIDTH := 5.0 * Tuning.TILE_SIZE
## How many locations one ask offers before it waits.
const LOCATIONS_A_LOOK := 8
## How many locations a fire lit at dusk is offered in each of its two passes.
const DUSK_LOCATIONS := 24

## Why `lay_ahead()` gave up a pick the ground round which had not drawn, as `waits()` counts it.
const _ITS_GROUND_HAD_NOT_DRAWN := "the ground round its site had not drawn"
const _BROKE_A_RULE := "every location offered broke a placement rule"
const _OFF_THE_ROUTES := "she is off the day's routes"
const _NO_GROUND_ON_THE_BRANCH := "no free ground of its own on the branch ahead of her"
const _NOT_WALKING := "she is not walking anywhere"
const _NO_GROUND_ON_HER_STREET := "no free location ahead of her on the street she is walking"

var _day: int
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
var _in_a_look := false
## The cells ahead of her in walking order, asked of the tree on the first branch ask of a look.
var _cells: Array[Vector2i] = []
var _cells_asked := false
## The rows refused in this look while unplaced, cleared when a look begins or ends and whenever a
## plan is laid.
var _nowhere := {}
## The beats laid and not given back -> the location each took.
var _laid := {}
## Why asks laid nothing, as `reason -> how many asks`.
var _waits := {}
## What draws the ground round a site before it stands (`use_the_ground_drawer()`); none until one
## is handed in.
var _draws_the_ground_round := Callable()

## `day` is the day laid for (a row's role is the day's), `tree` the day's route tree, `walk` the
## walk's events (its plans, which every beat is spaced and judged among, its doors and its calm),
## `locations` the day's locations, `judge` the day's rules over them and `ground` the tiles a row
## may stand on.
func _init(for_day: int, map: CityMap, tree: RouteTree, walk: WalkEvents,
		locations: DayLocations, judge: LocationGround, ground: SitedGround) -> void:
	_day = for_day
	_map = map
	_tree = tree
	_walk = walk
	_locations = locations
	_judge = judge
	_ground = ground

## Does at a day's start the scan the first ask for `def` would do mid-walk (`SitedGround.prepare()`).
func prepare(def: EventDef) -> void:
	_ground.prepare(def)

## **Hands the siting what draws the ground round a site**: `draws_round` is `func(at: Vector2,
## reach: float) -> bool`, which draws every undrawn unit of the day's locations any part of which
## lies within `reach` of `at`, what they place joining the walk's plans, and answers whether it drew
## any (`EventsAhead.draw_the_ground_round()`). `lay_ahead()` asks it of every pick it makes and gives
## the pick up for this look where it drew a unit, so no unit's draw reads a plan her walk lays and
## no beat stands beside a unit that has not drawn.
func use_the_ground_drawer(draws_round: Callable) -> void:
	_draws_the_ground_round = draws_round

## **Starts a look from where she is**: every `lay_ahead()` until `end_look()` reads one way ahead,
## asked of the route tree once, and a row refused in it is not judged again in it.
func begin_look(at: Vector2, heading: Vector2) -> void:
	_at = at
	_heading = heading
	_in_a_look = true
	_cells.clear()
	_cells_asked = false
	_nowhere.clear()

## Ends a look; nothing is kept past it.
func end_look() -> void:
	_in_a_look = false
	_cells.clear()
	_cells_asked = false
	_nowhere.clear()

## **Lays `plan` ahead of her**, on her street for a street beat and on her branch for any other, or
## answers false and leaves it as it is, with the reason in `waits()`: a wait is ordinary (she is
## off the day's routes, or walking home inside the streaming band of the branch's end) and the
## answer is to ask again a look later, from wherever she has got to, never to place it somewhere
## illegal. A placed plan is judged without its own body (what the day's plans are judged among
## leaves it out) and gives its old location back only once it has another. Inside a look.
func lay_ahead(plan: EventPlan) -> bool:
	var def := plan.row()
	if not plan.is_placed() and _nowhere.has(def):
		return _waited(_BROKE_A_RULE)
	var offers := _on_her_street(def) if _is_met_on_her_street(def) else _on_her_branch(def)
	if offers.is_empty():
		return false
	var among := _walk.everything_but(plan)
	for location: Location in offers:
		var sited := _judge.offer_on(def, location, _tiles_of(offers, location), among)
		if not sited:
			continue
		if _draws_the_ground_round.is_valid() and _draws_the_ground_round.call(
				sited.placed_at(), Tuning.EVENT_DRAW_AHEAD):
			# The units just drawn joined the walk's plans, which this pick was not judged among.
			return _waited(_ITS_GROUND_HAD_NOT_DRAWN)
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

## Whether `def` is laid on the street she is walking rather than on her branch: a row the catalogue
## marks as met there, and a wall by its fit alone, which is never put on a sidewalk a route runs
## along (`RouteSidewalkRule`: "the far side of a street answers a van, and nothing answers a van on
## the side the route is drawn down"), so the branch she may leave is the wrong place for it.
func _is_met_on_her_street(def: EventDef) -> bool:
	if def.is_met_on_her_street():
		return true
	return EventScheduler.role_for(def, _day) == GameEnums.BlockerRole.WALL \
			and not _ground.is_a_wall_by_cost(def)

## **The free locations holding tiles of `def`'s ground on her branch**, as `location -> its tiles`,
## nearest to walk to first, at most `LOCATIONS_A_LOOK`; empty with the reason in `waits()`. A tile
## counts when the tree itself carries it (a cell is not always one piece: `ReachabilityGrid` splits
## it into a node per connected component and a route carries nodes, so a second node the route
## never touches is no site) and it is at least `NOT_YET_REAL` from her.
func _on_her_branch(def: EventDef) -> Dictionary:
	var offers := {}
	if not _cells_asked:
		_cells_asked = true
		_cells = _cells_in_walking_order()
	if _cells.is_empty():
		_waited(_OFF_THE_ROUTES)
		return offers
	for cell in _cells:
		for dy in ReachabilityGrid.CELL:
			for dx in ReachabilityGrid.CELL:
				var tile: Vector2i = cell * ReachabilityGrid.CELL + Vector2i(dx, dy)
				if _map.tile_to_world(tile).distance_to(_at) < NOT_YET_REAL:
					continue
				var location := _locations.holding(tile, _map.tile_at(tile))
				if not _is_free(location):
					continue
				if not offers.has(location) and offers.size() >= LOCATIONS_A_LOOK:
					continue
				if _tree.branches_on(tile).is_empty() or not _ground.takes(def, tile):
					continue
				_group(offers, location, tile)
		if offers.size() >= LOCATIONS_A_LOOK:
			break
	if offers.is_empty():
		_waited(_NO_GROUND_ON_THE_BRANCH)
	return offers

## The cells of the tree ahead of her, nearest to walk to first.
func _cells_in_walking_order() -> Array[Vector2i]:
	var ahead := _tree.cells_ahead(_at, _heading, INF)
	var cells: Array[Vector2i] = []
	for cell: Vector2i in ahead:
		cells.append(cell)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return float(ahead[a]) < float(ahead[b]))
	return cells

## **The free locations holding tiles of `def`'s ground ahead of her on her street**, as `location ->
## its tiles`, by how far along her heading each location's first tile lies, at most
## `LOCATIONS_A_LOOK`; empty with the reason in `waits()`. The tiles are the ones within the stream
## radius, ahead of her, within `STREET_HALF_WIDTH` of her line of travel, with the whole of what the
## row draws out of the camera's view: a thing created at once is placed past the view's own edge
## (`Offscreen.boundary()`'s rule), so it is in the world where she will see it in a few seconds if
## she keeps walking that way, and like anything in the world it is not moved again.
## *(Proposed, not asked for: "on her route" read as the street she is walking.)*
func _on_her_street(def: EventDef) -> Dictionary:
	var offers := {}
	if _heading.length_squared() < 0.5:
		_waited(_NOT_WALKING)
		return offers
	var found: Array = []
	var centre := _map.world_to_tile(_at)
	var reach := ceili(Tuning.EVENT_STREAM_RADIUS / Tuning.TILE_SIZE)
	var scanned := 0
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var tile := centre + Vector2i(dx, dy)
			if not _ground.takes(def, tile):
				continue
			var offset := _map.tile_to_world(tile) - _at
			var along := offset.dot(_heading)
			if along <= 0.0 or offset.length() > Tuning.EVENT_STREAM_RADIUS \
					or absf(offset.cross(_heading)) > STREET_HALF_WIDTH:
				continue
			if _could_be_in_her_view(def, _map.tile_to_world(tile), _at):
				continue
			if _is_free(_locations.holding(tile, _map.tile_at(tile))):
				found.append([int(along / Tuning.TILE_SIZE), scanned, tile])
				scanned += 1
	found.sort_custom(func(a: Array, b: Array) -> bool:
			return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	for entry: Array in found:
		var tile: Vector2i = entry[2]
		var location := _locations.holding(tile, _map.tile_at(tile))
		if not offers.has(location) and offers.size() >= LOCATIONS_A_LOOK:
			continue
		_group(offers, location, tile)
	if offers.is_empty():
		_waited(_NO_GROUND_ON_HER_STREET)
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
## that another is found), takes the new for the day, and turns a crew to face the wall it pastes,
## its back to the street (`PlanBuilder.build()` turned it by the dawn's own side, out of a wall it
## was never going to stand at).
func _stand(plan: EventPlan, sited: EventPlan, location: Location) -> void:
	_give_back(plan)
	plan.stand_where(sited)
	if plan.row().stands_at_a_front():
		plan.face(Vector2.UP)
	_locations.take_for_her_walk(location, plan)
	_laid[plan] = location
	_nowhere.clear()

## Gives back the location `plan` took, where it took one.
func _give_back(plan: EventPlan) -> void:
	if _laid.has(plan):
		_locations.give_back(_laid[plan] as Location, plan)
		_laid.erase(plan)

## Records why an ask laid nothing and answers false. See `waits()`.
func _waited(reason: String) -> bool:
	_waits[reason] = int(_waits.get(reason, 0)) + 1
	return false

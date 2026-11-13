class_name RowGround
extends RefCounted
## **Which tiles a row may stand on today, and how many times over the day offers each**: one
## object for one walk, which scans the map once for each question a row asks and keeps the
## answer, and is handed to every placement that asks, at dawn and while she walks. So the city is
## scanned once a day for a question, and what is sited on her walk stands on the very ground the
## day was planned on.
##
## *(inbox #1156 in gray-dolphin: "have an object that contains the derived information -- don't
## rederive over and over again -- then pass that object around".)*
##
## **It is handed everything it asks**: the map; the walk's corridor (`Corridor`), or none for a
## walk with no routes, where a role asks nothing more than the row does; whether she sets off
## from the home's front door, whose street nothing then stands on
## (`DaySpec.holds_the_home_streets`); how many times over a tile is offered (`Weights`); and
## whether a wall is one by what it costs to walk through, as a function. Whoever makes a ground
## names them. The game's are `EventScheduler.row_ground()`'s: the scheduler's own numbers and its
## own reading of a wall, neither of which this file names.
##
## **An answer is kept under the question, not under the row**, because almost every row in the
## catalogue asks the same one (a sidewalk, either side), so one scan serves most of a day. The
## scan is the expensive half: two passes over every tile of the right type, a sidewalk being five
## thousand of them, with a closure test, a doorstep test and a kerb test on each, while the dawn
## draw asks for every row a location weighs.
##
## **A ground lives exactly one walk.** Nothing it reads moves inside one: the grid is repainted
## and the day's closures and holds are on the map before the first question is asked. Kept past
## its walk it would answer for streets that have since been closed or held, which is why it is
## made for the walk and handed round rather than kept on the map.
##
## **An answer is handed out as it is kept**: a caller reads it and never changes it. Model: no
## node.

## **How many times over the day offers a tile to a row**: the numbers a ground is made with. Each
## is one or more, and a ground made with `Weights.new()` offers every tile once.
class Weights extends RefCounted:
	var _precinct := 1
	var _on_the_routes := 1
	var _rim := 1
	var _gap := 1
	var _deep := 1

	## The weights of one walk:
	##
	## - `precinct`: a tile of a precinct street, to any row, against an ordinary tile's once;
	## - `on_the_routes`: a tile of a street the routes run along, to friction and to a wall by its
	##   fit alone;
	## - `rim`: a tile on the rim of the routes, to a costly wall that does not end the day;
	## - `gap`: such a tile on the street joining two strands of the routes, on top of `rim`;
	## - `deep`: a tile two turnings or more off the routes, to a wall that ends the day.
	static func of(precinct: int, on_the_routes: int, rim: int, gap: int, deep: int) -> Weights:
		var weights := Weights.new()
		weights._precinct = precinct
		weights._on_the_routes = on_the_routes
		weights._rim = rim
		weights._gap = gap
		weights._deep = deep
		return weights

	func precinct() -> int:
		return _precinct

	func on_the_routes() -> int:
		return _on_the_routes

	func rim() -> int:
		return _rim

	func gap() -> int:
		return _gap

	func deep() -> int:
		return _deep

var _map: CityMap
var _corridor: Corridor
var _from_the_door := true
var _weights: Weights
## `(row: EventDef) -> bool`: whether a wall is one by what it costs to walk through, and so
## pulled along the wall band's gradient, rather than by its fit alone (`_times_for_role()`).
var _wall_by_cost: Callable
## The question a row asks -> every tile that answers it, once for each time it is offered
## (`Array[Vector2i]`), in the map's own order.
var _tiles := {}
## The same question -> tile -> how many times it is offered.
var _offers := {}
## The question a row asks for a role -> tile -> how many times it is offered.
var _role_offers := {}
## Every tile under a street tree's footprint, as a set (`StreetTrees.footprint_tiles()`): one scan
## of the city's pits a walk, made when first asked. The trees are fixed for the run.
var _trees := {}
var _trees_are_known := false

## The ground of a walk on `map` routed by `corridor` (null for a walk with no routes), setting off
## from the home's front door or not (`from_the_door`), each tile offered as often as `weights`
## says, a wall told by `wall_by_cost`.
func _init(map: CityMap, corridor: Corridor, from_the_door: bool, weights: Weights,
		wall_by_cost: Callable) -> void:
	_map = map
	_corridor = corridor
	_from_the_door = from_the_door
	_weights = weights
	_wall_by_cost = wall_by_cost

# ---------------------------------------------------------------- questions ---

## **Every tile `def` may stand on today, once for each time the day offers it**, in the map's own
## order, a tile's copies together. The order matters to whoever rolls an index into it: a day has
## to be reproducible from its seed. `side` is the lane of the sidewalk asked for
## (`EventDef.Pavement`), or the row's own where it is under zero; it is typed `int` because a
## cross-script enum parameter does not always match the type Godot infers for a value read off
## another script's property.
##
## **Five kinds of ground are refused outright**, by construction rather than as a repair once
## something has landed there:
##
## - **a closed street**, which nobody can get to, so the day would hold an event for nothing;
## - **a held one** (`CityMap.is_held_at()`): not closed but spoken for, a hard seal's segment, a
##   region wall or door, or a segment bordering the home block;
## - **the home block's own interior**;
## - **the street the front door opens onto**, on a walk that sets off from that door
##   (`ClosurePlanner.home_street()`). The home is a notch with one exit, so the walk from the
##   doorstep to the first junction is the one stretch of a day she does not choose to be on, and a
##   thing standing on it is not a route decision, it is a tax. The segment rather than a radius: a
##   radius is a number somebody has to tune and it stops at an arbitrary distance down a street,
##   and a segment ends at the junction where the choice is made. The escape comes out of the
##   service exit on the side of the block and never uses that door
##   (`RouteSource.street_it_starts_in()`), so its ground keeps that street;
## - **a standing street tree's own ground.** The trees are the city's and fixed for the run while
##   the events are the day's, so the day is what yields. *(2026-09-12, the player: "events can only
##   be placed where no trees are (except for the fallen tree which must empty out one tree lot)".)*
##   The footprint rather than the trunk tile, because the ground a tree's shadow reaches over is
##   ground a van would be standing in. The fallen tree needs no exception here: it arrives as a
##   closure or a hard seal, and both hold their whole street already.
##
## **And the lane the row does not want** (`_wants_this_side()`).
##
## **A precinct is a retail street**, so it carries more of the day than a length of ordinary
## sidewalk does: it is where the cafés, the market stalls and the street musicians are, and each of
## its tiles is offered `Weights.precinct()` times over. Weighting the ground rather than adding a
## rule keeps everything that reads the answer working unchanged.
##
## **Anything `EventDef.has_a_spread` is refused a corner**, kept under a question of its own so the
## scan stays shared with every row that has no orientation to get wrong on one: a tile whose two
## coordinates are both inside a street belongs to two streets at once, and there is no single
## street left for a spread to lie across or be centered on.
##
## **A row that burns its front is refused the power station's** (`_burns_its_front()`): the
## station's facade is drawn whole whatever its building's condition says, its transformer yard
## has no wall at all for the burnt building's red arrow to end on, and it is the last night's
## building. Kept under its own question, so a poster crew asking for the same lane keeps the
## station's front.
func tiles_for(def: EventDef, side: int = -1) -> Array[Vector2i]:
	var wanted := def.pavement_side if side < 0 else side
	var scanned := _scanned(def, wanted)
	if not def.has_a_spread:
		return scanned
	var question := _question(def, wanted)
	if not _tiles.has(question):
		var without_corners: Array[Vector2i] = []
		for tile in scanned:
			if not _is_a_corner(tile):
				without_corners.append(tile)
		_tiles[question] = without_corners
	var kept: Array[Vector2i] = _tiles[question]
	return kept

## `tiles_for()`'s answer as `tile -> how many times it is offered`: what a caller asks whether a
## tile is the row's ground, or how strongly a stretch of ground draws the row, without walking the
## whole city's list.
func offers_for(def: EventDef, side: int = -1) -> Dictionary:
	var wanted := def.pavement_side if side < 0 else side
	var question := _question(def, wanted)
	if not _offers.has(question):
		var offers := {}
		for tile in tiles_for(def, wanted):
			offers[tile] = int(offers.get(tile, 0)) + 1
		_offers[question] = offers
	var kept: Dictionary = _offers[question]
	return kept

## **The tiles `def` may stand on when the day places it for `role`**, as `tile -> how many times
## it is offered`; a tile the role refuses is not in it.
##
## **The role is part of the question, and it is answered the way the precinct weight is**: by how
## many times a tile is offered (`_times_for_role()`), on top of what `offers_for()` gives it, so a
## wall is kept off the routes and friction drawn onto them without a rule downstream. Rows that
## ask the same question for the same role share the answer: what ends the day is part of the
## question, since the wall band has a gradient, and so is whether a wall is one by cost, since two
## rows alike in everything else can still disagree about the rim.
##
## **No row that stands only in alleys stands in one she has to walk down**
## (`EventDef.stands_only_in_alleys()`: the robber and the mouse). An alley the day's corridor runs
## through is ground she has no way around, and a robbery has no telegraph she could see coming: a
## risk with no warning is only fair on ground she chose to enter.
##
## With no corridor, or for a row the day does not place for a role
## (`GameEnums.BlockerRole.NONE`), the answer is `offers_for()`'s.
func offers_for_role(def: EventDef, role: GameEnums.BlockerRole) -> Dictionary:
	if _corridor == null or role == GameEnums.BlockerRole.NONE:
		return offers_for(def)
	var by_cost: bool = _wall_by_cost.call(def)
	var question := "%s|%d|%s|%s" % [_question(def, def.pavement_side), role, def.hard_fail,
			by_cost]
	if not _role_offers.has(question):
		var offers := {}
		var open := offers_for(def)
		var only_in_alleys := def.stands_only_in_alleys()
		for tile: Vector2i in open:
			if only_in_alleys and _corridor.depth(tile) == 0:
				continue
			var times := _times_for_role(tile, role, def.hard_fail, by_cost)
			if times > 0:
				offers[tile] = int(open[tile]) * times
		_role_offers[question] = offers
	var kept: Dictionary = _role_offers[question]
	return kept

# ------------------------------------------------------------------ the scan ---

## What `def` asks of the ground when it wants `side`: rows that ask the same thing share one
## answer. A spread asks for no corner on top of what its scan asks (`_scan_question()`).
func _question(def: EventDef, side: int) -> String:
	return _scan_question(def, side) + ("|no corner" if def.has_a_spread else "")

## What `def` asks of the scan when it wants `side`: the kinds of tile it stands on, the lane of
## the sidewalk, and whether it burns the front it stands at.
func _scan_question(def: EventDef, side: int) -> String:
	return "%s|%d%s" % [def.placement, side, "|burns" if _burns_its_front(def) else ""]

## The scan's answer for `def` wanting `side`, corners included, kept under the scan's own question.
func _scanned(def: EventDef, side: int) -> Array[Vector2i]:
	var question := _scan_question(def, side)
	if not _tiles.has(question):
		_tiles[question] = _scan(def, side)
	var kept: Array[Vector2i] = _tiles[question]
	return kept

## Every tile of the kinds `def` stands on that `tiles_for()` does not refuse, a precinct's tile
## `Weights.precinct()` times over.
func _scan(def: EventDef, side: int) -> Array[Vector2i]:
	var doorstep := Rect2i()
	if _from_the_door:
		var home_street := ClosurePlanner.home_street(_map)
		if home_street:
			doorstep = home_street.tile_rect()
	var trees := _tree_tiles()
	# In tiles: `CityMap.power_station` names the station's two blocks.
	var station := CityMap.blocks_tile_rect(_map.power_station) \
			if _burns_its_front(def) and _map.has_power_station() else Rect2i()
	var precinct := _weights.precinct()
	var open: Array[Vector2i] = []
	for type in def.placement:
		for candidate in _map.tiles_of_type(type as GameEnums.TileType):
			if _map.is_closed(candidate) or doorstep.has_point(candidate) \
					or _map.is_held_at(candidate) or _map.is_on_home_block(candidate) \
					or trees.has(candidate) \
					or station.has_point(candidate + Vector2i.UP) \
					or not _wants_this_side(candidate, side):
				continue
			open.append(candidate)
			if _map.street_kind_at(true, candidate) == GameEnums.StreetKind.PEDESTRIAN \
					or _map.street_kind_at(false, candidate) == GameEnums.StreetKind.PEDESTRIAN:
				for _extra in precinct - 1:
					open.append(candidate)
	return open

func _tree_tiles() -> Dictionary:
	if not _trees_are_known:
		_trees = StreetTrees.footprint_tiles(_map)
		_trees_are_known = true
	return _trees

## A tile whose two coordinates are **both** inside a street: a junction, belonging to two streets
## at once. A spread's look and its place on the sidewalk band both give up there, for there is no
## single street left for it to lie across or be centered on.
static func _is_a_corner(tile: Vector2i) -> bool:
	return CityMap.corridor_offset(tile.x) >= 0 and CityMap.corridor_offset(tile.y) >= 0

## Whether `def` leaves the building it stands against burnt (its scar is the one `City` draws as
## a burnt frontage), so the front it catches on has to be one that can be drawn burnt.
static func _burns_its_front(def: EventDef) -> bool:
	return def.aftermath.scar == City.BURNT_FRONTAGE_SCAR

## Whether `tile` is the lane of the sidewalk `side` names (`EventDef.Pavement`).
##
## Almost every row says `ANY` and this is a free `true`. The rows that do not are placement
## questions rather than balance ones: a parked van belongs at the kerb rather than in a traffic
## lane the crowd will drive straight through, and a lorry reversing into a yard belongs with its
## back to a wall. A tile with no building side at all (`CityMap.pavement_inward()` answering
## zero: a square, a junction box) is no lane of any side.
##
## `AGAINST_THE_BUILDING` asks for two things and the second is about the *art*: there has to be
## a real building on the far side, and it has to be **east or west**, because the silhouettes
## that back into things are drawn side-on and a sprite cannot face north. A frontage the lorry
## would have to reverse into sideways is not one it can be drawn reversing into, and half the
## sidewalks in the city are still eligible.
##
## `AT_THE_FRONT` is the south face's own lane, the one side a front is drawn on: the burning
## building's own side, since the building it catches on is drawn burnt afterwards, and what a
## siting on her walk asks for a row that pastes a front. **The tile behind has to be on the map
## as well as read `BUILDING`**, because `CityMap.tile_at()` reads anything off the map as
## `BUILDING`: without the bounds check the north sidewalk of the map's northmost street, with
## nothing behind it but the edge of the world, passes as a front.
func _wants_this_side(tile: Vector2i, side: int) -> bool:
	if side == EventDef.Pavement.ANY:
		return true
	var inward := _map.pavement_inward(tile)
	if inward == Vector2i.ZERO:
		return false
	if side == EventDef.Pavement.AT_THE_FRONT:
		return inward == Vector2i.UP and _map.in_bounds(tile + inward) \
				and _map.tile_at(tile + inward) == GameEnums.TileType.BUILDING
	if side == EventDef.Pavement.AT_THE_KERB:
		# The kerb lane is the one whose *road* side is actually road: on a two-tile sidewalk
		# that is the inner of the two, and asking the tiles rather than the offset keeps it true
		# of a crossing or a closed carriageway.
		return _map.is_street(tile - inward) \
				and _map.tile_at(tile - inward) != GameEnums.TileType.SIDEWALK
	return inward.y == 0 \
			and _map.tile_at(tile + inward) == GameEnums.TileType.BUILDING

# ------------------------------------------------------------------ the role ---

## How many times over a tile is offered because of what the day is placing there, on top of what
## the scan gives it.
##
## Zero means the tile is not offered at all, and there is exactly one case of it: **a wall never
## stands on ground a route runs along.** Every other preference here is a weight, because a weight
## cannot starve a row of ground and a filter can. What makes this one safe to state absolutely is
## that the rest of the city stays available to it: a wall wants its own band, it settles for
## anywhere else off the routes, and only the routes themselves are refused.
##
## **The refusal is per sidewalk and the rest of the band is per street**, which is the one place
## those two grains differ on purpose. `Corridor.depth()` answers a street tile for its whole
## street, because what a *price* is stated over is ground the player may be anywhere across; where
## a thing may **stand** is the narrower question, and a branch runs along one sidewalk of a street
## rather than down the middle of it. So `Corridor.carries_a_route()` is what closes the ground,
## and the sidewalk **across the street from a route** is where a very costly wall **wants** to be:
## *"the market stall should appear on the other side of the street where for some reason no event
## was chosen"* (PLAYTEST-77). What keeps a wide row off it is the width rule: a wall across the
## street whose reach covers the route's own sidewalk is refused that ground by
## `RouteSidewalkRule._leaves_the_routes_sidewalk_open()`.
##
## **The wall band has a gradient in it, and the gradient is the instruction**: the ground off the
## paths ranges from *very costly* to *deadly*. Stray one turning and it is expensive; stray further
## and it ends the day. So a **very costly** wall is pulled to the rim and a **lethal** one is
## pulled past it. Both keep the whole off-corridor city as a weight rather than a filter, so
## neither can be starved of ground on a day whose corridor happens to be most of the map.
##
## **The rim has two members and they are the same thing seen from the two grains.** One is a
## turning she might wrongly take, one street out (`depth() == 1`); the other is the far side of the
## street she is already on (`depth() == 0` with no route along it), which is the nearest ground to
## the route there is and the one she can read without leaving her own line. A wall is what bounds
## the corridor, and both of those bound it from somewhere she can see. That is why the costly
## weight is `away <= 1` rather than a turning exactly: the far sidewalk carries `Weights.rim()`
## like a turning does.
##
## The **lethal** half keeps its own gradient rather than joining that: it is pulled past the rim by
## `Weights.deep()`, and the far sidewalk is inside the rim, so a lethal row is no likelier there
## than at any other single turning.
##
## **And one street inside the rim is worth more than the rest of it.** A gap is the single street
## two adjacent strands of today's corridor are joined by, so it is the one piece of rim that is
## *inside* the day's own plan rather than beside it: with nothing on it the two strands are one
## wide easy region and choosing between them is not a choice. It is a **weight on top of the rim
## weight** (`Weights.gap()`) rather than a rule that closes every gap: a gap is likelier than an
## ordinary turning to carry something and never certain to, which is the variety the design asks
## for.
##
## **It applies to the costly half of the wall band and not to the lethal half.** A gap is on the
## rim by construction, so a lethal row's weight there is 1 against `Weights.deep()` further out,
## and multiplying that by the gap weight would make a gap the best lethal ground in the city and
## level the deep band with the corridor. The gradient's own sentence is the rule: stray one turning
## and it is expensive, stray further and it ends the day. So what stands in a gap is very
## expensive, and the deadly end stays where it was put.
##
## **A wall by fit alone skips the gradient entirely and reads like friction beyond the one
## refusal every wall keeps** (`by_cost`, the question the ground is handed, asked once a row
## rather than once a tile): a silent, narrow body earns no distance-before-she-commits pull, so it
## is weighted onto a tile of a route's street exactly as friction is, and left at one copy
## everywhere else, never pulled to the rim, never pushed past it.
func _times_for_role(tile: Vector2i, role: GameEnums.BlockerRole, lethal: bool,
		by_cost: bool) -> int:
	var away := _corridor.depth(tile)
	match role:
		GameEnums.BlockerRole.WALL:
			if _corridor.carries_a_route(tile):
				return 0
			if not by_cost:
				return _weights.on_the_routes() if away == 0 else 1
			if lethal:
				return _weights.deep() if away >= 2 else 1
			if away > 1:
				return 1
			return _weights.rim() * (_weights.gap() if _corridor.is_in_a_gap(tile) else 1)
		GameEnums.BlockerRole.FRICTION:
			return _weights.on_the_routes() if away == 0 else 1
		_:
			return 1

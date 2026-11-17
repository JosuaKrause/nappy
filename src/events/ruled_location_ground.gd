class_name RuledLocationGround
extends LocationGround
## **The day's ground as the dawn draw asks it** (`LocationGround`): a row's event at a location,
## left out where the day's rules invalidate it, and the location's own weight.
##
## - **The event** stands on a tile of the location the row fits (`LocationFit`), tried in an order
##   of the location's own stream, and is asked of the day's rules (`StreetInvalidation`) against
##   the plans it is handed and what the day stands. **Which tile, is a setting** (a mode is a
##   configuration): the unit draw takes the first tile no rule refuses, so nothing ranks a tile
##   by rows on other streets (`roomiest` false); the scripted rows and the escape take the first
##   tile with room all round, else the roomiest a rule leaves valid (`roomiest` true), else none.
##   With `roomiest` false the two spacings that never bend still hold, since
##   `StreetInvalidation.room()` refuses them: nothing within
##   `EventScheduler.EVENT_SPACING_ANY` of anything it is judged among, and nothing inside a lethal
##   row's field, either way round.
## - **A route is built inside its location's run where the setting says**
##   (`keeps_routes_on_the_run`, the unit draw's): a moving row's route stops at the far edge of
##   the junction boxes at its own street's ends (`Location.run()`), so everything that could come
##   near it stands in a unit its draw sees (inbox #1460 in silky-lemur). The drawn rows that move are the pacing
##   beats, the man shouting and the chatting mother, and the alley mouse: a beat of 8 tiles from a
##   tile near a street's end would run through the junction box and on past it, and is cut at the
##   box's far edge.
## - **The weight** (the player's "yes" to a weight per location, inbox #1185 in gentle-owl): a
##   precinct street as many times over as the walk's ground offers a precinct tile
##   (`RowGround.Weights.precinct()`, four), the street between two strands of the routes as many
##   times over for a costly wall as the ground offers a gap (`RowGround.Weights.gap()`, six), and
##   five times over for the mouse in an alley beside a sack pile (`_MOUSE_PILE_EXTRA_COPIES` and
##   one): the location's own ground alone. A row's weight on a kind of ground is in the bag's
##   fill already (`EventDef.weight_on()`, `UnitFills`) and is not counted again here. And the
##   mouse a location draws is offered the location's tiles beside a pile first
##   (`_beside_a_pile_first()`), so it stands by the sacks where the location reaches them.
##
## Handed the day, the day's seed, the map, the bodies the day stands (the seals and the region
## wall's, `DayEvents.standing()`), the walk's corridor, the fit (`LocationFit`), the day's rules,
## the walk's ground, whose weights and whose reading of a wall it asks (`RowGround.weights()`,
## `RowGround.is_a_wall_by_cost()`), and its two settings. It keeps no plan: what a candidate is
## judged among comes with each `offer()`. Model: no node.

## `alley_mouse`'s own preference: an alley location beside a garbage-sack pile
## (`GarbageSacks.alley_pile_tiles()`, within `_MOUSE_PILE_ADJACENCY` tiles) weighs the mouse
## `_MOUSE_PILE_EXTRA_COPIES` and one times over (`scale()`), and the mouse it
## draws is offered its tiles beside the pile first.
const _MOUSE_ID := "alley_mouse"
const _MOUSE_PILE_ADJACENCY := 1
const _MOUSE_PILE_EXTRA_COPIES := 4

var _day := 0
var _base := 0
var _map: CityMap
var _standing: Array[EventPlan] = []
var _corridor: Corridor
var _fit: LocationFit
var _rules: StreetInvalidation
var _ground: RowGround
var _roomiest := true
var _keeps_routes_on_the_run := false
var _piles := {}

## `ground` is the walk's ground (`RowGround`), the one `fit` is made over. The settings:
## `roomiest`, where no tile has room all round, take the roomiest a rule leaves valid (else the
## first tile no rule refuses); `keeps_routes_on_the_run`, a route is built inside its location's
## run (`Location.run()`).
func _init(day: int, base: int, map: CityMap, standing: Array[EventPlan], corridor: Corridor,
		fit: LocationFit, rules: StreetInvalidation, ground: RowGround, roomiest := true,
		keeps_routes_on_the_run := false) -> void:
	_day = day
	_base = base
	_map = map
	_standing = standing.duplicate()
	_corridor = corridor
	_fit = fit
	_rules = rules
	_ground = ground
	_roomiest = roomiest
	_keeps_routes_on_the_run = keeps_routes_on_the_run
	for tile in GarbageSacks.alley_pile_tiles(map, day):
		_piles[tile] = true

## Overrides LocationGround.offer.
func offer(def: EventDef, location: Location, among: Array[EventPlan]) -> EventPlan:
	var fits := _fit.tiles(def, location)
	if fits.is_empty():
		return null
	var rng := _stream_of(def, location)
	for i in range(fits.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var kept := fits[i]
		fits[i] = fits[j]
		fits[j] = kept
	if def.id == _MOUSE_ID:
		fits = _beside_a_pile_first(fits)
	return _first_valid(def, location, fits, among, rng)

## Overrides LocationGround.offer_on.
func offer_on(def: EventDef, location: Location, tiles: Array[Vector2i],
		among: Array[EventPlan]) -> EventPlan:
	if tiles.is_empty():
		return null
	return _first_valid(def, location, tiles, among, _stream_of(def, location))

## The stream a location's candidates for `def` are built on: seeded by the day, the location and the
## row alone, so the same row at the same location has the same route and facing whenever it is
## asked, and by whoever asks (the unit's draw, her walk's siting).
func _stream_of(def: EventDef, location: Location) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%s:%s" % [_base, location.tiles(), def.id])
	return rng

## **The event `def` would be at `location`**: a candidate built on each of `fits` in the order
## handed, on `rng`, asked of the day's rules among `among` (and what the day stands); the first with
## room all round, or with `roomiest` off the first no rule refuses, else the roomiest a rule leaves
## valid, else null.
func _first_valid(def: EventDef, location: Location, fits: Array[Vector2i],
		among: Array[EventPlan], rng: RandomNumberGenerator) -> EventPlan:
	var role := EventScheduler.role_for(def, _day)
	var reach_context := among.duplicate()
	reach_context.append_array(_standing)
	var run := location.run() if _keeps_routes_on_the_run else Rect2i()
	var best: EventPlan = null
	var best_room := -INF
	for tile in fits:
		var candidate := _fit.build(def, tile, rng, run)
		if not candidate:
			continue
		var room := _rules.room(candidate, role, tile, among, reach_context)
		if room == -INF:
			continue
		if room == INF or not _roomiest:
			return candidate
		if room > best_room:
			best_room = room
			best = candidate
	return best

## Overrides LocationGround.scale.
func scale(def: EventDef, location: Location) -> float:
	var times := 1.0
	var segment := location.segment()
	var middle := _map.world_to_tile(location.centre())
	if segment and (_map.street_kind_at(true, middle) == GameEnums.StreetKind.PEDESTRIAN
			or _map.street_kind_at(false, middle) == GameEnums.StreetKind.PEDESTRIAN):
		times *= float(_ground.weights().precinct())
	if segment and _ground.is_a_wall_by_cost(def) and not def.hard_fail \
			and EventScheduler.role_for(def, _day) == GameEnums.BlockerRole.WALL \
			and _corridor != null and _corridor.is_in_a_gap(middle):
		times *= float(_ground.weights().gap())
	if def.id == _MOUSE_ID and _beside_a_pile(location.tiles()):
		times *= float(_MOUSE_PILE_EXTRA_COPIES + 1)
	return times

## `tiles` with those within `_MOUSE_PILE_ADJACENCY` of a sack pile first, each half in the order
## it was handed.
func _beside_a_pile_first(tiles: Array[Vector2i]) -> Array[Vector2i]:
	var beside: Array[Vector2i] = []
	var rest: Array[Vector2i] = []
	for tile in tiles:
		if _beside_a_pile(Rect2i(tile, Vector2i.ONE)):
			beside.append(tile)
		else:
			rest.append(tile)
	beside.append_array(rest)
	return beside

## Whether a sack pile stands within `_MOUSE_PILE_ADJACENCY` tiles of `tiles`.
func _beside_a_pile(tiles: Rect2i) -> bool:
	for y in range(tiles.position.y - _MOUSE_PILE_ADJACENCY,
			tiles.end.y + _MOUSE_PILE_ADJACENCY):
		for x in range(tiles.position.x - _MOUSE_PILE_ADJACENCY,
				tiles.end.x + _MOUSE_PILE_ADJACENCY):
			if _piles.has(Vector2i(x, y)):
				return true
	return false

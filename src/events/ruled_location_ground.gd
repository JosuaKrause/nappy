class_name RuledLocationGround
extends LocationGround
## **The day's ground as the dawn draw asks it** (`LocationGround`): a row's event at a location,
## left out where the day's rules invalidate it, and the location's own weight.
##
## - **The event** stands on a tile of the location the row fits (`LocationFit`), tried in an order
##   of the location's own stream, and is asked of the day's rules (`StreetInvalidation`) against
##   the plans it is handed and what the day stands: the first tile with room all round, else the
##   roomiest a rule leaves valid, else none.
## - **The weight** (the player's "yes" to a weight per location, inbox #1185 in gentle-owl): a
##   precinct street as many times over as the walk's ground offers a precinct tile
##   (`RowGround.Weights.precinct()`, four), the street between two strands of the routes as many
##   times over for a costly wall as the ground offers a gap (`RowGround.Weights.gap()`, six), and
##   five times over for the mouse in an alley beside a sack pile (`_MOUSE_PILE_EXTRA_COPIES` and
##   one); then the row's weight on the location's kind of ground
##   (`EventScheduler.ground_weight()`). And the mouse a location draws is offered the location's
##   tiles beside a pile first (`_beside_a_pile_first()`), so it stands by the sacks where the
##   location reaches them.
##
## Handed the day, the day's seed, the map, the bodies the day stands (the seals and the region
## wall's, `DayEvents.standing()`), the walk's corridor, the fit (`LocationFit`), the day's rules,
## the walk's ground, whose weights and whose reading of a wall it asks (`RowGround.weights()`,
## `RowGround.is_a_wall_by_cost()`). It keeps no plan: what a candidate is judged among comes
## with each `offer()`. Model: no node.

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
var _piles := {}

## `ground` is the walk's ground (`RowGround`), the one `fit` is made over.
func _init(day: int, base: int, map: CityMap, standing: Array[EventPlan], corridor: Corridor,
		fit: LocationFit, rules: StreetInvalidation, ground: RowGround) -> void:
	_day = day
	_base = base
	_map = map
	_standing = standing.duplicate()
	_corridor = corridor
	_fit = fit
	_rules = rules
	_ground = ground
	for tile in GarbageSacks.alley_pile_tiles(map, day):
		_piles[tile] = true

## Overrides LocationGround.offer.
func offer(def: EventDef, location: Location, among: Array[EventPlan]) -> EventPlan:
	var fits := _fit.tiles(def, location)
	if fits.is_empty():
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%s:%s" % [_base, location.tiles(), def.id])
	for i in range(fits.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var kept := fits[i]
		fits[i] = fits[j]
		fits[j] = kept
	if def.id == _MOUSE_ID:
		fits = _beside_a_pile_first(fits)
	var role := EventScheduler.role_for(def, _day)
	var reach_context := among.duplicate()
	reach_context.append_array(_standing)
	var best: EventPlan = null
	var best_room := -INF
	for tile in fits:
		var candidate := _fit.build(def, tile, rng)
		if not candidate:
			continue
		var room := _rules.room(candidate, role, tile, among, reach_context)
		if room == INF:
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
			and _corridor.is_in_a_gap(middle):
		times *= float(_ground.weights().gap())
	if def.id == _MOUSE_ID and _beside_a_pile(location.tiles()):
		times *= float(_MOUSE_PILE_EXTRA_COPIES + 1)
	return times * EventScheduler.ground_weight(def, location.kind())

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

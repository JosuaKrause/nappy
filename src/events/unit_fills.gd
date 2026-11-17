class_name UnitFills
extends UnitBags
## **The day's bag fills, one for each view and kind of ground**, each worked out the first time a
## unit of that view and ground draws and kept for the day (`UnitDraw`), and each unit's fresh bag of
## its fill (`bag_for()`). A fill is a marble -> how
## many of it (`ViewBag`), a marble a row's id or `ViewBag.EMPTY`: the declared table's events
## per hundred draw locations as row marbles (`PlacementDensity`), the rows among themselves by
## weight, and empty marbles for the rest of the bag (inbox #1185 in gentle-owl: a view's bag
## holds every event possible in that view, each as many times as its weight, empty among them).
##
## A row's weight in a fill is its own (`EventDef.drawn_as_often()`, raised on a heated day), times
## its weight on the unit's ground (`EventDef.weight_on()`), times what the view is to the row's
## role on the day (the role-by-view weights, `RowGround.Weights`), times the draw locations its
## marble speaks for. **A wall share takes walls away and gives their place to empty**: the rows
## are measured against every wall weighed in full, so a halved wall row holds half its marbles
## and every other row keeps its count (azure-puffin 4; `DaySpec.share_of_walls_drawn()`). Model:
## no node.

## How many marbles one fill holds: enough that the lightest row of the thinnest cell is still
## several marbles and not one rounded up (`ViewBag` weighs by counts per kind of marble, so the
## size of the count costs nothing).
const MARBLES := 100000

var _rows := {}
var _day := 1
var _wall_share := 1.0
var _weights: RowGround.Weights
var _wall_by_cost: Callable
## `Vector2i(view, ground)` -> its fill, once worked out.
var _fills := {}

## `rows` the rows a unit draws today (id -> EventDef, as the day and its heat give them); `day`
## the day; `wall_share` the share of its walls the day draws (`DaySpec.share_of_walls_drawn()`);
## `weights` the day's ground's (`RowGround.weights()`), whose role-by-view weights a fill reads;
## `wall_by_cost` whether a row is a wall by what it costs (`RowGround.is_a_wall_by_cost`).
func _init(rows: Dictionary, day: int, wall_share: float, weights: RowGround.Weights,
		wall_by_cost: Callable) -> void:
	_rows = rows
	_day = day
	_wall_share = wall_share
	_weights = weights
	_wall_by_cost = wall_by_cost

## Overrides UnitBags.bag_for.
##
## **A fresh bag for each unit**, of the fill of its view and kind of ground (`of()`), on a stream
## of the unit's own, so what a far unit drew changes nothing here.
func bag_for(unit: PlacementUnit) -> ViewBag:
	var view := unit.view()
	return ViewBag.new(of(view as PlacementView.View, unit.kind()),
			hash("%d:%s:bag:%d" % [unit.stream().seed, unit.name(), view]))

## **The fill a unit in `view` on `ground` draws from**, `ViewBag.EMPTY` among its marbles.
func of(view: PlacementView.View, ground: PlacementGround.Kind) -> Dictionary:
	var key := Vector2i(view, ground)
	if not _fills.has(key):
		_fills[key] = _work_out(view, ground)
	var fill: Dictionary = _fills[key]
	return fill

## **The fill of `view` and `ground`**: the cell's events in a hundred as row marbles, each row's
## share of them its weight over every row's weighed with its walls in full, and empty the rest; the
## empty marble alone where no row stands or the cell holds no event.
func _work_out(view: PlacementView.View, ground: PlacementGround.Kind) -> Dictionary:
	var per_hundred := PlacementDensity.events_per_hundred(view, ground, _day)
	var whole := 0.0
	var weights := {}
	for id: String in _rows:
		var def: EventDef = _rows[id]
		var on_ground := def.weight_on(ground) * _speaks_for(def, ground)
		whole += on_ground * _in_view(def, view, 1.0)
		var weight := on_ground * _in_view(def, view, _wall_share)
		if weight > 0.0:
			weights[id] = weight
	if whole <= 0.0 or per_hundred <= 0.0:
		return {ViewBag.EMPTY: 1}
	var fill := {}
	var taken := 0
	for id: String in weights:
		var weight: float = weights[id]
		var count := maxi(1, roundi(weight / whole * per_hundred / 100.0 * MARBLES))
		fill[id] = count
		taken += count
	fill[ViewBag.EMPTY] = maxi(1, MARBLES - taken)
	return fill

## **A row's weight in `view`**: its own weight times what the view is to its role on the day, a
## wall's scaled by `wall_share`:
##
## - **friction**, and a wall by its fit alone, is aimed at the routes: the ground's
##   `on_the_routes()` times over on the route, once elsewhere;
## - **a wall by cost that does not end the day** is pulled to the rim: `rim()` times over
##   route-adjacent and on the route, where it stands only on the sidewalk across from the route,
##   once off the route;
## - **a wall that ends the day** is pulled past the rim: `deep()` times over off the route, once
##   nearer;
## - **anything else** (scenery) once everywhere;
## - a row refused an alley the routes run down (`EventDef.stands_only_in_alleys()`) has no marble
##   on the route.
func _in_view(def: EventDef, view: PlacementView.View, wall_share: float) -> float:
	var on := view == PlacementView.View.ON_THE_ROUTE
	var off := view == PlacementView.View.OFF_THE_ROUTE
	if on and def.stands_only_in_alleys():
		return 0.0
	var times := 1.0
	match EventScheduler.role_for(def, _day):
		GameEnums.BlockerRole.FRICTION:
			times = float(_weights.on_the_routes()) if on else 1.0
		GameEnums.BlockerRole.WALL:
			var by_cost: bool = _wall_by_cost.call(def)
			if not by_cost:
				times = float(_weights.on_the_routes()) if on else 1.0
			elif def.ends_the_day():
				times = float(_weights.deep()) if off else 1.0
			else:
				times = 1.0 if off else float(_weights.rim())
			times *= wall_share
	return def.drawn_as_often() * times

## **How many draw locations a row's marble speaks for on `ground`**: in a street, two where it
## takes a section (`EventDef.takes_of_a_street()`), since a section is its two sidewalk
## locations; one everywhere else. So a street expects its draw locations times the cell's events
## per hundred, the rows in the ratio of their weights, whatever each takes of it.
static func _speaks_for(def: EventDef, ground: PlacementGround.Kind) -> float:
	if ground != PlacementGround.Kind.STREET:
		return 1.0
	if def.takes_of_a_street() == EventDef.StreetShare.A_SECTION:
		return 2.0
	return 1.0

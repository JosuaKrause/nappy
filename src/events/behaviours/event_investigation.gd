class_name EventInvestigation
extends EventBehaviour
## **A vehicle that investigates** (`EventDef.investigates()`): while it waits, a car drives its route,
## and from the frame she is within its notice along a clear line it has seen her. It stops — where
## it is, on its route — as soon as its body is clear of every junction box, and owes the men it
## lets out; it stands while they are out, and once every one is back in it is done: a car drives on
## along its route, standing first while she is in its way, and a van stands where it is. The
## vehicle itself never chases (merry-stork; inbox #669 in coral-lark).
##
## **It is handed what never changes under it** as its event is set up: the figure it moves
## (`EventInstance.Figure`), where she is, its row (its notice, how many men it lets out, its body's
## shape, its field's reach, whether it moves or drives), the map, its route walk, and, once the car
## is made, the car's driving it stands for her. It asks what changes through its figure.

## How many steps `_stands_in_a_junction()` takes along the body: under a quarter tile each for the
## patrol's 42px, so no tile under it is stepped over.
const JUNCTION_SAMPLES := 8

## Whether it has noticed her along a clear line, from that frame on — its notice waits until it
## has also stopped, which a car with its body in a junction box does only once the body is clear.
var _seen_her := false
## How many men it has stopped for and still owes: `EventDef.lets_out()` from the frame it stops until
## `EventManager` has put them all down (`let_out()`).
var _officers_owed := 0
## The men it let out, once they are in the world. **Not carried across a stream-out**: they are
## instances of their own; a vehicle streamed back in that had let men out owes none and waits for
## none.
var _officers: Array[EventInstance] = []
## True once every man it let out is back in. It does not stop for her a second time.
var _investigated := false
## True once a car, done with its man, has been outside its own field's reach of her — an ordinary
## car from then on (`is_quiet_for_its_man()`). Latched once a tick, so the field stays a query.
var _left_her_once := false

## Its row: how near it notices her, how many men it lets out, its body's shape, how far its field
## reaches, whether it moves and whether it is a car.
var _row: EventDef
## The map it stands on, whose junction boxes it never stops in.
var _map: WorldMap
## Its route walk (`EventRouteWalk`), which drives its route while it runs it; null for a vehicle
## that does not move.
var _route: EventRouteWalk
## The car's driving (`EventCarDriving`), stood for her once its men are back, held by a weak
## reference: the car is handed this investigation, so a strong one each way would be a reference
## cycle that is never freed. Handed once the car is made (`take_its_car()`); null for a vehicle
## that does not drive.
var _car: WeakRef = null

## Handed, as its event is set up, the figure it moves, where she is, its row, the map and its route
## walk (or none).
func _init(figure: EventInstance.Figure, where: WhereSheIs, row: EventDef, map: WorldMap,
		route: EventRouteWalk) -> void:
	_figure = figure
	_where = where
	_row = row
	_map = map
	_route = route

## Handed the car's driving it stands for her once its men are back, as its event is set up: the
## car is made after it, since it is handed the car (`EventBehaviours.compose()`).
func take_its_car(car: EventCarDriving) -> void:
	_car = weakref(car)

## One tick: notice, stop and owe its men; wait for them; then drive its route again.
##
## Overrides EventBehaviour.step.
func step(delta: float) -> void:
	_investigate()
	if runs_its_route() and _row.mobile and _figure.walks().size() > 1:
		_route.advance(delta)

func _investigate() -> void:
	if _investigated:
		if not _left_her_once and _left_her():
			_left_her_once = true
		return
	if _figure.is_waiting():
		var her: Vector2 = _where.at()
		if not _seen_her and her != Vector2.INF \
				and _figure.place().distance_to(her) <= _row.notice_within() \
				and _figure.clear_line_to(her):
			_seen_her = true
		if _seen_her and not _stands_in_a_junction():
			_figure.notice_her()
			_officers_owed = _row.lets_out()
		return
	if _officers_owed > 0:
		return
	if not all_back():
		return
	_investigated = true
	_officers.clear()
	# A car that stood for its men has stood, so it pulls away only once she is out of its way —
	# never into her.
	var car: EventCarDriving = _car.get_ref() if _car != null else null
	if car != null:
		car.stand()

## **A car that stood for its man is quiet until it has left her: the man is the encounter**
## (inbox #669 in coral-lark). From the frame it stops for her, through his notice, chase, stop and
## walk back, and on as it drives on, until it is outside its own field's reach of her, its field is
## off. So what the encounter costs her is his notice, his chase and his stop, never the end of a
## calm day by itself. Its strike and its horn are a driving car's and come back the moment it
## drives. *Chosen while building, open to overturn.*
func is_quiet_for_its_man() -> bool:
	return _row.vehicle != null and not _figure.is_waiting() and not _left_her_once

## Whether she is outside this car's field from where it is: further than its outer radius past its
## own body, or nobody to be near.
func _left_her() -> bool:
	return _where.at() == Vector2.INF or _figure.place().distance_to(_where.at()) \
			> _row.heard_within() + _row.shape.reach()

## Whether it is running its route: before it has stopped for her, and again once it is done.
func runs_its_route() -> bool:
	return _figure.is_waiting() or _investigated

## **Whether any part of a car's body stands in a junction box**: a tile under its spine inside the
## crossing street's whole corridor as well as its own (`WorldMap.junction_box_at()`). It never
## stops there: nothing stands in a box it cannot leave, and the crossing traffic cannot see a
## patrol car's body to wait for it (sunny-finch). False for anything that does not drive.
func _stands_in_a_junction() -> bool:
	if _row.vehicle == null or _row.shape == null:
		return false
	var axis := _figure.solid_axis()
	var reach := _row.shape.reach()
	var at := _figure.place()
	for i in JUNCTION_SAMPLES + 1:
		var point: Vector2 = at + axis * lerpf(-reach, reach, float(i) / JUNCTION_SAMPLES)
		if _map.junction_box_at(_map.world_to_tile(point)) != Vector2i(-1, -1):
			return true
	return false

## Whether every man it let out is back in — gone from the world, by getting in at its door or by
## having been out of her sight — or no longer exists.
func all_back() -> bool:
	for officer in _officers:
		if is_instance_valid(officer) and not officer.is_gone():
			return false
	return true

## How many men it has stopped for and still owes.
func officers_owed() -> int:
	return _officers_owed if not _figure.is_gone() and not _figure.is_on_its_way_out() else 0

## Takes one man `EventManager` put down at its door, so it stands until he is back; his event
## starts his trail at that door (`EventInstance.let_out()`).
func let_out(officer: EventInstance) -> void:
	_officers_owed = maxi(_officers_owed - 1, 0)
	_officers.append(officer)

## Every man it let out who is still in the world.
func its_officers() -> Array[EventInstance]:
	var out: Array[EventInstance] = []
	for officer in _officers:
		if is_instance_valid(officer):
			out.append(officer)
	return out

## **One of its men has stopped her: every man it let out walks back to it** (inbox #669 in
## coral-lark), so a vehicle that let out more than one man whose catch is a stop costs her once,
## not once a man. The one who stopped her stands with her through his stop first.
func call_back_its_officers(stopped_by: EventInstance) -> void:
	for officer in its_officers():
		if officer != stopped_by:
			officer._be_done()

## Overrides EventBehaviour.save.
func save() -> Dictionary:
	return {"seen_her": _seen_her, "officers_owed": _officers_owed, "investigated": _investigated,
			"left_her_once": _left_her_once}

## Overrides EventBehaviour.restore.
func restore(state: Dictionary) -> void:
	_seen_her = bool(state.get("seen_her", false))
	_officers_owed = int(state.get("officers_owed", 0))
	_investigated = bool(state.get("investigated", false))
	_left_her_once = bool(state.get("left_her_once", false))

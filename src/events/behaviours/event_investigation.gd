class_name EventInvestigation
extends EventBehaviour
## **A vehicle that investigates** (`EventDef.investigates`): while it waits, a car drives its route,
## and from the frame she is within its notice along a clear line it has seen her. It stops — where
## it is, on its route — as soon as its body is clear of every junction box, and owes the men it
## lets out; it stands while they are out, and once every one is back in it is done: a car drives on
## along its route, standing first while she is in its way, and a van stands where it is. The
## vehicle itself never chases (merry-stork; inbox #669 in coral-lark).

## How many steps `_stands_in_a_junction()` takes along the body: under a quarter tile each for the
## patrol's 42px, so no tile under it is stepped over.
const JUNCTION_SAMPLES := 8

## Whether it has noticed her along a clear line, from that frame on — its notice waits until it
## has also stopped, which a car with its body in a junction box does only once the body is clear.
var _seen_her := false
## How many men it has stopped for and still owes: `EventDef.lets_out` from the frame it stops until
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

## Whether it has noticed her along a clear line.
func has_seen_her() -> bool:
	return _seen_her

## Whether every man it let out is back in, so it does not stop for her again.
func has_investigated() -> bool:
	return _investigated

## One tick: notice, stop and owe its men; wait for them; then drive its route again.
func step(delta: float) -> void:
	_investigate()
	if runs_its_route() and event.def.mobile and event.path.size() > 1:
		event.route.advance(delta)

func _investigate() -> void:
	var def: EventDef = event.def
	if _investigated:
		if not _left_her_once and _left_her():
			_left_her_once = true
		return
	if event.is_waiting():
		var her: Vector2 = event.player_at
		if not _seen_her and her != Vector2.INF \
				and event.global_position.distance_to(her) <= def.notice_within() \
				and event._clear_line_to(her):
			_seen_her = true
		if _seen_her and not _stands_in_a_junction():
			event._notice_her()
			_officers_owed = def.lets_out
		return
	if _officers_owed > 0:
		return
	if not all_back():
		return
	_investigated = true
	_officers.clear()
	# A car that stood for its men has stood, so it pulls away only once she is out of its way —
	# never into her.
	if event.car:
		event.car.stand()

## **A car that stood for its man is quiet until it has left her: the man is the encounter**
## (inbox #669 in coral-lark). From the frame it stops for her, through his notice, chase, stop and
## walk back, and on as it drives on, until it is outside its own field's reach of her, its field is
## off. So what the encounter costs her is his notice, his chase and his stop, never the end of a
## calm day by itself. Its strike and its horn are a driving car's and come back the moment it
## drives. *Chosen while building, open to overturn.*
func is_quiet_for_its_man() -> bool:
	return event.def.drives() and not event.is_waiting() and not _left_her_once

## Whether she is outside this car's field from where it is: further than its outer radius past its
## own body, or nobody to be near.
func _left_her() -> bool:
	return event.player_at == Vector2.INF or event.global_position.distance_to(event.player_at) \
			> event.def.outer_radius + event.def.shape.reach()

## Whether it is running its route: before it has stopped for her, and again once it is done.
func runs_its_route() -> bool:
	return event.is_waiting() or _investigated

## **Whether any part of a car's body stands in a junction box**: a tile under its spine inside the
## crossing street's whole corridor as well as its own (`WorldMap.junction_box_at()`). It never
## stops there: nothing stands in a box it cannot leave, and the crossing traffic cannot see a
## patrol car's body to wait for it (sunny-finch). False for anything that does not drive.
func _stands_in_a_junction() -> bool:
	var def: EventDef = event.def
	if not def.drives() or def.shape == null:
		return false
	var axis: Vector2 = event._solid_axis()
	var reach := def.shape.reach()
	var map: WorldMap = event._map
	for i in JUNCTION_SAMPLES + 1:
		var point: Vector2 = event.global_position \
				+ axis * lerpf(-reach, reach, float(i) / JUNCTION_SAMPLES)
		if map.junction_box_at(map.world_to_tile(point)) != Vector2i(-1, -1):
			return true
	return false

## Whether every man it let out is back in — gone from the world, by getting in at its door or by
## having been out of her sight — or no longer exists.
func all_back() -> bool:
	for officer in _officers:
		if is_instance_valid(officer) and not officer.is_finished:
			return false
	return true

## How many men it has stopped for and still owes.
func officers_owed() -> int:
	return _officers_owed if not event.is_finished and not event.is_leaving else 0

## Takes one man `EventManager` put down at its door, so it stands until he is back, and starts his
## trail at the door he got out of, which is where he walks back to.
func let_out(officer: EventInstance) -> void:
	_officers_owed = maxi(_officers_owed - 1, 0)
	_officers.append(officer)
	if officer.on_foot:
		officer.on_foot.let_out_of(event)

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

func save() -> Dictionary:
	return {"seen_her": _seen_her, "officers_owed": _officers_owed, "investigated": _investigated,
			"left_her_once": _left_her_once}

func restore(state: Dictionary) -> void:
	_seen_her = bool(state.get("seen_her", false))
	_officers_owed = int(state.get("officers_owed", 0))
	_investigated = bool(state.get("investigated", false))
	_left_her_once = bool(state.get("left_her_once", false))

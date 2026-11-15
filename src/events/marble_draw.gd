class_name MarbleDraw
extends RefCounted
## **One unit's draw: a marble is drawn first, then goes where it suits in the unit, and the unit
## draws again until its room is spoken for.** *(The player: "don't immediately tie a draw to a
## position. like if you always draw the top left first there will be a bias for that position.
## what you should do instead is do the draw and then depending on what it is place it in the
## street and draw more"; inbox #1466.)*
##
## - **Each marble is drawn from the unit's one bag** (`ViewBag`, of the unit's view,
##   `PlacementUnit.view()`), among the rows the unit may still take: **a row is left out of the
##   draw**, and stays in the bag, where the unit has drawn it already (at most one of a row in a
##   unit, in place of daily caps, since a cap binds whoever draws last), where what it takes of a
##   street (`EventDef.takes_of_a_street()`) does not fit the room left (`UnitRoom`: after a small
##   marble only small ones, the player's filter), and where the unit's rows cannot be laid out
##   with it under the day's rules (`LocationGround.offer()`, today's placement rules deciding, as
##   the player said: "which events make which others invalid on the same street -- this is what
##   your current rules accomplish. the same applies still", inbox #1185 in gentle-owl). The empty
##   marble is always accepted and takes one location, so each row left out makes empty likelier:
##   across from a drawn event the draw is mostly empty.
## - **The unit's rows are laid out again each time one is added, and the last layout stands**
##   (`_lay_out()`): largest first (a side, then a section, then a location; ties in the order
##   drawn), each row on the location that weighs it most and takes it
##   (`LocationGround.scale()`, ties in an order of the unit's stream), judged among the plans the
##   draw was handed and the rows laid before it. So no location has first pick, a larger row
##   drawn later still goes first, and whether the unit can hold a row beside what it has drawn is
##   known as the row comes up. No backtracking: a row the rules leave no place for among the
##   others leaves the *new* row out of the draw.
## - **A row's weight in the unit** is the largest the unit's open locations it may stand on weigh
##   it (`_weight()`), so a row whose ground is in one corner of a street is drawn as often as that
##   corner weighs it.
## - **Off the streets every marble takes one location**: a junction box, an alley's thirds, a park's
##   or a square's cells, every row the size of one.
##
## A row handed to her walk (`EventDef.is_handed_to_her_walk()`, the poster crew) is drawn and laid
## as any other and kept with no position, for her walk to site (`_as_drawn()`), so the rows laid
## after it are judged without it. Every location of the unit left open ends recorded as drawn.
##
## Handed the day's locations, which record each draw, the rows the bag's marbles name
## (`id -> EventDef`) and the day's ground. Model: no node.

var _locations: DayLocations
var _rows: Dictionary
var _ground: LocationGround

## One row of a layout: the row, what it takes of its unit, the location it stands in and its
## event as the location holds it.
class _Placing extends RefCounted:
	var _row: EventDef
	var _share: EventDef.StreetShare
	var _location: Location
	var _plan: EventPlan

	func _init(row: EventDef, share: EventDef.StreetShare, location: Location,
			plan: EventPlan) -> void:
		_row = row
		_share = share
		_location = location
		_plan = plan

	func row() -> EventDef:
		return _row

	func share() -> EventDef.StreetShare:
		return _share

	func location() -> Location:
		return _location

	func plan() -> EventPlan:
		return _plan

## `locations` records each draw (`DayLocations.record()`, `record_side()`); `rows` the rows the
## bag's marbles name (`id -> EventDef`); `ground` the judge.
func _init(locations: DayLocations, rows: Dictionary, ground: LocationGround) -> void:
	_locations = locations
	_rows = rows
	_ground = ground

## **Draws `unit`'s marbles from `bag` and lays its rows out**, judged among `among`: answers the
## events placed, in the order drawn, a row handed to her walk among them with no position. Every
## location of the unit left open is recorded as drawn; one not open (unavailable, taken or drawn)
## is left as it is. `among` is left as handed.
func draw(unit: PlacementUnit, bag: ViewBag, among: Array[EventPlan]) -> Array[EventPlan]:
	var room := UnitRoom.of(unit)
	var street := unit.kind() == PlacementUnit.Kind.STREET
	var open := _open_of(unit)
	var scales := {}
	var drawn: Array[EventDef] = []
	var laid: Array[_Placing] = []
	var trials := {}
	# The lambdas read `drawn`, `laid` and `trials` by reference, so each is changed in place.
	var accepts := func(id: String) -> bool:
		var def: EventDef = _rows[id]
		if drawn.has(def):
			return false
		if not room.fits(_share_of(def, street)):
			return false
		var trial := _lay_out(laid, drawn, def, unit, open, among, scales)
		trials[id] = trial
		return not trial.is_empty()
	var weight := func(id: String) -> float:
		var def: EventDef = _rows.get(id)
		return _weight(def, open, street, scales) if def else 0.0
	while room.is_open():
		var marble := bag.draw(accepts, weight)
		if marble == ViewBag.EMPTY:
			room.take(EventDef.StreetShare.A_LOCATION)
			continue
		var def: EventDef = _rows[marble]
		drawn.append(def)
		var trial: Array[_Placing] = trials[marble]
		laid.assign(trial)
		room.take(_share_of(def, street))
	for placing in laid:
		if placing.share() == EventDef.StreetShare.A_SIDE:
			_locations.record_side(placing.location(), placing.plan())
		else:
			_locations.record(placing.location(), placing.plan())
	for location in unit.locations():
		if location.is_open():
			_locations.record(location, null)
	var placed: Array[EventPlan] = []
	for def in drawn:
		for placing in laid:
			if placing.row() == def:
				placed.append(placing.plan())
	return placed

## **Where every row of `drawn` and `def` stands**, laid largest first, or empty where one cannot
## stand. `laid` is where `drawn` stood: the rows laid before `def` stand as they stood, since
## they are laid in the same order among the same plans and the judge is a function of what it is
## handed (`LocationGround`); `def` and the rows after it are laid again.
func _lay_out(laid: Array[_Placing], drawn: Array[EventDef], def: EventDef, unit: PlacementUnit,
		open: Array[Location], among: Array[EventPlan], scales: Dictionary) -> Array[_Placing]:
	var street := unit.kind() == PlacementUnit.Kind.STREET
	var rows: Array[EventDef] = drawn.duplicate()
	rows.append(def)
	rows = _largest_first(rows, street)
	var from := rows.find(def)
	var trial: Array[_Placing] = []
	var used := {}
	var judged: Array[EventPlan] = among.duplicate()
	for i in from:
		trial.append(laid[i])
	for placing in trial:
		for location in _taken_by(placing, unit):
			used[location] = true
		judged.append(placing.plan())
	for i in range(from, rows.size()):
		var placing := _place(rows[i], unit, open, used, judged, scales)
		if placing == null:
			var none: Array[_Placing] = []
			return none
		trial.append(placing)
		for location in _taken_by(placing, unit):
			used[location] = true
		judged.append(placing.plan())
	return trial

## **`row` on the first location that takes it**, heaviest first, ties in the order of `open`:
## each location it may stand on, none of whose ground is `used`, asked of the judge among
## `judged`. Null where none takes it.
func _place(row: EventDef, unit: PlacementUnit, open: Array[Location], used: Dictionary,
		judged: Array[EventPlan], scales: Dictionary) -> _Placing:
	var street := unit.kind() == PlacementUnit.Kind.STREET
	var share := _share_of(row, street)
	var ranked: Array = []
	for index in open.size():
		var location := open[index]
		if _may_hold(share, location, unit, open, used):
			ranked.append([_scale(row, location, scales), index, location])
	ranked.sort_custom(func(a: Array, b: Array) -> bool:
		var weight_a: float = a[0]
		var weight_b: float = b[0]
		if weight_a != weight_b:
			return weight_a > weight_b
		var index_a: int = a[1]
		var index_b: int = b[1]
		return index_a < index_b)
	for entry: Array in ranked:
		var location: Location = entry[2]
		var plan := _ground.offer(row, location, judged)
		if plan:
			return _Placing.new(row, share, location, _as_drawn(plan))
	return null

## **Whether a row taking `share` may stand in `location`**, none of the ground it would take
## `used`: a section where the section and both its sidewalk locations are open, a side where every
## sidewalk location of that sidewalk is, a location where it is a sidewalk location; off the
## streets any open location.
static func _may_hold(share: EventDef.StreetShare, location: Location, unit: PlacementUnit,
		open: Array[Location], used: Dictionary) -> bool:
	if used.has(location) or not open.has(location):
		return false
	if unit.kind() != PlacementUnit.Kind.STREET:
		return true
	match share:
		EventDef.StreetShare.A_SECTION:
			if location.kind() != Location.Kind.SECTION:
				return false
		_:
			if location.kind() != Location.Kind.SIDEWALK:
				return false
			if share == EventDef.StreetShare.A_LOCATION:
				return true
	for other in _ground_of(share, location, unit):
		if used.has(other) or not open.has(other):
			return false
	return true

## The locations of `unit` a row standing at `placing`'s location takes.
static func _taken_by(placing: _Placing, unit: PlacementUnit) -> Array[Location]:
	var taken: Array[Location] = [placing.location()]
	if unit.kind() == PlacementUnit.Kind.STREET:
		taken.append_array(_ground_of(placing.share(), placing.location(), unit))
	return taken

## **The other locations of a street `unit` a row taking `share` at `location` takes**: a section
## its two sidewalk locations, a side the other sidewalk locations of its sidewalk, a location none.
static func _ground_of(share: EventDef.StreetShare, location: Location,
		unit: PlacementUnit) -> Array[Location]:
	var ground: Array[Location] = []
	for other in unit.locations():
		if other == location or other.kind() != Location.Kind.SIDEWALK:
			continue
		if share == EventDef.StreetShare.A_SECTION and location.shares_a_section_with(other):
			ground.append(other)
		elif share == EventDef.StreetShare.A_SIDE and location.is_on_the_sidewalk_of(other):
			ground.append(other)
	return ground

## **`def`'s weight in the unit**: the largest of what the open locations it may stand on weigh it
## (`LocationGround.scale()`; in a street a section's for a row that takes a section, a sidewalk
## location's otherwise), zero where there is none, so the bag never rolls it.
func _weight(def: EventDef, open: Array[Location], street: bool, scales: Dictionary) -> float:
	var on_a_section := street and _share_of(def, street) == EventDef.StreetShare.A_SECTION
	var best := 0.0
	for location in open:
		if street and (location.kind() == Location.Kind.SECTION) != on_a_section:
			continue
		best = maxf(best, _scale(def, location, scales))
	return best

## How many times over `location` weighs `def` (`LocationGround.scale()`), asked once a draw.
func _scale(def: EventDef, location: Location, scales: Dictionary) -> float:
	if not scales.has(def.id):
		scales[def.id] = {}
	var of_row: Dictionary = scales[def.id]
	if not of_row.has(location):
		of_row[location] = _ground.scale(def, location)
	var scale: float = of_row[location]
	return scale

## What `def` takes of its unit: what it takes of a street in a street, one location elsewhere.
static func _share_of(def: EventDef, street: bool) -> EventDef.StreetShare:
	return def.takes_of_a_street() if street else EventDef.StreetShare.A_LOCATION

## **`rows` largest first**: a side, then a section, then a location, ties in the order handed.
static func _largest_first(rows: Array[EventDef], street: bool) -> Array[EventDef]:
	var ranked: Array = []
	for index in rows.size():
		var share := _share_of(rows[index], street)
		var size := 0 if share == EventDef.StreetShare.A_SIDE \
				else (1 if share == EventDef.StreetShare.A_SECTION else 2)
		ranked.append([size, index])
	ranked.sort_custom(func(a: Array, b: Array) -> bool:
		var size_a: int = a[0]
		var size_b: int = b[0]
		if size_a != size_b:
			return size_a < size_b
		var index_a: int = a[1]
		var index_b: int = b[1]
		return index_a < index_b)
	var sorted: Array[EventDef] = []
	for entry: Array in ranked:
		var index: int = entry[1]
		sorted.append(rows[index])
	return sorted

## **The unit's open locations in an order of its own stream** (Fisher-Yates on
## `PlacementUnit.stream()`), the order a tie between two locations weighing a row alike is broken
## in, so no location always has first pick.
static func _open_of(unit: PlacementUnit) -> Array[Location]:
	var open: Array[Location] = []
	for location in unit.locations():
		if location.is_open():
			open.append(location)
	var rng := unit.stream()
	for i in range(open.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var kept := open[i]
		open[i] = open[j]
		open[j] = kept
	return open

## `plan` as its location holds it: a row handed to her walk (`EventDef.is_handed_to_her_walk()`,
## the poster crew) with no position (`EventScheduler.owed_to_her_walk()`), for her walk to site;
## any other plan as drawn.
static func _as_drawn(plan: EventPlan) -> EventPlan:
	if plan.row().is_handed_to_her_walk():
		return EventScheduler.owed_to_her_walk(plan)
	return plan

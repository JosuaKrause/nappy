class_name DayUnits
extends RefCounted
## **The day's units and which touch which**, worked out once from the day's locations
## (`DayLocations.all()`) and handed to whatever draws or asks (`UnitDraw`, `UnitScopeRule`): the
## one object holding the answer, so nothing works it out again (inbox #1156 in gray-dolphin).
##
## **Two units touch when they share a junction box, or border the same alley, park or square**
## (the item, step 2 of `docs/todo/2026-11-11-polite-tapir/placement-by-construction.md`), stated on
## tile rects so no street network is asked:
##
## - a street **meets** the two junction boxes at its ends; a box meets itself;
## - a lot (an alley, a park or a square) has a **frame**, every block its tiles overlap grown by a
##   street's width, so the frame covers the streets round the block and the boxes at its corners;
##   a lot meets every box its frame covers, and **every unit its frame covers borders it**, the
##   lot itself included;
## - two different units touch where both meet one box or both border one lot;
## - and, where a reach is given (`of()`'s `reach`), two units whose ground lies within that reach
##   of each other touch as well. None is given in the game: the item's relation is the default,
##   and a reach is how a probe measures what a wider relation would pull (the board's
##   touching-reach question).
##
## *The designer's readings, open to overturn:* a lot borders every street and box round its
## block, not only the ones its ground opens onto (an alley robbery's field covers its whole block
## and the sidewalks round it); lots in one block touch; a box and a street on opposite sides of a
## block holding a lot touch through the lot. Each widens the item's words only where a row of one
## unit can reach the other's ground. Model: no node.

## Unit name -> the unit, every unit of the day.
var _units := {}
## The units in the order first met.
var _order: Array[PlacementUnit] = []
## Unit name -> the names of the units it touches.
var _touching := {}
## Unit name -> the units it touches in rank order, worked out on the first ask.
var _touching_in_order := {}

## **Groups `locations` (`DayLocations.all()`) into units** by kind and what each is a part of
## (`Location.part_of()`), in the order first met, and works out which touch which. `day_seed` is
## the day's, which each unit's rank and stream start from; `reach`, in px, where above zero, makes
## two units whose bounds lie within it of each other touch besides the item's relation.
static func of(locations: Array[Location], day_seed: int, reach := 0.0) -> DayUnits:
	var units := DayUnits.new()
	var grouped := {}
	var kinds := {}
	var keys: Array[Vector3i] = []
	for location in locations:
		var kind := _unit_kind(location.kind())
		var whole := location.part_of()
		var key := Vector3i(kind, whole.position.x, whole.position.y)
		if not grouped.has(key):
			grouped[key] = [] as Array[Location]
			kinds[key] = whole
			keys.append(key)
		(grouped[key] as Array[Location]).append(location)
	for key in keys:
		var tiles: Rect2i = kinds[key]
		var bounds := Rect2(Vector2(tiles.position) * Tuning.TILE_SIZE,
				Vector2(tiles.size) * Tuning.TILE_SIZE)
		var unit := PlacementUnit.new(key.x as PlacementUnit.Kind, tiles, bounds,
				grouped[key] as Array[Location], day_seed)
		units._units[unit.name()] = unit
		units._order.append(unit)
	units._work_out_touching(reach)
	return units

## The units `unit` touches, in rank order, lowest first.
func touching(unit: PlacementUnit) -> Array[PlacementUnit]:
	if not _touching_in_order.has(unit.name()):
		var found: Array[PlacementUnit] = []
		var names: Dictionary = _touching.get(unit.name(), {})
		for name: String in names:
			found.append(_units[name])
		found.sort_custom(func(a: PlacementUnit, b: PlacementUnit) -> bool:
			return a.draws_before(b))
		_touching_in_order[unit.name()] = found
	var kept: Array[PlacementUnit] = _touching_in_order[unit.name()]
	return kept.duplicate()

## Whether `a` and `b` touch: two different units sharing a box or a lot.
func touches(a: PlacementUnit, b: PlacementUnit) -> bool:
	var names: Dictionary = _touching.get(a.name(), {})
	return names.has(b.name())

## **The undrawn units any part of whose bounds lies within `radius` of `at`**, nearest first (by
## the distance from `at` to the bounds, a tie by the draw order); every undrawn unit for `radius`
## INF.
func undrawn_within(at: Vector2, radius: float) -> Array[PlacementUnit]:
	var ranked: Array = []
	for unit in _order:
		if unit.is_drawn():
			continue
		var distance := _distance_to(at, unit.bounds())
		if distance <= radius:
			ranked.append([distance, unit])
	ranked.sort_custom(func(a: Array, b: Array) -> bool:
		if a[0] != b[0]:
			return a[0] < b[0]
		return (a[1] as PlacementUnit).draws_before(b[1]))
	var found: Array[PlacementUnit] = []
	for entry: Array in ranked:
		found.append(entry[1])
	return found

## **The units, drawn or not, whose bounds lie within `reach` of `plan`**
## (`EventPlan.reach_touches()`): where a field of that reach, from where the plan stands or any
## corner of its route, can land.
func reached_by(plan: EventPlan, reach: float) -> Array[PlacementUnit]:
	var found: Array[PlacementUnit] = []
	for unit in _order:
		if plan.reach_touches(unit.bounds(), reach):
			found.append(unit)
	return found

## The unit kind a location's kind belongs to.
static func _unit_kind(kind: int) -> PlacementUnit.Kind:
	match kind:
		Location.Kind.SIDEWALK, Location.Kind.SECTION:
			return PlacementUnit.Kind.STREET
		Location.Kind.ALLEY:
			return PlacementUnit.Kind.ALLEY
		Location.Kind.OPEN:
			return PlacementUnit.Kind.OPEN
		_:
			return PlacementUnit.Kind.JUNCTION

static func _distance_to(at: Vector2, bounds: Rect2) -> float:
	var nearest := Vector2(clampf(at.x, bounds.position.x, bounds.end.x),
			clampf(at.y, bounds.position.y, bounds.end.y))
	return at.distance_to(nearest)

## Works out `_touching` from what each unit meets and borders, and, for a `reach` above zero,
## from which units' bounds lie within it of each other.
func _work_out_touching(reach: float) -> void:
	# Box (its junction) -> the names of the units meeting it; lot name -> the names bordering it.
	var meeting := {}
	var bordering := {}
	var boxes := {}
	for unit in _order:
		if unit.kind() == PlacementUnit.Kind.JUNCTION:
			boxes[_junction_of_box(unit.tiles())] = unit
	for unit in _order:
		match unit.kind():
			PlacementUnit.Kind.JUNCTION:
				_add(meeting, _junction_of_box(unit.tiles()), unit.name())
			PlacementUnit.Kind.STREET:
				for junction in _boxes_covered(unit.tiles().grow(1), boxes):
					_add(meeting, junction, unit.name())
			_:
				var frame := _frame_of(unit.tiles())
				_add(bordering, unit.name(), unit.name())
				for rect in frame:
					for junction in _boxes_covered(rect, boxes):
						_add(meeting, junction, unit.name())
				for other in _order:
					if other != unit and _covers(frame, other.tiles()):
						_add(bordering, unit.name(), other.name())
	for unit in _order:
		_touching[unit.name()] = {}
	for group: Dictionary in [meeting, bordering]:
		for key: Variant in group:
			var names: Array = (group[key] as Dictionary).keys()
			for a: String in names:
				var touched: Dictionary = _touching[a]
				for b: String in names:
					if a != b:
						touched[b] = true
	if reach <= 0.0:
		return
	for i in _order.size():
		for j in range(i + 1, _order.size()):
			var a := _order[i]
			var b := _order[j]
			if _gap_between(a.bounds(), b.bounds()) <= reach:
				(_touching[a.name()] as Dictionary)[b.name()] = true
				(_touching[b.name()] as Dictionary)[a.name()] = true

## The shortest distance between two rects, zero where they overlap or meet.
static func _gap_between(a: Rect2, b: Rect2) -> float:
	var dx := maxf(0.0, maxf(b.position.x - a.end.x, a.position.x - b.end.x))
	var dy := maxf(0.0, maxf(b.position.y - a.end.y, a.position.y - b.end.y))
	return Vector2(dx, dy).length()

static func _add(groups: Dictionary, key: Variant, name: String) -> void:
	if not groups.has(key):
		groups[key] = {}
	(groups[key] as Dictionary)[name] = true

## The junction a box's tiles are the box of.
static func _junction_of_box(tiles: Rect2i) -> Vector2i:
	return Vector2i(floori(tiles.position.x / float(CityMap.period())),
			floori(tiles.position.y / float(CityMap.period())))

## The junctions of the boxes among `boxes` (junction -> unit) whose tiles `rect` covers any of.
static func _boxes_covered(rect: Rect2i, boxes: Dictionary) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	var period := CityMap.period()
	for y in range(floori(rect.position.y / float(period)),
			floori((rect.end.y - 1) / float(period)) + 1):
		for x in range(floori(rect.position.x / float(period)),
				floori((rect.end.x - 1) / float(period)) + 1):
			var junction := Vector2i(x, y)
			var box: PlacementUnit = boxes.get(junction)
			if box and rect.intersects(box.tiles()):
				found.append(junction)
	return found

## **A lot's frame**: for every block `tiles` overlap, the block's rect grown by a street's width,
## so it covers the four streets round the block and the boxes at its corners. A block's rect is
## `Tuning.BLOCK_SIZE` square at `block * CityMap.period()` past a street's width.
static func _frame_of(tiles: Rect2i) -> Array[Rect2i]:
	var frame: Array[Rect2i] = []
	var period := float(CityMap.period())
	var first := Vector2i(maxi(0, floori((tiles.position.x - Tuning.STREET_WIDTH) / period)),
			maxi(0, floori((tiles.position.y - Tuning.STREET_WIDTH) / period)))
	var last := Vector2i(maxi(0, floori((tiles.end.x - 1 - Tuning.STREET_WIDTH) / period)),
			maxi(0, floori((tiles.end.y - 1 - Tuning.STREET_WIDTH) / period)))
	for by in range(first.y, last.y + 1):
		for bx in range(first.x, last.x + 1):
			frame.append(CityMap.block_rect(Vector2i(bx, by)).grow(Tuning.STREET_WIDTH))
	return frame

static func _covers(frame: Array[Rect2i], tiles: Rect2i) -> bool:
	for rect in frame:
		if rect.intersects(tiles):
			return true
	return false

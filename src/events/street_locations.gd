class_name StreetLocations
extends RefCounted
## **One street's locations** (inbox #1185 in gentle-owl): the street split along its length into three
## sections, each a section location over the street's whole width and two sidewalk locations, one
## per sidewalk, so up to six of those. An event that spans the street takes a whole section, and its
## two sidewalk locations with it (`take_section()`). See `Location` and `docs/EVENTS.md`, "The three
## views and the placement order".
##
## Made by `DayLocations.lay_out()` and asked through it. Pure state: no node, nothing that runs.

## Where a street's sections end, as shares of its length: three sections, the middle one shorter
## on a block of 8 tiles (3, 2 and 3), so a roadblock across the street's middle has a middle to
## stand in.
const SECTION_ENDS: Array[float] = [1.0 / 3.0, 2.0 / 3.0, 1.0]

var _sections: Array[Location] = []
var _sidewalks: Array[Location] = []

## `segment`'s locations on `map`, every one in `view` (`PlacementView.View`). A location is not
## available where any of its tiles is closed or on a street held today (`CityMap.is_held_at()`:
## a closure, a hard seal's street, the region wall or a door, the home's streets).
static func of(map: CityMap, segment: StreetNetwork.Segment, view: int) -> StreetLocations:
	var street := StreetLocations.new()
	var rect := segment.tile_rect()
	var length := rect.size.x if segment.horizontal else rect.size.y
	var along := Vector2i.RIGHT if segment.horizontal else Vector2i.DOWN
	var start := 0
	for index in SECTION_ENDS.size():
		var end := roundi(length * SECTION_ENDS[index])
		var size := Vector2i(end - start, rect.size.y) if segment.horizontal \
				else Vector2i(rect.size.x, end - start)
		var whole := Rect2i(rect.position + along * start, size)
		var available := _is_open(map, whole)
		street._sections.append(_located(map, segment, index, whole, view, available,
				Location.Kind.SECTION))
		for band in Corridor.sidewalk_bands(whole, segment.horizontal):
			street._sidewalks.append(_located(map, segment, index, band, view, available,
					Location.Kind.SIDEWALK))
		start = end
	return street

static func _located(map: CityMap, segment: StreetNetwork.Segment, index: int, tiles: Rect2i,
		view: int, available: bool, kind: int) -> Location:
	return Location.new(segment, index, tiles, map.tile_rect_to_world(tiles).get_center(), view,
			available, kind)

## Whether nothing a fixed part holds stands on `tiles`.
static func _is_open(map: CityMap, tiles: Rect2i) -> bool:
	for y in range(tiles.position.y, tiles.end.y):
		for x in range(tiles.position.x, tiles.end.x):
			var tile := Vector2i(x, y)
			if map.is_closed(tile) or map.is_held_at(tile):
				return false
	return true

## The street's three section locations, in order along it.
func sections() -> Array[Location]:
	return _sections

## The street's six sidewalk locations, two in each section, in order along it; a section taken
## takes its two.
func sidewalks() -> Array[Location]:
	return _sidewalks

## **The street's locations in the order the dawn draw fills them**: its three sections first, so
## an event that takes its section (one that spans the street or drives its carriageway) is drawn
## before the sidewalks it takes, then the six sidewalk locations, in an order `rng` shuffles, so no
## side or end of a street always draws first.
func drawing_order(rng: RandomNumberGenerator) -> Array[Location]:
	var order: Array[Location] = _sections.duplicate()
	var sidewalks := _sidewalks.duplicate()
	for i in range(sidewalks.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var kept: Location = sidewalks[i]
		sidewalks[i] = sidewalks[j]
		sidewalks[j] = kept
	order.append_array(sidewalks)
	return order

## Puts `plan`, an event that spans the street, on `section` for the day, and takes the section's
## two sidewalk locations with it, so no draw happens for any of the three.
func take_section(section: Location, plan: EventPlan) -> void:
	section.take(plan)
	for sidewalk in _sidewalks:
		if sidewalk.shares_a_section_with(section):
			sidewalk.take(plan)

## **Closes `sidewalk`'s section to a draw once the sidewalk holds an event**: an event that spans
## the street takes its whole section, the sidewalks with it, so a section one of whose sidewalks a
## dawn phase has filled (`DayLocations.assign_to()`) is drawn as the empty event rather than taking
## the section over the sidewalk's event, and the roadblock phase passes it over
## (`RoadblockPhase`). A section already drawn or taken is left as it is.
func close_the_section_of(sidewalk: Location) -> void:
	for section in _sections:
		if sidewalk.shares_a_section_with(section) and not section.is_drawn() \
				and not section.is_taken():
			section.record(null)

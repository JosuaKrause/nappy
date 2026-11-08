class_name DayLocations
extends RefCounted
## **Every street's locations for one day, laid out once at dawn and handed to whatever asks**
## (inbox #1185; `docs/EVENTS.md`, "The three views and the placement order"): each street's three
## sections and their sidewalk locations (`StreetLocations`), each told its view once
## (`Corridor.view_of()`), with the ground the city's fixed parts hold marked unavailable and what a
## phase has assigned taken for the day. The one object holding those answers, so nothing works
## them out again (inbox #1156 in gray-dolphin).
##
## **Laid out on day 13 alone in this step**, by the roadblock phase's call in
## `EventScheduler.build_day()` after the routes are established and the day's holds are on the map
## (`EventScheduler._place_the_roadblocks()`), and read by the roadblock phase (`RoadblockPhase`)
## alone, which assigns its sections; nothing reads it once the phase is done. The bags and the walk's
## draws, later steps of the placement, lay it out every day. Pure state: no node, nothing that runs.

var _streets := {}

## The day's locations on `map`, each street in the view `corridor` gives it. Every street the
## lattice has (`CityMap.street_segments()`), the ones a calm zone absorbed left out.
static func lay_out(map: CityMap, corridor: Corridor) -> DayLocations:
	var day := DayLocations.new()
	for segment in map.street_segments():
		day._streets[segment.key()] = StreetLocations.of(map, segment, corridor.view_of(segment))
	return day

## The sections in `view` (`PlacementView.View`) that are available and not yet taken, street by
## street in the lattice's order and along each street in order.
func sections_in(view: int) -> Array[Location]:
	var found: Array[Location] = []
	for key: Vector3i in _streets:
		for section in (_streets[key] as StreetLocations).sections():
			if section.view() == view and section.is_available() and not section.is_taken():
				found.append(section)
	return found

## Assigns `plan`, an event that spans the street (`EventDef.spans_the_street()`), to `section` for
## the day: the section and its two sidewalk locations are taken, so no draw happens for them.
func assign(section: Location, plan: EventScheduler.Planned) -> void:
	assert(plan.row().spans_the_street(),
			"DayLocations.assign(): only an event that spans the street takes a section")
	(_streets[section.segment().key()] as StreetLocations).take_section(section, plan)

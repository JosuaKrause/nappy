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
## (`EventScheduler._place_the_roadblocks()`). The roadblock phase (`RoadblockPhase`) assigns its
## sections at dawn; the day's plan hands it on to the walk (`DayEvents.locations()`,
## `DayPlanner.Plan.locations()`, `WalkEvents.locations()`), where day 13's task takes a section for
## its roadblock when none is close by (`nearest_section_in()`). The bags and the walk's draws, later
## steps of the placement, lay it out every day. Pure state: no node, nothing that runs.

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

## **The open section in `view` nearest along her paths**, for day 13's task when no roadblock is
## close by (inbox #1185: "if we don't find one closeby we swap one off screen route adjacent event
## with a roadblock"). `paths` is her paths from where she stands (`tile -> its distance along them`);
## a section is as near as the nearest of its own tiles they reach that `may_touch` (a tile) answers
## true for, and is passed over where `may_take` (the section) answers false: the caller's answer for
## her view and for what may be replaced. Null where no open section of `view` qualifies. *Read as, the orchestrator's and
## open to correction:* nearest along her paths (fork 7 of the placement proposal), with no cap on the
## distance, and a section whose locations are not yet drawn qualifying like any other.
func nearest_section_in(view: int, paths: Dictionary, may_touch: Callable,
		may_take: Callable) -> Location:
	var ranked: Array = []
	for section in sections_in(view):
		var nearest := INF
		var tiles := section.tiles()
		for y in range(tiles.position.y, tiles.end.y):
			for x in range(tiles.position.x, tiles.end.x):
				var tile := Vector2i(x, y)
				if paths.has(tile) and float(paths[tile]) < nearest and may_touch.call(tile):
					nearest = float(paths[tile])
		if nearest < INF:
			ranked.append([nearest, section])
	ranked.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for entry: Array in ranked:
		if may_take.call(entry[1]):
			return entry[1]
	return null

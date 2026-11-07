class_name StreetMap
extends RefCounted
## **A full-size map with nothing on it but its streets**, painted the way every generated city's
## are (`StreetLayout.lay()`): the whole lattice of sidewalks, roads and crossings round blocks that
## are all `BUILDING`, with the main road on a corridor of the caller's choosing.
##
## **For a suite whose subject reads the streets** — the crowd, navigation, siting — and only for
## one interaction or edge case on them (writing-tests, "Which map a test uses"). It has no home,
## no calm ground and no block plans, so it is never the map of a booted day or of a measurement: a
## day planned on it plans hundreds of events with nowhere to win. Full size because the street
## network and the crowd's corridors are fixed to the whole lattice (`Tuning.CITY_BLOCKS`), and on a
## smaller map the crowd's lanes run on past its edge.

## The main road's corridor when a caller names none: a vertical corridor inland of the city's
## edge, as the generator's own draw always is.
const MAIN_ROAD := 5

## The streets of a full-size map, with the main road on vertical corridor `main_road`.
static func full(main_road := MAIN_ROAD) -> CityMap:
	var map := CityMap.new()
	map.main_road = main_road
	map.index_posts()
	StreetLayout.lay(map)
	return map

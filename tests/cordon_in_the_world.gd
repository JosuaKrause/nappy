extends RefCounted
## **What day 12's police cordon shows in the world**, read the way the rest of the game meets it,
## for a suite that plays the day through the director (`ResistanceDirector.tick()`) and so holds
## no `ParkCordon` of its own: not a suite, a helper.
##
## The cordon is the happenings' own, and nothing in the game asks the director for it, so a suite
## that plays the day through the director reads it off what it puts in the world: its officers,
## each a figure on the city's entity layer (`CordonOfficer`), and the ground, where every taped
## stretch is recorded as obstructed (`WorldMap.obstructed_tiles`), which is what shuts the park to
## anyone walking (`is_shut()`).

## The cordon's officers standing in the city now.
static func officers(city: City) -> Array[CordonOfficer]:
	var found: Array[CordonOfficer] = []
	for figure in city.get_node("Entities").get_children():
		if figure is CordonOfficer and not figure.is_queued_for_deletion():
			found.append(figure)
	return found

## What shuts ground to someone on foot today: the closures and every solid body, the tape included.
static func shut_tiles(map: CityMap) -> Dictionary:
	var shut := map.closed_tiles.duplicate()
	shut.merge(map.obstructed_tiles)
	return shut

## Whether nobody on foot can get from `inside`, a point in the park, to the home: the park is
## taped shut. Open ground reaches the home by way of the park's edge until the last gap is taped.
static func is_shut(map: CityMap, inside: Vector2) -> bool:
	var field := map.walk_field(map.world_to_tile(inside), shut_tiles(map))
	return not map.reaches(field, map.home_rect.position)

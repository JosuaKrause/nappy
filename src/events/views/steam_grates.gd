class_name SteamGrates
extends RefCounted
## **The basement vents' floor grates, drawn**: a sprite of the grate's picture
## (`EventPictures.steam_grate()`) lying at each place the building says a grate lies
## (`BuildingPlan.grates()`), for the whole escape, added to the building through its map
## (`WorldMap.add_entity()`). The placement says where, as data; drawing them is this view's.
##
## **Ground, not something standing on it**: she walks over a grate between blows, so it lies on
## the ground layer (`DrawLayer.Layer.GROUND`), after the floor tiles, under the walls and the
## y-sorted layer she and every blow stand in, centred on the vent's point, where each blow's frames
## are anchored, so each blow's cloud rises out of it. No body: the grate is where the gate is, not a
## second gate.

## Lays a grate at each of `at` on `map`'s world, and answers them for whoever wants to find them.
static func lay(at: Array[Vector2], map: WorldMap) -> Array[Sprite2D]:
	var grates: Array[Sprite2D] = []
	for point in at:
		var grate := Sprite2D.new()
		grate.name = "SteamGrate"
		grate.texture = EventPictures.steam_grate()
		grate.centered = true
		grate.position = point
		map.add_entity(grate, DrawLayer.Layer.GROUND)
		grates.append(grate)
	return grates

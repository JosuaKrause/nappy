extends RefCounted
## What her street door shows and which building it stands in front of, read off the city's nodes.
##
## The city draws her door as a sprite of its own on the entities layer, whose `picture` is the
## ordinary door's region until the raid seals it and the sealed door's after (`City.DOOR_TEXTURE`,
## `City.SEALED_DOOR_TEXTURE`), and the one home-block building the door's notch is cut into is the
## lot its span overlaps. A suite asking either asks what the city built, not a member of `City`.

## The sprite the city drew her street door as, or null where there is none.
static func door(city: City) -> Sprite2D:
	for node in city.find_children("*", "Sprite2D", true, false):
		var picture: Variant = node.get("picture")
		if picture == City.DOOR_TEXTURE or picture == City.SEALED_DOOR_TEXTURE:
			return node
	return null

## Whether her street door shows the sealed picture.
static func is_sealed(city: City) -> bool:
	var drawn := door(city)
	return drawn != null and drawn.get("picture") == City.SEALED_DOOR_TEXTURE

## The one home-block building her door stands in front of: the lot whose world footprint overlaps
## the door's own span, centred on the door sprite and as wide as the door's picture.
static func building(city: City) -> Building:
	var drawn := door(city)
	if drawn == null:
		return null
	var half := AtlasTable.baked().native_size(City.DOOR_TEXTURE).x * 0.5
	var left: float = drawn.position.x - half
	var right: float = drawn.position.x + half
	for child in city.get_node("Buildings").get_children():
		var candidate := child as Building
		if candidate == null or not candidate.is_home_building:
			continue
		var world := city.map.tile_rect_to_world(candidate.lot)
		if world.position.x < right and world.end.x > left:
			return candidate
	return null

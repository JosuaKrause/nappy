extends RoofDrawer
## A roof drawer that records what a building tells it to draw instead of drawing it, handed to a
## building through `Building.roof_drawer` the way the city hands the real one. The roof suites
## test a roof's layout (`Building.roof_layout()`, where the random draws put each unit) and the
## roof that holds it apart: this is the holder's half, so a check compares what the building drew
## with the layout it placed, without reading what the building holds.
##
## Each draw returns a bare `Building.RoofObject` that never enters the tree, which the building
## keeps and frees as it frees a real one (a rebuild, an eviction, leaving the tree), so what is
## still drawn is the draws whose object is still alive.

## Every draw the building asked for, in order: `{"layer", "cell", "texture", "at", "links",
## "rotor_frame_b", "object"}`, with `at` in `layer`'s own space.
var draws: Array[Dictionary] = []

func _init() -> void:
	super(null)

func draw(layer: Node2D, cell: Vector2i, texture_key: StringName, at: Vector2, duct_links: int,
		rotor_frame_b: bool) -> Building.RoofObject:
	var object := Building.RoofObject.new()
	draws.append({"layer": layer, "cell": cell, "texture": texture_key, "at": at,
		"links": duct_links, "rotor_frame_b": rotor_frame_b, "object": object})
	return object

## The draws still standing on the roof, in the order they were drawn: those whose object the
## building has not freed.
func standing() -> Array[Dictionary]:
	var still: Array[Dictionary] = []
	for entry in draws:
		if is_instance_valid(entry.object):
			still.append(entry)
	return still

## What is drawn now, one `{"cell", "texture", "links"}` per standing draw, comparable with
## `placed()` of a layout.
func drawn() -> Array[Dictionary]:
	var units: Array[Dictionary] = []
	for entry in standing():
		units.append({"cell": entry.cell, "texture": entry.texture, "links": entry.links})
	return units

## What a layout places, in the shape `drawn()` gives: one `{"cell", "texture", "links"}` per unit,
## farthest first, with `links` -1 for a unit that is not a duct section.
static func placed(layout: Array[Dictionary]) -> Array[Dictionary]:
	var units: Array[Dictionary] = []
	for unit in layout:
		units.append({"cell": unit.cell, "texture": unit.texture, "links": unit.get("links", -1)})
	return units

## Where `unit` of `building`'s layout stands its foot, in the building's own space: centred across
## the unit's span of columns, on the floor line of its cell's row counted north from the ground
## line past the front wall.
static func foot_of(building: Building, unit: Dictionary) -> Vector2:
	var cell: Vector2i = unit.cell
	var span: int = unit.span
	return Vector2((cell.x + span * 0.5) * Building.TILE - building.columns() * Building.TILE * 0.5,
			-(building.wall_tiles() + cell.y) * Building.TILE)

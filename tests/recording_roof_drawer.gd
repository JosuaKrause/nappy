extends RoofDrawer
## A roof drawer that records what a building tells it to draw instead of drawing it, handed to a
## building through `Building.roof_drawer` the way the city hands the real one. The roof suites
## test a roof's layout (where the random draws put each unit) and the roof that holds it apart:
## this is the holder's half, and `layout()` reads the layout back from what the building drew.
##
## Each draw returns a bare `Building.RoofObject` that never enters the tree, which the building
## keeps and frees as it frees a real one (a rebuild, an eviction, leaving the tree), so what is
## still drawn is the draws whose object is still alive. A suite that is about what a roof leaves
## standing in a city (the residency suite: nothing stays behind in the layer when a building is
## evicted) sets `real`, and each draw is then also stood by that drawer, so the object returned is
## the real one, in the layer, and the record still says which building drew it.

const RoofReads := preload("res://tests/roof_reads.gd")

## Every draw the building asked for, in order: `{"layer", "cell", "texture", "at", "links",
## "rotor_frame_b", "object"}`, with `at` in `layer`'s own space.
var draws: Array[Dictionary] = []

## The drawer that also stands each unit, or null to stand nothing.
var real: RoofDrawer = null

func _init() -> void:
	super(null)

func draw(layer: Node2D, cell: Vector2i, texture_key: StringName, at: Vector2, duct_links: int,
		rotor_frame_b: bool) -> Building.RoofObject:
	var object: Building.RoofObject = real.draw(layer, cell, texture_key, at, duct_links,
			rotor_frame_b) if real != null else Building.RoofObject.new()
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

## What is drawn now, one `{"cell", "texture", "links"}` per standing draw, with `links` -1 for a
## unit that is not a duct section.
func drawn() -> Array[Dictionary]:
	var units: Array[Dictionary] = []
	for entry in standing():
		units.append({"cell": entry.cell, "texture": entry.texture, "links": entry.links})
	return units

## The roof the building has drawn, read as a layout: one `{"cell", "cells", "span", "texture"}`
## per standing draw, and `"links"` on a duct section, in the order they were drawn (farthest
## first). A unit's span is the columns its picture covers (`RoofReads.span_of()`); where its foot
## was put is `Draw.at`, which a suite checks against `foot_of()`.
func layout() -> Array[Dictionary]:
	var units: Array[Dictionary] = []
	for entry in standing():
		var cell: Vector2i = entry.cell
		var cells: Array[Vector2i] = []
		for step in RoofReads.span_of(entry.texture, entry.links):
			cells.append(cell + Vector2i(step, 0))
		var unit := {"cell": cell, "cells": cells, "span": cells.size(), "texture": entry.texture}
		if entry.links >= 0:
			unit["links"] = entry.links
		units.append(unit)
	return units

## Where `unit` of `building`'s layout stands its foot, in the building's own space: centred across
## the unit's span of columns, on the floor line of its cell's row counted north from the ground
## line past the front wall.
static func foot_of(building: Building, unit: Dictionary) -> Vector2:
	var cell: Vector2i = unit.cell
	var span: int = unit.span
	return Vector2((cell.x + span * 0.5) * Building.TILE - building.columns() * Building.TILE * 0.5,
			-(building.wall_tiles() + cell.y) * Building.TILE)

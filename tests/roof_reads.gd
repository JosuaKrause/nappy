extends RefCounted
## What a `Building`'s roof shows, read off the roof objects it stands.
##
## A building draws its roof furniture through a `RoofDrawer`, one `Building.RoofObject` per unit,
## standing on its foot: a unit is centred across the columns its picture covers, its foot on the
## floor line of its cell's row. That place is the roof's drawn geometry, so a suite asking which
## cell a unit stands on, or what the roof carries, reads where each object stands and not a member
## of the building that decided it. `RecordingRoofDrawer` (`tests/recording_roof_drawer.gd`) is the
## other half: what the building told its drawer to draw, where a suite hands one in.

const TILE := Building.TILE

## The roof units `building` stands, in the order they were added (farthest, highest row, first), one `{"cell": Vector2i, "cells":
## Array[Vector2i], "span": int, "texture": StringName}` each, and `"links"` on a duct section
## (the neighbours it joins, as bits 0 to 3). A unit's span is the columns its picture covers at
## the scale it is drawn (`equipment_scale()`), a duct section always one, so the cell is read back
## from the object's place. A live `City` parents the objects under its entity layer
## (`Building.roof_object_parent`), shared by every building, so an object is this building's when
## that read lands on a whole cell inside its columns and its roof, extension included. Empty while
## the building's scenery is not resident and for a roof with no interior.
static func units_of(building: Building) -> Array[Dictionary]:
	var units: Array[Dictionary] = []
	var parent: Node = building.roof_object_parent if building.roof_object_parent != null else building
	var deepest := building.roof_tiles()
	for col in building.columns():
		deepest = maxi(deepest, building.roof_tiles() + extension_of(building, col))
	for child in parent.get_children():
		if not child is Building.RoofObject:
			continue
		var object: Building.RoofObject = child
		var foot := object.global_position - building.global_position
		var unit := unit_at(building, object.texture_key, object.duct_links, foot)
		if unit.is_empty() or (unit.cell as Vector2i).y >= deepest:
			continue
		units.append(unit)
	return units

## The unit of picture `texture` joined as `links` (-1 for none) whose foot stands at `foot`, in
## `building`'s own space, or {} where that foot is not the centre of a whole cell's span inside
## the building's columns.
static func unit_at(building: Building, texture: StringName, links: int, foot: Vector2) -> Dictionary:
	var span := span_of(texture, links)
	var col := (foot.x + building.columns() * TILE * 0.5) / TILE - span * 0.5
	var row := -foot.y / TILE - building.wall_tiles()
	if not (is_equal_approx(col, roundf(col)) and is_equal_approx(row, roundf(row))):
		return {}
	if col < 0.0 or roundi(col) + span > building.columns() or row < 0.0:
		return {}
	var cell := Vector2i(roundi(col), roundi(row))
	var cells: Array[Vector2i] = []
	for step in span:
		cells.append(cell + Vector2i(step, 0))
	var unit := {"cell": cell, "cells": cells, "span": span, "texture": texture}
	if links >= 0:
		unit["links"] = links
	return unit

## The columns a unit of picture `texture` joined as `links` covers: its picture's native width at
## the scale it is drawn, over a tile, rounded up; a duct section is always one.
static func span_of(texture: StringName, links: int) -> int:
	if links >= 0 or texture == Building.DUCT_RUN:
		return 1
	return ceili(AtlasTable.baked().native_size(texture).x * equipment_scale(texture) / TILE)

## The scale a roof picture is drawn at: the standalone equipment and the access room are drawn
## larger than the pictures baked for them, everything else at its baked size.
static func equipment_scale(texture: StringName) -> float:
	if texture in [Building.VENT_STACK, Building.VENT_HOUSING, Building.EXHAUST_FAN,
			Building.PIPE_MANIFOLD]:
		return Building.STANDALONE_EQUIPMENT_SCALE
	if texture == Building.SERVICE_BULKHEAD:
		return Building.ACCESS_ROOM_SCALE
	return 1.0

## The rows the roof is taller than the building's own at column `col`, as `City` sets them
## (`Building.roof_extension_rows`), 0 where it sets none.
static func extension_of(building: Building, col: int) -> int:
	return building.roof_extension_rows[col] if col >= 0 and col < building.roof_extension_rows.size() else 0

## The roof rows of `building` from its own wall up to its tallest column, extension included.
static func tallest_of(building: Building) -> int:
	var tallest := building.roof_tiles()
	for col in building.columns():
		tallest = maxi(tallest, building.roof_tiles() + extension_of(building, col))
	return tallest

## Whether `cell` is on the roof interior ignoring the lips a step or seam draws: off the
## perimeter, from row 1 up to one short of its own column's top, extension included. A roof under
## three columns wide, or whose tallest column is under three rows deep, has none. Which interior
## cells a lip rules out is read off the front (`FrontReads.roof_edges_at()`), where a suite asks.
static func on_the_interior(building: Building, cell: Vector2i) -> bool:
	if building.columns() < 3 or tallest_of(building) < 3:
		return false
	return cell.x >= 1 and cell.x <= building.columns() - 2 and cell.y >= 1 \
			and cell.y < building.roof_tiles() + extension_of(building, cell.x) - 1

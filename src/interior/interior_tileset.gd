class_name InteriorTileSet
extends RefCounted
## Builds the interior's own `TileSet` from its SVG sources, the way `assets/ground_tileset.tres`
## does for the outdoor city — in code rather than as a `.tres`. A hand-written resource for a
## dozen single-tile sources is the same information typed twice, with a source id that can drift
## from `InteriorTile.Kind`'s own numbering; a static factory is the smaller artifact for a set
## this size, and unlike a `.tres` it can use the enum's own values as its source ids instead of a
## second build-order numbering — see `source_id_for()`.

## A door threshold's own tread sits on the mechanical stairwell floor beneath it, and the
## basement's exit sits on the same edge tile as the wall around it — the door itself is drawn as
## a standing sprite over this ground, the way a rail is drawn over a flight. See
## `InteriorScene._rebuild_overlays()`.
const _SOURCES := {
	InteriorTile.Kind.HALLWAY_FLOOR: "res://assets/interior/hallway_floor.svg",
	InteriorTile.Kind.HALLWAY_FLOOR_EDGE_N: "res://assets/interior/hallway_floor_edge_n.svg",
	InteriorTile.Kind.HALLWAY_FLOOR_EDGE_E: "res://assets/interior/hallway_floor_edge_e.svg",
	InteriorTile.Kind.HALLWAY_FLOOR_EDGE_S: "res://assets/interior/hallway_floor_edge_s.svg",
	InteriorTile.Kind.HALLWAY_FLOOR_EDGE_W: "res://assets/interior/hallway_floor_edge_w.svg",
	InteriorTile.Kind.STAIRWELL_FLOOR: "res://assets/interior/stairwell_floor.svg",
	InteriorTile.Kind.STAIR_FLIGHT_E: "res://assets/interior/stair_flight_e.svg",
	InteriorTile.Kind.STAIR_FLIGHT_W: "res://assets/interior/stair_flight_w.svg",
	InteriorTile.Kind.LANDING: "res://assets/interior/stair_landing.svg",
	InteriorTile.Kind.BASEMENT_FLOOR: "res://assets/interior/basement_floor.svg",
	InteriorTile.Kind.BASEMENT_FLOOR_EDGE_N: "res://assets/interior/basement_floor_edge_n.svg",
	InteriorTile.Kind.BASEMENT_FLOOR_EDGE_E: "res://assets/interior/basement_floor_edge_e.svg",
	InteriorTile.Kind.BASEMENT_FLOOR_EDGE_S: "res://assets/interior/basement_floor_edge_s.svg",
	InteriorTile.Kind.BASEMENT_FLOOR_EDGE_W: "res://assets/interior/basement_floor_edge_w.svg",
	InteriorTile.Kind.STAIRWELL_DOOR: "res://assets/interior/stairwell_floor.svg",
	InteriorTile.Kind.EMERGENCY_EXIT: "res://assets/interior/basement_floor_edge_n.svg",
}

## The atlas source id a ground cell of `kind` uses, or `-1` for a kind this TileSet does not
## carry a ground picture for (every elevation and overlay kind — see `InteriorTile.Kind`'s doc).
## Source ids are the `Kind` values themselves, so this and `build()` cannot drift apart the way
## two independently numbered tables could.
static func source_id_for(kind: InteriorTile.Kind) -> int:
	return int(kind) if _SOURCES.has(kind) else -1

static func build() -> TileSet:
	var set := TileSet.new()
	set.tile_size = Vector2i(Tuning.TILE_SIZE, Tuning.TILE_SIZE)
	for kind in _SOURCES:
		var source := TileSetAtlasSource.new()
		source.texture = load(_SOURCES[kind])
		source.texture_region_size = Vector2i(Tuning.TILE_SIZE, Tuning.TILE_SIZE)
		source.create_tile(Vector2i.ZERO)
		set.add_source(source, int(kind))
	return set

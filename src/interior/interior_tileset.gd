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
##
## Every value here is a region name on the `interior` atlas group's page rather than a source
## path — `build()` crops each one out of `AtlasLibrary.page_image(&"interior")` into its own
## standalone `ImageTexture`, the same technique the ground compositor uses for its own TileSet
## (`docs/TODO.md`, M171's "The ground" item), rather than nesting an `AtlasTexture` inside a
## `TileSetAtlasSource`: a `TileSetAtlasSource` addresses its texture on a uniform grid of its own
## `texture_region_size`, which a shelf-packed atlas page does not have, and its runtime rendering
## does not compose a second region on top of one an assigned `AtlasTexture` already carries.
const _SOURCES := {
	InteriorTile.Kind.HALLWAY_FLOOR: &"interior/hallway_floor",
	InteriorTile.Kind.HALLWAY_FLOOR_EDGE_N: &"interior/hallway_floor_edge_n",
	InteriorTile.Kind.HALLWAY_FLOOR_EDGE_E: &"interior/hallway_floor_edge_e",
	InteriorTile.Kind.HALLWAY_FLOOR_EDGE_S: &"interior/hallway_floor_edge_s",
	InteriorTile.Kind.HALLWAY_FLOOR_EDGE_W: &"interior/hallway_floor_edge_w",
	InteriorTile.Kind.STAIRWELL_FLOOR: &"interior/stairwell_floor",
	InteriorTile.Kind.STAIR_FLIGHT_E: &"interior/stair_flight_e",
	InteriorTile.Kind.STAIR_FLIGHT_W: &"interior/stair_flight_w",
	InteriorTile.Kind.STAIR_DOWN: &"interior/stair_down",
	InteriorTile.Kind.LANDING: &"interior/stair_landing",
	InteriorTile.Kind.STAIR_TOP_E: &"interior/m158_stair_side_upper_e",
	InteriorTile.Kind.STAIR_MIDDLE_E: &"interior/m158_stair_side_lower_e",
	InteriorTile.Kind.STAIR_TOP_W: &"interior/m158_stair_side_upper_w",
	InteriorTile.Kind.STAIR_MIDDLE_W: &"interior/m158_stair_side_lower_w",
	InteriorTile.Kind.STAIR_CORNER_E: &"interior/m158_stair_side_continue_e",
	InteriorTile.Kind.STAIR_CORNER_W: &"interior/m158_stair_side_continue_w",
	InteriorTile.Kind.STAIR_BLOCK: &"interior/m158_stair_side_block",
	InteriorTile.Kind.BASEMENT_FLOOR: &"interior/basement_floor",
	InteriorTile.Kind.BASEMENT_FLOOR_EDGE_N: &"interior/basement_floor_edge_n",
	InteriorTile.Kind.BASEMENT_FLOOR_EDGE_E: &"interior/basement_floor_edge_e",
	InteriorTile.Kind.BASEMENT_FLOOR_EDGE_S: &"interior/basement_floor_edge_s",
	InteriorTile.Kind.BASEMENT_FLOOR_EDGE_W: &"interior/basement_floor_edge_w",
	InteriorTile.Kind.DOOR: &"interior/stairwell_floor",
	InteriorTile.Kind.EMERGENCY_EXIT: &"interior/basement_floor_edge_n",
}

## The atlas source id a ground cell of `kind` uses, or `-1` for a kind this TileSet does not
## carry a ground picture for (every elevation and overlay kind — see `InteriorTile.Kind`'s doc).
## Source ids are the `Kind` values themselves, so this and `build()` cannot drift apart the way
## two independently numbered tables could.
static func source_id_for(kind: InteriorTile.Kind) -> int:
	return int(kind) if _SOURCES.has(kind) else -1

## The region name a ground cell of `kind` is baked under, on the `interior` group's page — what
## a test asks instead of comparing texture identity, now that every source is a cropped view of
## the shared page with no `resource_path` of its own to read a filename back off.
static func region_name_for(kind: InteriorTile.Kind) -> StringName:
	return _SOURCES.get(kind, &"")

static func build() -> TileSet:
	var set := TileSet.new()
	set.tile_size = Vector2i(Tuning.TILE_SIZE, Tuning.TILE_SIZE)
	var page := AtlasLibrary.page_image(&"interior")
	for kind in _SOURCES:
		var source := TileSetAtlasSource.new()
		source.texture = _cropped(page, _SOURCES[kind])
		source.texture_region_size = Vector2i(Tuning.TILE_SIZE, Tuning.TILE_SIZE)
		source.create_tile(Vector2i.ZERO)
		set.add_source(source, int(kind))
	return set

## One region's own pixels, lifted out of the shared page into a standalone texture a
## `TileSetAtlasSource` can address on its own uniform grid. `null` propagates from a missing page
## the same way a failed `load()` did before — `AtlasLibrary.page_image()` has already logged why.
static func _cropped(page: Image, name: StringName) -> ImageTexture:
	if page == null:
		return null
	return ImageTexture.create_from_image(page.get_region(AtlasLibrary.region_rect(name)))

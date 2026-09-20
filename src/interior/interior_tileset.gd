class_name InteriorTileSet
extends RefCounted
## Builds the interior's own `TileSet` from regions of the baked `interior` atlas page, the way
## `assets/ground_tileset.tres` does for the outdoor city — in code rather than as a `.tres`. A
## hand-written resource for a dozen single-tile sources is the same information typed twice,
## with a source id that can drift from `InteriorTile.Kind`'s own numbering; a static factory is
## the smaller artifact for a set this size, and unlike a `.tres` it can use the enum's own
## values as its source ids instead of a second build-order numbering — see `source_id_for()`.

## A door threshold's own tread sits on the mechanical stairwell floor beneath it, and the
## basement's exit sits on the same edge tile as the wall around it — the door itself is drawn as
## a standing sprite over this ground, the way a rail is drawn over a flight. See
## `InteriorScene._rebuild_overlays()`.
##
## Every value here is a region name on the `interior` atlas group's page rather than a source
## path. **Every source shares the one page texture** — `build()` never loads or composes a
## second texture of its own. A `TileSetAtlasSource` addresses its assigned texture on a grid of
## its own `texture_region_size`, offset by `margins`; that grid does need to be uniform *across
## the one source's own tiles*, but every source here holds exactly one tile, so the grid is the
## region itself — `margins` is the region's own top-left corner on the shared page and
## `texture_region_size` is the region's own size, which puts tile `(0, 0)` exactly on the region
## and needs no second copy of its pixels. Proved against this engine version with a throwaway
## script before writing it this way: `TileSetAtlasSource.get_tile_texture_region(Vector2i.ZERO)`
## on a source built this way equals `AtlasLibrary.region_rect(name)` exactly, and two sources
## sharing the same page texture at different offsets do not collide.
##
## **The group has to be acquired for as long as this `TileSet` is used**, not only while
## `build()` runs: every source's `texture` is the live page `AtlasLibrary.acquire()` loaded, so
## the picture stays valid exactly as long as the group that page belongs to is held.
## `InteriorScene._enter_tree()` acquires `interior` before `_ready()` calls `build()`, and
## releases it in `_exit_tree()` — after the `TileMapLayer` this `TileSet` is bound to has already
## been freed as `InteriorScene`'s own child, so nothing reads a stale texture. A caller with no
## such lifecycle of its own (a test calling `build()` directly) has to acquire the group itself
## for as long as it keeps the returned `TileSet`.
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
## a test asks to check a source's own texture and offset against, since every source shares one
## page object with no `resource_path` of its own to read a filename back off.
static func region_name_for(kind: InteriorTile.Kind) -> StringName:
	return _SOURCES.get(kind, &"")

## Requires the `interior` group already acquired — every source built here reads the group's own
## live page texture (`AtlasLibrary.region(name).atlas`), so building with nothing acquired asks
## `AtlasLibrary.region()` a question it answers `null` for, with its own `push_error`. See the
## class doc for how long the group has to stay acquired after this returns.
static func build() -> TileSet:
	var set := TileSet.new()
	set.tile_size = Vector2i(Tuning.TILE_SIZE, Tuning.TILE_SIZE)
	for kind in _SOURCES:
		var name: StringName = _SOURCES[kind]
		var region: AtlasTexture = AtlasLibrary.region(name)
		if region == null:
			continue
		var rect := AtlasLibrary.region_rect(name)
		var source := TileSetAtlasSource.new()
		source.texture = region.atlas
		source.margins = rect.position
		source.texture_region_size = rect.size
		source.create_tile(Vector2i.ZERO)
		set.add_source(source, int(kind))
	return set

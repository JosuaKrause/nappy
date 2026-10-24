class_name InteriorScene
extends WorldContext
## The escape scene's building, as one persistent map — `art/interior`'s floor plan and stair
## kit made walkable. Built once by `main` as the escape's building section first begins, for the
## escape a won day 14 hands the run over to and for `--start-escape` alike; absent from the
## fourteen days, and it needs no events and
## no crowd of its own — `WorldContext`'s own defaults (1.0 recovery, no excitement sources) are
## exactly "meters idle" already.
##
## Ground is a `TileMapLayer` built from `InteriorTileSet`, on the ground layer, with the stairwell
## walls behind it (`DrawLayer.Layer.BACKDROP`); walls, the lift door, the entrance, the barricade
## and the brick stand in elevation on the buildings layer, not y-sorted, for the reason `City`'s
## own `Buildings` layer has one: nothing can ever legitimately stand *behind* a wall, so nothing
## needs to sort against one. **Every door is drawn under her**, on the doors layer between the
## walls and her *(minty-lemur #789: "the escape doors should be in a way that the graphics is
## always under her")*: the stairwell doors, the open and the apartments' thresholds and the
## emergency exit. Sorted by its foot against hers a threshold, standing at its tile's south edge,
## would be drawn over her whenever she stood on it. The chandelier and the ground decals live in
## the y-sorted entity layer, the one the player joins through `add_entity()`. The stair-side roles
## are ground cells: the TileMap paints exactly the grammar the collision pass reads instead of
## placing a second visual assembly over another walkable map.
##
## **One map, seven parts, no loading.** `InteriorMap.build()` lays all seven parts at once, `64`
## tiles apart from each other — comfortably more than the 20×11.25 tiles a 640×360 view at zoom 2
## can ever show, so no part is in view from another. A door does not rebuild anything: it fades to
## black, moves her to the counterpart door's own tile, and fades back in — see
## `_start_door_transition()`. There is no "current part" left in this class.
##
## **A door tile is both where she leaves from and where she arrives.** Nothing here makes the
## arrival tile different from the trigger tile, because arrival arms a `ReleaseLatch`
## (`src/world/release_latch.gd`) on the door's own tile centre — the same "just spawned" flag the
## checkpoint hut and the crowd's own door hold use — and no door fires while it holds. Standing on
## the tile she arrived on, or stepping off it and straight back within the latch's radius, costs
## her nothing; leaving that radius clears it and every door, including the one she came through,
## can take her again.

signal exit_requested

## Every picture below is a region name on the `interior` atlas group; `_enter_tree()`/
## `_exit_tree()` acquire and release it, and every draw site fetches its texture through
## `AtlasLibrary.region()` — a live `AtlasTexture` over the group's shared page, whose own
## `.atlas`/`.region` a test can read directly, unlike a `resource_path` a region-backed texture
## does not carry.
const HALLWAY_WALL := &"interior/hallway_wall"
const HALLWAY_WINDOW := &"interior/hallway_wall_window"
## The same window with the street outside it lit. Swapped in for a fraction of a second whenever
## an explosion goes off — see `flash_windows()`.
const HALLWAY_WINDOW_FLASH := &"interior/hallway_wall_window_flash"
const WALL_LAMP_TEXTURE := &"interior/wall_lamp"
const LIFT_DOOR_TEXTURE := &"interior/lift_door_dead"
const ENTRANCE_DOOR_TEXTURE := &"interior/entrance_door"
const ENTRANCE_BARRICADE_TEXTURE := &"interior/entrance_barricade"
const HALLWAY_RUBBLE_TEXTURE := &"interior/hallway_rubble"
const BRICK_WALL := &"interior/basement_wall_brick"
const DOOR_TEXTURE := &"interior/stairwell_door"
const APARTMENT_THRESHOLD_TEXTURE := &"interior/apartment_threshold"
const OPEN_THRESHOLD_TEXTURE := &"interior/open_threshold"
const EMERGENCY_EXIT_TEXTURE := &"interior/emergency_exit_door"
const PUDDLE_TEXTURE := &"interior/puddle"
const DEBRIS_TEXTURE := &"interior/basement_debris"
const RAT_TEXTURE := &"interior/rat"
const CHANDELIER_TEXTURE := &"interior/chandelier"
const STAIRWELL_SEGMENT_BACKDROP := &"interior/stairwell_segment_backdrop"
const STAIRWELL_SHAFT_CAP_TOP := &"interior/stairwell_shaft_cap_top"

const TILE := float(Tuning.TILE_SIZE)
## How long the fade to black takes, each way — brisk, since it stands in for a flight of stairs
## rather than for a whole day changing.
const FADE_SECONDS := 0.35

var _plan: InteriorMapPlan
## See `wall_grid()`.
var _wall_grid: CityMap
var _tile_set: TileSet
var _ground: TileMapLayer
var _backdrops: Node2D
var _walls: Node2D
## Every door picture but the lift's and the entrance's, which are wall sprites: under her always —
## see this class's own doc.
var _doors: Node2D
var _entities: Node2D
## Plain `StaticBody2D` blockers, one per non-walkable cell in a margin around the building's own
## footprint — the physical half of `InteriorMapPlan.is_walkable()`. A `TileMapLayer` only gives
## collision to a cell that holds a tile, and the gaps between parts and everything off the whole
## footprint hold none at all, so without this she could walk clean through a wall she can see, or
## off the map's own edge, or straight across a gap from one part into another.
var _collision: Node2D
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
## True from the first fade-to-black frame to the last fade-from-black frame of a transition, so
## `process_player()` cannot fire a second one out from under the first while the teleport in the
## middle of it is still in flight.
var _transitioning := false
## Armed on every arrival through a door, centred on that door's own tile — see this class's own
## doc for why that is what lets the arrival tile and the trigger tile be the same tile. Updated
## every `process_player()` call; no door fires while it holds.
var _door_release_latch := ReleaseLatch.new()
## How far the latch reaches from a door's own tile centre — one tile and a half, comfortably past
## the trigger tile itself (`transition_at()` matches only the door's own tile) plus her body
## (`Tuning.PLAYER_BODY_RADIUS`, 14px), so a step that only grazes the tile's edge still counts as
## staying rather than as leaving and re-entering.
const _DOOR_RELEASE_RADIUS := TILE * 1.5

## Acquires the `interior` atlas group before `_ready()` builds anything that draws from it, and
## releases it on the matching exit — see `Building._enter_tree()`'s own doc for why this is
## paired with `_exit_tree()` rather than folded into `_ready()`.
func _enter_tree() -> void:
	AtlasLibrary.acquire(&"interior")

func _exit_tree() -> void:
	AtlasLibrary.release(&"interior")

func _ready() -> void:
	super()
	build()

## Builds the whole building and paints the scene for it. Idempotent: a second call does nothing,
## since the map never changes after the first — there is nothing left to rebuild once every part
## is laid out and painted, only her position to move.
func build() -> void:
	if _plan:
		return
	_ground = TileMapLayer.new()
	_ground.name = "Ground"
	add_child(_ground)
	_backdrops = _layer_node(DrawLayer.Layer.BACKDROP, "StairwellBackdrops")
	_walls = _layer_node(DrawLayer.Layer.BUILDINGS, "Walls")
	_doors = _layer_node(DrawLayer.Layer.DOORS, "Doors")
	_entities = _layer_node(DrawLayer.Layer.ENTITIES, "Entities", true)
	_collision = Node2D.new()
	_collision.name = "Collision"
	add_child(_collision)
	_fade_layer = CanvasLayer.new()
	_fade_layer.name = "FadeLayer"
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.name = "Fade"
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade_rect)

	_plan = InteriorMap.build()
	_tile_set = InteriorTileSet.build()
	_ground.tile_set = _tile_set
	for tile: Vector2i in _plan.tiles:
		var source := InteriorTileSet.source_id_for(_plan.tiles[tile])
		if source >= 0:
			_ground.set_cell(tile, source, Vector2i.ZERO)
	_rebuild_walls()
	_rebuild_stairwell_backdrops()
	_rebuild_overlays()
	_rebuild_collision()
	modulate = lighting_at(_plan.start_tile)

## The bounding box of every painted cell in the whole building — every part and every gap between
## them, since the collision pass and the camera limits both need to cover the gaps too (she must
## not be able to walk, or be framed, off the building's own combined edge).
func _footprint() -> Rect2i:
	var min_t := Vector2i(999999, 999999)
	var max_t := Vector2i(-999999, -999999)
	for tile: Vector2i in _plan.tiles:
		min_t = min_t.min(tile)
		max_t = max_t.max(tile)
	return Rect2i(min_t, max_t - min_t + Vector2i.ONE)

## One blocker per non-walkable cell in a margin around the whole building's footprint, including
## every gap between parts — so a gap blocks her exactly the way a wall does, and the only way from
## one part to another is through a door. Godot 4.7 was not asked to give a `TileMapLayer` collision
## on cells with no tile, so this is built by hand the same way the outdoor city never needs to
## (its ground is one continuous walkable sheet).
const _MARGIN := 1
func _rebuild_collision() -> void:
	for child in _collision.get_children():
		child.queue_free()
	var box := _footprint().grow(_MARGIN)
	var bands := _flight_bands()
	for y in range(box.position.y, box.position.y + box.size.y):
		for x in range(box.position.x, box.position.x + box.size.x):
			var tile := Vector2i(x, y)
			if _plan.is_walkable(tile):
				continue
			# A clearance is only for an absent pinch corner. Painted `c`, `C` and `b` cells stay
			# solid even if another diagonal elsewhere happens to name the same position.
			if not _plan.tiles.has(tile) and _plan.collision_clearance.has(tile):
				continue
			var body := StaticBody2D.new()
			var shape := CollisionShape2D.new()
			var outline := _blocker_outline(tile, bands)
			if outline.is_empty():
				var rectangle := RectangleShape2D.new()
				rectangle.size = Vector2.ONE * TILE
				shape.shape = rectangle
			else:
				var polygon := ConvexPolygonShape2D.new()
				polygon.points = outline
				shape.shape = polygon
			body.position = tile_to_world(tile)
			body.add_child(shape)
			_collision.add_child(body)

## **A flight's two edges are straight lines along its slope, not the stair sides' square corners.**
## A flight's walkable `t/m` band is two cells wide on every row, but the solid cells either side of
## it meet it at convex corners that lie on two lines only 22.6px apart across the slope, and her
## body is 28px across (`Tuning.PLAYER_BODY_RADIUS`, 14px): with full-cell blockers she can only
## pass each pair of corners moving nearly flat or nearly straight down, and a held sideways press
## walks a zigzag of flat steps and steep drops however the press is steered (inbox #783 in minty-lemur). So each
## solid cell beside a flight has the part of it inside the flight's band cut off, and the band's
## two edges are straight, `FLIGHT_HALF_WIDTH` either side of the flight's centre line (the line
## half-way between the centres of its `t` and its `m` cells).
##
## **1.125, so a landing's line is inside the band.** The landing tile level with a flight's first
## or last tread has its centre half a unit off the flight's centre line, and her centre stays
## `FLIGHT_HALF_WIDTH` less her radius (0.62 units) from it at most: at 1.125 a press from that
## tile's centre walks onto the flight and down the whole of it at 45 degrees without touching an
## edge, where at 1.0 she would touch the lower edge on the first tread and slide flat for a
## moment. Her centre has 11.5px of play either side of the centre line, so one that arrives off
## the line, from the landing's next row down, is slid onto it by the cut faces, and her centre is
## always over the drawn treads. Along a row, the lower edge lies 4px beyond the drawn side face
## (the hypotenuse of the `c`/`C` triangle) and the upper one 12px beyond the treads' tips.
##
## **Only solid cells are cut; the walkable flight cells keep no blocker of their own.** The corners
## of a `t` or `m` cell outside the band are pockets too small to hold her (the circle they hold
## is under 4px in radius), and a blocker in them would face the landing beside the flight's first
## and last row with a wall she could not step past.
##
## In tile units, measured along `(slope, -1)`: a descending-east flight's `t` cells are at one
## value of `x - y` and its `m` cells one lower, so the centre line is half-way between; a
## descending-west flight is the mirror, `-x - y`. One unit is 22.6px across the slope.
const FLIGHT_HALF_WIDTH := 1.125

## Every flight in the building as `{normal, centre, cells}`: `normal` is `(slope, -1)`, `centre`
## the mean of `normal · cell centre` over the flight's cells, and `cells` the solid cells beside it
## (its eight-neighbours that are not walkable), which are the ones `_blocker_outline()` cuts. A
## flight is one eight-connected run of flight cells of one slope.
func _flight_bands() -> Array[Dictionary]:
	var bands: Array[Dictionary] = []
	var seen := {}
	for start: Vector2i in _plan.tiles:
		var slope := InteriorTile.flight_direction(_plan.tiles[start])
		if slope == 0 or seen.has(start):
			continue
		var normal := Vector2(slope, -1)
		var total := 0.0
		var count := 0
		var beside := {}
		var queue: Array[Vector2i] = [start]
		seen[start] = true
		while not queue.is_empty():
			var cell: Vector2i = queue.pop_back()
			total += normal.dot(Vector2(cell) + Vector2(0.5, 0.5))
			count += 1
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var next := cell + Vector2i(dx, dy)
					if next == cell:
						continue
					if InteriorTile.flight_direction(_plan.tiles.get(next, InteriorTile.Kind.NONE)) == slope:
						if not seen.has(next):
							seen[next] = true
							queue.append(next)
					elif not _plan.is_walkable(next):
						beside[next] = true
		bands.append({"normal": normal, "centre": total / count, "cells": beside})
	return bands

## The blocker for a solid `tile` as a convex outline in pixels about the tile's centre, or empty
## for the plain full cell. Each flight it stands beside cuts away the part of it inside that
## flight's band, keeping the side of the band its own centre is on.
func _blocker_outline(tile: Vector2i, bands: Array[Dictionary]) -> PackedVector2Array:
	var corners := PackedVector2Array([Vector2(tile), Vector2(tile) + Vector2(1, 0),
			Vector2(tile) + Vector2(1, 1), Vector2(tile) + Vector2(0, 1)])
	var outline := corners
	var cut := false
	for band: Dictionary in bands:
		if not (band["cells"] as Dictionary).has(tile):
			continue
		var normal: Vector2 = band["normal"]
		var centre: float = band["centre"]
		var side := signf(normal.dot(Vector2(tile) + Vector2(0.5, 0.5)) - centre)
		# Kept: `side * (normal · p) >= side * centre + FLIGHT_HALF_WIDTH`.
		outline = _clip_to_half_plane(outline, normal * side, side * centre + FLIGHT_HALF_WIDTH)
		cut = true
	if not cut or outline == corners:
		return PackedVector2Array()
	var local := PackedVector2Array()
	for point in outline:
		local.append((point - Vector2(tile) - Vector2(0.5, 0.5)) * TILE)
	return local

## The part of convex `polygon` where `normal · p >= limit` (Sutherland–Hodgman against one line).
static func _clip_to_half_plane(polygon: PackedVector2Array, normal: Vector2, limit: float
		) -> PackedVector2Array:
	var kept := PackedVector2Array()
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i + 1) % polygon.size()]
		var da := normal.dot(a) - limit
		var db := normal.dot(b) - limit
		if da >= 0.0:
			kept.append(a)
		if (da >= 0.0) != (db >= 0.0):
			kept.append(a.lerp(b, da / (da - db)))
	return kept

func _rebuild_walls() -> void:
	# Wide doors are drawn after the repeating 32px wall strips. Their own centre registration keeps
	# both leaves visible instead of letting a neighbouring wall crop one side.
	_window_sprites.clear()
	for at: Vector2i in _plan.walls:
		var kind: InteriorTile.Kind = _plan.walls[at]
		if kind == InteriorTile.Kind.LIFT_DOOR or kind == InteriorTile.Kind.ENTRANCE_DOOR:
			continue
		var texture := _wall_texture(kind)
		var sprite := _add_wall_sprite(at, texture)
		if sprite and kind == InteriorTile.Kind.WINDOW:
			_window_sprites.append(sprite)
	for at: Vector2i in _plan.walls:
		var kind: InteriorTile.Kind = _plan.walls[at]
		if kind != InteriorTile.Kind.LIFT_DOOR and kind != InteriorTile.Kind.ENTRANCE_DOOR:
			continue
		_add_wall_sprite(at, _wall_texture(kind))
	_add_rubble()
	for at: Vector2i in _plan.entrance_tiles:
		var barricade := Sprite2D.new()
		var texture := AtlasLibrary.region(ENTRANCE_BARRICADE_TEXTURE)
		barricade.texture = texture
		barricade.centered = false
		barricade.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
		barricade.position = Vector2((at.x + 0.5) * TILE, at.y * TILE + TILE * 0.5)
		add_entity(barricade, DrawLayer.Layer.BUILDINGS)

## The fallen ceiling on the top floor, drawn over exactly the cells `InteriorMapPlan.rubble`
## closes. One picture registered at the patch's own top-left corner rather than one sprite per
## cell: a heap is a single mass, and four copies of the same tile would read as four crates.
##
## **In the wall layer, with the barricade and the plaster**, for the reason this class's own doc
## gives for putting elevation there — nothing can legitimately stand behind a thing that closes a
## corridor, so there is nothing for it to sort against.
func _add_rubble() -> void:
	if _plan.rubble.size == Vector2i.ZERO:
		return
	var heap := Sprite2D.new()
	heap.texture = AtlasLibrary.region(HALLWAY_RUBBLE_TEXTURE)
	heap.centered = false
	heap.position = Vector2(_plan.rubble.position) * TILE
	add_entity(heap, DrawLayer.Layer.BUILDINGS)

func _add_wall_sprite(at: Vector2i, name: StringName) -> Sprite2D:
	if name == &"":
		return null
	var texture := AtlasLibrary.region(name)
	if texture == null:
		return null
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
	sprite.position = Vector2((at.x + 0.5) * TILE, at.y * TILE)
	add_entity(sprite, DrawLayer.Layer.BUILDINGS)
	return sprite

# ------------------------------------------------------------------- the light ---

## The light in the part `tile` is in, multiplied over everything in the building — the floor, the
## walls, the events and her — as this scene's own `modulate`. **Not a `CanvasModulate`**: the
## building stays on the canvas under the city's own daylight for the whole of the escape's second
## section, and a canvas takes one of those at a time.
##
## **The building has no power, since the escape is the night of the blackout.** The hallways, the
## lobby and the basement are in the gloom, the basement darkest; the stairwells are on the red
## emergency lighting. One colour per part is enough because no part is ever in view from another
## (the 64-tile stride — see `InteriorMap`), and the colour changes only when she does, which is
## under a door's fade to black. A hallway lifts to `Palette.ESCAPE_FLASH_LIGHT` for as long as its
## windows are flashing, so a blast lights the corridor as well as the glass.
func lighting_at(tile: Vector2i) -> Color:
	var part := InteriorMap.part_at(tile)
	if part.begins_with("stairwell"):
		return Palette.ESCAPE_EMERGENCY_RED
	if part == "basement":
		return Palette.ESCAPE_BASEMENT_GLOOM
	if part.begins_with("hallway") and windows_are_flashing():
		return Palette.ESCAPE_FLASH_LIGHT
	return Palette.ESCAPE_GLOOM

# ------------------------------------------------------------------ the flash ---

## Every hallway window in the building, kept so a flash can light all of them at once.
var _window_sprites: Array[Sprite2D] = []
## Seconds of lit window left, or 0 for none. Counted down in `_process()` rather than handed to a
## `SceneTreeTimer`, so the flash freezes with the rest of the game behind a pause screen instead
## of burning down while nothing is being played.
var _window_flash_left := 0.0

## **The cue for something going off outside, near or far.** *"The hallway windows that flash when
## an explosion goes off"* — there is no burst on the street to see and no arc drawn for the noise
## yet, so what says a bomb has gone off somewhere out there is every window in the building going
## white at once for a frame or two.
##
## **Every one of them, together, always.** *(2026-09-19: "all windows always need to flash
## together. a single window cannot flash by itself.")* There is one call for a near bang and a far
## flash alike and no way to light a subset, which is the point: a window lighting while the one
## beside it stays dark does not read as a city being shelled, it reads as a broken sprite. That
## also makes "which hallway she is standing in" a question this never has to ask — the building is
## one map with three hallways 64 tiles apart, and the two she is not in are off screen and cost
## two texture assignments.
func flash_windows() -> void:
	_window_flash_left = Tuning.FINALE_WINDOW_FLASH_SECONDS
	var texture := AtlasLibrary.region(HALLWAY_WINDOW_FLASH)
	for sprite in _window_sprites:
		sprite.texture = texture

## Whether a flash is on screen right now — what `tests/test_interior.gd` asks, since a texture
## swap is not something a headless run can see.
func windows_are_flashing() -> bool:
	return _window_flash_left > 0.0

## How many windows are showing their lit picture — the question `windows_are_flashing()` cannot
## answer, and the one that holds *all of them or none*: a count that is neither is a window
## flashing on its own.
func windows_lit() -> int:
	var lit := 0
	var flash := AtlasLibrary.region(HALLWAY_WINDOW_FLASH)
	for sprite in _window_sprites:
		if sprite.texture == flash:
			lit += 1
	return lit

## How many hallway windows there are at all, so a test counting lit ones has something to compare
## against rather than a number of its own.
func window_count() -> int:
	return _window_sprites.size()

func _process(delta: float) -> void:
	if _window_flash_left <= 0.0:
		return
	_window_flash_left = maxf(0.0, _window_flash_left - delta)
	if _window_flash_left > 0.0:
		return
	var texture := AtlasLibrary.region(HALLWAY_WINDOW)
	for sprite in _window_sprites:
		sprite.texture = texture

func _wall_texture(kind: InteriorTile.Kind) -> StringName:
	match kind:
		InteriorTile.Kind.WINDOW:
			return HALLWAY_WINDOW
		InteriorTile.Kind.WALL_LAMP:
			return WALL_LAMP_TEXTURE
		InteriorTile.Kind.LIFT_DOOR:
			return LIFT_DOOR_TEXTURE
		InteriorTile.Kind.ENTRANCE_DOOR:
			return ENTRANCE_DOOR_TEXTURE
		InteriorTile.Kind.WALL:
			return HALLWAY_WALL
		InteriorTile.Kind.BRICK_WALL:
			return BRICK_WALL
		_:
			return &""

## Doors, the chandeliers and every ground decal — everything that stands above the floor rather
## than being the floor. The doors go in their own `Doors` layer under her, from here and from
## `_add_standing()` and `_add_threshold()`; only the chandeliers and the decals are in the
## y-sorted layer the player joins through `add_entity()`.
func _rebuild_overlays() -> void:
	for id: String in _plan.doors:
		var door: InteriorMapPlan.Door = _plan.doors[id]
		if _is_edge_threshold(door.id):
			_add_threshold(door.tile, OPEN_THRESHOLD_TEXTURE)
		else:
			_add_standing(door.tile, DOOR_TEXTURE)
	for tile: Vector2i in _plan.locked_thresholds:
		_add_threshold(tile, APARTMENT_THRESHOLD_TEXTURE)
	if _plan.exit_tile.x >= 0:
		_add_standing(_plan.exit_tile, EMERGENCY_EXIT_TEXTURE)
	for tile: Vector2i in _plan.decals:
		var kind: InteriorTile.Kind = _plan.decals[tile]
		var name := _decal_texture(kind)
		var sprite := Sprite2D.new()
		sprite.texture = AtlasLibrary.region(name)
		sprite.position = tile_to_world(tile)
		add_entity(sprite)
	_add_chandeliers()

func _is_edge_threshold(door_id: String) -> bool:
	return door_id.begins_with("hallway_") or door_id.begins_with("lobby:") \
			or door_id == "basement:entry"

## A chandelier at each hallway midpoint. The lobby's entrance has the same central column, so its
## chandelier would overlap the barricade that needs to read as the closed main way out.
func _add_chandeliers() -> void:
	for id in ["hallway_third", "hallway_second", "hallway_first"]:
		if not _plan.waypoints.has(id):
			continue
		var chandelier := Sprite2D.new()
		var texture := AtlasLibrary.region(CHANDELIER_TEXTURE)
		chandelier.texture = texture
		chandelier.centered = false
		chandelier.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
		chandelier.position = tile_to_world(_plan.waypoints[id] + Vector2i(0, -1))
		add_entity(chandelier)

func _decal_texture(kind: InteriorTile.Kind) -> StringName:
	match kind:
		InteriorTile.Kind.DEBRIS:
			return DEBRIS_TEXTURE
		InteriorTile.Kind.RAT:
			return RAT_TEXTURE
		_:
			return PUDDLE_TEXTURE

## A bottom-centre-anchored standing sprite at a tile's own centre — a stairwell door or the
## emergency exit, drawn the same way `Sprites.draw_standing()` draws every other feet-anchored
## actor, in the door layer under her.
func _add_standing(tile: Vector2i, name: StringName) -> void:
	var sprite := Sprite2D.new()
	var texture := AtlasLibrary.region(name)
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
	sprite.position = tile_to_world(tile)
	add_entity(sprite, DrawLayer.Layer.DOORS)

## A threshold sits at a floor tile's south boundary. Its origin is intentionally lower than an
## upright stairwell door's: the opening belongs to the wall beyond the corridor, not the floor.
func _add_threshold(tile: Vector2i, name: StringName) -> void:
	var sprite := Sprite2D.new()
	var texture := AtlasLibrary.region(name)
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
	sprite.position = Vector2((tile.x + 0.5) * TILE, (tile.y + 1) * TILE)
	add_entity(sprite, DrawLayer.Layer.DOORS)

## Repeats the shaft wall behind the ten-column grammar. The four eight-row panels cover the
## complete 26-row stairwell, including the final two-cell lobby approach, but add no floor:
## collision and walkability still come only from the parsed symbols.
func _rebuild_stairwell_backdrops() -> void:
	var segment_texture := AtlasLibrary.region(STAIRWELL_SEGMENT_BACKDROP)
	var cap_texture := AtlasLibrary.region(STAIRWELL_SHAFT_CAP_TOP)
	for side in ["left", "right"]:
		var top_landing: Vector2i = _plan.waypoints["stairwell_%s" % side]
		var origin := top_landing - InteriorMap.STAIRWELL_TOP_LANDING_LOCAL
		for panel in 4:
			var backdrop := Sprite2D.new()
			backdrop.texture = segment_texture
			backdrop.centered = false
			backdrop.position = Vector2(origin + Vector2i(0, panel * 8)) * TILE
			add_entity(backdrop, DrawLayer.Layer.BACKDROP)
		var cap := Sprite2D.new()
		cap.texture = cap_texture
		cap.centered = false
		cap.position = Vector2(origin + Vector2i(0, -2)) * TILE
		add_entity(cap, DrawLayer.Layer.BACKDROP)

# ------------------------------------------------------------------ placement and queries ---

## Centre of a tile in world space — the same convention `CityMap.tile_to_world()` uses, so an
## entity placed here reads exactly the way one placed outdoors does.
func tile_to_world(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE

func world_to_tile(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / TILE), floori(world_position.y / TILE))

func is_walkable(tile: Vector2i) -> bool:
	return _plan.is_walkable(tile)

## The building's walls as a grid `CityMap.wall_between()` can answer — open where
## `is_walkable()` says she may stand, building everywhere else: the solid between two flights, a
## stair side, the rubble, the gaps between parts. *(plaid-wombat, inbox #554: "Excitement should
## not go through **any** wall".)* So a field indoors is stopped at exactly the depths a field
## outdoors is, by the same function, rather than by a second copy of its geometry that could drift
## from it: a tile deep in anything thicker than one tile, the middle of a wall one tile thick.
##
## **A wall grid and nothing else.** The tiles are `SIDEWALK` and `BUILDING` only because those are
## the open and the shut kinds `wall_between()` reads; it carries no streets, blocks or closures, so
## it is handed to an `EventInstance` for its wall question alone (`EventInstance.set_walls()`) and
## never as the map every other question of its asks. Built on first use and kept: the plan never
## changes after `build()`. The building starts at tile (0, 0) — the slots run east from it and
## every part's rows south — and a tile off the grid counts as building, as it does outdoors.
func wall_grid() -> CityMap:
	if _wall_grid:
		return _wall_grid
	build()
	var box := _footprint()
	if box.position.x < 0 or box.position.y < 0:
		push_error("the building reaches tile %s, west or north of the wall grid's origin"
				% box.position)
	_wall_grid = CityMap.new(box.end)
	for tile: Vector2i in _plan.tiles:
		if _plan.is_walkable(tile):
			_wall_grid.set_tile(tile, GameEnums.TileType.SIDEWALK)
	return _wall_grid

## `+1`/`-1` if `world_position`'s tile is a diagonal flight tile, `0` otherwise — the one question
## `Stroller._physics_process()` asks every frame to redirect a sideways press along a flight's own
## slope. See `InteriorTile.flight_direction()`. Off a flight, a landing tile included, she walks
## the way she presses *(inbox #782 in minty-lemur, the player: outside of a stair she goes into the direction)*.
func slope_dir_at(world_position: Vector2) -> int:
	return InteriorTile.flight_direction(_plan.tiles.get(world_to_tile(world_position), InteriorTile.Kind.NONE))

## Where a fresh run starts — the third floor's own door, mid-hallway on its south edge.
func start_world_position() -> Vector2:
	return tile_to_world(_plan.start_tile)

## `InteriorMap.PARTS`' own waypoint, in world space — what `--start-escape <part>` teleports to.
## `Vector2.ZERO` (her own start) for a name this does not recognise, the same "unknown means the
## default" shape `DevFlags.start_escape_at()` already leaves to its caller.
func part_world_position(part: String) -> Vector2:
	if _plan.waypoints.has(part):
		return tile_to_world(_plan.waypoints[part])
	return start_world_position()

## What `waypoint()` answers for a name the plan does not have. Off every part's own footprint by
## several map widths, so a caller that forgets to check it puts something nowhere at all rather
## than on the ground beside her.
const NOWHERE := Vector2i(-999999, -999999)

## An `InteriorMapPlan` waypoint by name — a stairwell's landing, a hallway's midpoint, the lobby
## floor — or `NOWHERE`. The escape's events are sited against these rather than against tile
## arithmetic of their own, so a change to the building's layout moves them with it.
func waypoint(id: String) -> Vector2i:
	return _plan.waypoints.get(id, NOWHERE)

## The inner cell of each intermediate floor's level approach, in one shaft — the second of the two
## level `F` cells below a `D`, two tiles from the door. Named for what it is: **the grammar has no
## half-landing between floors and no cell of kind `LANDING` in a shaft at all**, so anything
## sited here is on a floor's own approach, one cell further in than the door.
##
## Which is exactly what the fire wants: two tiles from the door, its body closes the flight the
## approach leads onto without covering the corridor transition itself, so the way past it is
## through that floor's door rather than back up the stairs. The top and lobby approaches are
## excluded, since neither has a flight above it to close.
func inner_floor_approaches(part_id: String) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for landing_id in ["landing_second", "landing_first"]:
		var first: Vector2i = waypoint("%s:%s" % [part_id, landing_id])
		if first == NOWHERE:
			continue
		var inner := first + Vector2i.DOWN
		if _plan.is_walkable(inner):
			found.append(inner)
	return found

## Every painted cell inside one grammar rectangle, including the non-walkable stair-side roles.
## Finale placement and focused tests use the same bounds rather than inferring a shaft from the
## changing positions of its alternating doors.
func stairwell_tiles(part_id: String) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	var top: Vector2i = waypoint(part_id)
	if top == NOWHERE:
		return found
	var origin := top - InteriorMap.STAIRWELL_TOP_LANDING_LOCAL
	var bounds := Rect2i(origin, InteriorMap.STAIRWELL_SIZE)
	for tile: Vector2i in _plan.tiles:
		if bounds.has_point(tile):
			found.append(tile)
	return found

## One shaft's own walk, its lobby landing to its top landing, tile by tile. A shaft is a corridor
## with no branches too — the level `F` columns and the `t/m` and `T/M` diagonals are the only
## ground in the grammar — so its shortest walk *is* the staircase, and anything that has to travel
## the shaft travels it over cells she could stand on rather than across the solid `c`/`C`/`b`
## sides and the background between the flights.
##
## The doors are dead ends off it: each `D` cell's only walkable neighbours are the level approach
## below it, so a shortest walk never stands on one.
func stairwell_walk(part_id: String) -> Array[Vector2i]:
	var bottom := waypoint("%s:landing_lobby" % part_id)
	var top := waypoint(part_id)
	if bottom == NOWHERE or top == NOWHERE:
		return []
	return _shortest_walk(bottom, top)

## Where the basement corridor is one tile wide on the way out, in the order she meets them — see
## `InteriorMapPlan.corridor_narrows`. Passed through rather than recomputed by scanning for cells
## with two blocked sides, so what a gate stands on is what the layout laid rather than whatever
## the geometry happens to offer today.
func basement_narrows() -> Array[Vector2i]:
	return _plan.corridor_narrows

## The basement's corridor, entry to exit, tile by tile. The corridor has no branches, so its
## shortest walk *is* the corridor, and anything sited a fraction of the way along it stands
## somewhere she has to pass rather than somewhere she might.
func basement_walk() -> Array[Vector2i]:
	var entry := _plan.door("basement:entry")
	if not entry or _plan.exit_tile.x < 0:
		return []
	return _shortest_walk(entry.tile, _plan.exit_tile)

## Breadth-first over walkable tiles, unwound into the path itself — `from` first, `to` last, or
## empty when there is no walk between them.
##
## **Eight-connected, not four.** A shaft's flights are runs of diagonal steps — the reviewed
## `t/m` and `T/M` roles drop one tile height over one tile width — so a four-connected walk finds
## no way down a staircase at all. She walks those corners, so a walk that could not is not the
## walk she takes.
func _shortest_walk(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var previous := {from: from}
	var queue: Array[Vector2i] = [from]
	var head := 0
	while head < queue.size():
		var tile: Vector2i = queue[head]
		head += 1
		if tile == to:
			break
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var next := tile + Vector2i(dx, dy)
				if previous.has(next) or not _plan.is_walkable(next):
					continue
				previous[next] = tile
				queue.append(next)
	if not previous.has(to):
		return []
	var path: Array[Vector2i] = []
	var at := to
	while at != from:
		path.append(at)
		at = previous[at]
	path.append(from)
	path.reverse()
	return path

## The whole building's own footprint, grown by a wide margin — **wider than it looks like it
## needs to be, on purpose.** `Stroller`'s `Camera2D` is authored at `zoom = Vector2(2, 2)`
## (`scenes/player/stroller.tscn`), so its own visible world footprint is 640×360, not the
## viewport's raw 1280×720 — and a `Camera2D` asked to keep its **whole view** inside a `limit_*`
## box **smaller** than that footprint cannot satisfy the constraint on that axis at all, which
## Godot resolves by pinning the camera to a fixed point derived from the limits alone rather than
## from wherever the tracked node actually is. `_CAMERA_MARGIN` is sized comfortably past half the
## zoomed-out footprint on every side; the whole-building footprint is already far bigger than that
## on its own, seven parts 64 tiles apart, so this margin is a small addition on top rather than
## the difference between working and pinned.
const _CAMERA_MARGIN := 400.0
func camera_bounds() -> Rect2:
	var box := _footprint()
	return Rect2(Vector2(box.position) * TILE, Vector2(box.size) * TILE).grow(_CAMERA_MARGIN)

## The building's node for `layer`, named `name`, handed over as its node for that draw layer
## (`add_entity()`).
func _layer_node(layer: int, name: String, y_sorted := false) -> Node2D:
	var node := Node2D.new()
	node.name = name
	return layers().hold(layer, node, y_sorted)

# ------------------------------------------------------------------ the meters ---
# `InteriorScene` is a `WorldContext`, so the baby asks it how loud it is here. With nothing in the
# building the base class's own defaults are already the right answer — 1.0 recovery everywhere and
# nothing charging excitement — and the escape's own events are what make them say otherwise.

## The events inside the building, or null while the building is walked empty. The same
## relationship `City` has to its own `EventManager`: the world holds the events and the events
## hold the world, because an event has to be added to the scene it stands in.
var events: InteriorEvents = null

## **The basement gives nothing back**: the meter does not fall while she is in it, awake or asleep
## (`Tuning.EXCITEMENT_DECAY_BASEMENT_MULTIPLIER`), so what a vent charges her with stays until she
## is out. Every other part of the building is an ordinary 1.0.
func decay_multiplier(world_position: Vector2) -> float:
	if InteriorMap.part_at(world_to_tile(world_position)) == "basement":
		return Tuning.EXCITEMENT_DECAY_BASEMENT_MULTIPLIER
	return 1.0

func total_excitement_at(world_position: Vector2) -> float:
	return events.total_excitement_at(world_position) if events else 0.0

func excitement_sources_at(world_position: Vector2) -> Array:
	if not events:
		return []
	return events.excitement_sources_at(world_position)

# ------------------------------------------------------------------ transitions ---

## Whether `tile` is a transition trigger, and what it leads to. Factored out from
## `process_player()` so a test can ask the exact question the running game asks every frame
## without also waiting on the fade this class owns — see `tests/test_interior.gd`.
func transition_at(tile: Vector2i) -> Dictionary:
	for id: String in _plan.doors:
		var door: InteriorMapPlan.Door = _plan.doors[id]
		if door.tile == tile:
			return {"kind": "door", "door": door}
	if _plan.exit_tile.x >= 0 and tile == _plan.exit_tile:
		return {"kind": "exit"}
	return {}

## Called every frame by `main._process()` while the escape scene is running. Reads `player`'s own
## tile rather than being told about it, the same way `EventInstance` and `CrowdAgent` ask the
## world about her rather than being pushed a position — there is exactly one caller, but the
## question is "what is on this ground", not "what did somebody just do". Takes `_delta` only to
## keep `main._process()`'s own call site uniform with every other per-frame update there; nothing
## here is a rate the fade `Tween` does not already own.
func process_player(player: Node2D, _delta: float) -> void:
	modulate = lighting_at(world_to_tile(player.global_position))
	_door_release_latch.update(player.global_position)
	if _transitioning or _door_release_latch.holds():
		return
	var tile := world_to_tile(player.global_position)
	var result := transition_at(tile)
	if result.is_empty():
		return
	if result["kind"] == "door":
		_start_door_transition(result["door"], player)
	else:
		_start_exit()

func _start_door_transition(door: InteriorMapPlan.Door, player: Node2D) -> void:
	_transitioning = true
	var target_door: String = door.target_door
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, FADE_SECONDS)
	tween.tween_callback(func() -> void: teleport_to_door(target_door, player))
	tween.tween_property(_fade_rect, "modulate:a", 0.0, FADE_SECONDS)
	tween.tween_callback(func() -> void: _transitioning = false)

func _start_exit() -> void:
	_transitioning = true
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, FADE_SECONDS)
	tween.tween_callback(func() -> void: exit_requested.emit())

## Lifts the black the service exit left over the screen, once whoever listened to
## `exit_requested` has finished building whatever is behind it. **The exit's own tween stops at
## full opacity on purpose** — a door fades back in by itself because its counterpart is already
## on this map, and the way out has to hold the black for however long the city takes to be
## assembled, or the first frame of it is seen being built.
##
## Also the way back in after a lost section: she is put at the hallway's own start, and a fade
## rect left opaque from a transition that was interrupted would leave the retry playing behind a
## black screen.
func clear_fade() -> void:
	_transitioning = false
	if _fade_rect.modulate.a <= 0.0:
		return
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 0.0, FADE_SECONDS)

## Takes the building's wall blockers out of the physics space for good, once she has walked out
## into the city. **The building shares the city's space and its coordinates:** both are laid out
## from the world origin, and the footprint's blockers reach city row 26, with the margin row
## solid along the city's whole width, so left in place they are a wall across the city that
## nothing draws (inbox #777 in minty-lemur). Only the blockers go: the building's pictures stay, under the city's
## own, and so does its fade, which `clear_fade()` still lifts over the street. Freed at once
## rather than queued, so nothing else in this same call, the city's build and its first streaming
## pass included, finds them in the space; the caller is the exit's own tween callback, never a
## physics query. Nothing walks the building again on this boot — a lost city section starts the
## city again — so nothing rebuilds them.
func take_the_walls_out() -> void:
	if _collision == null:
		return
	remove_child(_collision)
	_collision.free()
	_collision = null

## Moves `player` to the door named `door_id`'s own tile — "just inside its counterpart door," in
## the TODO's own words, since the door tile is exactly where she is placed. Exposed rather than
## kept behind the tween above, so a test can drive the same teleport the running game uses without
## also driving the fade's timing — see `transition_at()`'s own doc for the same reasoning.
##
## `reset_at()` rather than a bare `global_position` assignment: it also resets the camera's own
## smoothing (`Camera2D.reset_smoothing()`), which is what makes this a *snap* to the door rather
## than a slide across the empty ground between two parts — *(2026-09-10, playtest 55: "fade to
## black, teleport, then fade in again", and the camera "snapping with her, not sliding across the
## gap")*. Facing chosen as north on arrival: arbitrary, and open to revisit once the scene is
## actually played rather than stepped.
func teleport_to_door(door_id: String, player: Node2D) -> void:
	var door := _plan.door(door_id)
	var at := tile_to_world(door.tile)
	_door_release_latch.arm(at, _DOOR_RELEASE_RADIUS)
	# Under the black, so the part she arrives in is never seen in the light of the one she left.
	modulate = lighting_at(door.tile)
	if player is Stroller:
		(player as Stroller).reset_at(at, Vector2.UP)
	else:
		player.global_position = at
		# `reset_at()` already does this for the `Stroller` branch above; a bare test double
		# still needs it or physics interpolation draws it sliding in from the part it left.
		player.reset_physics_interpolation()

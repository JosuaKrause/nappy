class_name InteriorScene
extends WorldContext
## The escape scene's building, as one persistent map — `assets/interior`'s floor plan and stair
## kit made walkable. Built once by `main._ready_escape()` behind `--start-escape`; absent from
## every ordinary run, which is why it needs no events and no crowd of its own — `WorldContext`'s
## own defaults (1.0 recovery, no excitement sources) are exactly "meters idle" already.
##
## Ground is a `TileMapLayer` built from `InteriorTileSet`; walls, doors, the barricade and the
## brick stand in elevation in a plain layer under everything, the same reasoning `Building` and
## `City`'s own `Buildings` layer use — nothing can ever legitimately stand *behind* a wall, so
## nothing needs to sort against one. Rails, newels, the chandelier, ground decals and every door
## threshold's own standing sprite live in a y-sorted layer above the ground, the same layer the
## player joins through `add_entity()`, so she walks behind a rail the same way she walks behind an
## event's shadow outdoors.
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

const HALLWAY_WALL := preload("res://assets/interior/hallway_wall.svg")
const HALLWAY_WINDOW := preload("res://assets/interior/hallway_wall_window.svg")
const WALL_LAMP_TEXTURE := preload("res://assets/interior/wall_lamp.svg")
const LIFT_DOOR_TEXTURE := preload("res://assets/interior/lift_door_dead.svg")
const ENTRANCE_DOOR_TEXTURE := preload("res://assets/interior/entrance_door.svg")
const ENTRANCE_BARRICADE_TEXTURE := preload("res://assets/interior/entrance_barricade.svg")
const BRICK_WALL := preload("res://assets/interior/basement_wall_brick.svg")
const DOOR_TEXTURE := preload("res://assets/interior/stairwell_door.svg")
const APARTMENT_THRESHOLD_TEXTURE := preload("res://assets/interior/apartment_threshold.svg")
const OPEN_THRESHOLD_TEXTURE := preload("res://assets/interior/open_threshold.svg")
const EMERGENCY_EXIT_TEXTURE := preload("res://assets/interior/emergency_exit_door.svg")
const PUDDLE_TEXTURE := preload("res://assets/interior/puddle.svg")
const DEBRIS_TEXTURE := preload("res://assets/interior/basement_debris.svg")
const RAT_TEXTURE := preload("res://assets/interior/rat.svg")
const CHANDELIER_TEXTURE := preload("res://assets/interior/chandelier.svg")
const STAIRWELL_SEGMENT_BACKDROP := preload("res://assets/interior/stairwell_segment_backdrop.svg")
const STAIRWELL_SHAFT_CAP_TOP := preload("res://assets/interior/stairwell_shaft_cap_top.svg")
const STAIRWELL_SHAFT_CAP_BOTTOM := preload("res://assets/interior/stairwell_shaft_cap_bottom.svg")
const STAIR_FLIGHT_RUN_E := preload("res://assets/interior/stair_flight_run_e.svg")
const STAIR_FLIGHT_RUN_W := preload("res://assets/interior/stair_flight_run_w.svg")
const STAIR_LANDING_FLOOR := preload("res://assets/interior/stair_landing_floor.svg")
const STAIR_LANDING_TURN := preload("res://assets/interior/stair_landing_turn.svg")
const STAIR_RAIL_RUN_E := preload("res://assets/interior/stair_rail_run_e.svg")
const STAIR_RAIL_RUN_W := preload("res://assets/interior/stair_rail_run_w.svg")
const STAIR_RAIL_RUN_E_REAR := preload("res://assets/interior/stair_rail_run_e_rear.svg")
const STAIR_RAIL_RUN_W_REAR := preload("res://assets/interior/stair_rail_run_w_rear.svg")
const STAIR_FLIGHT_SHORT_E := preload("res://assets/interior/stair_flight_short_e.svg")
const STAIR_RAIL_SHORT_E := preload("res://assets/interior/stair_rail_short_e.svg")
const STAIR_RAIL_SHORT_E_REAR := preload("res://assets/interior/stair_rail_short_e_rear.svg")

const TILE := float(Tuning.TILE_SIZE)
## How long the fade to black takes, each way — brisk, since it stands in for a flight of stairs
## rather than for a whole day changing.
const FADE_SECONDS := 0.35

var _plan: InteriorMapPlan
var _tile_set: TileSet
var _ground: TileMapLayer
var _backdrops: Node2D
var _walls: Node2D
var _structure: Node2D
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
	_backdrops = Node2D.new()
	_backdrops.name = "StairwellBackdrops"
	_backdrops.z_index = -1
	add_child(_backdrops)
	_walls = Node2D.new()
	_walls.name = "Walls"
	_walls.z_index = 1
	add_child(_walls)
	_structure = Node2D.new()
	_structure.name = "StairStructure"
	_structure.z_index = 1
	add_child(_structure)
	_entities = Node2D.new()
	_entities.name = "Entities"
	_entities.z_index = 2
	_entities.y_sort_enabled = true
	add_child(_entities)
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
	_rebuild_stairwell_structure()
	_rebuild_overlays()
	_rebuild_collision()

## The bounding box of every walkable-or-standable cell in the whole building — every part and
## every gap between them, since the collision pass and the camera limits both need to cover the
## gaps too (she must not be able to walk, or be framed, off the building's own combined edge).
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
	for y in range(box.position.y, box.position.y + box.size.y):
		for x in range(box.position.x, box.position.x + box.size.x):
			var tile := Vector2i(x, y)
			if _plan.tiles.has(tile) or _plan.collision_clearance.has(tile):
				continue
			var body := StaticBody2D.new()
			var shape := CollisionShape2D.new()
			var rectangle := RectangleShape2D.new()
			rectangle.size = Vector2.ONE * TILE
			shape.shape = rectangle
			body.position = tile_to_world(tile)
			body.add_child(shape)
			_collision.add_child(body)

func _rebuild_walls() -> void:
	# Wide doors are drawn after the repeating 32px wall strips. Their own centre registration keeps
	# both leaves visible instead of letting a neighbouring wall crop one side.
	for at: Vector2i in _plan.walls:
		var kind: InteriorTile.Kind = _plan.walls[at]
		if kind == InteriorTile.Kind.LIFT_DOOR or kind == InteriorTile.Kind.ENTRANCE_DOOR:
			continue
		var texture := _wall_texture(kind)
		_add_wall_sprite(at, texture)
	for at: Vector2i in _plan.walls:
		var kind: InteriorTile.Kind = _plan.walls[at]
		if kind != InteriorTile.Kind.LIFT_DOOR and kind != InteriorTile.Kind.ENTRANCE_DOOR:
			continue
		_add_wall_sprite(at, _wall_texture(kind))
	for at: Vector2i in _plan.entrance_tiles:
		var barricade := Sprite2D.new()
		barricade.texture = ENTRANCE_BARRICADE_TEXTURE
		barricade.centered = false
		barricade.offset = Vector2(-ENTRANCE_BARRICADE_TEXTURE.get_width() * 0.5,
				-ENTRANCE_BARRICADE_TEXTURE.get_height())
		barricade.position = Vector2((at.x + 0.5) * TILE, at.y * TILE + TILE * 0.5)
		_walls.add_child(barricade)

func _add_wall_sprite(at: Vector2i, texture: Texture2D) -> void:
	if not texture:
		return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
	sprite.position = Vector2((at.x + 0.5) * TILE, at.y * TILE)
	_walls.add_child(sprite)

func _wall_texture(kind: InteriorTile.Kind) -> Texture2D:
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
			return null

## Doors, rails, newels, the chandeliers and every ground decal — everything that stands above the
## floor rather than being the floor, all in the y-sorted layer the player joins through
## `add_entity()`.
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
		var sprite := Sprite2D.new()
		sprite.texture = _decal_texture(kind)
		sprite.position = tile_to_world(tile)
		_entities.add_child(sprite)
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
		chandelier.texture = CHANDELIER_TEXTURE
		chandelier.centered = false
		chandelier.offset = Vector2(-CHANDELIER_TEXTURE.get_width() * 0.5, -CHANDELIER_TEXTURE.get_height())
		chandelier.position = tile_to_world(_plan.waypoints[id] + Vector2i(0, -1))
		_entities.add_child(chandelier)

func _decal_texture(kind: InteriorTile.Kind) -> Texture2D:
	match kind:
		InteriorTile.Kind.DEBRIS:
			return DEBRIS_TEXTURE
		InteriorTile.Kind.RAT:
			return RAT_TEXTURE
		_:
			return PUDDLE_TEXTURE

## A bottom-centre-anchored standing sprite at a tile's own centre — a door threshold, drawn the
## same way `Sprites.draw_standing()` draws every other feet-anchored actor.
func _add_standing(tile: Vector2i, texture: Texture2D) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
	sprite.position = tile_to_world(tile)
	_entities.add_child(sprite)

## A threshold sits at a floor tile's south boundary. Its origin is intentionally lower than an
## upright stairwell door's: the opening belongs to the wall beyond the corridor, not the floor.
func _add_threshold(tile: Vector2i, texture: Texture2D) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
	sprite.position = Vector2((tile.x + 0.5) * TILE, (tile.y + 1) * TILE)
	_entities.add_child(sprite)

## Draws one broad architectural bay behind every landing that has a flight below it, then puts a
## continuous deck over the same four diagonal cells. The cells, collision clearance and slope
## callback remain exactly the map's existing walkable graph; this only gives their presentation
## the breadth and enclosure the references call for.
func _rebuild_stairwell_structure() -> void:
	# A named floor landing owns its enclosed eight-row backdrop. Turn landings need no second
	# backdrop, but both kinds own a broad half-flight assembly below.
	for id: String in _plan.waypoints:
		if not id.begins_with("stairwell_") or not id.contains(":landing_"):
			continue
		var landing: Vector2i = _plan.waypoints[id]
		var east: int = _plan.tiles.get(landing + Vector2i(1, 1), InteriorTile.Kind.NONE)
		var west: int = _plan.tiles.get(landing + Vector2i(-1, 1), InteriorTile.Kind.NONE)
		if east != InteriorTile.Kind.STAIR_FLIGHT_E and west != InteriorTile.Kind.STAIR_FLIGHT_W:
			continue
		var backdrop := Sprite2D.new()
		backdrop.texture = STAIRWELL_SEGMENT_BACKDROP
		backdrop.centered = false
		backdrop.position = Vector2((landing.x - 4) * TILE, landing.y * TILE)
		_backdrops.add_child(backdrop)
	for side in ["left", "right"]:
		var top: Vector2i = _plan.waypoints["stairwell_%s" % side]
		_add_shaft_cap(top, STAIRWELL_SHAFT_CAP_TOP, Vector2(0, -64))
		var bottom: Vector2i = _plan.waypoints["stairwell_%s:landing_lobby" % side]
		_add_shaft_cap(bottom, STAIRWELL_SHAFT_CAP_BOTTOM, Vector2.ZERO)
	_add_basement_entry_stair()
	for landing: Vector2i in _plan.tiles:
		if _plan.tiles[landing] != InteriorTile.Kind.LANDING:
			continue
		var east: int = _plan.tiles.get(landing + Vector2i(1, 1), InteriorTile.Kind.NONE)
		var west: int = _plan.tiles.get(landing + Vector2i(-1, 1), InteriorTile.Kind.NONE)
		if east != InteriorTile.Kind.STAIR_FLIGHT_E and west != InteriorTile.Kind.STAIR_FLIGHT_W:
			continue
		var descends_east := east == InteriorTile.Kind.STAIR_FLIGHT_E
		var deck: Texture2D = STAIR_FLIGHT_RUN_E if descends_east else STAIR_FLIGHT_RUN_W
		var origin := _flight_origin(landing, descends_east)
		_add_flight_deck(origin, deck)
		if _is_floor_landing(landing):
			var rear_rail: Texture2D = STAIR_RAIL_RUN_E_REAR if descends_east else STAIR_RAIL_RUN_W_REAR
			_add_flight_rear_rail(origin, rear_rail)
		var rail: Texture2D = STAIR_RAIL_RUN_E if descends_east else STAIR_RAIL_RUN_W
		_add_flight_rail(origin, rail)
	for landing: Vector2i in _plan.tiles:
		if _plan.tiles[landing] != InteriorTile.Kind.LANDING:
			continue
		if _is_floor_landing(landing):
			_add_floor_landing_platform(landing)
			continue
		var east: int = _plan.tiles.get(landing + Vector2i(1, 1), InteriorTile.Kind.NONE)
		_add_turn_landing_platform(landing, east == InteriorTile.Kind.STAIR_FLIGHT_E)

func _is_floor_landing(landing: Vector2i) -> bool:
	for id: String in _plan.waypoints:
		if id.begins_with("stairwell_") and id.contains(":landing_") and _plan.waypoints[id] == landing:
			return true
	return false

func _add_shaft_cap(landing: Vector2i, texture: Texture2D, offset: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = Vector2((landing.x - 4) * TILE, landing.y * TILE) + offset
	_backdrops.add_child(sprite)

func _add_floor_landing_platform(landing: Vector2i) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = STAIR_LANDING_FLOOR
	sprite.centered = false
	sprite.position = Vector2((landing.x - 1) * TILE, landing.y * TILE)
	_structure.add_child(sprite)

func _add_turn_landing_platform(landing: Vector2i, descends_east: bool) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = STAIR_LANDING_TURN
	sprite.centered = false
	var x := landing.x if descends_east else landing.x - 1
	sprite.position = Vector2(x * TILE, (landing.y - 1) * TILE)
	_structure.add_child(sprite)

func _add_basement_entry_stair() -> void:
	var entry: InteriorMapPlan.Door = _plan.door("basement:entry")
	var top: Vector2i = entry.tile - Vector2i(2, 2)
	var origin: Vector2 = Vector2(top) * TILE
	_add_flight_deck(origin, STAIR_FLIGHT_SHORT_E)
	_add_flight_rear_rail(origin, STAIR_RAIL_SHORT_E_REAR)
	_add_flight_rail(origin, STAIR_RAIL_SHORT_E)

func _flight_origin(landing: Vector2i, descends_east: bool) -> Vector2:
	var x := landing.x if descends_east else landing.x - 4
	return Vector2(x * TILE, landing.y * TILE)

func _add_flight_deck(origin: Vector2, texture: Texture2D) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = origin
	_structure.add_child(sprite)

func _add_flight_rear_rail(origin: Vector2, texture: Texture2D) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = origin
	_structure.add_child(sprite)

func _add_flight_rail(origin: Vector2, texture: Texture2D) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	# The bottom-edge sort key leaves the walker behind the foreground rail throughout the flight.
	sprite.offset = Vector2(0, -texture.get_height())
	sprite.position = origin + Vector2(0, texture.get_height())
	_entities.add_child(sprite)

# ------------------------------------------------------------------ placement and queries ---

## Centre of a tile in world space — the same convention `CityMap.tile_to_world()` uses, so an
## entity placed here reads exactly the way one placed outdoors does.
func tile_to_world(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE

func world_to_tile(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / TILE), floori(world_position.y / TILE))

func is_walkable(tile: Vector2i) -> bool:
	return _plan.is_walkable(tile)

## `+1`/`-1` if `world_position`'s tile is a diagonal flight tile, `0` otherwise — the one question
## `Stroller._physics_process()` asks every frame to redirect a sideways press along a flight's own
## slope. See `InteriorTile.flight_direction()`.
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

## Joins the y-sorted layer everything standing in this scene lives on.
func add_entity(node: Node) -> void:
	_entities.add_child(node)

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
	if player is Stroller:
		(player as Stroller).reset_at(at, Vector2.UP)
	else:
		player.global_position = at

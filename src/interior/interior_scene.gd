class_name InteriorScene
extends WorldContext
## The escape scene's building, one map at a time — `assets/interior`'s floor plan and stair kit
## made walkable. Built by `main._ready_escape()` behind `--start-escape`; absent from every
## ordinary run, which is why it needs no events and no crowd of its own — `WorldContext`'s own
## defaults (1.0 recovery, no excitement sources) are exactly "meters idle" already.
##
## Ground is a `TileMapLayer` built from `InteriorTileSet`; walls, doors, the barricade and the
## brick stand in elevation in a plain layer under everything, the same reasoning `Building` and
## `City`'s own `Buildings` layer use — nothing can ever legitimately stand *behind* a wall, so
## nothing needs to sort against one. Rails, newels, the chandelier, ground decals and every door
## threshold's own standing sprite live in a y-sorted layer above the ground, the same layer the
## player joins through `add_entity()`, so she walks behind a rail the same way she walks behind an
## event's shadow outdoors.
##
## **Seven maps, joined only by doors, never by a shared coordinate space.** Each
## `InteriorMap.build()` call returns a small grid with its own origin; walking onto a door tile
## fades out, rebuilds this scene for the door's own `target_map`, places her at the counterpart
## door and fades back in — see `_start_door_transition()`. There is no "next floor" arithmetic
## left in this class; `InteriorMapPlan.Door` carries the whole topology.
##
## **A door tile is both where she leaves from and where she arrives.** Nothing here makes the
## arrival tile different from the trigger tile — the way the original single-shaft design needed
## a landing two tiles from its own door — because the trigger is edge-detected: `process_player()`
## remembers her last tile and only fires when the current one is *newly* a trigger, not merely
## *is* one, so being placed on a door the instant a transition finishes does not immediately fire
## the next one. `_last_player_tile` carries that memory across frames.

signal exit_requested

const HALLWAY_WALL := preload("res://assets/interior/hallway_wall.svg")
const HALLWAY_WINDOW := preload("res://assets/interior/hallway_wall_window.svg")
const WALL_LAMP_TEXTURE := preload("res://assets/interior/wall_lamp.svg")
const LIFT_DOOR_TEXTURE := preload("res://assets/interior/lift_door_dead.svg")
const ENTRANCE_DOOR_TEXTURE := preload("res://assets/interior/entrance_door.svg")
const ENTRANCE_BARRICADE_TEXTURE := preload("res://assets/interior/entrance_barricade.svg")
const BRICK_WALL := preload("res://assets/interior/basement_wall_brick.svg")
const DOOR_TEXTURE := preload("res://assets/interior/stairwell_door.svg")
const EMERGENCY_EXIT_TEXTURE := preload("res://assets/interior/emergency_exit_door.svg")
const PUDDLE_TEXTURE := preload("res://assets/interior/puddle.svg")
const DEBRIS_TEXTURE := preload("res://assets/interior/basement_debris.svg")
const RAT_TEXTURE := preload("res://assets/interior/rat.svg")
const CHANDELIER_TEXTURE := preload("res://assets/interior/chandelier.svg")
const RAIL_E := preload("res://assets/interior/stair_rail_e.svg")
const RAIL_W := preload("res://assets/interior/stair_rail_w.svg")
const RAIL_LEVEL := preload("res://assets/interior/stair_rail_level.svg")
const NEWEL := preload("res://assets/interior/stair_newel.svg")

const TILE := float(Tuning.TILE_SIZE)
## How long the fade to black takes, each way — brisk, since it stands in for a flight of stairs
## rather than for a whole day changing.
const FADE_SECONDS := 0.35

## `InteriorMap.MapKind` as a plain `int` — see `InteriorMapPlan.Door.target_map`'s own doc for why
## every cross-file reference to the enum widens rather than naming it.
var map_kind := 0
var _plan: InteriorMapPlan
var _tile_set: TileSet
var _ground: TileMapLayer
var _walls: Node2D
var _entities: Node2D
## Plain `StaticBody2D` blockers, one per non-walkable cell in a margin around the map's own
## footprint — the physical half of `InteriorMapPlan.is_walkable()`. A `TileMapLayer` only gives
## collision to a cell that holds a tile, and the space around the hallway, the gap beside a
## stairwell's flights and everything off a map's own footprint hold none at all, so without this
## she could walk clean through a wall she can see, or off the map's own edge.
var _collision: Node2D
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
## True from the first fade-to-black frame to the last fade-from-black frame of a transition, so
## `process_player()` cannot fire a second one out from under the first while the map swap and the
## placement in the middle of it are still in flight.
var _transitioning := false
## The tile she stood on last frame, so a transition fires only on the frame she newly steps onto
## a trigger tile rather than on every frame she merely stands on one — see this class's own doc
## for why that is what lets the arrival tile and the trigger tile be the same tile.
var _last_player_tile := Vector2i(-999999, -999999)

func _ready() -> void:
	super()
	_ensure_built()

## Builds the child layers if `_ready()` has not already, so `build()` works on a node that has
## never entered a tree — a script-only `main` under test adds this as a plain child of itself
## without ever joining the running scene tree, and `_ready()` only fires on tree entry.
## Idempotent: a second call after `_ready()` has already run does nothing.
func _ensure_built() -> void:
	if _ground:
		return
	_ground = TileMapLayer.new()
	_ground.name = "Ground"
	add_child(_ground)
	_walls = Node2D.new()
	_walls.name = "Walls"
	_walls.z_index = 1
	add_child(_walls)
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

## Builds `kind`'s map plan and repaints the scene for it. Called once at boot and again by every
## transition — rebuilding wholesale rather than diffing the two maps, the way `City.start_day()`
## repaints its own ground rather than patching cells, because a map this small is cheaper to
## rebuild than to diff.
func build(kind: int) -> void:
	_ensure_built()
	map_kind = kind
	_plan = InteriorMap.build(kind)
	if not _tile_set:
		_tile_set = InteriorTileSet.build()
	_ground.tile_set = _tile_set
	_ground.clear()
	for tile: Vector2i in _plan.tiles:
		var source := InteriorTileSet.source_id_for(_plan.tiles[tile])
		if source >= 0:
			_ground.set_cell(tile, source, Vector2i.ZERO)
	_rebuild_walls()
	_rebuild_overlays()
	_rebuild_collision()

## The footprint every per-map pass (collision, camera bounds) grows from — the bounding box of
## every walkable-or-standable cell, since a wall stands only where a floor tile already is.
func _footprint() -> Rect2i:
	var min_t := Vector2i(999999, 999999)
	var max_t := Vector2i(-999999, -999999)
	for tile: Vector2i in _plan.tiles:
		min_t = min_t.min(tile)
		max_t = max_t.max(tile)
	return Rect2i(min_t, max_t - min_t + Vector2i.ONE)

## One blocker per non-walkable cell in a margin around the map's own footprint. `queue_free()` on
## the old set rather than reusing bodies — a map swap is rare enough (one per door) that
## rebuilding wholesale costs nothing worth optimising, the same call `_rebuild_walls()` and
## `_rebuild_overlays()` already make.
const _MARGIN := 1
func _rebuild_collision() -> void:
	for child in _collision.get_children():
		child.queue_free()
	var box := _footprint().grow(_MARGIN)
	for y in range(box.position.y, box.position.y + box.size.y):
		for x in range(box.position.x, box.position.x + box.size.x):
			var tile := Vector2i(x, y)
			if _plan.tiles.has(tile):
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
	for child in _walls.get_children():
		child.queue_free()
	for at: Vector2i in _plan.walls:
		var kind: InteriorTile.Kind = _plan.walls[at]
		var texture := _wall_texture(kind)
		if not texture:
			continue
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.offset = Vector2(-TILE * 0.5, -texture.get_height())
		sprite.position = Vector2((at.x + 0.5) * TILE, at.y * TILE)
		_walls.add_child(sprite)
	if _plan.entrance_column >= 0:
		var barricade := Sprite2D.new()
		barricade.texture = ENTRANCE_BARRICADE_TEXTURE
		barricade.centered = false
		barricade.offset = Vector2(-ENTRANCE_BARRICADE_TEXTURE.get_width() * 0.5,
				-ENTRANCE_BARRICADE_TEXTURE.get_height())
		barricade.position = Vector2((_plan.entrance_column + 0.5) * TILE, TILE * 0.5)
		_walls.add_child(barricade)

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

## Doors, rails, newels, the chandelier and every ground decal — everything that stands above the
## floor rather than being the floor, all in the y-sorted layer the player joins through
## `add_entity()`.
func _rebuild_overlays() -> void:
	for child in _entities.get_children():
		child.queue_free()
	for id: String in _plan.doors:
		var door: InteriorMapPlan.Door = _plan.doors[id]
		_add_standing(door.tile, DOOR_TEXTURE)
	if _plan.exit_tile.x >= 0:
		_add_standing(_plan.exit_tile, EMERGENCY_EXIT_TEXTURE)
	for tile: Vector2i in _plan.decals:
		var kind: InteriorTile.Kind = _plan.decals[tile]
		var sprite := Sprite2D.new()
		sprite.texture = _decal_texture(kind)
		sprite.position = tile_to_world(tile)
		_entities.add_child(sprite)
	if map_kind in [InteriorMap.MapKind.STAIRWELL_LEFT, InteriorMap.MapKind.STAIRWELL_RIGHT]:
		_add_stairwell_rails()
	if map_kind in [InteriorMap.MapKind.HALLWAY_THIRD, InteriorMap.MapKind.HALLWAY_SECOND,
			InteriorMap.MapKind.HALLWAY_FIRST, InteriorMap.MapKind.LOBBY]:
		var box := _footprint()
		var mid_column := box.position.x + box.size.x / 2
		var chandelier := Sprite2D.new()
		chandelier.texture = CHANDELIER_TEXTURE
		chandelier.centered = false
		chandelier.offset = Vector2(-CHANDELIER_TEXTURE.get_width() * 0.5, -CHANDELIER_TEXTURE.get_height())
		chandelier.position = tile_to_world(Vector2i(mid_column, 0))
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

## Rails over every flight and landing tile in this stairwell, and a newel at each `LANDING`
## (every turn is one, since a door tile is a full landing in its own right and does not get one).
##
## Each rail's y-sort key is pinned to its tile's own **south edge** rather than its centre, so a
## walker standing anywhere in that tile's row — her feet somewhere between the row's north and
## south edge — sorts behind it: the key the rail competes with is always the far edge of her own
## row, never the near one, which is what keeps her reading as walking *behind* the rail rather
## than sometimes in front of it depending on where in the tile she stands.
func _add_stairwell_rails() -> void:
	for tile: Vector2i in _plan.tiles:
		var kind: InteriorTile.Kind = _plan.tiles[tile]
		match kind:
			InteriorTile.Kind.STAIR_FLIGHT_E:
				_add_rail(tile, RAIL_E)
			InteriorTile.Kind.STAIR_FLIGHT_W:
				_add_rail(tile, RAIL_W)
			InteriorTile.Kind.LANDING:
				_add_rail(tile, RAIL_LEVEL)
				_add_newel(tile)
			InteriorTile.Kind.DOOR:
				_add_rail(tile, RAIL_LEVEL)

func _add_rail(tile: Vector2i, texture: Texture2D) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2(-TILE * 0.5, -TILE)
	sprite.position = Vector2((tile.x + 0.5) * TILE, (tile.y + 1) * TILE)
	_entities.add_child(sprite)

func _add_newel(at_turn: Vector2i) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = NEWEL
	sprite.centered = false
	sprite.offset = Vector2(-NEWEL.get_width() * 0.5, -NEWEL.get_height())
	sprite.position = Vector2((at_turn.x + 1) * TILE, (at_turn.y + 1) * TILE)
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

## The map's own footprint, grown by a wide margin — **wider than it looks like it needs to be, on
## purpose.** `Stroller`'s `Camera2D` is authored at `zoom = Vector2(2, 2)`
## (`scenes/player/stroller.tscn`), so its own visible world footprint is 640×360, not the
## viewport's raw 1280×720 — and a `Camera2D` asked to keep its **whole view** inside a `limit_*`
## box **smaller** than that footprint cannot satisfy the constraint on that axis at all, which
## Godot resolves by pinning the camera to a fixed point derived from the limits alone rather than
## from wherever the tracked node actually is. `_CAMERA_MARGIN` is sized comfortably past half the
## zoomed-out footprint on every side. The outdoor city never carries this risk at all:
## `City.camera_bounds()` grows the whole map by a full block, always far bigger than 640×360.
const _CAMERA_MARGIN := 400.0
func camera_bounds() -> Rect2:
	var box := _footprint()
	return Rect2(Vector2(box.position) * TILE, Vector2(box.size) * TILE).grow(_CAMERA_MARGIN)

## Joins the y-sorted layer everything standing in this scene lives on.
func add_entity(node: Node) -> void:
	_entities.add_child(node)

# ------------------------------------------------------------------ transitions ---

## Whether `tile` is a transition trigger on the current map, and what it leads to. Factored out
## from `process_player()` so a test can ask the exact question the running game asks every frame
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
	var tile := world_to_tile(player.global_position)
	if tile == _last_player_tile:
		return
	_last_player_tile = tile
	if _transitioning:
		return
	var result := transition_at(tile)
	if result.is_empty():
		return
	if result["kind"] == "door":
		_start_door_transition(result["door"], player)
	else:
		_start_exit()

func _start_door_transition(door: InteriorMapPlan.Door, player: Node2D) -> void:
	_transitioning = true
	var target_map: int = door.target_map
	var target_door: String = door.target_door
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, FADE_SECONDS)
	tween.tween_callback(func() -> void: go_to_map(target_map, target_door, player))
	tween.tween_property(_fade_rect, "modulate:a", 0.0, FADE_SECONDS)
	tween.tween_callback(func() -> void: _transitioning = false)

func _start_exit() -> void:
	_transitioning = true
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, FADE_SECONDS)
	tween.tween_callback(func() -> void: exit_requested.emit())

## Rebuilds for `kind` and places `player` at the door named `door_id` on that map — "the upper
## landing at its door," in the TODO's own words. Exposed rather than kept behind the tween above,
## so a test can drive the same map-swap and placement code the running game uses without also
## driving the fade's timing — see `transition_at()`'s own doc for the same reasoning.
##
## Facing chosen as north on arrival: arbitrary, and open to revisit once the scene is actually
## played rather than stepped.
func go_to_map(kind: int, door_id: String, player: Node2D) -> void:
	build(kind)
	var door := _plan.door(door_id)
	var at := tile_to_world(door.tile)
	_last_player_tile = door.tile
	# `reset_at()` rather than a bare `global_position` assignment: it also resets the camera's
	# own smoothing (`Camera2D.reset_smoothing()`). Without that, `position_smoothing_enabled`
	# (set on `scenes/player/stroller.tscn`'s own Camera2D) keeps chasing wherever she was on the
	# map before, and every day already resets through the same call for the same reason.
	if player is Stroller:
		(player as Stroller).reset_at(at, Vector2.UP)
	else:
		player.global_position = at

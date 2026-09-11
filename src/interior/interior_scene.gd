class_name InteriorScene
extends WorldContext
## The escape scene's building, one floor at a time — `assets/interior`'s floor plan and stair
## kit made walkable. Built by `main._ready_escape()` behind `--start-escape`; absent from every
## ordinary run, which is why it needs no events and no crowd of its own — `WorldContext`'s own
## defaults (1.0 recovery, no excitement sources) are exactly "meters idle" already.
##
## Ground is a `TileMapLayer` built from `InteriorTileSet`; walls, doors, the barricade and the
## brick stand in elevation in a plain layer under everything, the same reasoning `Building` and
## `City`'s own `Buildings` layer use — nothing can ever legitimately stand *behind* a wall, so
## nothing needs to sort against one. Rails, newels, the chandelier, the puddle decals and every
## door threshold's own standing sprite live in a y-sorted layer above the ground, the same layer
## the player joins through `add_entity()`, so she walks behind a rail the same way she walks
## behind an event's shadow outdoors.

signal exit_requested

const HALLWAY_WALL := preload("res://assets/interior/hallway_wall.svg")
const HALLWAY_WINDOW := preload("res://assets/interior/hallway_wall_window.svg")
const LIFT_DOOR_TEXTURE := preload("res://assets/interior/lift_door_dead.svg")
const ENTRANCE_DOOR_TEXTURE := preload("res://assets/interior/entrance_door.svg")
const ENTRANCE_BARRICADE_TEXTURE := preload("res://assets/interior/entrance_barricade.svg")
const BRICK_WALL := preload("res://assets/interior/basement_wall_brick.svg")
const STAIRWELL_DOOR_TEXTURE := preload("res://assets/interior/stairwell_door.svg")
const EMERGENCY_EXIT_TEXTURE := preload("res://assets/interior/emergency_exit_door.svg")
const PUDDLE_TEXTURE := preload("res://assets/interior/puddle.svg")
const CHANDELIER_TEXTURE := preload("res://assets/interior/chandelier.svg")
const RAIL_E := preload("res://assets/interior/stair_rail_e.svg")
const RAIL_W := preload("res://assets/interior/stair_rail_w.svg")
const RAIL_LEVEL := preload("res://assets/interior/stair_rail_level.svg")
const NEWEL := preload("res://assets/interior/stair_newel.svg")

const TILE := float(Tuning.TILE_SIZE)
## How long the fade to black takes, each way — brisk, since it stands in for a flight of stairs
## rather than for a whole day changing.
const FADE_SECONDS := 0.35

## `InteriorMap.FloorKind` as a plain `int` — see `InteriorFloor.kind`'s own doc for why every
## cross-file reference to the enum widens rather than naming it.
var floor_kind := 0
var _floor: InteriorFloor
var _tile_set: TileSet
var _ground: TileMapLayer
var _walls: Node2D
var _entities: Node2D
## Plain `StaticBody2D` blockers, one per non-walkable cell in a margin around the floor's own
## footprint — the physical half of `InteriorFloor.is_walkable()`. A `TileMapLayer` only gives
## collision to a cell that holds a tile, and the space north of the hallway, the gap row between
## a stairwell's two flights and everything off the building's own footprint hold none at all, so
## without this she could walk clean through a wall she can see, or off the map's own edge.
var _collision: Node2D
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
## True from the first fade-to-black frame to the last fade-from-black frame of a transition, so
## `process_player()` cannot fire a second one out from under the first while the floor swap and
## the placement in the middle of it are still in flight.
var _transitioning := false

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

## Builds `kind`'s floor plan and repaints the scene for it. Called once at boot and again by
## every transition — rebuilding wholesale rather than diffing the two floors, the way
## `City.start_day()` repaints its own ground rather than patching cells, because a floor plan
## this small is cheaper to rebuild than to diff.
func build(kind: int) -> void:
	_ensure_built()
	floor_kind = kind
	_floor = InteriorMap.build(kind)
	if not _tile_set:
		_tile_set = InteriorTileSet.build()
	_ground.tile_set = _tile_set
	_ground.clear()
	for tile: Vector2i in _floor.tiles:
		var source := InteriorTileSet.source_id_for(_floor.tiles[tile])
		if source >= 0:
			_ground.set_cell(tile, source, Vector2i.ZERO)
	_rebuild_walls()
	_rebuild_overlays()
	_rebuild_collision()

## One blocker per non-walkable cell in a margin around the floor's own footprint. `queue_free()`
## on the old set rather than reusing bodies — a floor swap is rare enough (one per stairwell
## descent) that rebuilding wholesale costs nothing worth optimising, the same call
## `_rebuild_walls()` and `_rebuild_overlays()` already make.
const _MARGIN := 1
func _rebuild_collision() -> void:
	for child in _collision.get_children():
		child.queue_free()
	for y in range(-_MARGIN, InteriorMap.HALLWAY_ROWS + 3 + _MARGIN):
		for x in range(-_MARGIN, InteriorMap.HALLWAY_LENGTH + _MARGIN):
			var tile := Vector2i(x, y)
			if _floor.tiles.has(tile):
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
	for column: int in _floor.north_wall:
		var kind: InteriorTile.Kind = _floor.north_wall[column]
		var texture := _wall_texture(kind)
		if not texture:
			continue
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.offset = Vector2(-TILE * 0.5, -texture.get_height())
		sprite.position = Vector2((column + 0.5) * TILE, 0.0)
		_walls.add_child(sprite)
	if _floor.entrance_column >= 0:
		var barricade := Sprite2D.new()
		barricade.texture = ENTRANCE_BARRICADE_TEXTURE
		barricade.centered = false
		barricade.offset = Vector2(-ENTRANCE_BARRICADE_TEXTURE.get_width() * 0.5,
				-ENTRANCE_BARRICADE_TEXTURE.get_height())
		barricade.position = Vector2((_floor.entrance_column + 0.5) * TILE, TILE * 0.5)
		_walls.add_child(barricade)

func _wall_texture(kind: InteriorTile.Kind) -> Texture2D:
	match kind:
		InteriorTile.Kind.WINDOW:
			return HALLWAY_WINDOW
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

## Doors, rails, newels, the chandelier and the basement's puddles — everything that stands above
## the floor rather than being the floor, all in the y-sorted layer the player joins through
## `add_entity()`.
func _rebuild_overlays() -> void:
	for child in _entities.get_children():
		child.queue_free()
	for sw in _floor.stairwells:
		_add_standing(sw.door_tile, STAIRWELL_DOOR_TEXTURE)
		if sw.has_flights():
			_add_rails(sw)
	if _floor.exit_tile.x >= 0:
		_add_standing(_floor.exit_tile, EMERGENCY_EXIT_TEXTURE)
	for tile in _floor.puddle_tiles:
		var puddle := Sprite2D.new()
		puddle.texture = PUDDLE_TEXTURE
		puddle.position = tile_to_world(tile)
		_entities.add_child(puddle)
	if floor_kind != InteriorMap.FloorKind.BASEMENT:
		var chandelier := Sprite2D.new()
		chandelier.texture = CHANDELIER_TEXTURE
		chandelier.centered = false
		chandelier.offset = Vector2(-CHANDELIER_TEXTURE.get_width() * 0.5,
				-CHANDELIER_TEXTURE.get_height())
		chandelier.position = tile_to_world(Vector2i(InteriorMap.HALLWAY_LENGTH / 2, 0))
		_entities.add_child(chandelier)

## A bottom-centre-anchored standing sprite at a tile's own centre — a door threshold, drawn the
## same way `Sprites.draw_standing()` draws every other feet-anchored actor.
func _add_standing(tile: Vector2i, texture: Texture2D) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
	sprite.position = tile_to_world(tile)
	_entities.add_child(sprite)

## Rails over both flights and both landings, and a newel at each of the two turn corners.
##
## Each rail's y-sort key is pinned to its tile's own **south edge** rather than its centre, so a
## walker standing anywhere in that tile's row — her feet somewhere between the row's north and
## south edge — sorts behind it: the key the rail competes with is always the far edge of her own
## row, never the near one, which is what keeps her reading as walking *behind* the rail rather
## than sometimes in front of it depending on where in the tile she stands.
func _add_rails(sw: InteriorFloor.Stairwell) -> void:
	var door_col := sw.door_tile.x
	var dir := 1 if sw.side == "left" else -1
	var row_door := sw.door_tile.y
	var row_lower := sw.lower_landing_tile.y
	var turn_col := door_col + dir * 4
	var rail_down := RAIL_E if dir > 0 else RAIL_W
	var rail_back := RAIL_W if dir > 0 else RAIL_E
	for i in range(1, 4):
		_add_rail(Vector2i(door_col + dir * i, row_door), rail_down)
	_add_rail(Vector2i(turn_col, row_door), RAIL_LEVEL)
	for i in range(1, 4):
		_add_rail(Vector2i(turn_col - dir * i, row_lower), rail_back)
	_add_rail(Vector2i(door_col, row_lower), RAIL_LEVEL)
	_add_newel(Vector2i(turn_col, row_door))
	_add_newel(Vector2i(door_col, row_lower))

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
	return _floor.is_walkable(tile)

## Where a fresh run starts — the third floor's own door, mid-hallway on its south edge.
func start_world_position() -> Vector2:
	return tile_to_world(_floor.start_tile)

## Roughly the building's own footprint, plus a tile of margin — the outdoor city's
## `camera_bounds()` grows the map by a border band for the same reason: so panning does not read
## as hitting a wall exactly at the last walkable tile.
func camera_bounds() -> Rect2:
	return Rect2(Vector2.ONE * -TILE,
			Vector2(InteriorMap.HALLWAY_LENGTH + 2, InteriorMap.HALLWAY_ROWS + 5) * TILE)

## Joins the y-sorted layer everything standing in this scene lives on.
func add_entity(node: Node) -> void:
	_entities.add_child(node)

# ------------------------------------------------------------------ transitions ---

## Whether `tile` is a transition trigger on the current floor, and what it leads to. Factored out
## from `process_player()` so a test can ask the exact question the running game asks every frame
## without also waiting on the fade this class owns — see `tests/test_interior.gd`.
func transition_at(tile: Vector2i) -> Dictionary:
	for sw in _floor.stairwells:
		if sw.has_flights() and tile == sw.lower_landing_tile:
			return {"kind": "floor", "side": sw.side}
	if _floor.exit_tile.x >= 0 and tile == _floor.exit_tile:
		return {"kind": "exit"}
	return {}

## Called every frame by `main._process()` while the escape scene is running. Reads `player`'s own
## tile rather than being told about it, the same way `EventInstance` and `CrowdAgent` ask the
## world about her rather than being pushed a position — there is exactly one caller, but the
## question is "what is on this ground", not "what did somebody just do".
func process_player(player: Node2D, delta: float) -> void:
	if _transitioning:
		return
	var result := transition_at(world_to_tile(player.global_position))
	if result.is_empty():
		return
	if result["kind"] == "floor":
		_start_floor_transition(result["side"], player)
	else:
		_start_exit()

func _start_floor_transition(side: String, player: Node2D) -> void:
	_transitioning = true
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, FADE_SECONDS)
	tween.tween_callback(func() -> void: go_to_floor(InteriorMap.floor_below(floor_kind), side, player))
	tween.tween_property(_fade_rect, "modulate:a", 0.0, FADE_SECONDS)
	tween.tween_callback(func() -> void: _transitioning = false)

func _start_exit() -> void:
	_transitioning = true
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, FADE_SECONDS)
	tween.tween_callback(func() -> void: exit_requested.emit())

## Rebuilds for `kind` and places `player` on that floor's `side` stairwell, at its own door — "the
## upper landing at its door", in the TODO's own words. Exposed rather than kept behind the tween
## above, so a test can drive the same floor-swap and placement code the running game uses without
## also driving the fade's timing — see `transition_at()`'s own doc for the same reasoning.
##
## Facing chosen as north, toward the hallway she would walk into next: arbitrary, and open to
## revisit once the scene is actually played rather than stepped.
func go_to_floor(kind: int, side: String, player: Node2D) -> void:
	build(kind)
	var sw := _floor.stairwell(side)
	player.global_position = tile_to_world(sw.door_tile)
	if player is Stroller:
		(player as Stroller).facing = Vector2.UP

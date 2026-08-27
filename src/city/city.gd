class_name City
extends WorldContext
## Turns a CityMap into a scene: ground, buildings, props, boundary, and the answers the
## baby needs about the ground it is standing on.
##
## Ground is drawn by this node itself, so it lands behind the y-sorted `Entities` child
## without needing a z_index fight.

## Wall height per district, in whole tiles. Heights are quantised because the facade is
## assembled from 32px tiles now; a float height would mean a stretched tile. Clamped
## against the lot depth so a roof always shows.
const _HEIGHT_TILES := {
	GameEnums.BlockPurpose.RESIDENTIAL: Vector2i(2, 3),
	GameEnums.BlockPurpose.COURTYARD: Vector2i(2, 3),
	GameEnums.BlockPurpose.COMMERCIAL: Vector2i(2, 3),
	GameEnums.BlockPurpose.INDUSTRIAL: Vector2i(1, 2),
	GameEnums.BlockPurpose.CIVIC: Vector2i(3, 4),
	GameEnums.BlockPurpose.PARK: Vector2i(1, 1),
	GameEnums.BlockPurpose.FOREST: Vector2i(1, 1),
	GameEnums.BlockPurpose.QUIET_SQUARE: Vector2i(1, 1),
}
## A building never takes more than this share of its lot depth, so a roof remains.
const MAX_HEIGHT_FRACTION := 0.55
const BOUNDARY_THICKNESS := 64.0

## Trees per block, by what the block currently is. A forest is a park with more trees in it
## and no swings, which is most of what the difference between them is on the ground.
const _TREES := {
	GameEnums.BlockPurpose.PARK: 10,
	GameEnums.BlockPurpose.FOREST: 22,
	GameEnums.BlockPurpose.QUIET_SQUARE: 4,
	GameEnums.BlockPurpose.COURTYARD: 3,
}

@onready var _entities: Node2D = $Entities
@onready var _ground: TileMapLayer = $Ground

var map: CityMap
var events: EventManager
var crowd: Crowd
var _daylight: CanvasModulate
var _act := 1
## Rebuilt every day from the block purposes; freed and replaced wholesale.
var _props: Array[Node2D] = []
## Today's closed streets, and the barriers and wreckage that say so. Also rebuilt daily.
var _closures: Array[RoadClosure] = []
var _closure_nodes: Array[Node] = []
## Fixed for the run — only their condition changes.
var _buildings: Array[Building] = []

const DOOR_TEXTURE := preload("res://assets/props/door.svg")

## Everything that is fixed for the whole run. What a block *is* changes day to day, and
## that lives in `start_day()`.
func build(city_map: CityMap) -> void:
	map = city_map
	_paint_ground()
	# Buildings first: the door sits in the wall of the building above the notch, at exactly
	# the same y. A y-sort tie is broken by tree order, so the door has to be added second
	# or the wall draws over it.
	_spawn_buildings()
	_spawn_home()
	_spawn_boundary()
	events = EventManager.new()
	events.name = "Events"
	add_child(events)
	events.setup(self, map)
	crowd = Crowd.new()
	crowd.name = "Crowd"
	add_child(crowd)
	crowd.setup(self, map)
	_daylight = CanvasModulate.new()
	_daylight.name = "Daylight"
	add_child(_daylight)
	set_daylight(1.0)
	queue_redraw()

## Which act's cast the city is under. See Palette.act_tint.
func set_act(act: int) -> void:
	_act = act

## 1.0 at dawn, 0.0 at dusk. The day timer is shown as the light going, with the clock in
## the HUD as the precise version for anyone who wants it.
func set_daylight(fraction: float) -> void:
	if not _daylight:
		return
	var light := Palette.LIGHT_MIDDAY.lerp(Palette.LIGHT_DUSK, 1.0 - fraction)
	var tint := Palette.act_tint(_act)
	_daylight.color = Color(light.r * tint.r, light.g * tint.g, light.b * tint.b)

# ------------------------------------------------------------ WorldContext ---

func is_calm_zone(world_position: Vector2) -> bool:
	return Tile.is_calm(map.tile_type_at_world(world_position)) if map else false

func is_alley(world_position: Vector2) -> bool:
	return Tile.is_alley(map.tile_type_at_world(world_position)) if map else false

## Events and the crowd are the same kind of quantity to the baby, so they simply add. The
## crowd is the floor an ordinary street sits at; the events are what happens on top of it.
func total_excitement_at(world_position: Vector2) -> float:
	var total := 0.0
	if events:
		total += events.total_excitement_at(world_position)
	if crowd:
		total += crowd.total_excitement_at(world_position)
	return total

# ------------------------------------------------------------------ spawning ---

## The front door. A sprite in the y-sorted layer rather than part of the ground, so she
## passes in front of it the way she passes in front of any other wall.
func _spawn_home() -> void:
	var stoop := map.tile_rect_to_world(map.home_rect)
	var door := Sprite2D.new()
	door.texture = DOOR_TEXTURE
	# Feet-anchored like everything else: the NODE sits on the ground plane at the back of
	# the notch and the art is offset upward from there. Putting the node at the sprite's
	# top instead makes y-sort compare the wrong edge, and the building above the doorway
	# wins and hides it.
	door.centered = false
	door.offset = Vector2(-DOOR_TEXTURE.get_width() * 0.5, -DOOR_TEXTURE.get_height())
	door.position = Vector2(stoop.get_center().x, stoop.position.y)
	_entities.add_child(door)

func _spawn_buildings() -> void:
	for rect in map.building_rects:
		var world := map.tile_rect_to_world(rect)
		var building := Building.new()
		# Origin is the south edge centre of the lot (see building.gd).
		building.position = Vector2(world.get_center().x, world.end.y)
		building.footprint = world.size
		building.variant = _variant_for(rect)
		building.height = _height_for(rect, rect.size.y)
		building.lot = rect
		_entities.add_child(building)
		_buildings.append(building)

## The block a lot belongs to.
func _block_of(rect: Rect2i) -> Vector2i:
	return (rect.position - Vector2i.ONE * Tuning.STREET_WIDTH) / CityMap.period()

func _variant_for(rect: Rect2i) -> int:
	return absi(hash("%d:%d:%d" % [map.seed_used, rect.position.x, rect.position.y]))

func _height_for(rect: Rect2i, lot_depth_tiles: int) -> float:
	var range_tiles: Vector2i = _HEIGHT_TILES[map.starting_purpose(_block_of(rect))]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("h:%d:%d:%d" % [map.seed_used, rect.position.x, rect.position.y])
	var tiles := rng.randi_range(range_tiles.x, range_tiles.y)
	# Slivers left beside an alley or a plaza are shallow lots; cap them to a low wall
	# rather than letting the extrusion swallow the whole roof. A one-tile sliver is all
	# wall, which is the one case where there is no roof to protect.
	var cap := maxi(1, mini(lot_depth_tiles - 1,
			floori(lot_depth_tiles * MAX_HEIGHT_FRACTION)))
	return mini(tiles, cap) * float(Tuning.TILE_SIZE)

## The city today. Repaints the ground from the block purposes `state` currently holds,
## then re-dresses it: the props a block has and the condition its buildings are in both
## follow from what the block now is.
##
## This is the per-day half that the old design did not have — the city used to be built
## once and reused, and the between-days screen only had to restart the events. Rebuilding
## the block interiors is cheap (the buildings and the lattice are untouched) and it is the
## only way a requisitioned park can stop having swings in it.
func start_day(state: CityState, day: int, rng: RandomNumberGenerator) -> void:
	map.repaint(state)
	_paint_ground()
	_dress_blocks(state)
	# Last, and after the repaint: which blocks are calm is what the closure invariant is
	# stated over, and a requisitioned park is not one of them.
	_close_streets(day, rng)

## Today's closed streets. The whole street comes out of the network; the barriers stand at
## its two mouths, where they can be seen from the junction rather than found half way down.
func _close_streets(day: int, rng: RandomNumberGenerator) -> void:
	for node in _closure_nodes:
		node.queue_free()
	_closure_nodes.clear()
	_closures = ClosurePlanner.plan_day(map, day, rng)
	map.close_streets(_closures)
	for closure in _closures:
		_spawn_closure(closure)

func closures() -> Array[RoadClosure]:
	return _closures

func _spawn_closure(closure: RoadClosure) -> void:
	for mouth in closure.mouth_centres(map):
		_spawn_barrier(closure, mouth)
	if ClosureMarker.CAUSES.has(closure.kind):
		var cause := ClosureMarker.new()
		cause.piece = ClosureMarker.Piece.CAUSE
		cause.kind = closure.kind
		cause.position = closure.cause_centre(map)
		_add_closure_node(cause, true)

## A line of barrier panels across the mouth, with the sign on the middle one, and one static
## body behind the whole line. The panels are separate nodes so that a barrier running away
## from the camera y-sorts panel by panel against the player; the collision is one box,
## because collision does not care what order things are drawn in.
func _spawn_barrier(closure: RoadClosure, at: Vector2) -> void:
	var across := closure.barrier_runs_across()
	var width := Tuning.STREET_WIDTH * float(Tuning.TILE_SIZE)
	var panels := maxi(1, roundi(width / ClosureMarker.FENCE_ACROSS.get_width()))
	var span := width / panels
	for i in panels:
		var panel := ClosureMarker.new()
		panel.piece = ClosureMarker.Piece.SIGN if i == panels / 2 else ClosureMarker.Piece.FENCE
		panel.kind = closure.kind
		panel.across = across
		panel.span = span
		var offset := -width * 0.5 + span * (i + 0.5)
		panel.position = at + (Vector2(offset, 0.0) if across else Vector2(0.0, offset))
		_add_closure_node(panel, true)

	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(width, Tuning.CLOSURE_BARRIER_DEPTH) if across \
			else Vector2(Tuning.CLOSURE_BARRIER_DEPTH, width)
	shape.shape = box
	body.position = at
	body.add_child(shape)
	_add_closure_node(body, false)

func _add_closure_node(node: Node, y_sorted: bool) -> void:
	_closure_nodes.append(node)
	if y_sorted:
		_entities.add_child(node)
	else:
		add_child(node)

func _dress_blocks(state: CityState) -> void:
	for prop in _props:
		prop.queue_free()
	_props.clear()
	for block: Vector2i in map.block_plans:
		var purpose := state.purpose_of(map.block_plans, block)
		_dress_block(block, purpose)
	for building in _buildings:
		building.condition = _condition_for(
				state.purpose_of(map.block_plans, _block_of(building.lot)))

## What a block's buildings look like now. A boarded-up street and a burnt-out one are the
## same footprints and very different places.
func _condition_for(purpose: GameEnums.BlockPurpose) -> Building.Condition:
	match purpose:
		GameEnums.BlockPurpose.BOARDED_UP:
			return Building.Condition.BOARDED
		GameEnums.BlockPurpose.BURNT_OUT:
			return Building.Condition.BURNT
		_:
			return Building.Condition.LIVED_IN

## Trees and swings, placed from the *city* seed rather than the day's, so a park looks the
## same every morning. A fixed city the player can learn has to include its trees.
func _dress_block(block: Vector2i, purpose: GameEnums.BlockPurpose) -> void:
	var layout: BlockLayout = map.block_layouts.get(block)
	if not layout or not BlockLayout.has(layout.open_rect):
		return
	if purpose == GameEnums.BlockPurpose.PARK and BlockLayout.has(layout.playground):
		var playground := map.tile_rect_to_world(layout.playground)
		var frame := Prop.new()
		frame.kind = Prop.Kind.PLAYGROUND_FRAME
		frame.position = Vector2(playground.get_center().x, playground.end.y - 8.0)
		frame.variant = block.x * 31 + block.y
		_add_prop(frame)

	var wanted: int = _TREES.get(purpose, 0)
	if wanted == 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("props:%d:%d:%d" % [map.seed_used, block.x, block.y])
	var lot := map.tile_rect_to_world(layout.open_rect)
	var placed := 0
	var attempts := 0
	while placed < wanted and attempts < wanted * 8:
		attempts += 1
		var at := Vector2(rng.randf_range(lot.position.x + 16.0, lot.end.x - 16.0),
				rng.randf_range(lot.position.y + 16.0, lot.end.y - 16.0))
		# Keep the playground clear so the swing frame reads.
		if not Tile.is_calm(map.tile_type_at_world(at)):
			continue
		if map.tile_type_at_world(at) == GameEnums.TileType.PLAYGROUND:
			continue
		var tree := Prop.new()
		tree.kind = Prop.Kind.TREE
		tree.position = at
		tree.variant = rng.randi()
		tree.scale_factor = rng.randf_range(0.75, 1.25)
		_add_prop(tree)
		placed += 1

func _add_prop(prop: Node2D) -> void:
	_props.append(prop)
	_entities.add_child(prop)

## Walls just outside the map, so the player cannot walk off the edge of the world.
func _spawn_boundary() -> void:
	var extent := map.world_size()
	var t := BOUNDARY_THICKNESS
	var walls := [
		Rect2(-t, -t, extent.x + t * 2.0, t),
		Rect2(-t, extent.y, extent.x + t * 2.0, t),
		Rect2(-t, 0.0, t, extent.y),
		Rect2(extent.x, 0.0, t, extent.y),
	]
	for wall in walls:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = wall.size
		shape.shape = rectangle
		body.position = wall.get_center()
		body.add_child(shape)
		add_child(body)

## Adds a node to the y-sorted layer, where it will sort against buildings and props.
func add_entity(node: Node) -> void:
	_entities.add_child(node)

# ------------------------------------------------------------------ ground ---

## Paints the ground once from `assets/ground_tileset.tres`.
##
## This used to be ~120 lines of draw_rect and computed dashes. Kerbs, centre lines and
## zebra crossings are authored art now, chosen per cell by GroundTiles — which means they
## can be edited in a drawing program instead of by changing arithmetic, and it is one
## place rather than four.
func _paint_ground() -> void:
	_ground.clear()
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			var source := GroundTiles.source_for(map, tile)
			if source >= 0:
				_ground.set_cell(tile, source, Vector2i.ZERO)

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
	GameEnums.District.RESIDENTIAL: Vector2i(2, 3),
	GameEnums.District.COMMERCIAL: Vector2i(2, 3),
	GameEnums.District.INDUSTRIAL: Vector2i(1, 2),
	GameEnums.District.CIVIC: Vector2i(3, 4),
	GameEnums.District.PARK: Vector2i(1, 1),
}
## A building never takes more than this share of its lot depth, so a roof remains.
const MAX_HEIGHT_FRACTION := 0.55
const BOUNDARY_THICKNESS := 64.0
const TREES_PER_PARK := 10

@onready var _entities: Node2D = $Entities
@onready var _ground: TileMapLayer = $Ground

var map: CityMap
var events: EventManager
var _daylight: CanvasModulate
var _act := 1

const DOOR_TEXTURE := preload("res://assets/props/door.svg")

func build(city_map: CityMap) -> void:
	map = city_map
	_paint_ground()
	# Buildings first: the door sits in the wall of the building above the notch, at exactly
	# the same y. A y-sort tie is broken by tree order, so the door has to be added second
	# or the wall draws over it.
	_spawn_buildings()
	_spawn_home()
	_spawn_park_props()
	_spawn_boundary()
	events = EventManager.new()
	events.name = "Events"
	add_child(events)
	events.setup(self, map)
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

func total_excitement_at(world_position: Vector2) -> float:
	return events.total_excitement_at(world_position) if events else 0.0

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
		_entities.add_child(building)

func _district_of(rect: Rect2i) -> GameEnums.District:
	var block := (rect.position - Vector2i.ONE * Tuning.STREET_WIDTH) / CityMap.period()
	return map.districts.get(block, GameEnums.District.RESIDENTIAL)

func _variant_for(rect: Rect2i) -> int:
	return absi(hash("%d:%d:%d" % [map.seed_used, rect.position.x, rect.position.y]))

func _height_for(rect: Rect2i, lot_depth_tiles: int) -> float:
	var range_tiles: Vector2i = _HEIGHT_TILES[_district_of(rect)]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("h:%d:%d:%d" % [map.seed_used, rect.position.x, rect.position.y])
	var tiles := rng.randi_range(range_tiles.x, range_tiles.y)
	# Slivers left beside an alley or a plaza are shallow lots; cap them to a low wall
	# rather than letting the extrusion swallow the whole roof. A one-tile sliver is all
	# wall, which is the one case where there is no roof to protect.
	var cap := maxi(1, mini(lot_depth_tiles - 1,
			floori(lot_depth_tiles * MAX_HEIGHT_FRACTION)))
	return mini(tiles, cap) * float(Tuning.TILE_SIZE)

func _spawn_park_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("props:%d" % map.seed_used)

	for i in map.playgrounds.size():
		var playground := map.tile_rect_to_world(map.playgrounds[i])
		var frame := Prop.new()
		frame.kind = Prop.Kind.PLAYGROUND_FRAME
		frame.position = Vector2(playground.get_center().x, playground.end.y - 8.0)
		frame.variant = i
		_entities.add_child(frame)

	for block in map.park_blocks:
		var lot := map.tile_rect_to_world(CityMap.block_rect(block))
		var placed := 0
		var attempts := 0
		while placed < TREES_PER_PARK and attempts < TREES_PER_PARK * 8:
			attempts += 1
			var at := Vector2(rng.randf_range(lot.position.x + 16.0, lot.end.x - 16.0),
					rng.randf_range(lot.position.y + 16.0, lot.end.y - 16.0))
			# Keep the playground clear so the swing frame reads.
			if map.tile_type_at_world(at) != GameEnums.TileType.PARK:
				continue
			var tree := Prop.new()
			tree.kind = Prop.Kind.TREE
			tree.position = at
			tree.variant = rng.randi()
			tree.scale_factor = rng.randf_range(0.75, 1.25)
			_entities.add_child(tree)
			placed += 1

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

## Excitement fields go above the ground but below everything that stands on it, so an
## aura never paints over a roof.
func add_aura_layer(node: Node2D) -> void:
	node.z_index = 1
	add_child(node)

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

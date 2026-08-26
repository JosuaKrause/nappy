class_name City
extends WorldContext
## Turns a CityMap into a scene: ground, buildings, props, boundary, and the answers the
## baby needs about the ground it is standing on.
##
## Ground is drawn by this node itself, so it lands behind the y-sorted `Entities` child
## without needing a z_index fight.

## Height range per district, in px. Clamped against the lot depth so a roof always shows.
const _HEIGHTS := {
	GameEnums.District.RESIDENTIAL: Vector2(48.0, 80.0),
	GameEnums.District.COMMERCIAL: Vector2(58.0, 96.0),
	GameEnums.District.INDUSTRIAL: Vector2(34.0, 54.0),
	GameEnums.District.CIVIC: Vector2(88.0, 124.0),
	GameEnums.District.PARK: Vector2(40.0, 40.0),
}
## A building never takes more than this share of its lot depth, so a roof remains.
const MAX_HEIGHT_FRACTION := 0.55
const BOUNDARY_THICKNESS := 64.0
const TREES_PER_PARK := 10

@onready var _entities: Node2D = $Entities

var map: CityMap
var events: EventManager
var _daylight: CanvasModulate
var _act := 1

func build(city_map: CityMap) -> void:
	map = city_map
	_spawn_buildings()
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

func _spawn_buildings() -> void:
	for rect in map.building_rects:
		var world := map.tile_rect_to_world(rect)
		var building := Building.new()
		# Origin is the south edge centre of the lot (see building.gd).
		building.position = Vector2(world.get_center().x, world.end.y)
		building.footprint = world.size
		building.variant = _variant_for(rect)
		building.height = _height_for(rect, world.size.y)
		_entities.add_child(building)

func _district_of(rect: Rect2i) -> GameEnums.District:
	var block := (rect.position - Vector2i.ONE * Tuning.STREET_WIDTH) / CityMap.period()
	return map.districts.get(block, GameEnums.District.RESIDENTIAL)

func _variant_for(rect: Rect2i) -> int:
	return absi(hash("%d:%d:%d" % [map.seed_used, rect.position.x, rect.position.y]))

func _height_for(rect: Rect2i, lot_depth: float) -> float:
	var range_px: Vector2 = _HEIGHTS[_district_of(rect)]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("h:%d:%d:%d" % [map.seed_used, rect.position.x, rect.position.y])
	var height := rng.randf_range(range_px.x, range_px.y)
	# Slivers left beside an alley or a plaza are shallow lots; cap them to a low wall
	# rather than letting the extrusion swallow the whole roof.
	return minf(height, lot_depth * MAX_HEIGHT_FRACTION)

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

# ------------------------------------------------------------------ drawing ---

func _draw() -> void:
	if not map:
		return
	_draw_ground()
	_draw_kerbs()
	_draw_road_markings()
	_draw_crossings()
	_draw_home()

## Merges runs of identical tiles along each row into single rects. A 104x104 map is
## ~10k tiles; run-merging cuts that to a few hundred draw calls. `_draw` is only re-run
## on queue_redraw(), so this cost is paid once.
func _draw_ground() -> void:
	var tile_px := float(Tuning.TILE_SIZE)
	for y in map.size.y:
		var run_start := 0
		var run_type := map.tile_at(Vector2i(0, y))
		for x in range(1, map.size.x + 1):
			var same := x < map.size.x and map.tile_at(Vector2i(x, y)) == run_type
			if same:
				continue
			draw_rect(Rect2(run_start * tile_px, y * tile_px, (x - run_start) * tile_px, tile_px),
					Tile.ground_colour(run_type))
			if x < map.size.x:
				run_start = x
				run_type = map.tile_at(Vector2i(x, y))

func _draw_road_markings() -> void:
	var dash := 16.0
	var gap := 14.0
	var period := CityMap.period()
	var extent := map.world_size()
	# The centre line runs along the seam between the two road tiles of each corridor.
	var centre_offset := float(Tuning.STREET_WIDTH) * 0.5 * Tuning.TILE_SIZE

	for corridor in Tuning.CITY_BLOCKS.x + 1:
		var x := corridor * period * Tuning.TILE_SIZE + centre_offset
		_dashed_line(Vector2(x, 0.0), Vector2(x, extent.y), dash, gap)
	for corridor in Tuning.CITY_BLOCKS.y + 1:
		var y := corridor * period * Tuning.TILE_SIZE + centre_offset
		_dashed_line(Vector2(0.0, y), Vector2(extent.x, y), dash, gap)

func _dashed_line(from: Vector2, to: Vector2, dash: float, gap: float) -> void:
	var direction := (to - from).normalized()
	var length := from.distance_to(to)
	var travelled := 0.0
	while travelled < length:
		var end := minf(travelled + dash, length)
		var a := from + direction * travelled
		var b := from + direction * end
		# Skip the stretch inside an intersection, where a centre line makes no sense.
		if map.tile_type_at_world((a + b) * 0.5) == GameEnums.TileType.ROAD:
			draw_line(a, b, Palette.ROAD_MARKING, 2.0)
		travelled += dash + gap

## The seam between the sidewalk and the road, drawn only alongside blocks — a kerb line
## through an intersection would be a kerb across the mouth of the junction.
func _draw_kerbs() -> void:
	var tile_px := float(Tuning.TILE_SIZE)
	var period := CityMap.period()
	var near := Tuning.SIDEWALK_WIDTH * tile_px
	var far := (Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH) * tile_px

	for corridor in Tuning.CITY_BLOCKS.x + 1:
		var base_x := corridor * period * tile_px
		for row in Tuning.CITY_BLOCKS.y:
			var span := map.tile_rect_to_world(CityMap.block_rect(Vector2i(0, row)))
			for offset in [near, far]:
				draw_line(Vector2(base_x + offset, span.position.y),
						Vector2(base_x + offset, span.end.y), Palette.KERB, 2.0)

	for corridor in Tuning.CITY_BLOCKS.y + 1:
		var base_y := corridor * period * tile_px
		for column in Tuning.CITY_BLOCKS.x:
			var span := map.tile_rect_to_world(CityMap.block_rect(Vector2i(column, 0)))
			for offset in [near, far]:
				draw_line(Vector2(span.position.x, base_y + offset),
						Vector2(span.end.x, base_y + offset), Palette.KERB, 2.0)

## Zebra stripes, spaced across the whole 2-tile crossing patch rather than repeated within
## every tile — per-tile stripes turned every junction into visual static.
const _STRIPE_SPACING := 16.0
const _STRIPE_WIDTH := 7.0

func _draw_crossings() -> void:
	var tile_px := float(Tuning.TILE_SIZE)
	for y in map.size.y:
		for x in map.size.x:
			if map.tile_at(Vector2i(x, y)) != GameEnums.TileType.CROSSING:
				continue
			# Stripes lie across the direction of traffic, so the road axis decides them:
			# a crossing over a north-south road gets stripes running east-west.
			var vertical_road := Tile.is_road(map.tile_at(Vector2i(x, y - 1))) \
					or Tile.is_road(map.tile_at(Vector2i(x, y + 1)))
			var origin := Vector2(x, y) * tile_px
			var count := int(tile_px / _STRIPE_SPACING)
			for i in count:
				# Phase from the absolute tile position, so stripes line up across the
				# tiles of one patch instead of restarting in each.
				var along := fposmod(float(i) * _STRIPE_SPACING
						+ (origin.y if vertical_road else origin.x), tile_px)
				# Full tile width across, with no inset: a crossing patch is two tiles
				# wide, and insetting each one split every stripe down the middle.
				if vertical_road:
					draw_rect(Rect2(origin + Vector2(0.0, along),
							Vector2(tile_px, _STRIPE_WIDTH)), Palette.CROSSING_STRIPE)
				else:
					draw_rect(Rect2(origin + Vector2(along, 0.0),
							Vector2(_STRIPE_WIDTH, tile_px)), Palette.CROSSING_STRIPE)

func _draw_home() -> void:
	var home := map.tile_rect_to_world(map.home_rect)
	draw_rect(home, Palette.HOME_STOOP)
	var door := Rect2(home.get_center().x - 11.0, home.end.y - 26.0, 22.0, 26.0)
	draw_rect(door, Palette.HOME_DOOR)
	draw_rect(door, Palette.OUTLINE, false, 1.5)

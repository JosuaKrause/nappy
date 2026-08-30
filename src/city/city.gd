class_name City
extends WorldContext
## Turns a CityMap into a scene: ground, buildings, props, boundary, and the answers the
## baby needs about the ground it is standing on.
##
## Ground is drawn by this node itself, so it lands behind the y-sorted `Entities` child
## without needing a z_index fight.
##
## **Buildings are a layer of their own, underneath the entities.** *(M37, playtest 07 finding 4:
## "the warning indicators render below roofs".)* A `Building`'s origin is the south edge of its
## lot and its drawn mass extends a whole block north of there, so y-sorting against it draws it
## in front of everything on the pavement running up the side of that block — which shows
## wherever the two also overlap in x, and that is anything wider than the 16px from a tile
## centre to the lot edge: a lorry always, a person never, and the player and every cue over her
## head whenever she hugs a frontage.
##
## The fix is not a better comparison, it is that **the comparison is meaningless**: buildings
## tile their lots exactly and no lot tile is walkable (`tests/test_generator.gd` asserts both),
## so nothing can ever legitimately stand behind one. Two things that can never be on opposite
## sides of each other have no business being sorted against each other.

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
## How deep the ring of frontages outside the map is, in tiles. A block, so the far side of a
## boundary street is the same depth of building as both sides of every other street.
const OUTSIDE_DEPTH_TILES := Tuning.BLOCK_SIZE

## Trees per *block* of open ground, by what the block currently is. A forest is a park with
## more trees in it and no swings, which is most of what the difference between them is on the
## ground.
##
## Per block rather than per lot since M21: a four-block calm zone is seven and a half blocks'
## worth of ground once the absorbed streets are counted, and ten trees spread over that is a
## field with some shrubs in it rather than a park. `_dress_block` scales by the lot's area.
const _TREES := {
	GameEnums.BlockPurpose.PARK: 10,
	GameEnums.BlockPurpose.FOREST: 22,
	GameEnums.BlockPurpose.QUIET_SQUARE: 4,
	GameEnums.BlockPurpose.COURTYARD: 3,
}

@onready var _entities: Node2D = $Entities
@onready var _buildings_layer: Node2D = $Buildings
@onready var _ground: TileMapLayer = $Ground

var map: CityMap
var events: EventManager
var crowd: Crowd
## The lights on the spine. Held here because both the traffic and the signal heads read it, and
## advanced by `Crowd`, which is the thing a rig steps — see `Crowd.step()`.
var signals: TrafficSignals
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
	_spawn_the_edge_of_the_city()
	signals = TrafficSignals.new(map)
	_spawn_signal_heads()
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

## What the ground she is standing on does to her recovery: calm, precinct, ordinary, main road,
## best to worst. *(M41, playtest 12 finding 8.)*
##
## A precinct beats a main road even where the two cross, and that is not an oversight: standing
## on brick is standing on brick, and the tile she is on is the whole of what this question is
## about. A main road's *pavement* is main road, though — the thing that makes it bad ground is
## the road beside it, not the surface under her.
func decay_multiplier(world_position: Vector2) -> float:
	if not map:
		return 1.0
	if Tile.is_calm(map.tile_type_at_world(world_position)):
		return Tuning.EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER
	var tile := map.world_to_tile(world_position)
	var across := map.street_kind_at(true, tile)
	var along := map.street_kind_at(false, tile)
	if across == GameEnums.StreetKind.PEDESTRIAN or along == GameEnums.StreetKind.PEDESTRIAN:
		return Tuning.EXCITEMENT_DECAY_PRECINCT_MULTIPLIER
	if across == GameEnums.StreetKind.MAIN or along == GameEnums.StreetKind.MAIN:
		return Tuning.EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER
	return 1.0

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
	# top instead makes y-sort compare the wrong edge, and the player walks in front of a
	# door she is standing north of. *(It used to be the building above the doorway that won
	# and hid it; since M37 a building cannot occlude anything in this layer at all.)*
	door.centered = false
	door.offset = Vector2(-DOOR_TEXTURE.get_width() * 0.5, -DOOR_TEXTURE.get_height())
	door.position = Vector2(stoop.get_center().x, stoop.position.y)
	_entities.add_child(door)

## What is on the far side of the streets that run along the boundary. *(M41.)*
##
## **The lattice already ends in T-junctions and nobody could see it.** The outermost corridor on
## each side is a whole street — pavement, carriageway, pavement — and every interior street runs
## into it and stops, which is exactly what a T is. What was missing is the other half of the
## street: there was nothing beyond its far pavement, so the edge of the map read as a road with a
## void along one side, and an interior street reaching it read as being *cut off* rather than as
## turning. A row of frontages is the whole fix, and it is the cheapest thing in this milestone.
##
## Art and nothing else: these buildings are outside the map, so no tile, no route and no event
## can ever reach them. They are deliberately kept out of `_buildings`, which is the list whose
## condition follows a block's arc — an outside lot has no block and no arc, and a burnt-out
## frontage across a boundary the player cannot cross would be a story about nothing.
##
## The gaps in the row are where the corridors meet the boundary, so the two exits below need no
## exception carved for them: the spine reaches the edge through a gap that is already there.
func _spawn_the_edge_of_the_city() -> void:
	var depth := OUTSIDE_DEPTH_TILES
	for bx in Tuning.CITY_BLOCKS.x:
		var span := CityMap.block_rect(Vector2i(bx, 0))
		_spawn_outside_frontage(Rect2i(Vector2i(span.position.x, -depth),
				Vector2i(span.size.x, depth)))
		_spawn_outside_frontage(Rect2i(Vector2i(span.position.x, map.size.y),
				Vector2i(span.size.x, depth)))
	for by in Tuning.CITY_BLOCKS.y:
		var span := CityMap.block_rect(Vector2i(0, by))
		_spawn_outside_frontage(Rect2i(Vector2i(-depth, span.position.y),
				Vector2i(depth, span.size.y)))
		_spawn_outside_frontage(Rect2i(Vector2i(map.size.x, span.position.y),
				Vector2i(depth, span.size.y)))
	# And the four corners, so the ring has no notch in it where two frontages nearly meet.
	for corner in [Vector2i(-depth, -depth), Vector2i(map.size.x, -depth),
			Vector2i(-depth, map.size.y), Vector2i(map.size.x, map.size.y)]:
		_spawn_outside_frontage(Rect2i(corner as Vector2i, Vector2i.ONE * depth))
	_spawn_spine_exits()

func _spawn_outside_frontage(lot: Rect2i) -> void:
	var world := map.tile_rect_to_world(lot)
	var building := Building.new()
	building.position = Vector2(world.get_center().x, world.end.y)
	building.footprint = world.size
	building.variant = _variant_for(lot)
	# Two or three storeys, the residential range, rolled the same way every other lot is. A
	# skyline that stops being a skyline at the boundary is the thing this is here to prevent.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("edge:%d:%d:%d" % [map.seed_used, lot.position.x, lot.position.y])
	building.height = rng.randi_range(2, 3) * float(Tuning.TILE_SIZE)
	building.lot = lot
	_buildings_layer.add_child(building)

## The four ways the spine leaves: a tunnel north, a bridge south, and the east-west main road
## simply carrying on — *"the side-to-side main road just going towards east/west in one space"*.
##
## Each one fills the gap its own corridor leaves in the ring of frontages, which is the whole
## reason they have to exist at all rather than being left as bare road: the camera can see past
## the boundary now, and a gap with nothing in it is the invisible wall back again with a picture
## either side of it.
func _spawn_spine_exits() -> void:
	var extent := map.world_size()
	var down := (map.main_road * CityMap.period()
			+ Tuning.STREET_WIDTH * 0.5) * float(Tuning.TILE_SIZE)
	var across := (CrowdLanes.arterial_index(Tuning.CITY_BLOCKS.y) * CityMap.period()
			+ Tuning.STREET_WIDTH * 0.5) * float(Tuning.TILE_SIZE)
	_spawn_exit(CityEdge.Kind.TUNNEL, Vector2(down, 0.0))
	_spawn_exit(CityEdge.Kind.BRIDGE, Vector2(down, extent.y))
	_spawn_exit(CityEdge.Kind.ROAD_EAST, Vector2(extent.x, across))
	_spawn_exit(CityEdge.Kind.ROAD_WEST, Vector2(0.0, across))

func _spawn_exit(kind: CityEdge.Kind, at: Vector2) -> void:
	var exit := CityEdge.new()
	exit.kind = kind
	exit.position = at
	if exit.occludes():
		_entities.add_child(exit)
	else:
		_buildings_layer.add_child(exit)

## A signal head on every arm of every junction the spine passes through.
##
## Four per junction rather than one. A single light in the middle of a crossroads would be asking
## the reader to work out which arm it means, and from directly above a head has no face to point
## with — so **where it stands is what says which road it is talking about**: each one is on the
## kerb *beside the carriageway it stops*, one junction-mouth back on the approach side and on
## that approach's right, which is where a driver would look for it and where a person waiting to
## cross that road is already standing.
##
## Nineteen junctions of a hundred, so this is seventy-six nodes that redraw two or three times a
## minute each. Fixed for the run: a light is part of the lattice, not part of the day.
func _spawn_signal_heads() -> void:
	var inset := Tuning.TILE_SIZE * 0.5
	var half := Tuning.STREET_WIDTH * float(Tuning.TILE_SIZE) * 0.5
	for x in CrowdLanes.corridor_count(Tuning.CITY_BLOCKS.x):
		for y in CrowdLanes.corridor_count(Tuning.CITY_BLOCKS.y):
			var junction := Vector2i(x, y)
			if not signals.is_signalled(junction):
				continue
			var centre := Vector2(x * CityMap.period() + Tuning.STREET_WIDTH * 0.5,
					y * CityMap.period() + Tuning.STREET_WIDTH * 0.5) * float(Tuning.TILE_SIZE)
			var arms: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
			for heading in arms:
				var right := Vector2(-heading.y, heading.x)
				var at := centre - heading * (half + inset) + right * (half - inset)
				if not map.is_walkable(map.world_to_tile(at)):
					continue
				var light := TrafficLight.new()
				light.junction = junction
				light.faces(heading)
				light.signals = signals
				light.position = at
				_entities.add_child(light)

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
		# Their own layer, under the entities — see the note at the top of this file. They still
		# y-sort against each other, which costs nothing and keeps two lots that share a block
		# boundary stacking the way the eye expects.
		_buildings_layer.add_child(building)
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

	var per_block: int = _TREES.get(purpose, 0)
	if per_block == 0:
		return
	# A block's worth of open ground is the unit the table above is written in, so the count
	# follows the area actually being dressed. Clamped at one block from below rather than
	# scaled down: a courtyard is a quarter of a block and its three trees are what makes it
	# read as a court rather than as a yard, which is a tuned number and not an area.
	var block_area := float(Tuning.BLOCK_SIZE * Tuning.BLOCK_SIZE)
	var lots := maxf(1.0, float(layout.open_rect.size.x * layout.open_rect.size.y) / block_area)
	var wanted := roundi(per_block * lots)
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

## How far the camera may see. The map, plus the ring of frontages outside it. *(M41.)*
##
## It used to be the map exactly, which is the reason the boundary looked like a wall and would
## have gone on looking like one however much was built out there: the camera stopped at the last
## walkable tile, so the far side of a boundary street — and the tunnel the spine leaves by — were
## drawn every frame and never once on screen. She still cannot *walk* past the boundary; what
## changed is that she can see there is something past it.
func camera_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, map.world_size()).grow(
			OUTSIDE_DEPTH_TILES * float(Tuning.TILE_SIZE))

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
	_paint_outside_the_map()

## Ground under the ring of frontages outside the map. *(Playtest 14: "did you do the border yet?
## It's just black.")*
##
## M41 built the ring and `camera_bounds()` opened the camera onto it, and neither put anything
## on the floor out there — the tilemap has only ever been painted over `map.size`, so the
## frontages stood on the clear colour. From inside the city that is a black seam past the last
## kerb; from the boundary street it is most of the far side of the road.
##
## **Painted by continuing the edge outward rather than by choosing an "outside" tile.** The tile
## the map ends on is already the right answer to "what is out there" — pavement behind a
## frontage, carriageway where a corridor runs off the map — so each outside tile clamps to the
## nearest tile *in* the map and takes its picture. The spine's four exits then get their road
## for free, which is the thing that would have needed a special case.
##
## The one substitution is a crossing: zebra stripes repeated eight tiles into the distance are a
## ladder lying in the road, and there is nothing out there to cross to.
func _paint_outside_the_map() -> void:
	var depth := OUTSIDE_DEPTH_TILES
	for y in range(-depth, map.size.y + depth):
		for x in range(-depth, map.size.x + depth):
			if x >= 0 and x < map.size.x and y >= 0 and y < map.size.y:
				continue
			var inside := Vector2i(clampi(x, 0, map.size.x - 1), clampi(y, 0, map.size.y - 1))
			var source := GroundTiles.source_for(map, inside)
			if map.tile_at(inside) == GameEnums.TileType.CROSSING:
				source = GroundTiles.ROAD
			if source >= 0:
				_ground.set_cell(Vector2i(x, y), source, Vector2i.ZERO)

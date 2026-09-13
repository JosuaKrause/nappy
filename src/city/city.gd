class_name City
extends WorldContext
## Turns a CityMap into a scene: ground, buildings, props, boundary, and the answers the
## baby needs about the ground it is standing on.
##
## Ground is drawn by this node itself, so it lands behind the y-sorted `Entities` child
## without needing a z_index fight.
##
## **Buildings are a layer of their own, underneath the entities**, or the warning indicators
## render below roofs. A `Building`'s origin is the south edge of its
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
	# The tallest thing in the city, and it is meant to be: a big building is what a player
	# navigates by. Both ends are above the depth cap on its own lot, so it always renders at
	# the cap — which is the point, rather than an accident to tidy up.
	GameEnums.BlockPurpose.BIG_BUILDING: Vector2i(5, 6),
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

## The layer for the one thing drawn *over* the entities: the dark inside the tunnel, which has to
## land on a car as it drives in. `Entities` is 2 in `city.tscn`; nothing else in the city is
## above it.
const OVERHEAD_Z_INDEX := 3

## Trees per *block* of open ground, by what the block currently is. A forest is a park with
## more trees in it and no swings, which is most of what the difference between them is on the
## ground.
##
## Per block rather than per lot: a four-block calm zone is seven and a half blocks'
## worth of ground once the absorbed streets are counted, and ten trees spread over that is a
## field with some shrubs in it rather than a park. `_dress_block` scales by the lot's area.
const _TREES := {
	GameEnums.BlockPurpose.PARK: 10,
	GameEnums.BlockPurpose.FOREST: 22,
	GameEnums.BlockPurpose.QUIET_SQUARE: 4,
	GameEnums.BlockPurpose.COURTYARD: 3,
}

## Gap between adjacent bollards across a precinct's mouth, in px. Inside the 12-16px range
## that reads as a deliberate line without crowding the 64px carriageway band `bollard_positions`
## spaces them over.
const BOLLARD_SPACING := 14.0

## The least two trees in one lot may stand apart, centre to centre — read off the picture rather
## than asked for. `Prop.TREES` (`tree_a.svg`, `tree_b.svg`) are both drawn 40px wide, and
## `_dress_block` below rolls `scale_factor` as large as 1.25x, so the widest either canopy is ever
## drawn is 50px; two canopies planted any closer than their own width overlap and read as one
## shape rather than as two trees, which is the clump this spacing exists to stop.
const MIN_TREE_SPACING := 40.0 * 1.25

@onready var _entities: Node2D = $Entities
@onready var _buildings_layer: Node2D = $Buildings
@onready var _ground: TileMapLayer = $Ground
@onready var _decals: CityDecals = $Decals

var map: CityMap
var events: EventManager
var crowd: Crowd
## The lights on the spine. Held here because both the traffic and the signal heads read it, and
## advanced by `Crowd`, which is the thing a rig steps — see `Crowd.step()`.
var signals: TrafficSignals
var _daylight: CanvasModulate
var _act := 1
## Today's day number, read by `_paint_ground()` for the crack level `GroundTiles` picks —
## `Tuning.degradation_for(_day)`. 1 (no degradation) until `start_day()` sets it, which happens
## before a player ever sees the city `build()` painted it with.
var _day := 1
## The scene's TileSet is the immutable source for every daily repaint. Reusing the Ground layer's
## current TileSet would feed a prior day's composed grass atlas back into the compositor.
var _authored_ground_tile_set: TileSet
## Rebuilt every day from the block purposes; freed and replaced wholesale.
var _props: Array[Node2D] = []
## Today's corridor: the ways from the doorstep to the calm areas still worth reaching, grown
## before anything is placed. Everything the day sites is sited against **this** tree — the
## closures as walls off it, the events by role, the telemetry picture that says whether any of
## it points anywhere — so it is grown once here rather than three times from the same seed.
var _tree: RouteTree = null
## Today's region wall and doors, grown from `_tree` — permanent partition, per-day split. See
## `RegionPlanner.plan_day` and `region_plan()`.
var _region_plan: RegionPlanner.RegionPlan = null
## Today's closed streets, and the barriers and wreckage that say so. Also rebuilt daily.
var _closures: Array[RoadClosure] = []
var _closure_nodes: Array[Node] = []
## Fixed for the run — only their condition changes.
var _buildings: Array[Building] = []
## Fixed for the run, from `StreetTrees.planted()` — unlike `_props`, never rebuilt daily: a
## street tree is frontage, not a block's own purpose, so it stands whatever the block behind it
## becomes.
var _street_trees: Array[Prop] = []
## The same props, keyed by the pit tile they stand in — what `refresh_street_trees()` looks a
## fallen tree's own pit up in. Keyed by tile rather than by world position because that is what
## the planners hand back, and a float position is not a key.
var _street_tree_pits := {}

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
	_spawn_street_trees()
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

## Whether this is calm ground at all, for the debug overlay and the telemetry. **Not** a
## `WorldContext` question: `Baby` asks `sleepiness_multiplier` instead, because calm ground is a
## rate rather than a kind of place.
func is_calm_zone(world_position: Vector2) -> bool:
	return Tile.is_calm(map.tile_type_at_world(world_position)) if map else false

## How much faster the sleepiness meter fills on this ground.
##
## 1.0 off calm ground, and `Tuning.sleepiness_calm_multiplier` on it — which is a function of **how
## many blocks the lot has**, not of the tile. A single park block and one corner of a four-block
## zone are the same grass, so this is the one ground question that cannot be answered from the tile
## type alone, and that is the reason for the cache below.
func sleepiness_multiplier(world_position: Vector2) -> float:
	if not map:
		return 1.0
	var tile := map.world_to_tile(world_position)
	if tile != _sleepiness_tile:
		_sleepiness_tile = tile
		_sleepiness_answer = _sleepiness_on(tile)
	return _sleepiness_answer

## The last tile this was asked about and what it answered.
##
## **Cached because the question is about a lot and `block_at` is a search.** Every other ground
## question is a tile lookup; this one walks the block list to find which lot the tile belongs to,
## and it is asked every physics frame. She covers a tile in about ten frames at a walk, so caching
## the tile turns a hundred-and-twenty-block scan per frame into one per tile entered.
##
## Cleared at dawn rather than never: `map.repaint` can turn a park into `SPOILED` overnight, and a
## cached answer that outlives the ground it was about is the shape of bug this project keeps
## finding — see `_ground_for`'s note about a cache with a shorter life than its invalidation rule.
var _sleepiness_tile := Vector2i(-1, -1)
var _sleepiness_answer := 1.0

func _sleepiness_on(tile: Vector2i) -> float:
	if not Tile.is_calm(map.tile_at(tile)):
		return 1.0
	return Tuning.sleepiness_calm_multiplier(map.calm_lot_blocks(
			map.block_at(map.tile_to_world(tile))))

## What the ground she is standing on does to her recovery: calm, precinct, ordinary, alley, main
## road, best to worst — and then, for the rest of a day she is carrying the resistance's package,
## worse again.
##
## A precinct beats a main road even where the two cross, and that is not an oversight: standing
## on brick is standing on brick, and the tile she is on is the whole of what this question is
## about. A main road's *pavement* is main road, though — the thing that makes it bad ground is
## the road beside it, not the surface under her.
func decay_multiplier(world_position: Vector2) -> float:
	var ground := _ground_decay_multiplier(world_position)
	if GameState.resistance_carrying_package:
		# The one cost in the game that is not a field at a place: picking the package up makes
		# every street after it dearer for the rest of the day, rather than the street it was
		# picked up on.
		ground *= Tuning.RESISTANCE_PACKAGE_DECAY_MULTIPLIER
	return ground

func _ground_decay_multiplier(world_position: Vector2) -> float:
	if not map:
		return 1.0
	var type := map.tile_type_at_world(world_position)
	if Tile.is_calm(type):
		return Tuning.EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER
	# An alley is cut through a block rather than laid out as a corridor, so no street kind answers
	# for it and it would otherwise read as an ordinary street. It is asked before the corridors
	# for that reason and not by precedence: the two cannot overlap.
	if Tile.is_alley(type):
		return Tuning.EXCITEMENT_DECAY_ALLEY_MULTIPLIER
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

## Events and the crowd are the same kind of quantity to the baby, so they simply concatenate —
## `Baby._update_excitement()` traces each pair back to accumulate_landed() on the body that put
## it there, which is what lets an event's and a crowd body's colour come from the same place.
func excitement_sources_at(world_position: Vector2) -> Array:
	var sources: Array = []
	if events:
		sources.append_array(events.excitement_sources_at(world_position))
	if crowd:
		sources.append_array(crowd.excitement_sources_at(world_position))
	return sources

func total_excitement_at(world_position: Vector2) -> float:
	var total := 0.0
	for pair in excitement_sources_at(world_position):
		total += pair[1]
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
	# door she is standing north of. (Buildings cannot occlude it: they are a layer of their own,
	# underneath the entities.)
	door.centered = false
	door.offset = Vector2(-DOOR_TEXTURE.get_width() * 0.5, -DOOR_TEXTURE.get_height())
	door.position = Vector2(stoop.get_center().x, stoop.position.y)
	_entities.add_child(door)

## `StreetTrees.planted()`'s own positions, drawn as `Prop`s once for the whole run — never
## rebuilt in `_dress_blocks()`, unlike a park's trees, because a street tree belongs to the
## street's own frontage rather than to what the block behind it currently is.
func _spawn_street_trees() -> void:
	var planted_trees := StreetTrees.planted(map)
	_decals.set_street_tree_pits(planted_trees, map)
	for planted_tree in planted_trees:
		var tree := Prop.new()
		tree.kind = Prop.Kind.STREET_TREE
		tree.position = planted_tree.position
		tree.variant = hash(planted_tree.position)
		_entities.add_child(tree)
		_street_trees.append(tree)
		_street_tree_pits[planted_tree.tile] = tree

## Hides the street tree in every pit today's plan emptied, and shows every other one — so the
## tree lying across a closed street is the one missing from the row beside it.
##
## **Called twice a day, and both times are load-bearing.** `start_day` below runs it once the
## closures are planned, which is where a `FALLEN_TREE` closure's own pit is decided; `Main`
## runs it again once `EventManager.start_day` has planned the seals, because a `fallen_tree_seal`
## is chosen later and takes a pit of its own. Reading `CityMap.is_tree_pit_emptied` rather than
## keeping a list here is what lets the second call be a plain refresh rather than a second
## bookkeeping path.
func refresh_street_trees() -> void:
	for tile: Vector2i in _street_tree_pits:
		var tree: Prop = _street_tree_pits[tile]
		tree.visible = not map.is_tree_pit_emptied(tile)
	_decals.refresh_street_tree_pits()

## What is on the far side of the streets that run along the boundary.
##
## **Something has to be**: the outermost corridor is a whole street, every interior street runs
## into it and stops, and with nothing beyond its far pavement the edge reads as a road with a void
## along one side.
##
## **And it may not be a row of buildings.** A frontage out there says *more city, going on for
## ever*, which is the one thing the edge of the map must not say: a city with no end to it has no
## shape, and the boundary wall then has nothing to be.
##
## The land says it instead, and says something different on each side: water to the south, open
## country east and west, a mountain to the north. See `_paint_outside_the_map`, which is the whole
## of the border — it is ground rather than objects, so this function has nothing to do except put
## the exits in.
func _spawn_the_edge_of_the_city() -> void:
	_spawn_spine_exits()

## The two ways the spine leaves: a tunnel under the mountain to the north, a bridge over the water
## to the south.
##
## **Two, and not four.** An east-west exit would be a carriageway running out into a wood, which
## is a road to nowhere now that east and west are a fence, grass and forest — and it would not be
## a main road anyway: there is one spine, it runs north to south, so an east-west exit sits on a
## corridor that is an arterial in no other part of the game.
##
## What makes them worth having: the exits are the last stretch of the spine as it already exists,
## lethal for the same reason every other carriageway is. See `CityEdge` — *the city goes on and
## this is how you would leave it*.
func _spawn_spine_exits() -> void:
	_spawn_exit(CityEdge.Kind.TUNNEL, tunnel_world_position())
	_spawn_exit(CityEdge.Kind.TUNNEL_DARK, tunnel_world_position())
	_spawn_exit(CityEdge.Kind.BRIDGE, bridge_world_position())

## The spine's own centre line, in world space — where both exits are anchored, and the one place
## that arithmetic lives now that the finale asks where the ways out are as well as drawing them.
func _spine_centre_x() -> float:
	return (map.main_road * CityMap.period()
			+ Tuning.STREET_WIDTH * 0.5) * float(Tuning.TILE_SIZE)

## The tunnel mouth, at the north end of the spine.
func tunnel_world_position() -> Vector2:
	return Vector2(_spine_centre_x(), 0.0)

## The bridge deck, at the south end of the spine.
func bridge_world_position() -> Vector2:
	return Vector2(_spine_centre_x(), map.world_size().y)

## The dark inside the tunnel goes in a layer of its own above the entities, so it lands on a car
## as the car drives in; the portal's face is y-sorted with them; the bridge and the road are
## ground and go under them. `CityEdge` says why the dark cannot be y-sorted too.
func _spawn_exit(kind: CityEdge.Kind, at: Vector2) -> void:
	var exit := CityEdge.new()
	exit.kind = kind
	exit.position = at
	if exit.overhangs():
		exit.z_index = OVERHEAD_Z_INDEX
		add_child(exit)
	elif exit.occludes():
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
## **The across-offset is measured from the kerb, not from the corridor's edge**, and that is the
## trap: `half - inset` is 80px from the centre line of a 192px corridor, 2.5 tiles out on a
## pavement that starts at 1.0, so every head stands hard against the **frontage** — the full width
## of the footway away from the road it is talking about, which is a light that has stopped saying
## which road it means. From the kerb it is half the carriageway plus half a tile of pavement, so
## the post stands on the footway rather than in the gutter.
##
## Only the spine's junctions are signalled, so this is a few dozen nodes that redraw two or three
## times a minute each. Fixed for the run: a light is part of the lattice, not part of the day.
func _spawn_signal_heads() -> void:
	var inset := Tuning.TILE_SIZE * 0.5
	var half := Tuning.STREET_WIDTH * float(Tuning.TILE_SIZE) * 0.5
	var kerb := Tuning.carriageway_width() * 0.5 + inset
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
				var at := centre - heading * (half + inset) + right * kerb
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
		building.district = map.starting_purpose(_block_of(rect))
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
	# Before anything reads the ground again: a park that burnt down last night is not calm today.
	_sleepiness_tile = Vector2i(-1, -1)
	_day = day
	_paint_ground()
	_decals.set_placed(Litter.placed(map, day))
	_dress_blocks(state)
	# Last, and after the repaint: which blocks are calm is what the closure invariant is
	# stated over, and a requisitioned park is not one of them.
	_close_streets(day, rng)
	# And after the closures, since a `FALLEN_TREE` closure is what empties a pit. `Main` runs it
	# once more after the day's seals are planned — see `refresh_street_trees()`.
	refresh_street_trees()

## The same city, dressed for the escape: everything `start_day()` does except grow a day's
## corridor and close streets off it.
##
## **The finale's route is not a tree**, so there is nothing here for `RouteTree` to grow and
## nothing for `ClosurePlanner` or `RegionPlanner` to be stated against — one ordered chain to each
## edge, with everything off it sealed, is `FinalePlanner`'s and `SealPlanner`'s work and arrives
## through `EventManager.start_finale()` instead. `route_tree()` and `region_plan()` therefore
## answer `null` for the whole sequence and `closures()` is empty, which is what their own
## contract already says about a `City` whose `start_day` has not run: *only meaningful after
## `start_day`*.
##
## The repaint, the ground, the litter and the block dressing all still happen, because the parks
## she walks through have to be the parks the run's seed built.
func start_finale(state: CityState, day: int) -> void:
	map.repaint(state)
	_sleepiness_tile = Vector2i(-1, -1)
	_day = day
	_paint_ground()
	_decals.set_placed(Litter.placed(map, day))
	_dress_blocks(state)

## Today's closed streets. The whole street comes out of the network; the barriers stand at
## its two mouths, where they can be seen from the junction rather than found half way down.
func _close_streets(day: int, rng: RandomNumberGenerator) -> void:
	for node in _closure_nodes:
		node.queue_free()
	_closure_nodes.clear()
	# Before the closures, because they are placed off it. See `ClosurePlanner._shuffled_candidates`.
	_tree = RouteTree.for_day(map, day)
	# Before the closures too: a closure may not land on a region boundary (wall or door), which
	# `ClosurePlanner.plan_day` needs handed to it rather than recomputing — see its own doc.
	_region_plan = RegionPlanner.plan_day(map, day, _tree)
	Telemetry.note("plan", "regions: %d boundary, %d wall, %d door, calm by region: %s"
			% [_region_plan.walls.size() + _region_plan.doors.size(), _region_plan.walls.size(),
			_region_plan.doors.size(), RegionPlanner.regions_with_calm(map)])
	_closures = ClosurePlanner.plan_day(map, day, rng, _tree, _region_plan)
	map.close_streets(_closures)
	for closure in _closures:
		_spawn_closure(closure)

func closures() -> Array[RoadClosure]:
	return _closures

## Every building this city built, fixed for the run — read by `DebugLayers` so its bounding-box
## layer can trace each one's own `shape` rather than a second list of them.
func buildings() -> Array[Building]:
	return _buildings

## Today's trees, bollards and playground frames (rebuilt daily by `_dress_blocks`), plus the
## street trees fixed for the whole run — read by `DebugLayers` so its shadow layer can trace
## each one's own `shape` the same way, and by `tests/test_blocks.gd`'s spacing check.
func props() -> Array[Node2D]:
	var all: Array[Node2D] = []
	all.append_array(_props)
	all.append_array(_street_trees)
	return all

## Today's corridor. Grown in `_close_streets`, so it is only meaningful after `start_day`.
func route_tree() -> RouteTree:
	return _tree

## Today's region wall and doors. Grown in `_close_streets` from `_tree`, so it is only
## meaningful after `start_day` — the same contract as `route_tree()`.
func region_plan() -> RegionPlanner.RegionPlan:
	return _region_plan

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
	_dress_precincts()
	_place_garbage_sacks()
	for building in _buildings:
		building.condition = _condition_for(
				state.purpose_of(map.block_plans, _block_of(building.lot)))
		building.day = _day

## Today's garbage sacks — `GarbageSacks.placed()` re-rolled from the day, unlike the trees above:
## the city degrades over the run, so unlike a park's planting this is not the same every morning.
## Each is a `Prop` with a `GroundShape` for its shadow and no body, exactly as decorative as a
## bollard.
func _place_garbage_sacks() -> void:
	for entry in GarbageSacks.placed(map, _day):
		var sack := Prop.new()
		sack.kind = Prop.Kind.SACK_PILE if entry.pile else Prop.Kind.SACK
		sack.position = entry.position
		_add_prop(sack)

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
	# Every tree already placed in this lot, so a candidate too close to one of them is rejected
	# the same way one landing off calm ground already is — checked before it is ever added rather
	# than thinned out afterwards, the same rule closures and events are already held to.
	var planted: Array[Vector2] = []
	while placed < wanted and attempts < wanted * 8:
		attempts += 1
		var at := Vector2(rng.randf_range(lot.position.x + 16.0, lot.end.x - 16.0),
				rng.randf_range(lot.position.y + 16.0, lot.end.y - 16.0))
		# Keep the playground clear so the swing frame reads.
		if not Tile.is_calm(map.tile_type_at_world(at)):
			continue
		if map.tile_type_at_world(at) == GameEnums.TileType.PLAYGROUND:
			continue
		if _too_close_to_a_planted_tree(at, planted):
			continue
		var tree := Prop.new()
		tree.kind = Prop.Kind.TREE
		tree.position = at
		tree.variant = rng.randi()
		tree.scale_factor = rng.randf_range(0.75, 1.25)
		_add_prop(tree)
		planted.append(at)
		placed += 1

## Whether `at` lands within `MIN_TREE_SPACING` of a tree this lot has already planted — pulled out
## from the loop above so the spacing rule is one line to read and one line to test.
static func _too_close_to_a_planted_tree(at: Vector2, planted: Array[Vector2]) -> bool:
	for other in planted:
		if at.distance_to(other) < MIN_TREE_SPACING:
			return true
	return false

## A line of posts across the carriageway at each mouth of every precinct, so a street that
## meets one reads as closed on purpose rather than as the road running out. Placed from the map
## alone, with no rng: a closed mouth is geometry, not a roll, so `bollard_positions` needs no
## seed and a test can call it without building a scene.
func _dress_precincts() -> void:
	for at in bollard_positions(map):
		var bollard := Prop.new()
		bollard.kind = Prop.Kind.BOLLARD
		bollard.position = at
		_add_prop(bollard)

## Where the posts across a precinct's mouth stand, in world space. One row on the first tile of
## paving at each end of every span (`CityMap.precinct_spans`), spread across the carriageway
## band only — the middle two tiles of the corridor's `Tuning.STREET_WIDTH` — so the pavements on
## either side stay open for a pram while the road itself reads as stopped.
##
## Static, and stated entirely over `map`: a bollard's position is a fact about the lattice, not
## about the day, so nothing here reaches for a seed the way `_dress_block`'s trees do.
static func bollard_positions(map: CityMap) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var tile := float(Tuning.TILE_SIZE)
	var band_tiles := Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH * 2
	var band_px := band_tiles * tile
	var count := maxi(2, floori(band_px / BOLLARD_SPACING) + 1)
	var margin := (band_px - float(count - 1) * BOLLARD_SPACING) * 0.5
	for span in map.precinct_spans:
		var vertical := span.x == 1
		var corridor: int = span.y
		# The paving now reaches the crossroads' own road edge at each end — the same widened
		# range `CityMap.street_kind()` reads paving from, so a post never stands short of or
		# past where the ground itself changes.
		var lo := span.z * CityMap.period() + Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH
		var hi := (span.w + 1) * CityMap.period() + Tuning.SIDEWALK_WIDTH
		var band_start := (corridor * CityMap.period() + Tuning.SIDEWALK_WIDTH) * tile
		for along_tile: int in [lo, hi - 1]:
			var along_px := (along_tile + 0.5) * tile
			for i in count:
				var across_px := band_start + margin + i * BOLLARD_SPACING
				positions.append(Vector2(across_px, along_px) if vertical
						else Vector2(along_px, across_px))
	return positions

func _add_prop(prop: Node2D) -> void:
	_props.append(prop)
	_entities.add_child(prop)

## How far the camera may see. The map, plus the band of land painted outside it.
##
## **Not the map exactly**, or the boundary looks like a wall however much is built out there: the
## camera would stop at the last walkable tile, so the far side of a boundary street — and the
## tunnel the spine leaves by — would be drawn every frame and never once on screen. She still
## cannot *walk* past the boundary; she can see that there is something past it.
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
	_ground.tile_set = _ground_tile_set_with_transfers()
	_ground.clear()
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			var source := GroundTiles.source_for(map, tile, _day)
			if source >= 0:
				_ground.set_cell(tile, source,
						GroundLayers.atlas_coords_for(source, map.seed_used, tile, _ground.tile_set))
	_paint_outside_the_map()

## Starts each repaint from the scene's authored TileSet, so transfer fallback and ground composition
## remain stable when a new day chooses different damage or grass cells.
func _ground_tile_set_with_transfers() -> TileSet:
	if _authored_ground_tile_set == null:
		_authored_ground_tile_set = _ground.tile_set
	return GroundLayers.build_tile_set(_authored_ground_tile_set)

## What the city stops at, on each of its four sides.
##
## The tilemap is painted over `map.size` and no further, so without this everything the camera can
## see outside the map stands on the clear colour. Painting it by continuing the edge outward cures
## the black and leaves the wrong answer standing: more city, receding into a camera limit, on
## every side.
##
## **The border is the land, and each side says a different thing about why the city ends:**
##
## - **South — a bulkhead, then open water.** The southern boundary street is already the *shore*
##   (`CityGenerator._place_precincts` puts a promenade there and says so), and this is the half of
##   that sentence the ground was never told. No buildings: the one course of stone is the edge.
## - **East and west — a fence, then grass going into forest.** The city runs out into open
##   country rather than stopping at anything, which is why the fence is palings and not a wall:
##   it has to say *the city ends here* without saying *you are shut in*.
## - **North — scree, then the mountainside.** The one side that is a wall, and it should read as
##   one: the city backs onto rock.
##
## **Two exceptions, and they are the whole reason the exits exist.** The spine leaves by a tunnel
## north and a bridge south, so at the spine's own width the carriageway carries on through the
## border instead of being buried in it — see `_spawn_spine_exits`, and `CityEdge._swallow_the_road`
## for the road going into the dark. Take the exceptions away and `CityEdge`'s whole sentence — *the
## city goes on and this is how you would leave it* — is a tunnel mouth set into a cliff with no
## road reaching it. **The two exceptions are not the same depth.** The bridge carries the road the
## whole width of the band, because a deck is in the open; the tunnel carries it only as far as the
## portal's opening (`CityEdge.TUNNEL_DEPTH_TILES`), because past the mouth the road is inside the
## mountain and what is on top of it is rock.
##
## Nothing here is walkable and none of it has a `GameEnums.TileType`: this paints the **tilemap**
## and `CityMap` is untouched, so the walkable set and every guarantee stated over it are identical
## tile for tile. The boundary wall is still what stops her.
func _paint_outside_the_map() -> void:
	var depth := OUTSIDE_DEPTH_TILES
	for y in range(-depth, map.size.y + depth):
		for x in range(-depth, map.size.x + depth):
			if x >= 0 and x < map.size.x and y >= 0 and y < map.size.y:
				continue
			var source := _border_source(x, y, depth)
			if source >= 0:
				var tile := Vector2i(x, y)
				_ground.set_cell(tile, source,
						GroundLayers.atlas_coords_for(source, map.seed_used, tile, _ground.tile_set))

## Which border tile belongs at an outside cell. Each side is written as *what you meet, in order,
## walking away from the last kerb*, and how far out of the city a tile is is what indexes it.
##
## **The north and south bands own the corners outright, and each one keeps its own step.**
##
## **Giving a corner to whichever side it is further out of is the trap.** It reads as reasonable
## and it is a diagonal: *further out of* is a comparison between two distances, and the place where
## two distances are equal is a 45° line, so every corner of the map grows a stepped seam with
## mountain on one side and forest on the other. Nothing out there makes sense of a diagonal — there
## is no cliff face, no coastline and no reason for the woods to end at an angle.
##
## So **a band runs the full width of the map**, and the east and west bands are what is left in
## between. A mountain that carries on past the last street is a mountain; a fence that stops where
## the scree starts is a fence meeting a hillside, which is what a fence does. What this cannot do,
## and deliberately does not, is anything *at* the corner: no headland, no bay, no new terrain.
##
## The order below is the whole rule. North first, then south, then whatever is left.
func _border_source(x: int, y: int, depth: int) -> int:
	var north := -y
	var south := y - (map.size.y - 1)
	var west := -x
	var east := x - (map.size.x - 1)

	if _leaves_by_the_spine(x):
		var on_to_the_bridge := south > 0 and south <= depth
		var into_the_tunnel := north > 0 and north <= CityEdge.TUNNEL_DEPTH_TILES
		if on_to_the_bridge or into_the_tunnel:
			return GroundTiles.source_for(map, Vector2i(x, clampi(y, 0, map.size.y - 1)), _day)
	if north > 0:
		return GroundTiles.SCREE if north == 1 else GroundTiles.MOUNTAIN
	if south > 0:
		return GroundTiles.BULKHEAD if south == 1 else GroundTiles.WATER
	var out := maxi(west, east)
	if out == 1:
		return GroundTiles.FENCE
	return GroundTiles.GRASS if out <= 3 else GroundTiles.FOREST

## Whether this column is the carriageway of the spine, which is the one thing that crosses the
## border rather than stopping at it. The kerbs either side stop with the city: a pavement running
## into a tunnel would be an invitation, and what is out there is lethal by design.
func _leaves_by_the_spine(x: int) -> bool:
	var offset := x - map.main_road * CityMap.period()
	return offset >= Tuning.SIDEWALK_WIDTH \
			and offset < Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH

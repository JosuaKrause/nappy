class_name City
extends WorldContext
## Turns a CityMap into a scene: ground, buildings, props, boundary, and the answers the
## baby needs about the ground it is standing on.
##
## The `Ground` child owns the freeable ground chunks and draws them behind the y-sorted `Entities`
## child without needing a z_index fight.
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
## and a building's drawing stays inside its own lot, so nothing can ever legitimately stand
## behind one. Two things that can never be on opposite sides of each other have no business
## being sorted against each other.
##
## **Roof equipment and the power station's two stacks are the exceptions.** Their pictures may
## rise north of their roof footprints and into a street where she can stand behind them. Each is
## therefore a feet-anchored `Building.RoofObject` or `Building.StationStack` in `Entities`, sorting
## against her like any other entity: drawn over whatever stands north of its foot and under
## whatever stands south of it.

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
## Wall rows the door's own home-block building always gets — fixed rather than rolled
## (`docs/DECISIONS.md`, M185, a ground floor is blank wall or shops), so the block looks the same
## on every seed. The ground floor is row 0, so four rows reach the third floor, where she lives
## and where the escape begins (PLAYTEST-131) — the same floor `Building.neighbor_window_row()`
## boards the neighbor's window on, down the hall from her own door. It sits above the top of the
## screen at the normal camera on her doorstep, since she starts facing away down the street and
## `Stroller._update_camera()`'s own look-ahead leads the view in whatever direction she faces —
## but it does not have to be visible immediately (PLAYTEST-134, statement 4 revisited): turning to
## face the building brings it into frame. `_home_building_height()` does not apply
## `MAX_HEIGHT_FRACTION` to this lot on purpose: four rows of six is more wall than that ratio
## would allow, and what actually keeps a roof showing is `Building.wall_tiles()`'s own hard clamp
## to `rows() - 1`, which this still goes through.
const HOME_BUILDING_WALL_ROWS := 4
## Wall rows every other home-block building (the two lots flanking the door notch) gets, fixed
## the same way. Each lot is only `Tuning.HOME_SIZE_TILES.y` (2) deep, so `Building.wall_tiles()`'s
## own cap (`rows() - 1`) always clamps this down to one row regardless of the value here — the
## constant only has to be something that cap can act on.
const HOME_FLANKING_WALL_ROWS := 2
const BOUNDARY_THICKNESS := 64.0
## How deep the framed border band outside the finite map is, in tiles. The southern bridge's
## road and the unwalkable landscape beneath and beyond that band are drawn wherever the view
## asks for them, the player's camera included.
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
@onready var _ground: SceneryGround = $Ground
@onready var _decals: CityDecals = $Decals
@onready var _building_shadows: BuildingShadows = $BuildingShadows

var map: CityMap
var events: EventManager
var crowd: Crowd
## The lights on the spine. Held here because both the traffic and the signal heads read it, and
## advanced by `Crowd`, which is the thing a rig steps — see `Crowd.step()`.
var signals: TrafficSignals
## The last night's blackout, which puts out every window, light and mast at once. See `Blackout`.
var blackout: Blackout
var _daylight: CanvasModulate
var _act := 1
## Today's day number, read by `_paint_ground()` for the crack level `GroundTiles` picks —
## `Tuning.degradation_for(_day)`. 1 (no degradation) until `start_day()` sets it, which happens
## before a player ever sees the city `build()` painted it with.
var _day := 1
## The scene's TileSet is the immutable source for every daily repaint. Reusing the Ground layer's
## current TileSet would feed a prior day's composed grass atlas back into the compositor.
var _authored_ground_tile_set: TileSet
var scenery: SceneryResidency
var _ground_corridor: Corridor
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
## The posters on the fronts: which cells can carry one and what is pasted on them. Built once
## with the buildings, pasted each dawn. See `PosterWalls`.
var _posters: PosterWalls
## Fixed for the run, from `StreetTrees.planted()` — unlike `_props`, never rebuilt daily: a
## street tree is frontage, not a block's own purpose, so it stands whatever the block behind it
## becomes.
var _street_trees: Array[Prop] = []
## The same props, keyed by the pit tile they stand in — what `refresh_street_trees()` looks a
## fallen tree's own pit up in. Keyed by tile rather than by world position because that is what
## the planners hand back, and a float position is not a key.
var _street_tree_pits := {}

## Region name of the door's own picture in the "decoration" `AtlasLibrary` group.
const DOOR_TEXTURE := &"props/door"
## Region name of her street door once day 10's raid has sealed it — `art/buildings/
## home_door_sealed.svg`, the same 26×34 canvas and feet anchor as `DOOR_TEXTURE` (`docs/
## GRAPHICS.md`), so swapping `_home_door`'s texture needs no change to its offset or position.
const SEALED_DOOR_TEXTURE := &"buildings/home_door_sealed"
## `GameState.scars` id for the sealed street door, recorded at the doorstep by
## `ResistanceHappenings._maybe_raid()` once the raid actually arrives. No `since_day` comparison
## is needed the way `EventScheduler.SILENCED_MAST` reads one: `_spawn_home()` and `start_day()`'s
## `_sync_home_door()` both run after `GameState.begin_day()`'s dawn photograph, so the scar's mere
## presence already answers "sealed as of this dawn" for every day after the one it was added on,
## and the moment it happens on its own day is `seal_home_door()`'s, called live.
const SEALED_DOOR_SCAR := "sealed_door"
## `GameState.scars` id day 3's fire leaves (`EventCatalogue._burning_building()`'s own
## `scar_id`), read by `mark_the_burnt_frontage()` the same way `_door_texture_for_today()` reads
## `SEALED_DOOR_SCAR` above.
const BURNT_FRONTAGE_SCAR := "burnt_shell"
## The street door sprite `_spawn_home()` built, kept so `seal_home_door()` can swap its texture
## live, the moment day 10's raid actually arrives, instead of waiting for a day that never
## rebuilds it — `build()` runs once for the whole run (see the class doc).
var _home_door: HomeDoor

## The sealed/unsealed fact survives unloading; only the Sprite's texture reference is resident.
class HomeDoor extends Sprite2D:
	var scenery_resident := true
	var picture: StringName:
		set(value):
			picture = value
			texture = AtlasLibrary.region(picture) if scenery_resident else null

	func set_scenery_resident(resident: bool) -> void:
		if scenery_resident == resident:
			return
		scenery_resident = resident
		texture = AtlasLibrary.region(picture) if resident else null

	func scenery_bounds() -> Rect2:
		return Rect2(global_position + offset, Vector2(AtlasLibrary.native_size(picture)))

## Everything that is fixed for the whole run. What a block *is* changes day to day, and
## that lives in `start_day()`.
func build(city_map: CityMap) -> void:
	map = city_map
	scenery = SceneryResidency.new()
	scenery.city = self
	add_child(scenery)
	_decals.streamed = true
	_building_shadows.streamed = true
	# The street's decoration, acquired before the first day is drawn. The baked "decoration" page
	# loads synchronously on `acquire()`, so every draw below already has a region to ask for —
	# see `AtlasLibrary`.
	AtlasLibrary.acquire(CityDecals.DECORATION_ATLAS)
	_paint_ground()
	# Buildings first: the door sits in the wall of the building above the notch, at exactly
	# the same y. A y-sort tie is broken by tree order, so the door has to be added second
	# or the wall draws over it.
	_spawn_buildings()
	# Right after the buildings, whose blank ground-floor cells are what it reads. See `PosterWalls`.
	_posters = PosterWalls.new()
	_posters.name = "Posters"
	add_child(_posters)
	_posters.setup(self, map)
	# Footprints are fixed for the run (`docs/DECISIONS.md`, M61); streamed shadow chunks derive
	# their geometry from this source as they become resident.
	var shown_rects: Array[Rect2i] = []
	for footprint in map.building_rects:
		if _recipe_shows_building(footprint):
			shown_rects.append(footprint)
	if map.has_stretch():
		_building_shadows.falls_on = map.in_stretch
	_building_shadows.set_buildings(shown_rects)
	if _recipe_contains(map.home_world_position()):
		_spawn_home()
	_spawn_street_trees()
	_spawn_boundary()
	if map.has_stretch():
		_spawn_the_void_edge()
	elif not map.recipe_exterior:
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
	blackout = Blackout.new()
	blackout.name = "Blackout"
	add_child(blackout)
	blackout.setup(self, _buildings)
	_daylight = CanvasModulate.new()
	_daylight.name = "Daylight"
	add_child(_daylight)
	set_daylight(1.0)
	scenery.update(_home_scenery_view(), true)
	queue_redraw()

## Hands the decoration atlas back. `build()`'s `acquire()` is the city's one reference on the
## group, so a city freed without the matching `release()` here would leave the page counted, and
## resident, for a city that no longer exists. The event families are `EventManager`'s own and are
## released by its own `_exit_tree()`.
func _exit_tree() -> void:
	AtlasLibrary.release(CityDecals.DECORATION_ATLAS)

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
##
## **Inside a region door the crowd is off too, and that is the same sentence as the events half.**
## `EventManager.door_holding_her_at()` answers whether this point is inside a running hold; she is
## in the hut for those two seconds, not on the pavement, so the queue outside it charges her no
## more than the street does. Without this the toll would still be the toll plus however busy the
## door happened to be. The events half already answers with the hold's own flat rate alone — see
## `EventManager.excitement_sources_at()` — so all this adds is skipping the concatenation.
func excitement_sources_at(world_position: Vector2) -> Array:
	var sources: Array = []
	if events:
		sources.append_array(events.excitement_sources_at(world_position))
		if events.door_holding_her_at(world_position):
			return sources
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
	_home_door = HomeDoor.new()
	# Sealed already on a boot that resumes on day 11 or later, or reloads a save written after
	# the raid — `_door_texture_for_today()` reads `GameState.scars`, already loaded by the time
	# `main.gd` calls `City.build()`. Day 10 itself is `seal_home_door()`'s, called live the
	# moment the raid actually arrives.
	_home_door.picture = _door_texture_for_today()
	# Feet-anchored like everything else: the NODE sits on the ground plane at the back of
	# the notch and the art is offset upward from there. Putting the node at the sprite's
	# top instead makes y-sort compare the wrong edge, and the player walks in front of a
	# door she is standing north of. (Buildings cannot occlude it: they are a layer of their own,
	# underneath the entities.)
	_home_door.centered = false
	# Both door pictures share one canvas (`SEALED_DOOR_TEXTURE`'s own doc), so this size and
	# offset stay correct whichever one is showing, today or after a live swap.
	var door_size := AtlasLibrary.native_size(DOOR_TEXTURE)
	_home_door.offset = Vector2(-door_size.x * 0.5, -door_size.y)
	# Same centre-x `_door_world_x_range()` hands the building behind it, so the sprite and the
	# blanked window column can never disagree about where the door actually is.
	var x_range := _door_world_x_range()
	_home_door.position = Vector2((x_range.x + x_range.y) * 0.5, stoop.position.y)
	_entities.add_child(_home_door)
	scenery.register(_home_door)

## `SEALED_DOOR_TEXTURE` once the scar it leaves is on record, `DOOR_TEXTURE` before then.
func _door_texture_for_today() -> StringName:
	for scar in GameState.scars:
		if String(scar["id"]) == SEALED_DOOR_SCAR:
			return SEALED_DOOR_TEXTURE
	return DOOR_TEXTURE

## Puts the street door where `GameState.scars` says it belongs, for the dawn `start_day()`
## already runs every day: sealed from day 11 on and after a save/load, ordinary again the dawn a
## lost day 10 gives its own scar back (`GameState._give_back_what_the_attempt_spent()`), since
## `_spawn_home()` itself only ever runs once, at boot, for the whole run.
func _sync_home_door() -> void:
	if _home_door:
		_home_door.picture = _door_texture_for_today()

## Swaps her street door to the sealed picture, live, the moment day 10's raid actually arrives
## (`ResistanceHappenings._maybe_raid()`, while she is out of sight of it) — the one day
## `_sync_home_door()`'s own dawn read is too early for, since the raid has not happened yet when
## it runs.
func seal_home_door() -> void:
	if _home_door:
		_home_door.picture = SEALED_DOOR_TEXTURE

## The door's own world-space x-span, `[min, max)` — `DOOR_TEXTURE`'s native width, centred on
## `map.home_rect` the way `_spawn_home()`'s own sprite is. Read before the door itself exists
## (`_spawn_buildings()` runs first — see `build()`), so it stands on `map.home_rect` and
## `AtlasLibrary` rather than on the door node, and handed to every home-block `Building` so it can
## blank the ground-floor column(s) standing behind the door instead of drawing a window there.
func _door_world_x_range() -> Vector2:
	var centre_x := map.tile_rect_to_world(map.home_rect).get_center().x
	var half_width := AtlasLibrary.native_size(DOOR_TEXTURE).x * 0.5
	return Vector2(centre_x - half_width, centre_x + half_width)

## Boards the neighbor's window for the rest of the run: the third-floor window cell — row index
## 3, ground floor is row 0 — nearest above her own door, on the one home-block `Building` the
## door notch actually stands in front of (`_home_door_building()`). Her own floor, the top one at
## this height, down the hall from her own door. It stands above the top of the screen at the
## normal camera on her doorstep, facing away down the street — turning to face the building
## brings it into frame (PLAYTEST-134, statement 4 revisited). Idempotent, so
## `ResistanceHappenings.start_day()` calling it every day from day 11 on costs nothing once it is
## set. That building always has at least four wall rows (`HOME_BUILDING_WALL_ROWS`), fixed rather
## than rolled, so there is no shorter front here for a topmost row to stand in for it.
func board_neighbor_window() -> void:
	var building := _home_door_building()
	if not building or building.neighbor_window_col >= 0:
		return
	var door_centre_x := (_door_world_x_range().x + _door_world_x_range().y) * 0.5
	var best_col := 0
	var best_distance := INF
	for col in building.columns():
		var distance := absf(building.column_centre_x(col) - door_centre_x)
		if distance < best_distance:
			best_distance = distance
			best_col = col
	building.neighbor_window_col = best_col
	Telemetry.note("contact",
			"the neighbor's window is boarded at column %d, row %d (the third floor)"
			% [best_col, building.neighbor_window_row()])

## The one home-block `Building` the door's own world-space span actually stands in front of —
## every lot on the home block carries `is_home_building`, but the door notch's columns are cut
## out of every other one (`_spawn_buildings()`'s own doc), so only this lot's world footprint
## overlaps `_door_world_x_range()`.
func _home_door_building() -> Building:
	var x_range := _door_world_x_range()
	for building in _buildings:
		if not building.is_home_building:
			continue
		var world := map.tile_rect_to_world(building.lot)
		if world.position.x < x_range.y and world.end.x > x_range.x:
			return building
	return null

## `StreetTrees.planted()`'s own positions, drawn as `Prop`s once for the whole run — never
## rebuilt in `_dress_blocks()`, unlike a park's trees, because a street tree belongs to the
## street's own frontage rather than to what the block behind it currently is.
func _spawn_street_trees() -> void:
	var edges := map.witness_only()
	var planted_trees := StreetTrees.planted(map)
	map.restore_edges(edges)
	if map.has_stretch():
		# Only the stretch's own trees and their pits: a pit drawn out in the void is ground. The
		# authored tree positions supply drawing, pits and clearance from one list.
		var shown: Array[StreetTrees.Planted] = []
		for planted_tree in planted_trees:
			if _recipe_contains(planted_tree.position):
				shown.append(planted_tree)
		planted_trees = shown
	_decals.set_street_tree_pits(planted_trees, map)
	for planted_tree in planted_trees:
		if not _recipe_contains(planted_tree.position):
			continue
		var tree := Prop.new()
		tree.kind = Prop.Kind.STREET_TREE
		tree.position = planted_tree.position
		tree.variant = hash(planted_tree.position)
		_entities.add_child(tree)
		scenery.register(tree)
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
	scenery.register(exit)

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
			if not signals.has_lights(junction):
				continue
			var centre := Vector2(x * CityMap.period() + Tuning.STREET_WIDTH * 0.5,
					y * CityMap.period() + Tuning.STREET_WIDTH * 0.5) * float(Tuning.TILE_SIZE)
			var arms: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
			for heading in arms:
				var right := Vector2(-heading.y, heading.x)
				var at := centre - heading * (half + inset) + right * kerb
				if not _recipe_contains(at):
					continue
				if not map.is_walkable(map.world_to_tile(at)):
					continue
				var light := TrafficLight.new()
				light.junction = junction
				light.faces(heading)
				light.signals = signals
				light.position = at
				_entities.add_child(light)
				scenery.register(light)

func _spawn_buildings() -> void:
	# A stretch's buildings are measured against the city they were cut from — which of their
	# columns a neighbouring roof covers, how far a roof reaches over an alley — rather than
	# against the void round the stretch, which would read every edge of it as more building.
	var edges := map.witness_only()
	var door_x_range := _door_world_x_range()
	var buildings: Array[Building] = []
	for rect in map.building_rects:
		var world := map.tile_rect_to_world(rect)
		var building := Building.new()
		building.scenery_resident = false
		building.scenery_clock = _ground
		# Origin is the south edge centre of the lot (see building.gd).
		building.position = Vector2(world.get_center().x, world.end.y)
		building.footprint = world.size
		building.variant = _variant_for(rect)
		building.district = map.starting_purpose(_block_of(rect))
		building.height = _height_for(rect, rect.size.y)
		building.lot = rect
		# A stretch's authored values are the inputs to its geometry, not a repaint after it: the
		# height decides the roof extension a touching lot needs, and the variant decides the tint
		# shared by pieces of one courtyard. Ordinary generated cities have no listed values, so
		# this changes nothing for them.
		_draw_as_the_recipe_says(building)
		# Every lot on the home block is hers — the door's own notch carves no `Building` of its
		# own, so this is every wall standing around it.
		building.is_home_building = _block_of(rect) == map.home_block
		if building.is_home_building:
			# Only the one lot the door notch's own footprint overlaps ever reads this as true —
			# every other home-block lot's world x sits entirely outside the door's span, since
			# `CityGenerator._subtract_all()` cuts the notch's own columns out of them — but handing
			# it to all of them costs nothing and needs no lookup for which one that is.
			building.door_world_x_range = door_x_range
		# Dressed here, before coverage and the roof extension below are computed, since
		# `_assign_roof_extensions()` needs to know which buildings are the power station to keep an
		# extension off its yard (no roof stands there to extend).
		_dress_the_power_station(building, rect)
		buildings.append(building)
	# Coverage and the roof extension it needs both read every lot's own `wall_tiles()`, fixed by
	# the generated or authored values above, so both run before any of them enters the tree — see
	# `_covered_ground_cols()` and `_assign_roof_extensions()`. Never asked of her own building
	# (`covered_ground_cols` stays empty) — her own building's front is the one the player knows
	# as home and stays as it is, and the home block's own doorstep already exempts it from the
	# route-redundancy guarantee the same way.
	for i in buildings.size():
		if not buildings[i].is_home_building:
			buildings[i].covered_ground_cols = _covered_ground_cols(map.building_rects[i])
	var courtyard_of := _courtyard_lot_of(map.building_rects)
	_assign_roof_extensions(buildings, courtyard_of)
	_share_courtyard_tint(buildings, courtyard_of)
	map.restore_edges(edges)
	for building in buildings:
		if not _recipe_shows_building(building.lot):
			building.free()
			continue
		# Their own layer, under the entities — see the note at the top of this file. They still
		# y-sort against each other, which costs nothing and keeps two lots that share a block
		# boundary stacking the way the eye expects.
		# Roof pictures stand in the y-sorted entity layer at their feet. Tall roof equipment can
		# reach into the walkable row north of the lot, so it must sort against street actors just
		# like the power station stacks do.
		building.roof_object_parent = _entities
		_buildings_layer.add_child(building)
		_buildings.append(building)
		scenery.register(building)
		# The one part of a building drawn among the entities — see the note at the top of this file.
		var feet := building.stack_feet()
		for i in feet.size():
			var stack := Building.StationStack.new()
			stack.name = "StationStack%d" % i
			stack.position = building.position + feet[i]
			_entities.add_child(stack)
			scenery.register(stack)

## `Building.covered_ground_cols` for `rect`: true at column `col` where the tile directly south of
## `rect`'s own front row — one row below its south edge, the row a passer-by would stand on — is
## `GameEnums.TileType.BUILDING` rather than walkable ground. `map.is_walkable()` is the fixed
## lattice fact the **city** skill asks for — "no purpose change may move a walkable tile" — never
## `is_open()`'s per-day closures, so this is computed once here rather than in `start_day()`. This
## is the candidate set only: `_assign_roof_extensions()` keeps a column covered only where a roof
## actually reaches it, so a south tile past the map's own edge (`CityMap.tile_at()` reads it as
## `BUILDING`) or a power station's yard leaves its front's facade standing.
func _covered_ground_cols(rect: Rect2i) -> Array[bool]:
	var result: Array[bool] = []
	var south_row := rect.position.y + rect.size.y
	for col in rect.size.x:
		result.append(not map.is_walkable(Vector2i(rect.position.x + col, south_row)))
	return result

## `Building.roof_extension_rows`, `roof_extension_seamless` and `seamless_cover_cols` for every
## building in `buildings` (parallel to `map.building_rects`): wherever a building's own
## `covered_ground_cols` marks a column covered, the tile directly south of it belongs to some
## other lot's rect — the one whose roof now has to reach up to meet the covered building's own
## roof — found by a tile lookup over every rect rather than a spatial search, since the whole set
## is small and built once per run. The extension at that column is exactly the covered
## building's own `wall_tiles()`: precisely enough rows to reach the world row its roof already
## starts at, edge to edge. A power
## station's yard columns (`_hall_cols()`, read after `_dress_the_power_station()` above has set
## `power_station`) are skipped since no roof stands there to extend — the yard is fenced ground,
## not a building mass.
##
## **A front column draws no facade only where a roof actually covers it.** Once every extension
## is placed, each building's `covered_ground_cols` is narrowed to the columns an extension
## reached; a column nothing covers — a yard's, a tile past the map's edge, any south tile no lot
## owns — keeps its facade, since a column with neither a facade nor a roof over it shows the dark
## background where its wall would be (the player, shown one: "Keep its facade"). Nothing reads
## `covered_ground_cols` before this, so the door and every other roll see only the final answer.
##
## **Seamless when both rectangles are cut from the same courtyard lot.** A single-block or
## apartment-complex courtyard is cut into up to four rectangles around its hole
## (`CityGenerator._build_block()`'s own `COURTYARD` branch, `_subtract_all()`), each its own
## `Building` — so a covered seam between two of them is two pieces of one physical building, not
## a front covering a genuinely separate one behind it, and the extension that fills it reads as
## the *same* roof continuing rather than stopping in a parapet. `courtyard_of` maps each building
## index to whichever courtyard's own `map.lot_rect(block)` encloses it, or -1
## (`_courtyard_lot_of()`). Both sides of a seamless seam are marked — the covering piece's column
## in `roof_extension_seamless`, the covered piece's in `seamless_cover_cols` — and
## `Building.roof_cell_edges()` withholds both lips there. A covered piece with no roof rows at all
## is never seamless: nothing of its own carries on above the extension, so the extension caps.
func _assign_roof_extensions(buildings: Array[Building], courtyard_of: Array[int]) -> void:
	var tile_to_index := {}
	for i in map.building_rects.size():
		var rect: Rect2i = map.building_rects[i]
		for x in rect.size.x:
			for y in rect.size.y:
				tile_to_index[Vector2i(rect.position.x + x, rect.position.y + y)] = i
	var extensions: Array[Array] = []
	var seamless: Array[Array] = []
	var seamless_below: Array[Array] = []
	for building in buildings:
		var zeros: Array[int] = []
		zeros.resize(building.columns())
		zeros.fill(0)
		extensions.append(zeros)
		var falses: Array[bool] = []
		falses.resize(building.columns())
		falses.fill(false)
		seamless.append(falses)
		seamless_below.append(falses.duplicate())
	var reached: Array[Array] = []
	for building in buildings:
		var none: Array[bool] = []
		none.resize(building.covered_ground_cols.size())
		none.fill(false)
		reached.append(none)
	for i in buildings.size():
		var back := buildings[i]
		if back.covered_ground_cols.is_empty():
			continue
		var rect: Rect2i = map.building_rects[i]
		for col in back.covered_ground_cols.size():
			if not back.covered_ground_cols[col]:
				continue
			var south := Vector2i(rect.position.x + col, rect.position.y + rect.size.y)
			var front_index: int = tile_to_index.get(south, -1)
			if front_index < 0:
				continue
			var front := buildings[front_index]
			var front_rect: Rect2i = map.building_rects[front_index]
			var local_col := south.x - front_rect.position.x
			if front.power_station:
				var hall := front._hall_cols()
				if local_col < hall.x or local_col >= hall.y:
					continue
			var front_extension: Array[int] = extensions[front_index]
			front_extension[local_col] = back.wall_tiles()
			var back_reached: Array[bool] = reached[i]
			back_reached[col] = true
			if courtyard_of[i] >= 0 and courtyard_of[i] == courtyard_of[front_index] \
					and back.roof_tiles() > 0:
				var front_seamless: Array[bool] = seamless[front_index]
				front_seamless[local_col] = true
				var back_seamless: Array[bool] = seamless_below[i]
				back_seamless[col] = true
	for i in buildings.size():
		buildings[i].roof_extension_rows = extensions[i]
		buildings[i].roof_extension_seamless = seamless[i]
		buildings[i].seamless_cover_cols = seamless_below[i]
		if buildings[i].covered_ground_cols != reached[i]:
			buildings[i].covered_ground_cols = reached[i]

## Gives every piece of one courtyard lot one tint (`Building.tint_variant`), so the rectangles a
## courtyard is cut into read as the one building they are rather than as three or four neighbours.
## An ordinary city takes the first piece's variant, as before. A stretch may show only part of a
## complete-context courtyard, so its first authored piece in the same canonical rectangle order
## supplies the tint instead; a hidden witness piece must not choose the visible colour. A tint
## rather than a shared `variant`, which would erase the other authored rolls the buildings keep.
## `courtyard_of` is `_courtyard_lot_of()`'s answer for `map.building_rects`.
func _share_courtyard_tint(buildings: Array[Building], courtyard_of: Array[int]) -> void:
	var first_variant := {}
	if map.has_stretch():
		for i in buildings.size():
			var lot := courtyard_of[i]
			if lot < 0 or first_variant.has(lot) \
					or not _recipe_shows_building(buildings[i].lot):
				continue
			first_variant[lot] = buildings[i].variant
	for i in buildings.size():
		var lot := courtyard_of[i]
		if lot < 0:
			continue
		if not first_variant.has(lot):
			first_variant[lot] = buildings[i].variant
		buildings[i].tint_variant = first_variant[lot]

## Which courtyard lot (an index into the courtyards found on `map`, or -1) each of `rects` was cut
## from — single-block and apartment-complex courtyards alike, `map.zone_rects` or not, since both
## go through the same `COURTYARD` branch of `_build_block()` and both can split into more than one
## rectangle. `map.lot_rect(block)` is the whole lot a courtyard's rectangles were cut from, never
## smaller than any of them, so `encloses()` is exact rather than an overlap test.
func _courtyard_lot_of(rects: Array[Rect2i]) -> Array[int]:
	var courtyard_lots: Array[Rect2i] = []
	for block in map.block_layouts.keys():
		if map.starting_purpose(block) == GameEnums.BlockPurpose.COURTYARD:
			courtyard_lots.append(map.lot_rect(block))
	var result: Array[int] = []
	for rect in rects:
		var found := -1
		for i in courtyard_lots.size():
			if courtyard_lots[i].encloses(rect):
				found = i
				break
		result.append(found)
	return result

## Makes `building` the power station when `rect` is its mass: the door over the pavement
## `CityMap.power_station_door` names, and the transformer yard over the other block — the hall is
## the door's block and the street the mass was built across.
func _dress_the_power_station(building: Building, rect: Rect2i) -> void:
	if not map.has_power_station() or rect != CityMap.blocks_tile_rect(map.power_station):
		return
	building.power_station = true
	building.station_door_col = map.power_station_door.position.x - rect.position.x
	var door_is_west := building.station_door_col < Tuning.BLOCK_SIZE
	building.station_yard_cols = Vector2i(rect.size.x - Tuning.BLOCK_SIZE if door_is_west else 0,
			Tuning.BLOCK_SIZE)

## The block a lot belongs to.
func _block_of(rect: Rect2i) -> Vector2i:
	return (rect.position - Vector2i.ONE * Tuning.STREET_WIDTH) / CityMap.period()

## A home-block building's own fixed choice, keyed on nothing but the lot's own tile position —
## never `map.seed_used` — so its wall/roof colour and `Building._build_windows()`'s own window
## style and lit-window pattern (keyed on `variant` and the building's world position, itself fixed
## since `CityMap.home_block` and every constant the lattice is built from are the same on every
## seed) no longer depend on the seed either. A non-home building keeps the per-seed roll.
func _variant_for(rect: Rect2i) -> int:
	if _block_of(rect) == map.home_block:
		return absi(hash("home:%d:%d" % [rect.position.x, rect.position.y]))
	return absi(hash("%d:%d:%d" % [map.seed_used, rect.position.x, rect.position.y]))

func _height_for(rect: Rect2i, lot_depth_tiles: int) -> float:
	if _block_of(rect) == map.home_block:
		return _home_building_height(rect, lot_depth_tiles)
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

## `HOME_BUILDING_WALL_ROWS` for the one lot the door's own world-space span stands in front of,
## `HOME_FLANKING_WALL_ROWS` for the other home-block lots — fixed, never rolled, so
## `_height_for()`'s home branch moves no RNG stream at all. `is_door_building` repeats
## `_home_door_building()`'s own overlap test on the rect directly, because `_spawn_buildings()`
## sets every building's height before `_spawn_home()` builds the door sprite it would otherwise
## read (see `build()`'s own ordering note) — `_door_world_x_range()` itself only needs
## `map.home_rect`, already fixed by the generator by the time this runs. The lot depth this is
## measured against (`lot_depth_tiles`) is `CityGenerator`'s own carve of the home block, six tiles
## for the door building on every seed tested — comfortably clear of the four wall rows plus at
## least one roof row this asks for; a seed where it were not would have to be reported as a fork
## rather than silently losing the roof, which is why this clamps to `rows() - 1` rather than
## reaching for `MAX_HEIGHT_FRACTION` as well.
func _home_building_height(rect: Rect2i, lot_depth_tiles: int) -> float:
	var world := map.tile_rect_to_world(rect)
	var door_x_range := _door_world_x_range()
	var is_door_building := world.position.x < door_x_range.y and world.end.x > door_x_range.x
	var tiles := HOME_BUILDING_WALL_ROWS if is_door_building else HOME_FLANKING_WALL_ROWS
	var cap := maxi(1, lot_depth_tiles - 1)
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
	scenery.view = _home_scenery_view()
	map.repaint(state)
	# Before anything reads the ground again: a park that burnt down last night is not calm today.
	_sleepiness_tile = Vector2i(-1, -1)
	_day = day
	# After `GameState.begin_day()`'s own dawn photograph (`main.gd` calls this after that), so a
	# lost day 10's scar is already given back by the time this reads `GameState.scars`.
	_sync_home_door()
	_paint_ground()
	_decals.set_placed(_recipe_litter(day))
	_dress_blocks(state)
	# Last, and after the repaint: which blocks are calm is what the closure invariant is
	# stated over, and a requisitioned park is not one of them.
	_close_streets(day, rng)
	# And after the closures, since a `FALLEN_TREE` closure is what empties a pit. `Main` runs it
	# once more after the day's seals are planned — see `refresh_street_trees()`.
	refresh_street_trees()
	# After the tree is grown, which is what the dawn's pasting reads "the streets she uses most"
	# off, and after `_dress_blocks()`, which is what says a front has burnt.
	_posters.start_day(day, _tree)
	scenery.update(_home_scenery_view(), true)

## Recipe activity is installed by its runtime after this shared day presentation. The
## explicit construction witness supplies global route/region context without randomly
## scheduling new closures over the authored composition.
##
## **A stretch pastes no dawn**: its posters are the recipe's own (`setup.posters`), so the walls are
## marked pasted through today before the day starts and nothing the seed would paste appears.
func start_recipe_day(state: CityState, day: int, _rng: RandomNumberGenerator) -> void:
	start_finale(state, day)
	var edges := map.witness_only()
	_tree = RouteTree.for_day(map, day)
	_region_plan = RegionPlanner.plan_day(map, day, _tree)
	map.restore_edges(edges)
	_closures = map.recipe_closures.duplicate()
	map.close_streets(_closures)
	for closure in _closures:
		_spawn_closure(closure)
	if map.has_stretch():
		GameState.posters.pasted_through = maxi(GameState.posters.pasted_through, day)
	_posters.start_day(day, _tree)

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
##
## And the route-kerb tint (M145) goes with the tree it has nothing to draw from without anything
## extra here: `_tint_the_route_kerbs()` only ever runs from `_close_streets()`, which the finale
## never calls, and `_paint_ground()` above paints every kerb cell its plain source, so a twin from
## yesterday cannot survive the repaint.
func start_finale(state: CityState, day: int) -> void:
	scenery.view = _home_scenery_view()
	map.repaint(state)
	_sleepiness_tile = Vector2i(-1, -1)
	_day = day
	_paint_ground()
	_decals.set_placed(_recipe_litter(day))
	_dress_blocks(state)
	_posters.show_only()
	scenery.update(_home_scenery_view(), true)

## Today's closed streets. The whole street comes out of the network; the barriers stand at
## its two mouths, where they can be seen from the junction rather than found half way down.
func _close_streets(day: int, rng: RandomNumberGenerator) -> void:
	for node in _closure_nodes:
		node.queue_free()
	_closure_nodes.clear()
	# Before the closures, because they are placed off it. See `ClosurePlanner._shuffled_candidates`.
	_tree = RouteTree.for_day(map, day)
	_tint_the_route_kerbs()
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

## The route's own curbstones, tinted — a trial (M145) of whether a faint hint on the ground can
## stay under the threshold of being noticed as one; see `docs/CITY.md`, "Guiding her to the calm".
##
## No second layer: `GroundLayers.build_tile_set()` already gave every kerb source
## (`GroundTiles.ROUTE_KERB_SOURCES`) a tinted twin (`GroundTiles.route_twin_of`), composed with the
## `curbstone` component (or, where the bake carries whole authored tiles, the stone's own fill) blended toward
## `Palette.ROUTE_KERB_TINT` by `Tuning.ROUTE_KERB_TINT_ALPHA` — so the paving around the stone is
## untouched. This only ever decides *which* cells qualify and re-sets each straight onto `_ground`
## at its twin, same atlas coordinates: the two can never disagree about a cell's coordinates,
## because there is only the one layer. A twin that was never registered (an incomplete art drop)
## leaves the tile on its plain source, the same graceful fallback `GroundLayers` gives everywhere
## else. Alpha zero is the trial's off switch, with nothing else to change.
##
## **A kerb tile qualifies when its street's `Corridor.depth()` is zero — the mark says *this
## street*, not *this sidewalk*.** `depth()` answers at the grain of the whole street on purpose
## (see `Corridor`'s own doc — that grain is what every placement rule is stated in), so both
## pavements of every street the tree runs along are tinted, from intersection to intersection: a
## street tile resolves to its segment's key regardless of which of the segment's own cells the
## tree actually walked, so a tree that only uses part of a segment — leaving it through an alley
## or a park, or ending at a calm area partway along — still tints the whole segment rather than a
## stretch of it, with nothing here having to special-case a partial run.
##
## **Never a street the tree only crosses at a junction, and never an unwalked stretch of the main
## road.** A junction cell resolves to no segment at all (`StreetNetwork.segment_containing`), so
## crossing one — a route switching pavements, or cutting through from a park or an alley — marks
## no street's `depth()` down to zero; `RouteTree.junctions()`'s own doc says the same thing from
## the other side, that such a crossing "contributes a junction no on-tree street names". And the
## main road's own cells, anywhere but at a junction, are off the growth graph entirely
## (`RouteTree._is_off_the_growths_graph`), so they carry no colour and no segment of the spine
## reaches zero unless the tree's trunk genuinely had to walk it — which is a street the tree does
## run along, not one it merely passes near.
##
## **The placement rules keep the narrower question.** `Corridor.carries_a_route(tile)` — whether
## the tree runs along *this cell*, non-empty `RouteTree.branches_on(tile)` — is what a wall, a
## piece of friction or a set piece still asks; only the paint here asks the wider one, so nothing
## about where a body may stand moves with the mark.
##
## Called from `_close_streets`, right after `_tree` is grown and before the region plan or the
## closures, so a tree a closure has not yet touched is what the tint answers for.
func _tint_the_route_kerbs() -> void:
	_ground_corridor = Corridor.of(_tree)
	_ground.repaint()

func closures() -> Array[RoadClosure]:
	return _closures

## Every building this city built, fixed for the run — read by `DebugLayers` so its bounding-box
## layer can trace each one's own `shape` rather than a second list of them.
func buildings() -> Array[Building]:
	return _buildings

## Today's trees, bollards and playground frames (rebuilt daily by `_dress_blocks`), plus the
## street trees fixed for the whole run — read by `DebugLayers` so its shadow layer can trace
## each one's own `shape` the same way, and by `tests/test_blocks.gd`'s spacing check.
## The posters on the fronts — see `PosterWalls`.
func poster_walls() -> PosterWalls:
	return _posters

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
	# Supports precede the rails mounted on them. The sign's panel draws its composite
	# after the rail, at the run midpoint rather than at a panel endpoint.
	for feet in closure.posts(map):
		var post := ParkFenceMarker.new() if closure is ParkClosure else ClosureMarker.new()
		post.piece = ClosureMarker.Piece.POST
		post.kind = closure.kind
		post.position = feet
		_add_closure_node(post, true)
	for mouth in closure.mouth_centres(map):
		_spawn_barrier(closure, mouth)
	if ClosureMarker.CAUSES.has(closure.kind):
		var cause := ClosureMarker.new()
		cause.piece = ClosureMarker.Piece.CAUSE
		cause.kind = closure.kind
		cause.across = closure.barrier_runs_across()
		cause.position = closure.cause_centre(map)
		_add_closure_node(cause, true)

## A line of barrier panels across the mouth, with the sign on the middle one, and one static
## body behind the whole line. The panels are separate nodes so that a barrier running away
## from the camera y-sorts panel by panel against the player; the collision is one box,
## because collision does not care what order things are drawn in.
##
## **The line's width is the closure's own** (`barrier_width()`), a street's width for an ordinary
## closure and one calm area's own edge for a `ParkClosure` — so a run longer or shorter than a
## street's mouth still tiles panels edge to edge across its own real length rather than a fixed
## one, with no overlap and no gap to overshoot a corner with.
func _spawn_barrier(closure: RoadClosure, at: Vector2) -> void:
	var across := closure.barrier_runs_across()
	var width := closure.barrier_width()
	var picture_width := width
	var picture_at := at
	if closure is ParkClosure:
		var fence := closure as ParkClosure
		# An open end's post is inset on its own ground. Rails end on that post, while
		# the collision below continues to cover the entire entrance as planned.
		var start_inset := 0.0 if fence.joined_start else ParkClosure.POST_HALF
		var end_inset := 0.0 if fence.joined_end else ParkClosure.POST_HALF
		picture_width -= start_inset + end_inset
		picture_at += (Vector2.RIGHT if across else Vector2.DOWN) * (start_inset - end_inset) * 0.5
	var pitch := float(AtlasLibrary.native_size(ClosureMarker.FENCE_ACROSS).x)
	if closure is ParkClosure and not across:
		pitch = 44.0
	var panels := maxi(1, roundi(picture_width / pitch))
	var span := picture_width / panels
	var sign_panel := panels / 2
	if closure is ParkClosure and not across:
		# This is the nearest panel whose elevated rail can cross the sign. Draw the
		# composite after that rail; later panels start at or below the sign's feet.
		var sign_from_start := at.y - (picture_at.y - picture_width * 0.5)
		sign_panel = mini(panels - 1,
				ceili((sign_from_start + ParkFenceMarker.UPPER_RISE) / span) - 1)
	for i in panels:
		var panel := ParkFenceMarker.new() if closure is ParkClosure else ClosureMarker.new()
		panel.piece = ClosureMarker.Piece.SIGN if i == sign_panel else ClosureMarker.Piece.FENCE
		panel.kind = closure.kind
		panel.across = across
		panel.span = span
		panel.rise = closure.end_on_rise()
		if panel is ParkFenceMarker:
			(panel as ParkFenceMarker).draw_support = i < panels - 1
			(panel as ParkFenceMarker).rail_offset = -(closure as ParkClosure).outward.x * 4.0
		# Broadside a panel's feet are the middle of its share; end-on they are the near end of
		# it, since an end-on panel is drawn up the screen from its feet — feet at the middle
		# would stand the whole column half a panel up the screen from the ground it covers.
		var offset := -picture_width * 0.5 + span * (i + (0.5 if across else 1.0))
		panel.position = picture_at + (Vector2(offset, 0.0) if across else Vector2(0.0, offset))
		if closure is ParkClosure and not across and i == panels - 1:
			var fence := closure as ParkClosure
			# Use the post's exact anchor: two arithmetically equivalent float paths can
			# differ by a fraction of a pixel and make y-sort put the post over the sign.
			panel.position = fence._point(fence.to_along if fence.joined_end
					else fence.to_along - ParkClosure.POST_HALF)
		if panel is ParkFenceMarker:
			(panel as ParkFenceMarker).sign_offset = at - panel.position
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
	if node is ScenerySprite:
		scenery.register(node)

func _dress_blocks(state: CityState) -> void:
	for prop in _props:
		prop.queue_free()
	_props.clear()
	if map.has_stretch():
		_dress_the_stretch()
	else:
		for block: Vector2i in map.block_plans:
			var purpose := state.purpose_of(map.block_plans, block)
			_dress_block(block, purpose)
		_dress_precincts()
		_place_garbage_sacks()
	for building in _buildings:
		var listed: Dictionary = map.stretch_buildings.get(building.lot, {})
		building.condition = int(listed.condition) as Building.Condition if not listed.is_empty() \
				else _condition_for(state.purpose_of(map.block_plans, _block_of(building.lot)))
		building.day = _day
	mark_the_burnt_frontage()

## A stretch's props are its recipe's (`CityMap.stretch_props`): every tree, swing frame, bollard
## and sack where the recipe puts it, in place of the rolls a day's blocks and streets would make.
func _dress_the_stretch() -> void:
	for listed in map.stretch_props:
		var prop := Prop.new()
		prop.kind = int(listed.kind) as Prop.Kind
		prop.position = listed.at
		prop.variant = int(listed.variant)
		prop.scale_factor = float(listed.scale)
		_add_prop(prop)

## Forces the one `Building` behind day 3's fire to `Building.Condition.BURNT`, overriding
## whatever its own block's purpose just set above — *"the building is what needs to be burnt, not
## an object next to the building"*. The block's purpose is unmoved (this building's block may still
## be ordinary `RESIDENTIAL`, `COMMERCIAL` ground the arc never touches); only the one frontage the
## fire actually reached shows it, in the look `Building.Condition.BURNT` draws (windows black and
## broken under soot, the door boarded, the parapet charred) for the scheduled `BURNT_OUT` block
## purpose above too — the same look for a different, per-building reason.
##
## **The lookup is the shape of `board_neighbor_window()`/`_home_door_building()`**: a fixed fact
## about the run (`GameState.scars`) answers which `Building` it is, once, rather than a field
## carried on the building itself. `burning_building` only ever catches on a wall this file actually
## draws (`EventDef.Pavement.AT_THE_FRONT`, `EventCatalogue._burning_building()`'s own doc), so the
## tile one step north of the scar (`Vector2i.UP`, the same direction `EventScheduler.
## _wants_this_side()`'s `AT_THE_FRONT` case checks, on the map and `BUILDING`) is always a real
## lot. `tests/test_acts.gd` checks that over every site the fire can be given.
##
## Idempotent, like every other per-day override here: `Building.condition`'s own setter is a no-op
## once it already says `BURNT`, so calling this from every `_dress_blocks()` pass — the ordinary
## day and the finale's own dressing alike — costs nothing once the frontage is found, and finds
## nothing before day 4, when the scar does not exist yet. A run records one `burnt_shell` scar,
## and every one the list holds burns its own building all the same.
##
## **Also called live, once, by day 8's task on a run with no recorded scar**
## (`ResistanceDirector._burn_a_front_for_the_task()`): it records a scar at a front the fire could
## have caught on and asks for the building behind it to be burnt there and then, so *"Take what's
## in the stroller to the burnt building"* leads to a burnt building rather than bare sidewalk.
func mark_the_burnt_frontage() -> void:
	for scar in GameState.scars:
		if String(scar["id"]) != BURNT_FRONTAGE_SCAR:
			continue
		var wall_tile := map.world_to_tile(scar["position"] as Vector2) + Vector2i.UP
		for building in _buildings:
			if building.lot.has_point(wall_tile):
				building.condition = Building.Condition.BURNT
				break

## The way in of the building directly north of the sidewalk point `sidewalk` — the same lot
## `mark_the_burnt_frontage()` burns behind a scar — as a world point half a tile up its ground
## floor, on the door (`Building.way_in_local_x()`, the one nearest `sidewalk` on a front with
## several storefronts). `Vector2.INF` with no building there. Day 8's red arrow and its task's
## contact end here: *"or better to the door"* (sandy-egret).
func way_in_behind(sidewalk: Vector2) -> Vector2:
	var wall_tile := map.world_to_tile(sidewalk) + Vector2i.UP
	for building in _buildings:
		if building.lot.has_point(wall_tile):
			var x := building.way_in_local_x(sidewalk.x - building.position.x)
			return building.position + Vector2(x, -Tuning.TILE_SIZE * 0.5)
	return Vector2.INF

## **One block's buildings, shown as what the block is now**, during the day rather than at dawn —
## day 11's market, boarded up ahead of her while she cannot see it (`ResistanceHappenings`). The
## same `_condition_for()` the dawn dressing reads, for the buildings of `block` alone, and the
## same `mark_the_burnt_frontage()` after it, so a block boarded up around the building day 3's
## fire burned never boards up the burnt building itself.
func present_block(block: Vector2i, state: CityState) -> void:
	var condition := _condition_for(state.purpose_of(map.block_plans, block))
	for building in _buildings:
		if _block_of(building.lot) == block:
			building.condition = condition
	mark_the_burnt_frontage()

## **Ground taken away in front of her**: `tiles` become `SPOILED` now, in the map and on screen —
## day 12's park, closing a ring at a time once she has reached its swing (`ResistanceHappenings`).
## Each tile and its eight neighbors are repainted from `GroundTiles.source_for()`, the dawn paint's
## own answer, so an edge drawn against the old ground is redrawn against the new. The swing frame
## goes with the playground tile it stands on, and the calm-ground cache is dropped, since the tile
## she is standing on may be one that just stopped being calm.
func close_ground(tiles: Array[Vector2i]) -> void:
	var redraw := {}
	var closed := {}
	for tile in tiles:
		map.repaint_tile(tile, GameEnums.TileType.SPOILED)
		closed[tile] = true
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				redraw[tile + Vector2i(dx, dy)] = true
	for tile: Vector2i in redraw:
		var source := scenery_ground_source(tile)
		if source >= 0:
			_ground.set_cell(tile, source,
					GroundLayers.atlas_coords_for(source, map.seed_used, tile, _ground.tile_set))
	_sleepiness_tile = Vector2i(-1, -1)
	for prop in _props.duplicate():
		var frame := prop as Prop
		if frame and frame.kind == Prop.Kind.PLAYGROUND_FRAME \
				and closed.has(map.world_to_tile(frame.position)):
			_props.erase(frame)
			frame.queue_free()

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
	# **The one exception to "the same every morning" is the one park this run ever fences.**
	# `ParkClosure`'s line stands on the lot's own edge row, and a tree seeded there before the
	# fence existed would stand on the fence line — cleared for the barrier the same way the
	# ground itself was, on the one occasion the ground changes at all. `margin` only widens past
	# the ordinary 16px inset while `block` is `map.fenced_park`, so every other park's trees are
	# untouched by this at every reading.
	var margin := 16.0
	if map.fenced_park == block and ClosurePlanner.calm_area_rect(map, block) == layout.open_rect:
		margin += Tuning.CLOSURE_BARRIER_DEPTH
	while placed < wanted and attempts < wanted * 8:
		attempts += 1
		var at := Vector2(rng.randf_range(lot.position.x + margin, lot.end.x - margin),
				rng.randf_range(lot.position.y + margin, lot.end.y - margin))
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
	if not _recipe_contains(prop.position):
		prop.free()
		return
	_props.append(prop)
	_entities.add_child(prop)
	if prop is ScenerySprite:
		scenery.register(prop)

## The framing of the whole city plus its border band, for the cameras that look at the city
## rather than follow her: the `--overview` view, the dev rig and the trailer's zoom-out. The
## player's own camera has no limits, so it follows her centered with the look-ahead wherever she
## stands, and the ground past the edge is painted for whatever view asks
## (`scenery_ground_source()`). The rectangle is the map grown by the band painted outside it,
## less the reach a glance toward a corner costs.
func camera_bounds() -> Rect2:
	if map.recipe_exterior or map.has_stretch():
		return Rect2(-100000000, -100000000, 200000000, 200000000)
	var depth := OUTSIDE_DEPTH_TILES * float(Tuning.TILE_SIZE)
	return Rect2(Vector2.ZERO, map.world_size()).grow(depth - Stroller.CAMERA_LOOK_AHEAD)

## Walls just outside the map, so the player cannot walk off the edge of the world.
func _spawn_boundary() -> void:
	if map.recipe_exterior or map.has_stretch():
		return
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

## Adds a node to the y-sorted layer, where it sorts against the props, the power station's stacks
## and every other entity — never against a building, which is a layer of its own beneath them.
func add_entity(node: Node) -> void:
	_entities.add_child(node)

# ------------------------------------------------------------------ ground ---

## Configures the ground from `assets/ground_tileset.tres` and prepares its initial nearby chunks.
##
## This used to be ~120 lines of draw_rect and computed dashes. Kerbs, centre lines and
## zebra crossings are authored art now, chosen per cell by GroundTiles — which means they
## can be edited in a drawing program instead of by changing arithmetic, and it is one
## place rather than four.
func _paint_ground() -> void:
	_ground_corridor = null
	_ground.configure(self, _composed_ground_tile_set())
	var initial := scenery.view if scenery.view.has_area() else _home_scenery_view()
	for key in _ground.keys_in(initial.grow(SceneryResidency.LOAD_MARGIN)):
		_ground.prepare(key)

func _home_scenery_view() -> Rect2:
	return Rect2(map.doorstep_world_position() - Tuning.VIEW_HALF_EXTENT,
			Tuning.VIEW_HALF_EXTENT * 2)

## Current source, independent of residency. Border and route paint use this same answer
## at boot, on approach, after a closure, and when a distant chunk returns.
func scenery_ground_source(tile: Vector2i) -> int:
	if map.has_stretch() and not map.in_stretch(tile):
		return -1
	if map.recipe_exterior and not map.recipe_bounds.has_point(tile):
		return GroundTiles.ALLEY
	if tile.x < 0 or tile.y < 0 or tile.x >= map.size.x or tile.y >= map.size.y:
		return _paint_outside_the_map(tile)
	var source := GroundTiles.source_for(map, tile, _day)
	if _ground_corridor and source in GroundTiles.ROUTE_KERB_SOURCES \
			and _ground_corridor.depth(tile) == 0:
		var twin := GroundTiles.route_twin_of(source)
		if twin >= 0 and _ground.tile_set.has_source(twin):
			return twin
	return source

func _recipe_contains(at: Vector2) -> bool:
	if map.has_stretch():
		return map.in_stretch(map.world_to_tile(at))
	return not map.recipe_exterior or map.recipe_bounds.has_point(map.world_to_tile(at))

## Whether a building on `lot` is shown: every one in a city, those inside a bounded recipe's
## rectangle, and in a stretch only the recipe's own (`CityMap.stretch_buildings`).
func _recipe_shows_building(lot: Rect2i) -> bool:
	if map.has_stretch():
		return map.stretch_buildings.has(lot)
	return not map.recipe_exterior or map.recipe_bounds.encloses(lot)

## Applies a stretch building's listed district, variant and wall height before any derived
## geometry or shared tint is computed, so a change to the seed roll cannot change either the
## handcrafted building or a roof joined to it. Nothing for any other city.
func _draw_as_the_recipe_says(building: Building) -> void:
	var listed: Dictionary = map.stretch_buildings.get(building.lot, {})
	if listed.is_empty():
		return
	building.district = int(listed.district) as GameEnums.BlockPurpose
	building.variant = int(listed.variant)
	building.height = float(listed.height) * Tuning.TILE_SIZE

## The walls round a stretch, where the void meets one of its tiles and no building of its own
## stands: a body on every such tile, one row of them at a time, so she, a pursuer and a nudge from
## the crowd all stop at the edge of the scene the way they stop at a frontage. Nothing is drawn.
func _spawn_the_void_edge() -> void:
	var walled := {}
	for lot: Rect2i in map.stretch_buildings:
		for tile in map.rect_tiles(lot):
			walled[tile] = true
	var edge := {}
	for y in map.size.y:
		for x in map.size.x:
			var tile := Vector2i(x, y)
			if not map.in_stretch(tile):
				continue
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var beside := tile + Vector2i(dx, dy)
					if not map.in_stretch(beside) and not walled.has(beside):
						edge[beside] = true
	var body := StaticBody2D.new()
	body.name = "VoidEdge"
	var rows := {}
	for tile: Vector2i in edge:
		if not rows.has(tile.y):
			rows[tile.y] = []
		(rows[tile.y] as Array).append(tile.x)
	for y: int in rows:
		var xs: Array = rows[y]
		xs.sort()
		var start: int = xs[0]
		var last: int = xs[0]
		for i in range(1, xs.size() + 1):
			if i < xs.size() and int(xs[i]) == last + 1:
				last = xs[i]
				continue
			var run := map.tile_rect_to_world(Rect2i(start, y, last - start + 1, 1))
			var shape := CollisionShape2D.new()
			var rectangle := RectangleShape2D.new()
			rectangle.size = run.size
			shape.shape = rectangle
			shape.position = run.get_center()
			body.add_child(shape)
			if i < xs.size():
				start = xs[i]
				last = xs[i]
	add_child(body)

func _recipe_litter(day: int) -> Array[Litter.Placed]:
	var shown: Array[Litter.Placed] = []
	if map.has_stretch():
		for listed in map.stretch_litter:
			var entry := Litter.Placed.new()
			entry.position = listed.at
			entry.texture_index = int(listed.texture)
			shown.append(entry)
		return shown
	for placed in Litter.placed(map, day):
		if _recipe_contains(placed.position):
			shown.append(placed)
	return shown

## Starts each repaint from the scene's authored TileSet, so the composition stays stable when a
## new day chooses different damage or grass cells — the authored resource names each source's
## baked region and holds no picture, so composing it twice can never accumulate layers.
func _composed_ground_tile_set() -> TileSet:
	if _authored_ground_tile_set == null:
		_authored_ground_tile_set = _ground.tile_set
	return GroundLayers.build_tile_set(_authored_ground_tile_set)

## What the city stops at, on each of its four sides.
##
## The resident tilemap covers only the current view. Outside the finite city, this continues the
## landscape far enough for that view without continuing the city itself: no roads, walkable cells
## or collision are added.
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
## road reaching it. **The two exceptions are not the same depth.** The bridge carries the road as
## far as any view asks (the deck is `CityEdge.BRIDGE_DECK_PX` long), because a deck is in the open; the tunnel carries it only as far as the
## portal's opening (`CityEdge.TUNNEL_DEPTH_TILES`), because past the mouth the road is inside the
## mountain and what is on top of it is rock.
##
## Nothing here is walkable and none of it has a `GameEnums.TileType`: this paints the tilemap
## and the separate animated water surface,
## and `CityMap` is untouched, so the walkable set and every guarantee stated over it are identical
## tile for tile. The boundary wall is still what stops her.
func _paint_outside_the_map(tile: Vector2i) -> int:
	return _border_source(tile.x, tile.y)

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
func _border_source(x: int, y: int) -> int:
	var north := -y
	var south := y - (map.size.y - 1)
	var west := -x
	var east := x - (map.size.x - 1)

	if _leaves_by_the_spine(x):
		var on_to_the_bridge := south > 0
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

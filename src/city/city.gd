class_name City
extends CityDressing
## Turns a CityMap into a scene: ground, buildings, props, boundary, and the answers the
## baby needs about the ground it is standing on.
##
## The `Ground` child owns the freeable ground chunks; with the decals and the buildings' shadows it
## draws on `DrawLayer.Layer.GROUND`, under every other layer the city hosts (`add_entity()`).
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
## the same way. Each lot is only `CityGenerator.HOME_SIZE_TILES.y` (2) deep, so `Building.wall_tiles()`'s
## own cap (`rows() - 1`) always clamps this down to one row regardless of the value here — the
## constant only has to be something that cap can act on.
const HOME_FLANKING_WALL_ROWS := 2
const BOUNDARY_THICKNESS := 64.0

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


## The smallest and largest scale a park tree's `scale_factor()` is rolled at in `_dress_block()`.
const PARK_TREE_SCALES := Vector2(0.75, 1.25)

const EXCITEMENT_DECAY_ALLEY_MULTIPLIER := 0.58

## Layered on top of the ground's own multiplier for the rest of a day once the resistance's
## package is picked up (`run.resistance().is_carrying_package()`) — the one cost in the subquest
## that is deferred and total rather than local, so it changes the afternoon's routing rather than
## one minute of it. Chosen on the same severity as a main road's own 0.6, on the harsher side of
## it: this is a decision she made, not ground she has to cross.
const RESISTANCE_PACKAGE_DECAY_MULTIPLIER := 0.5

const EXCITEMENT_DECAY_PRECINCT_MULTIPLIER := 1.5

## What the **ground** does to the decay, best to worst: calm, precinct, ordinary street, alley,
## main road.
##
## This is what makes a route a **recovery rate** rather than only a set of things to walk past,
## and what makes a precinct worth walking to although it is loud: a retail street is busy, and it
## is still the best place in the city that is not a park to bring a meter down.
##
## **The multipliers are ratios and the absolute rates are the design**, so a change to the walking
## rate above moves every one of these to keep its own ground where it was put:
##
##     calm 12.0/s   precinct 9.0/s   street 6.0/s   alley 3.5/s   main road 0.12/s
##
## The park has to read on *both* bars, not just the sleepiness one — half of "this is working" is
## the excitement visibly falling away as she walks in under the trees. **Its floor is that a park
## must stay a place rather than a switch**: at 12.0/s a full meter takes eight and a third seconds
## to clear, which is long enough to be somewhere she walks to and stays in. Much faster and the
## park is a button she taps.
##
## The main road is the same sentence inverted, and nearly all the way there: it is the one ground
## in the city that gives back next to nothing, at any density, which is most of what "a main road
## is crossed, not walked" means arithmetically — walking it for any stretch is walking ground that
## does not recover rather than ground that merely recovers slowly. `tests/probes/m117_decay.gd`'s
## main-road leg reads +5.69/s net on day 1 and +1.36/s on day 9, three seeds each: even where the
## spine has thinned to the lightest traffic of the run, it still costs rather than gives anything
## back.
##
## **It is the lever that holds the spine's own price**, because it is the one number exclusive to
## this corridor — the pedestrian field above only reaches `Tuning.PEDESTRIAN_OUTER_RADIUS` now, short
## enough that the arterial's own crowd noise cannot carry that price alone, and a louder car would
## be loud on every street it also drives down rather than only this one. Crossing the road stays a
## soft block rather than a wall: `tests/crowd_rig.gd`'s worst-of-eight crossing reads 27.76 of a
## hundred-point meter, comfortably under half, because the same short pedestrian reach that costs
## the ground its own recovery also lightens what a crossing itself loads.
##
## **An alley sits between the two** — pressured ground rather than a shortcut to recovery, which
## is what keeps `Baby.EXCITEMENT_FROM_ALLEY` (3.0/s of constant dread) meaning something: it sits just
## under the 3.5/s an alley gives back, so an empty alley is very nearly flat and is never quite
## recovery.
const EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER := 2.0

const EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER := 0.02

@onready var _entities: Node2D = $Entities
@onready var _buildings_layer: Node2D = $Buildings
## The ground layer the residency prepares and evicts region by region (`SceneryResidency.update()`
## reads it to do so), and the clock the buildings' animation phase follows.
@onready var scenery_ground: SceneryGround = $Ground
@onready var _decals: CityDecals = $Decals
@onready var _building_shadows: BuildingShadows = $BuildingShadows

var _map: CityMap
## How everything that moves over `map` moves (`Navigator`): built over the map by `build()` and
## held here for as long as the city stands, so the events, the crowd and whatever else moves over
## the map share the one (`navigator()`).
var _navigator: Navigator

## The map `build()` was handed: the streets, blocks and tiles this city stands on.
func map() -> CityMap:
	return _map

## How everything that moves over `map` moves: the navigator `build()` made, which the builder hands
## to the events and the crowd, and `main` to the resistance.
func navigator() -> Navigator:
	return _navigator

## Today's streets as dawn left them (`DayStreets`): the route tree, the region wall and doors, the
## closures and the region a siting reads. Made with the city, written only by the city's dawn
## (`_close_streets()`, `start_recipe_day()`), and handed to whoever asks (`streets()`).
var _streets := DayStreets.new()
## Where the city and the day's closures write their own account for the run log — handed in by
## `equip()` before `build()`, which hands it on to the fronts; silent until then.
var _trace := RunTrace.new()

# ------------------------------------------------- handed in before build() reads them ---
## How this city draws and schedules its own ground and scenery, handed in by whoever builds it —
## `main`, from the run's configuration — before `build()` reads them (`equip()`,
## `use_ground_recipe()`, `use_run()`, `schedule_scenery()`, `leave_out()`). The defaults are an
## ordinary run's, which is what a test's own city gets. What moves on the city is stood by
## `SimulationBuilder`, which `main` equips the same way.

## How a needed nearby ground region is scheduled (`--ground-mode`). See `SceneryGround.Mode`.
var _ground_mode := SceneryGround.Mode.ONE
## A scripted recipe's frame-locked playback, handed on to the residency
## (`SceneryResidency.lock_to_frames()`).
var _frame_locked := false
## `--skip shadows`: what a frame reading leaves out of the city's own drawing. See
## `DevFlags.skip_words()`.
var _skip_shadows := false
## Where the scenery queue charges its time to the frame record, handed in by `equip()`; the null
## sink until then.
var _timing := FrameTiming.new()
## The lights on the spine. Held here because both the traffic and the signal heads read it, and
## advanced by `Crowd`, which is the thing a rig steps — see `Crowd.step()`.
var _signals: TrafficSignals
var _daylight: CanvasModulate
## The light of the day (`set_daylight()`) and how far a blast lifts it (`light_the_sky()`), which
## the daylight's colour is made of (`_show_the_light()`).
var _light_of_the_day := Color.WHITE
var _sky_lit := 0.0
var _act := 1
## Today's day number, read by `_paint_ground()` for the crack level `GroundTiles` picks —
## `Tuning.degradation_for(_day)`. 1 (no degradation) until `start_day()` sets it, which happens
## before a player ever sees the city `build()` painted it with.
var _day := 1
## The scene's TileSet is the immutable source for every daily repaint. Reusing the Ground layer's
## current TileSet would feed a prior day's composed grass atlas back into the compositor.
var _authored_ground_tile_set: TileSet
var scenery: SceneryResidency
## The walk whose kerbs are tinted (`tint_the_route()`): the day's tree, or the escape's chains once
## they are planned. Null until one is handed in, and again after every repaint of the ground.
var _tinted_route: RouteSource = null
## Rebuilt every day from the block purposes; freed and replaced wholesale.
var _props: Array[Node2D] = []
## The barriers and wreckage that say which streets today closed (`_streets.closures()`). Rebuilt
## daily.
var _closure_nodes: Array[Node] = []
## Fixed for the run — only their condition changes.
var _buildings: Array[Building] = []
## The run the city stands in, handed in rather than reached for through a global: what is
## pasted on the walls (`posters`), the scars and block arcs a lost day gives back
## (`attempt_spend`), whether the pram carries the package (`resistance`), and the seed and day
## streams the walls are pasted from, which `PosterWalls` is handed in turn. Whoever builds the city
## hands it over before `build()` (`use_run()`, from `main._new_city()` or `RunCity` in a test);
## `build()` refuses a city without it.
var _run: RunState = null
## The ground's composition recipe, read from disk once per process: `main._new_city()` hands the
## one the sitting holds (`use_ground_recipe()`), so every day's city composes from the same read. A
## city nobody handed one (a suite's) reads the file itself, once.
var _ground_recipe := GroundRecipe.new()
## The baked atlas pages this city and everything it builds draw from (`AtlasLibrary`):
## `equip()` hands the sitting's, and the city hands it on to its buildings, props,
## exits, lights, markers, ground and decals. `main` and `RunCity` hand it in; `build()` refuses a
## city never equipped.
var _atlas: AtlasLibrary = null
## What the decals, every vent's turning rotor and every closure piece lay their pictures through
## (`SceneryDrawer`): the one drawer, handed to the decals, to every closure piece and, inside the
## roof drawer, to every building.
var _scenery_drawer := SceneryDrawer.new()
## Fixed for the run, from `StreetTrees.planted()` — unlike `_props`, never rebuilt daily: a
## street tree is frontage, not a block's own purpose, so it stands whatever the block behind it
## becomes.
var _street_trees: Array[Prop] = []
## The same props, keyed by the pit tile they stand in — what `refresh_street_trees()` looks a
## fallen tree's own pit up in. Keyed by tile rather than by world position because that is what
## the planners hand back, and a float position is not a key.
var _street_tree_pits := {}

## Region name of the door's own picture in the "decoration" atlas group.
const DOOR_TEXTURE := &"props/door"
## Region name of her street door once day 10's raid has sealed it — `art/buildings/
## home_door_sealed.svg`, the same 26×34 canvas and feet anchor as `DOOR_TEXTURE` (`docs/
## GRAPHICS.md`), so swapping `_home_door`'s texture needs no change to its offset or position.
const SEALED_DOOR_TEXTURE := &"buildings/home_door_sealed"
## `run.attempt_spend().scars()` id for the sealed street door, recorded at the doorstep by
## `ResistanceHappenings._maybe_raid()` once the raid actually arrives. No `since_day` comparison
## is needed the way `DawnMasts.SILENCED_MAST` reads one: `_spawn_home()` and `start_day()`'s
## `_sync_home_door()` both run after `RunCalendar.begin_day()`'s dawn photograph, so the
## scar's mere presence already answers "sealed as of this dawn" for every day after the one it
## was added on, and the moment it happens on its own day is `CityFronts.seal_home_door()`'s,
## called live.
const SEALED_DOOR_SCAR := "sealed_door"
## The street door sprite `_spawn_home()` built, kept so the dawn can put it right
## (`_sync_home_door()`) and handed to the fronts, which swap its texture live the moment day 10's
## raid actually arrives (`CityFronts.seal_home_door()`), instead of waiting for a day that never
## rebuilds it — `build()` runs once for the whole run (see the class doc).
var _home_door: HomeDoor
## The fronts the run's story changes (`CityFronts`), over `_buildings` and `_home_door`: built in
## `build()` once both stand, asked by the city's own dawn dressing, and handed to whoever asks
## (`fronts()`). Null before `build()`.
var _fronts: CityFronts

## The sealed/unsealed fact survives unloading; only the Sprite's texture reference is resident.
class HomeDoor extends Sprite2D:
	## The city's library, handed before `picture` is first set.
	var atlas: AtlasLibrary
	## Its standing with the scenery residency, which the city registers it with (`residence()`).
	var _residence := SceneryResidence.new(self, _scenery_bounds, _apply_residence)
	var picture: StringName:
		set(value):
			picture = value
			texture = atlas.region(picture) if _residence.is_resident() else null

	## What the scenery residency asks of the door: whether its picture is resident, the ground it
	## covers, and the switch between the two.
	func residence() -> SceneryResidence:
		return _residence

	## Takes the door's picture back from the atlas when it turns resident, and drops it when it
	## stops being.
	func _apply_residence(resident: bool) -> void:
		texture = atlas.region(picture) if resident else null

	func _scenery_bounds() -> Rect2:
		return Rect2(global_position + offset, Vector2(AtlasTable.baked().native_size(picture)))

## Hands the scene's `Buildings` and `Entities` over as the city's nodes for those draw layers
## (`add_entity()`), both y-sorted: everything on the ground sorts at its feet, and two lots sharing
## a block edge stack the way the eye expects. A building never sorts against an entity, being a
## layer of its own beneath them — see the note at the top of this file.
func _ready() -> void:
	layers().hold(DrawLayer.Layer.BUILDINGS, _buildings_layer, true)
	layers().hold(DrawLayer.Layer.ENTITIES, _entities, true)

## What the city and everything it builds is equipped with, before `build()`: the run log's trace,
## the baked atlas pages and the frame record the scenery queue charges its time to. The same three,
## in the same order, as `SimulationBuilder.equip()`, so `main` equips both alike.
func equip(run_trace: RunTrace, library: AtlasLibrary, frame_timing: FrameTiming) -> void:
	_trace = run_trace
	_atlas = library
	_timing = frame_timing

## The library this city draws from and hands on to what it builds (`equip()`). The game never
## asks it back; tests/test_atlas_boot.gd reads it to hold that the city draws from the sitting's.
func atlas() -> AtlasLibrary:
	return _atlas

## The ground's composition recipe the city composes every day's ground from, in place of the file
## it reads itself.
func use_ground_recipe(recipe: GroundRecipe) -> void:
	_ground_recipe = recipe

## The run the city stands in; `build()` refuses a city never handed one.
func use_run(the_run: RunState) -> void:
	_run = the_run

## The two ways the scenery's preparation is scheduled: how a needed ground region is scheduled
## (`--ground-mode`), and whether a scripted recipe's playback is locked to frames.
func schedule_scenery(mode: SceneryGround.Mode, frame_locked: bool) -> void:
	_ground_mode = mode
	_frame_locked = frame_locked

## Whether the city's own shadow drawing is left out (`--skip shadows`), named as
## `SimulationBuilder.leave_out()` is.
func leave_out(shadows: bool) -> void:
	_skip_shadows = shadows

## What the decals, every vent's turning rotor and every closure piece lay their pictures through,
## in place of the one the city makes; before `build()`. The game uses the default, a suite hands
## a recording drawer.
func draw_scenery_through(drawer: SceneryDrawer) -> void:
	_scenery_drawer = drawer

## Everything that is fixed for the whole run. What a block *is* changes day to day, and
## that lives in `start_day()`.
func build(city_map: CityMap) -> void:
	if _run == null:
		push_error("City.build(): the run must be handed in first")
		return
	assert(_atlas != null, "City.build(): equip() must hand the city its library first")
	_map = city_map
	_navigator = Navigator.new(_map)
	scenery = SceneryResidency.new()
	scenery.use_frame_timing(_timing)
	scenery.lock_to_frames(_frame_locked)
	scenery.setup(self, _map, scenery_ground, _building_shadows, _decals)
	add_child(scenery)
	scenery_ground.use_mode(_ground_mode)
	_decals.use_atlas(_atlas)
	_decals.draw_through(_scenery_drawer)
	_decals.stream_in_chunks()
	_building_shadows.stream_in_chunks()
	_building_shadows.draw_through(ShadowDrawer.new())
	_building_shadows.skip_drawing(_skip_shadows)
	# The street's decoration, acquired before the first day is drawn. The baked "decoration" page
	# loads synchronously on `acquire()`, so every draw below already has a region to ask for —
	# see `AtlasLibrary`.
	_atlas.acquire(CityDecals.DECORATION_ATLAS)
	_paint_ground()
	# Buildings first: the door sits in the wall of the building above the notch, at exactly
	# the same y. A y-sort tie is broken by tree order, so the door has to be added second
	# or the wall draws over it.
	_spawn_buildings()
	# Footprints are fixed for the run (`docs/DECISIONS.md`, M61); streamed shadow chunks derive
	# their geometry from this source as they become resident.
	var shown_rects: Array[Rect2i] = []
	for footprint in _map.building_lots():
		if _recipe_shows_building(footprint):
			shown_rects.append(footprint)
	if _map.has_stretch():
		_building_shadows.use_falls_on(_map.in_stretch)
	_building_shadows.set_buildings(shown_rects)
	if _recipe_contains(_map.home_world_position()):
		_spawn_home()
	_fronts = CityFronts.over(_buildings, _home_door, _door_world_x_range(), _map, _run, _trace)
	_spawn_street_trees()
	_spawn_boundary()
	if _map.has_stretch():
		_spawn_the_void_edge()
	elif not _map.has_recipe_exterior():
		_spawn_the_edge_of_the_city()
	_signals = TrafficSignals.new(_map)
	_spawn_signal_heads()
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
	if _atlas != null:
		_atlas.release(CityDecals.DECORATION_ATLAS)

## Which act's cast the city is under. See Palette.act_tint.
##
## Overrides CityDressing.set_act.
func set_act(act: int) -> void:
	_act = act

## 1.0 at dawn, 0.0 at dusk. The day timer is shown as the light going, with the clock in
## the HUD as the precise version for anyone who wants it.
##
## Overrides CityDressing.set_daylight.
func set_daylight(fraction: float) -> void:
	if not _daylight:
		return
	var light := Palette.LIGHT_MIDDAY.lerp(Palette.LIGHT_DUSK, 1.0 - fraction)
	var tint := Palette.act_tint(_act)
	_light_of_the_day = Color(light.r * tint.r, light.g * tint.g, light.b * tint.b)
	_show_the_light()

## **The sky lit by a blast**, `level` of the way from the day's own light to
## `Palette.ESCAPE_FLASH_LIGHT`, the light a hallway of the escape's building lifts to while its
## windows flash, so a blast lights the street as it lights the corridor (`BlastLight`). 0 is the
## day's light alone.
##
## Overrides CityDressing.light_the_sky.
func light_the_sky(level: float) -> void:
	_sky_lit = clampf(level, 0.0, 1.0)
	_show_the_light()

## The day's light, lifted toward the blast's by how lit the sky is.
func _show_the_light() -> void:
	if _daylight:
		_daylight.color = _light_of_the_day.lerp(Palette.ESCAPE_FLASH_LIGHT, _sky_lit)

# ------------------------------------------------------------ WorldContext ---

## How much faster the sleepiness meter fills on this ground.
##
## 1.0 off calm ground, and `Tuning.sleepiness_calm_multiplier` on it — which is a function of **how
## many blocks the lot has**, not of the tile. A single park block and one corner of a four-block
## zone are the same grass, so this is the one ground question that cannot be answered from the tile
## type alone, and that is the reason for the cache below.
##
## Overrides WorldContext.sleepiness_multiplier.
func sleepiness_multiplier(world_position: Vector2) -> float:
	if not _map:
		return 1.0
	var tile := _map.world_to_tile(world_position)
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
## finding — see `RowGround`'s note that a ground lives exactly one walk.
var _sleepiness_tile := Vector2i(-1, -1)
var _sleepiness_answer := 1.0

func _sleepiness_on(tile: Vector2i) -> float:
	if not Tile.is_calm(_map.tile_at(tile)):
		return 1.0
	return Tuning.sleepiness_calm_multiplier(_map.calm_lot_blocks(
			_map.block_at(_map.tile_to_world(tile))))

## What the ground she is standing on does to her recovery: calm, precinct, ordinary, alley, main
## road, best to worst — and then, for the rest of a day she is carrying the resistance's package,
## worse again.
##
## A precinct beats a main road even where the two cross, and that is not an oversight: standing
## on brick is standing on brick, and the tile she is on is the whole of what this question is
## about. A main road's *pavement* is main road, though — the thing that makes it bad ground is
## the road beside it, not the surface under her.
##
## Overrides WorldContext.decay_multiplier.
func decay_multiplier(world_position: Vector2) -> float:
	var ground := _ground_decay_multiplier(world_position)
	if _run.resistance().is_carrying_package():
		# The one cost in the game that is not a field at a place: picking the package up makes
		# every street after it dearer for the rest of the day, rather than the street it was
		# picked up on.
		ground *= RESISTANCE_PACKAGE_DECAY_MULTIPLIER
	return ground

func _ground_decay_multiplier(world_position: Vector2) -> float:
	if not _map:
		return 1.0
	var type := _map.tile_type_at_world(world_position)
	if Tile.is_calm(type):
		return EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER
	# An alley is cut through a block rather than laid out as a corridor, so no street kind answers
	# for it and it would otherwise read as an ordinary street. It is asked before the corridors
	# for that reason and not by precedence: the two cannot overlap.
	if Tile.is_alley(type):
		return EXCITEMENT_DECAY_ALLEY_MULTIPLIER
	var tile := _map.world_to_tile(world_position)
	var across := _map.street_kind_at(true, tile)
	var along := _map.street_kind_at(false, tile)
	if across == GameEnums.StreetKind.PEDESTRIAN or along == GameEnums.StreetKind.PEDESTRIAN:
		return EXCITEMENT_DECAY_PRECINCT_MULTIPLIER
	if across == GameEnums.StreetKind.MAIN or along == GameEnums.StreetKind.MAIN:
		return EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER
	return 1.0

## Overrides WorldContext.is_alley.
func is_alley(world_position: Vector2) -> bool:
	return _map.is_alley(world_position) if _map else false

# ------------------------------------------------------------------ spawning ---

## The front door. A sprite in the y-sorted layer rather than part of the ground, so she
## passes in front of it the way she passes in front of any other wall.
func _spawn_home() -> void:
	var stoop := _map.tile_rect_to_world(_map.home_tile_rect())
	_home_door = HomeDoor.new()
	_home_door.atlas = _atlas
	# Sealed already on a boot that resumes on day 11 or later, or reloads a save written after
	# the raid — `_door_texture_for_today()` reads the run's scars (`run.attempt_spend()`), already loaded by the
	# time `main.gd` calls `City.build()`. Day 10 itself is `CityFronts.seal_home_door()`'s, called
	# live the moment the raid actually arrives.
	_home_door.picture = _door_texture_for_today()
	# Feet-anchored like everything else: the NODE sits on the ground plane at the back of
	# the notch and the art is offset upward from there. Putting the node at the sprite's
	# top instead makes y-sort compare the wrong edge, and the player walks in front of a
	# door she is standing north of. (Buildings cannot occlude it: they are a layer of their own,
	# underneath the entities.)
	_home_door.centered = false
	# Both door pictures share one canvas (`SEALED_DOOR_TEXTURE`'s own doc), so this size and
	# offset stay correct whichever one is showing, today or after a live swap.
	var door_size := AtlasTable.baked().native_size(DOOR_TEXTURE)
	_home_door.offset = Vector2(-door_size.x * 0.5, -door_size.y)
	# Same centre-x `_door_world_x_range()` hands the building behind it, so the sprite and the
	# blanked window column can never disagree about where the door actually is.
	var x_range := _door_world_x_range()
	_home_door.position = Vector2((x_range.x + x_range.y) * 0.5, stoop.position.y)
	add_entity(_home_door)
	scenery.register(_home_door.residence())

## `SEALED_DOOR_TEXTURE` once the scar it leaves is on record, `DOOR_TEXTURE` before then.
func _door_texture_for_today() -> StringName:
	if _run.attempt_spend().has_scar(SEALED_DOOR_SCAR):
		return SEALED_DOOR_TEXTURE
	return DOOR_TEXTURE

## Puts the street door where the run's scars say it belongs, for the dawn `start_day()`
## already runs every day: sealed from day 11 on and after a save/load, ordinary again the dawn a
## lost day 10 gives its own scar back (`run.run_parts().give_back()`), since
## `_spawn_home()` itself only ever runs once, at boot, for the whole run.
func _sync_home_door() -> void:
	if _home_door:
		_home_door.picture = _door_texture_for_today()

## The door's own world-space x-span, `[min, max)` — `DOOR_TEXTURE`'s native width, centred on
## `map.home_tile_rect()` the way `_spawn_home()`'s own sprite is. Read before the door itself
## exists (`_spawn_buildings()` runs first — see `build()`), so it stands on
## `map.home_tile_rect()` and `AtlasTable` rather than on the door node, and handed to every
## home-block `Building` so it can blank the ground-floor column(s) standing behind the door
## instead of drawing a window there.
func _door_world_x_range() -> Vector2:
	var centre_x := _map.tile_rect_to_world(_map.home_tile_rect()).get_center().x
	var half_width := AtlasTable.baked().native_size(DOOR_TEXTURE).x * 0.5
	return Vector2(centre_x - half_width, centre_x + half_width)

## `StreetTrees.planted()`'s own positions, drawn as `Prop`s once for the whole run — never
## rebuilt in `_dress_blocks()`, unlike a park's trees, because a street tree belongs to the
## street's own frontage rather than to what the block behind it currently is.
func _spawn_street_trees() -> void:
	var edges := _map.witness_only()
	var planted_trees := StreetTrees.planted(_map)
	_map.restore_edges(edges)
	if _map.has_stretch():
		# Only the stretch's own trees and their pits: a pit drawn out in the void is ground. The
		# authored tree positions supply drawing, pits and clearance from one list.
		var shown: Array[StreetTrees.Planted] = []
		for planted_tree in planted_trees:
			if _recipe_contains(planted_tree.position):
				shown.append(planted_tree)
		planted_trees = shown
	_decals.set_street_tree_pits(planted_trees, _map)
	for planted_tree in planted_trees:
		if not _recipe_contains(planted_tree.position):
			continue
		var tree := Prop.new()
		tree.dress(_atlas, Prop.Kind.STREET_TREE, hash(planted_tree.position))
		tree.position = planted_tree.position
		add_entity(tree)
		scenery.register(tree.residence())
		_street_trees.append(tree)
		_street_tree_pits[planted_tree.tile] = tree

## Hides the street tree in every pit today's plan emptied, and shows every other one — so the
## tree lying across a closed street is the one missing from the row beside it.
##
## **Called twice a day, and both times are load-bearing.** `start_day` below runs it once the
## closures are planned, which is where a `FALLEN_TREE` closure's own pit is decided; the day's
## start (`DayDirector.start()`) runs it again once `EventManager.start_day` has planned the seals,
## because a `fallen_tree_seal` is chosen later and takes a pit of its own. Reading
## `CityMap.is_tree_pit_emptied` rather than keeping a list here is what lets the second call be a
## plain refresh rather than a second bookkeeping path.
##
## Overrides CityDressing.refresh_street_trees.
func refresh_street_trees() -> void:
	for tile: Vector2i in _street_tree_pits:
		var tree: Prop = _street_tree_pits[tile]
		tree.visible = not _map.is_tree_pit_emptied(tile)
	_decals.refresh_street_tree_pits()

## Sets a recipe's roof furniture on the building standing on `lot`
## (`Building.author_roof_furniture()`), or answers the one problem that no building stands there.
##
## Overrides CityDressing.furnish_a_roof.
func furnish_a_roof(lot: Rect2i, fixtures: Array) -> Array[String]:
	var errors: Array[String] = []
	var found := false
	for building in _buildings:
		if building.lot_rect() == lot:
			found = true
			errors.append_array(building.author_roof_furniture(fixtures))
	if not found:
		errors.append(NO_BUILDING_ON_THE_LOT)
	return errors

## Restarts the signals' cycle, runs it on `into_the_cycle` seconds and cuts their power when `dark`.
##
## Overrides CityDressing.start_the_signals.
func start_the_signals(into_the_cycle: float, dark: bool) -> void:
	_signals.restart_cycle()
	_signals.advance(into_the_cycle)
	if dark:
		_signals.use_power(false)

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
	_spawn_exit(CityEdge.Piece.TUNNEL, tunnel_world_position())
	_spawn_exit(CityEdge.Piece.TUNNEL_DARK, tunnel_world_position())
	_spawn_exit(CityEdge.Piece.BRIDGE, bridge_world_position())

## The spine's own centre line, in world space — where both exits are anchored, and the one place
## that arithmetic lives now that the finale asks where the ways out are as well as drawing them.
func _spine_centre_x() -> float:
	return (_map.main_road_corridor() * CityMap.period()
			+ Tuning.STREET_WIDTH * 0.5) * float(Tuning.TILE_SIZE)

## The tunnel mouth, at the north end of the spine.
func tunnel_world_position() -> Vector2:
	return Vector2(_spine_centre_x(), 0.0)

## The bridge deck, at the south end of the spine.
func bridge_world_position() -> Vector2:
	return Vector2(_spine_centre_x(), _map.world_size().y)

## The dark inside the tunnel goes in a layer of its own above the entities, so it lands on a car
## as the car drives in; the portal's face is y-sorted with them; the bridge and the road are
## ground and go under them. `CityEdge` says why the dark cannot be y-sorted too.
func _spawn_exit(piece: CityEdge.Piece, at: Vector2) -> void:
	var exit := CityEdge.new()
	exit.dress(_atlas, piece)
	exit.position = at
	if exit.overhangs():
		add_entity(exit, DrawLayer.Layer.OVERHEAD)
	elif exit.occludes():
		add_entity(exit)
	else:
		add_entity(exit, DrawLayer.Layer.BUILDINGS)
	scenery.register(exit.residence())

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
	# One drawer for every head: it holds nothing but the atlas the heads draw from.
	var drawer := TrafficLightDrawer.new(_atlas)
	for x in CrowdLanes.corridor_count(Tuning.CITY_BLOCKS.x):
		for y in CrowdLanes.corridor_count(Tuning.CITY_BLOCKS.y):
			var junction := Vector2i(x, y)
			if not _signals.has_lights(junction):
				continue
			var centre := Vector2(x * CityMap.period() + Tuning.STREET_WIDTH * 0.5,
					y * CityMap.period() + Tuning.STREET_WIDTH * 0.5) * float(Tuning.TILE_SIZE)
			var arms: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
			for heading in arms:
				var right := Vector2(-heading.y, heading.x)
				var at := centre - heading * (half + inset) + right * kerb
				if not _recipe_contains(at):
					continue
				if not _map.is_walkable(_map.world_to_tile(at)):
					continue
				var light := TrafficLight.new()
				light.mount(_atlas, drawer, junction, _signals)
				light.faces(heading)
				light.position = at
				add_entity(light)
				scenery.register(light.residence())

func _spawn_buildings() -> void:
	# A stretch's buildings are measured against the city they were cut from — which of their
	# columns a neighbouring roof covers, how far a roof reaches over an alley — rather than
	# against the void round the stretch, which would read every edge of it as more building.
	var edges := _map.witness_only()
	var door_x_range := _door_world_x_range()
	# One drawer for every roof and one for every front: each holds nothing but the atlas the
	# buildings draw from, and the roof's also the scenery drawer its vents' rotors lay their frames
	# through.
	var roof_drawer := RoofDrawer.new(_atlas, _scenery_drawer)
	var front_drawer := FrontDrawer.new(_atlas)
	var buildings: Array[Building] = []
	for rect in _map.building_lots():
		var world := _map.tile_rect_to_world(rect)
		var building := Building.new()
		building.equip(_atlas, roof_drawer, front_drawer)
		building.use_scenery_clock(scenery_ground)
		# Origin is the south edge centre of the lot (see building.gd).
		building.position = Vector2(world.get_center().x, world.end.y)
		building.stand_on(rect, world.size, _variant_for(rect), _map.starting_purpose(block_of(rect)),
				_height_for(rect, rect.size.y))
		# A stretch's authored values are the inputs to its geometry, not a repaint after it: the
		# height decides the roof extension a touching lot needs, and the variant decides the tint
		# shared by pieces of one courtyard. Ordinary generated cities have no listed values, so
		# this changes nothing for them.
		_draw_as_the_recipe_says(building)
		# Every lot on the home block is hers — the door's own notch carves no `Building` of its
		# own, so this is every wall standing around it.
		building.stand_on_home_block(block_of(rect) == _map.home_block_coordinate())
		if building.is_on_home_block():
			# Only the one lot the door notch's own footprint overlaps ever reads this as true —
			# every other home-block lot's world x sits entirely outside the door's span, since
			# `CityGenerator._subtract_all()` cuts the notch's own columns out of them — but handing
			# it to all of them costs nothing and needs no lookup for which one that is.
			building.mark_door_span(door_x_range)
		# Dressed here, before coverage and the roof extension below are computed, since
		# `assign_roof_extensions()` needs to know which buildings are the power station to keep an
		# extension off its yard (no roof stands there to extend).
		_dress_the_power_station(building, rect)
		buildings.append(building)
	# Coverage and the roof extension it needs both read every lot's own `wall_tiles()`, fixed by
	# the generated or authored values above, so both run before any of them enters the tree — see
	# `_covered_ground_cols()` and `assign_roof_extensions()`. Never asked of her own building
	# (`Building.covered_ground_cols()` stays empty) — her own building's front is the one the player knows
	# as home and stays as it is, and the home block's own doorstep already exempts it from the
	# route-redundancy guarantee the same way.
	for i in buildings.size():
		if not buildings[i].is_on_home_block():
			buildings[i].mark_covered_ground_cols(_covered_ground_cols(_map.building_lots()[i]))
	var courtyard_of := _courtyard_lot_of(_map.building_lots())
	assign_roof_extensions(buildings, courtyard_of)
	_share_courtyard_tint(buildings, courtyard_of)
	_map.restore_edges(edges)
	for building in buildings:
		if not _recipe_shows_building(building.lot_rect()):
			building.free()
			continue
		# Their own layer, under the entities — see the note at the top of this file. They still
		# y-sort against each other, which costs nothing and keeps two lots that share a block
		# boundary stacking the way the eye expects.
		# Roof pictures stand in the y-sorted entity layer at their feet. Tall roof equipment can
		# reach into the walkable row north of the lot, so it must sort against street actors just
		# like the power station stacks do.
		building.put_roof_objects_in(_entities)
		add_entity(building, DrawLayer.Layer.BUILDINGS)
		_buildings.append(building)
		scenery.register(building.residence())
		# The one part of a building drawn among the entities — see the note at the top of this file.
		var feet := building.stack_feet()
		for i in feet.size():
			var stack := Building.StationStack.new()
			stack.atlas = _atlas
			stack.name = "StationStack%d" % i
			stack.position = building.position + feet[i]
			add_entity(stack)
			scenery.register(stack.residence())

## `Building.covered_ground_cols()` for `rect`: true at column `col` where the tile directly south of
## `rect`'s own front row — one row below its south edge, the row a passer-by would stand on — is
## `GameEnums.TileType.BUILDING` rather than walkable ground. `map.is_walkable()` is the fixed
## lattice fact the **city** skill asks for — "no purpose change may move a walkable tile" — never
## `is_open()`'s per-day closures, so this is computed once here rather than in `start_day()`. This
## is the candidate set only: `assign_roof_extensions()` keeps a column covered only where a roof
## actually reaches it, so a south tile past the map's own edge (`CityMap.tile_at()` reads it as
## `BUILDING`) or a power station's yard leaves its front's facade standing.
func _covered_ground_cols(rect: Rect2i) -> Array[bool]:
	var result: Array[bool] = []
	var south_row := rect.position.y + rect.size.y
	for col in rect.size.x:
		result.append(not _map.is_walkable(Vector2i(rect.position.x + col, south_row)))
	return result

## `Building.extend_roof_over()` and the courtyard seams (`Building.mark_courtyard_seams()`) for every
## building in `buildings` (parallel to `map.building_lots()`): wherever a building's own
## `covered_ground_cols()` marks a column covered, the tile directly south of it belongs to some
## other lot's rect — the one whose roof now has to reach up to meet the covered building's own
## roof — found by a tile lookup over every rect rather than a spatial search, since the whole set
## is small and built once per run. The extension at that column is exactly the covered
## building's own `wall_tiles()`: precisely enough rows to reach the world row its roof already
## starts at, edge to edge. A power
## station's yard columns (`hall_cols()`, read after `_dress_the_power_station()` above has made
## it the station, `is_power_station()`) are skipped since no roof stands there to extend — the yard is fenced ground,
## not a building mass.
##
## **A front column draws no facade only where a roof actually covers it.** Once every extension
## is placed, each building's `covered_ground_cols()` is narrowed to the columns an extension
## reached; a column nothing covers — a yard's, a tile past the map's edge, any south tile no lot
## owns — keeps its facade, since a column with neither a facade nor a roof over it shows the dark
## background where its wall would be (the player, shown one: "Keep its facade"). Nothing reads
## `covered_ground_cols()` before this, so the door and every other roll see only the final answer.
##
## **Seamless when both rectangles are cut from the same courtyard lot.** A single-block or
## apartment-complex courtyard is cut into up to four rectangles around its hole
## (`CityGenerator._build_block()`'s own `COURTYARD` branch, `_subtract_all()`), each its own
## `Building` — so a covered seam between two of them is two pieces of one physical building, not
## a front covering a genuinely separate one behind it, and the extension that fills it reads as
## the *same* roof continuing rather than stopping in a parapet. `courtyard_of` maps each building
## index to whichever courtyard's own `map.lot_rect(block)` encloses it, or -1
## (`_courtyard_lot_of()`). Both sides of a seamless seam are marked — the covering piece's column
## as its extension's seam, the covered piece's as its covered column's
## (`Building.mark_courtyard_seams()`) — and `Building._roof_cell_edges()` withholds both lips there. A covered piece with no roof rows at
## all is never seamless: nothing of its own carries on above the extension, so the extension caps.
func assign_roof_extensions(buildings: Array[Building], courtyard_of: Array[int]) -> void:
	var tile_to_index := {}
	for i in _map.building_lots().size():
		var rect: Rect2i = _map.building_lots()[i]
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
	var covered: Array[Array] = []
	var reached: Array[Array] = []
	for building in buildings:
		var cols := building.covered_ground_cols()
		covered.append(cols)
		var none: Array[bool] = []
		none.resize(cols.size())
		none.fill(false)
		reached.append(none)
	for i in buildings.size():
		var back := buildings[i]
		var back_covered: Array[bool] = covered[i]
		if back_covered.is_empty():
			continue
		var rect: Rect2i = _map.building_lots()[i]
		for col in back_covered.size():
			if not back_covered[col]:
				continue
			var south := Vector2i(rect.position.x + col, rect.position.y + rect.size.y)
			var front_index: int = tile_to_index.get(south, -1)
			if front_index < 0:
				continue
			var front := buildings[front_index]
			var front_rect: Rect2i = _map.building_lots()[front_index]
			var local_col := south.x - front_rect.position.x
			if front.is_power_station():
				var hall := front.hall_cols()
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
		buildings[i].extend_roof_over(extensions[i])
		buildings[i].mark_courtyard_seams(seamless[i], seamless_below[i])
		var narrowed: Array[bool] = reached[i]
		if covered[i] != narrowed:
			buildings[i].mark_covered_ground_cols(narrowed)

## Gives every piece of one courtyard lot one tint (`Building.share_tint()`), so the rectangles a
## courtyard is cut into read as the one building they are rather than as three or four neighbours.
## An ordinary city takes the first piece's variant, as before. A stretch may show only part of a
## complete-context courtyard, so its first authored piece in the same canonical rectangle order
## supplies the tint instead; a hidden witness piece must not choose the visible colour. A tint
## rather than a shared variant (`Building.look_variant()`), which would erase the other authored
## rolls the buildings keep.
## `courtyard_of` is `_courtyard_lot_of()`'s answer for `map.building_lots()`.
func _share_courtyard_tint(buildings: Array[Building], courtyard_of: Array[int]) -> void:
	var first_variant := {}
	if _map.has_stretch():
		for i in buildings.size():
			var lot := courtyard_of[i]
			if lot < 0 or first_variant.has(lot) \
					or not _recipe_shows_building(buildings[i].lot_rect()):
				continue
			first_variant[lot] = buildings[i].look_variant()
	for i in buildings.size():
		var lot := courtyard_of[i]
		if lot < 0:
			continue
		if not first_variant.has(lot):
			first_variant[lot] = buildings[i].look_variant()
		buildings[i].share_tint(first_variant[lot])

## Which courtyard lot (an index into the courtyards found on `map`, or -1) each of `rects` was cut
## from — single-block and apartment-complex courtyards alike, a multi-block lot (`map.zone_anchors()`) or not, since both
## go through the same `COURTYARD` branch of `_build_block()` and both can split into more than one
## rectangle. `map.lot_rect(block)` is the whole lot a courtyard's rectangles were cut from, never
## smaller than any of them, so `encloses()` is exact rather than an overlap test.
func _courtyard_lot_of(rects: Array[Rect2i]) -> Array[int]:
	var courtyard_lots: Array[Rect2i] = []
	for block: Vector2i in _map.blocks_with_layouts():
		if _map.starting_purpose(block) == GameEnums.BlockPurpose.COURTYARD:
			courtyard_lots.append(_map.lot_rect(block))
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
## `CityMap.power_station_door_tiles()` names, and the transformer yard over the other block — the hall is
## the door's block and the street the mass was built across.
func _dress_the_power_station(building: Building, rect: Rect2i) -> void:
	if not _map.has_power_station() or rect != CityMap.blocks_tile_rect(_map.power_station_blocks()):
		return
	var door_col := _map.power_station_door_tiles().position.x - rect.position.x
	var door_is_west := door_col < Tuning.BLOCK_SIZE
	building.dress_as_power_station(door_col,
			Vector2i(rect.size.x - Tuning.BLOCK_SIZE if door_is_west else 0, Tuning.BLOCK_SIZE))

## The block a lot belongs to — the city's own lots and the fronts' (`CityFronts`).
static func block_of(rect: Rect2i) -> Vector2i:
	return (rect.position - Vector2i.ONE * Tuning.STREET_WIDTH) / CityMap.period()

## A home-block building's own fixed choice, keyed on nothing but the lot's own tile position —
## never `map.city_seed()` — so its wall/roof colour and `Building._build_windows()`'s own window
## style and lit-window pattern (keyed on `Building.look_variant()` and the building's world position, itself fixed
## since `CityMap.home_block_coordinate()` and every constant the lattice is built from are the same on every
## seed) no longer depend on the seed either. A non-home building keeps the per-seed roll.
func _variant_for(rect: Rect2i) -> int:
	if block_of(rect) == _map.home_block_coordinate():
		return absi(hash("home:%d:%d" % [rect.position.x, rect.position.y]))
	return absi(hash("%d:%d:%d" % [_map.city_seed(), rect.position.x, rect.position.y]))

func _height_for(rect: Rect2i, lot_depth_tiles: int) -> float:
	if block_of(rect) == _map.home_block_coordinate():
		return _home_building_height(rect, lot_depth_tiles)
	var range_tiles: Vector2i = _HEIGHT_TILES[_map.starting_purpose(block_of(rect))]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("h:%d:%d:%d" % [_map.city_seed(), rect.position.x, rect.position.y])
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
## `map.home_tile_rect()`, already fixed by the generator by the time this runs. The lot depth
## this is measured against (`lot_depth_tiles`) is `CityGenerator`'s own carve of the home
## block, six tiles for the door building on every seed tested — comfortably clear of the four
## wall rows plus at least one roof row this asks for; a seed where it were not would have to be
## reported as a fork rather than silently losing the roof, which is why this clamps to
## `rows() - 1` rather than reaching for `MAX_HEIGHT_FRACTION` as well.
func _home_building_height(rect: Rect2i, lot_depth_tiles: int) -> float:
	var world := _map.tile_rect_to_world(rect)
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
##
## **The escape's city is the same call with its section's spec** (`DaySpec`), since what
## differs is settings rather than steps: `spec.closes_the_streets()` says whether the day grows its
## route tree and closes streets off it (`_close_streets()`) or has its walk handed in once it
## is planned (`tint_the_route()` — the escape's chains, planned after the city is dressed, are
## not a tree for `ClosurePlanner` or `RegionPlanner` to be stated against, so
## `streets().route_tree()` and `streets().region_plan()` answer `null` and
## `streets().closures()` is empty, which is what their own contract says about a city whose day
## has grown none); `spec.pastes_posters` says whether the crews paste at dawn
## (`PosterWalls.dress_for()`) or the walls only show what the run left
## (`PosterWalls.show_only()`). The repaint, the door, the ground, the litter, the block
## dressing and the street trees happen either way, because the parks she walks through have to
## be the parks the run's seed built. The run flow hands `spec` in on every day and every
## section (`DayDirector.start()`, the same object the day's event manager is handed); left out, as a rig that
## builds a city with no run flow leaves it, it is a day's (`DaySpec.for_day()`). `day` is the
## calendar's — the escape is walked on the last day's — and `rng` the closures' stream.
##
## Overrides CityDressing.start_day.
func start_day(state: CityState, day: int, rng: RandomNumberGenerator,
		spec: DaySpec = null) -> void:
	if spec == null:
		spec = DaySpec.for_day(day)
	_dress(state, day)
	if spec.closes_the_streets():
		# Last, and after the repaint: which blocks are calm is what the closure invariant is
		# stated over, and a requisitioned park is not one of them.
		_close_streets(spec, rng)
	# And after the closures, since a `FALLEN_TREE` closure is what empties a pit. The day's start
	# runs it once more after the day's seals are planned — see `refresh_street_trees()`.
	refresh_street_trees()
	# After the tree is grown, which is what the dawn's pasting reads "the streets she uses most"
	# off, and after `_dress_blocks()`, which is what says a front has burnt: the walls paste on
	# this word (`PosterWalls.dress_for()`).
	day_dressed.emit(day, spec)
	scenery.update(_home_scenery_view(), true)

## Everything a day does to the city before its streets are closed: the repaint, the door, the
## ground, the litter and the block dressing.
func _dress(state: CityState, day: int) -> void:
	scenery.use_view(_home_scenery_view())
	_map.repaint(state, _trace)
	# Before anything reads the ground again: a park that burnt down last night is not calm today.
	_sleepiness_tile = Vector2i(-1, -1)
	_day = day
	# After `RunCalendar.begin_day()`'s own dawn photograph (`main.gd` calls this after
	# that), so a lost day 10's scar is already given back by the time this reads the run's
	# scars.
	_sync_home_door()
	_paint_ground()
	_decals.set_placed(_recipe_litter(day))
	_dress_blocks(state)

## Recipe activity is installed by its runtime after this shared day presentation. The
## explicit construction witness supplies global route/region context without randomly
## scheduling new closures over the authored composition.
##
## **A stretch pastes no dawn**: its posters are the recipe's own (`setup.posters`), so the walls are
## marked pasted through today before the day starts and nothing the seed would paste appears.
##
## `spec` is the walk's, as `start_day()` takes it (whether the region wall stands is its answer);
## left out, it is a day's (`DaySpec.for_day()`).
##
## Overrides CityDressing.start_recipe_day.
func start_recipe_day(state: CityState, day: int, _rng: RandomNumberGenerator,
		spec: DaySpec = null) -> void:
	if spec == null:
		spec = DaySpec.for_day(day)
	_dress(state, day)
	scenery.update(_home_scenery_view(), true)
	var edges := _map.witness_only()
	var tree := RouteTree.for_day(_map, day)
	var plan := RegionPlanner.plan_day(_map, spec, tree)
	_map.restore_edges(edges)
	var closures: Array[RoadClosure] = _map.recipe_road_closures().duplicate()
	_streets.begin_day(tree, plan, closures)
	_map.close_streets(closures)
	for closure in closures:
		_spawn_closure(closure)
	if _map.has_stretch():
		_run.posters().mark_pasted_through(day)
	day_dressed.emit(day, spec)

## The closed streets of the day `spec` describes. The whole street comes out of the network; the
## barriers stand at its two mouths, where they can be seen from the junction rather than found half
## way down.
func _close_streets(spec: DaySpec, rng: RandomNumberGenerator) -> void:
	var day := spec.day_number()
	for node in _closure_nodes:
		node.queue_free()
	_closure_nodes.clear()
	# Before the closures, because they are placed off it. See `ClosurePlanner._shuffled_candidates`.
	# Tinted before the region plan or the closures, so a tree a closure has not yet touched is what
	# the tint answers for.
	var tree := RouteTree.for_day(_map, day)
	tint_the_route(tree)
	# Before the closures too: a closure may not land on a region boundary (wall or door), which
	# `ClosurePlanner.plan_day` needs handed to it rather than recomputing — see its own doc.
	var plan := RegionPlanner.plan_day(_map, spec, tree)
	_trace.note("plan", "regions: %d boundary, %d wall, %d door, calm by region: %s"
			% [plan.wall_segments().size() + plan.door_segments().size(), plan.wall_segments().size(),
			plan.door_segments().size(), RegionPlanner.regions_with_calm(_map)])
	var closures := ClosurePlanner.plan_day(_map, spec, rng, tree, plan, _trace)
	_streets.begin_day(tree, plan, closures)
	_map.close_streets(closures)
	for closure in closures:
		_spawn_closure(closure)

## The route's own curbstones, tinted — a trial of whether a faint hint on the ground can stay under
## the threshold of being noticed as one; see `docs/CITY.md`, "Guiding her to the calm". **One tint
## for every walk**: the day's tree, handed in by `_close_streets()` as soon as it is grown, and the
## escape's two chains, handed in by `DayDirector.start()` after every plan of the section, a restart's included.
## *(Inbox #747: "yes, of course the yellow tint. we spent the whole game establishing that why would
## it be different in the last section?")*
##
## No second layer: `GroundLayers.build_tile_set()` already gave every kerb source
## (`GroundTiles.ROUTE_KERB_SOURCES`) a tinted twin (`GroundTiles.route_twin_of`), composed with the
## `curbstone` component (or, where the bake carries whole authored tiles, the stone's own fill) blended toward
## `Palette.ROUTE_KERB_TINT` by `GroundLayers.ROUTE_KERB_TINT_ALPHA` — so the paving around the stone is
## untouched. This only ever decides *which* cells qualify and re-sets each straight onto `scenery_ground`
## at its twin, same atlas coordinates: the two can never disagree about a cell's coordinates,
## because there is only the one layer. A twin that was never registered (an incomplete art drop)
## leaves the tile on its plain source, the same graceful fallback `GroundLayers` gives everywhere
## else. Alpha zero is the trial's off switch, with nothing else to change.
##
## **A kerb tile qualifies when the walk marks it** (`RouteSource.marks_the_kerb_at()`) **— the mark
## says *this street*, not *this sidewalk*.** Both pavements of every street the walk runs along are
## tinted, from intersection to intersection, whichever of the street's own cells the walk actually
## used: a tree that only uses part of a segment — leaving it through an alley or a park, or ending at
## a calm area partway along — still tints the whole segment, and a chain tints every street it walks
## (`SealPlanner.runs_through()`), the same set the escape's events stand on and its seals spare.
##
## **Never a street the walk only crosses at a junction, and never an unwalked stretch of the main
## road.** A junction cell resolves to no segment at all (`StreetNetwork.segment_containing`), so
## crossing one — a route switching pavements, or cutting through from a park or an alley — marks
## no street; `RouteTree.junctions()`'s own doc says the same thing from the other side, that such a
## crossing "contributes a junction no on-tree street names", and a chain's street it only turns at
## is sealed and carries no tint. And the main road's own cells, anywhere but at a junction, are off
## the tree's growth graph entirely (`RouteTree._is_off_the_growths_graph`), so no segment of the
## spine is marked on a day unless the tree's trunk genuinely had to walk it.
##
## **The placement rules keep the narrower question.** `RouteSource.carries_a_route(tile)` — whether
## the walk runs along *this cell* — is what a wall, a piece of friction or a set piece still asks;
## only the paint here asks the wider one, so nothing about where a body may stand moves with the
## mark. `_paint_ground()` paints every kerb cell its plain source first, so a twin from yesterday's
## walk cannot survive into today's.
##
## Overrides CityDressing.tint_the_route.
func tint_the_route(route: RouteSource) -> void:
	_tinted_route = route
	scenery_ground.repaint()

## The scenery's residency (`SceneryResidency.update()`) brought to `view` at once, every chunk and
## building within it prepared now: the day's start asks it round where she is put down, so the
## first frame there draws a whole street.
##
## Overrides CityDressing.prepare_scenery_in.
func prepare_scenery_in(view: Rect2) -> void:
	scenery.update(view, true)

## Whether a kerb tile is on today's tinted walk.
func _is_on_the_tinted_route(tile: Vector2i) -> bool:
	return _tinted_route != null and _tinted_route.marks_the_kerb_at(tile)

## Every building this city built, fixed for the run — read by `DebugLayers` so its bounding-box
## layer can trace each one's own `shape` rather than a second list of them.
##
## Overrides CityDressing.buildings.
func buildings() -> Array[Building]:
	return _buildings

## The lights on the spine (`TrafficSignals`), for whoever reads which junction shows red.
func traffic_signals() -> TrafficSignals:
	return _signals

## Which way the ground is scheduled this run (`schedule_scenery()`, the `--ground-mode` flag).
func ground_mode_in_force() -> SceneryGround.Mode:
	return _ground_mode

## Today's trees, bollards and playground frames (rebuilt daily by `_dress_blocks`), plus the
## street trees fixed for the whole run — read by `DebugLayers` so its shadow layer can trace
## each one's own `shape` the same way, and by `tests/test_blocks.gd`'s spacing check.
##
## Overrides CityDressing.props.
func props() -> Array[Node2D]:
	var all: Array[Node2D] = []
	all.append_array(_props)
	all.append_array(_street_trees)
	return all

## Today's streets as dawn left them (`DayStreets`): the route tree, the region wall and doors, the
## closures and the region a siting reads. The same object for the city's whole life; its answers
## change only at a dawn that closes streets, or when a rig or a scene recipe replaces the plan.
func streets() -> DayStreets:
	return _streets

## The fronts the run's story changes (`CityFronts`): the burnt frontage, the way in behind a
## sidewalk, a block shown during the day, the neighbor's window and her sealed door. Built once in
## `build()`, over the buildings and her door, which are fixed for the run.
##
## Overrides CityDressing.fronts.
func fronts() -> CityFronts:
	return _fronts

func _spawn_closure(closure: RoadClosure) -> void:
	# Supports precede the rails mounted on them. The sign's panel draws its composite
	# after the rail, at the run midpoint rather than at a panel endpoint.
	for feet in closure.posts(_map):
		var post := ParkFenceMarker.new() if closure is ParkClosure else ClosureMarker.new()
		post.use_atlas(_atlas)
		post.draw_through(_scenery_drawer)
		post.stand_as(ClosureMarker.Piece.POST, closure.kind(), true)
		post.position = feet
		_add_closure_node(post, true)
	for mouth in closure.mouth_centres(_map):
		_spawn_barrier(closure, mouth)
	if ClosureMarker.CAUSES.has(closure.kind()):
		var cause := ClosureMarker.new()
		cause.use_atlas(_atlas)
		cause.draw_through(_scenery_drawer)
		cause.stand_as(ClosureMarker.Piece.CAUSE, closure.kind(), closure.barrier_runs_across())
		cause.position = closure.cause_centre(_map)
		_add_closure_node(cause, true)

## A line of barrier panels across the mouth, with the sign on the middle one, and one static
## body behind the whole line. The panels are the line's slices (`DrawLayer.add_slices()`), each
## standing at its own feet, so a barrier running away from the camera y-sorts panel by panel
## against the player; the collision is one box, because collision does not care what order things
## are drawn in.
##
## **The line's width is the closure's own** (`barrier_width()`), a street's width for an ordinary
## closure and one calm area's own edge for a `ParkClosure` — so a run longer or shorter than a
## street's mouth still tiles panels edge to edge across its own real length rather than a fixed
## one, with no overlap and no gap to overshoot a corner with. The panels run the barrier's own
## footprint end to end (`_barrier_footprint()`, `DrawLayer.run_of()`), and a park's fence post to
## post (`ParkClosure.rail_ends()`).
func _spawn_barrier(closure: RoadClosure, at: Vector2) -> void:
	var across := closure.barrier_runs_across()
	var width := closure.barrier_width()
	var footprint := _barrier_footprint(closure)
	var picture_width := width
	var picture_at := at
	var ends := DrawLayer.run_of(footprint, at)
	if closure is ParkClosure:
		var fence := closure as ParkClosure
		# An open end's post is inset on its own ground. Rails end on that post, while
		# the collision below continues to cover the entire entrance as planned.
		var start_inset := 0.0 if fence.start_turns_a_corner() else ParkClosure.POST_HALF
		var end_inset := 0.0 if fence.end_turns_a_corner() else ParkClosure.POST_HALF
		picture_width -= start_inset + end_inset
		picture_at += (Vector2.RIGHT if across else Vector2.DOWN) * (start_inset - end_inset) * 0.5
		ends = fence.rail_ends()
	var pitch := float(AtlasTable.baked().native_size(ClosureMarker.FENCE_ACROSS).x)
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
	var feet := DrawLayer.slice_feet(ends[0], ends[1], panels)
	var slices: Array[Node2D] = []
	for i in panels:
		var panel := ParkFenceMarker.new() if closure is ParkClosure else ClosureMarker.new()
		panel.use_atlas(_atlas)
		panel.draw_through(_scenery_drawer)
		panel.stand_as(ClosureMarker.Piece.SIGN if i == sign_panel else ClosureMarker.Piece.FENCE,
				closure.kind(), across)
		panel.cover_slice(span, closure.end_on_rise())
		if panel is ParkFenceMarker:
			(panel as ParkFenceMarker).mount_rail(i < panels - 1,
					-(closure as ParkClosure).outward().x * 4.0)
			(panel as ParkFenceMarker).mount_sign(at - feet[i])
		slices.append(panel)
	DrawLayer.add_slices(self, slices, feet)
	for panel in slices:
		_track_closure_node(panel)

	var body := footprint.body()
	body.position = at
	_add_closure_node(body, false)

## **A closure's barrier line as a solid**: one box `barrier_width()` long and
## `Tuning.CLOSURE_BARRIER_DEPTH` deep, laid across the street or along the park's edge, its origin
## at the line's middle. Its body stops her (`_spawn_barrier()`); its tiles are closed ground, since
## the line stands on a mouth the closure takes (`CityMap.close_streets()`), so every other mover is
## stopped by the same line.
static func _barrier_footprint(closure: RoadClosure) -> Footprint:
	var width := closure.barrier_width()
	var size := Vector2(width, Tuning.CLOSURE_BARRIER_DEPTH) if closure.barrier_runs_across() \
			else Vector2(Tuning.CLOSURE_BARRIER_DEPTH, width)
	return Footprint.of(GroundShape.rect(size * 0.5))

func _add_closure_node(node: Node, y_sorted: bool) -> void:
	if y_sorted:
		add_entity(node)
	else:
		add_child(node)
	_track_closure_node(node)

## Keeps a closure's node for the day, to be taken down with it, and hands a picture to the scenery.
func _track_closure_node(node: Node) -> void:
	_closure_nodes.append(node)
	if node is ScenerySprite:
		scenery.register((node as ScenerySprite).residence())

func _dress_blocks(state: CityState) -> void:
	for prop in _props:
		prop.queue_free()
	_props.clear()
	if _map.has_stretch():
		_dress_the_stretch()
	else:
		for block: Vector2i in _map.blocks_with_plans():
			var purpose := state.purpose_of(_map.plans_by_block(), block)
			_dress_block(block, purpose)
		_dress_precincts()
		_place_garbage_sacks()
	for building in _buildings:
		var listed: Dictionary = _map.stretch_building_on(building.lot_rect())
		building.show_condition(int(listed.condition) as Building.Condition if not listed.is_empty() \
				else condition_for(state.purpose_of(_map.plans_by_block(), block_of(building.lot_rect()))))
		building.show_day(_day)
	_fronts.mark_the_burnt_frontage()

## A stretch's props are its recipe's (`CityMap.stretch_prop_list()`): every tree, swing frame, bollard
## and sack where the recipe puts it, in place of the rolls a day's blocks and streets would make.
func _dress_the_stretch() -> void:
	for listed in _map.stretch_prop_list():
		var prop := Prop.new()
		prop.dress(_atlas, int(listed.kind) as Prop.Kind, int(listed.variant), float(listed.scale))
		prop.position = listed.at
		_add_prop(prop)

## Today's garbage sacks — `GarbageSacks.placed()` re-rolled from the day, unlike the trees above:
## the city degrades over the run, so unlike a park's planting this is not the same every morning.
## Each is a `Prop` with a `GroundShape` for its shadow and no body, exactly as decorative as a
## bollard.
func _place_garbage_sacks() -> void:
	for entry in GarbageSacks.placed(_map, _day):
		var sack := Prop.new()
		sack.dress(_atlas, Prop.Kind.SACK_PILE if entry.pile else Prop.Kind.SACK)
		sack.position = entry.position
		_add_prop(sack)

## What a block's buildings look like now. A boarded-up street and a burnt-out one are the
## same footprints and very different places. The dawn dressing's and the fronts' own
## (`CityFronts.present_block()`), so a block shown during the day looks as a dawn would show it.
static func condition_for(purpose: GameEnums.BlockPurpose) -> Building.Condition:
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
	var layout: BlockLayout = _map.layout_of(block)
	if not layout or not layout.has_open_ground():
		return
	if purpose == GameEnums.BlockPurpose.PARK and layout.has_playground():
		var playground := _map.tile_rect_to_world(layout.playground_rect())
		var frame := Prop.new()
		frame.dress(_atlas, Prop.Kind.PLAYGROUND_FRAME, block.x * 31 + block.y)
		frame.position = Vector2(playground.get_center().x, playground.end.y - 8.0)
		_add_prop(frame)

	var per_block: int = _TREES.get(purpose, 0)
	if per_block == 0:
		return
	# A block's worth of open ground is the unit the table above is written in, so the count
	# follows the area actually being dressed. Clamped at one block from below rather than
	# scaled down: a courtyard is a quarter of a block and its three trees are what makes it
	# read as a court rather than as a yard, which is a tuned number and not an area.
	var block_area := float(Tuning.BLOCK_SIZE * Tuning.BLOCK_SIZE)
	var open := layout.open_ground()
	var lots := maxf(1.0, float(open.size.x * open.size.y) / block_area)
	var wanted := roundi(per_block * lots)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("props:%d:%d:%d" % [_map.city_seed(), block.x, block.y])
	var lot := _map.tile_rect_to_world(layout.open_ground())
	var placed := 0
	var attempts := 0
	# Every tree already placed in this lot, so a candidate too close to one of them is rejected
	# the same way one landing off calm ground already is — checked before it is ever added rather
	# than thinned out afterwards, the same rule closures and events are already held to.
	var planted: Array[Vector2] = []
	var spacing := _min_tree_spacing()
	# **The one exception to "the same every morning" is the one park this run ever fences.**
	# `ParkClosure`'s line stands on the lot's own edge row, and a tree seeded there before the
	# fence existed would stand on the fence line — cleared for the barrier the same way the
	# ground itself was, on the one occasion the ground changes at all. `margin` only widens past
	# the ordinary 16px inset while `block` is `map.fenced_park_block()`, so every other park's trees are
	# untouched by this at every reading.
	var margin := 16.0
	if _map.fenced_park_block() == block and ClosurePlanner.calm_area_rect(_map, block) == layout.open_ground():
		margin += Tuning.CLOSURE_BARRIER_DEPTH
	while placed < wanted and attempts < wanted * 8:
		attempts += 1
		var at := Vector2(rng.randf_range(lot.position.x + margin, lot.end.x - margin),
				rng.randf_range(lot.position.y + margin, lot.end.y - margin))
		# Keep the playground clear so the swing frame reads.
		if not Tile.is_calm(_map.tile_type_at_world(at)):
			continue
		if _map.tile_type_at_world(at) == GameEnums.TileType.PLAYGROUND:
			continue
		if _too_close_to_a_planted_tree(at, planted, spacing):
			continue
		var tree := Prop.new()
		tree.dress(_atlas, Prop.Kind.TREE, rng.randi(),
				rng.randf_range(PARK_TREE_SCALES.x, PARK_TREE_SCALES.y))
		tree.position = at
		_add_prop(tree)
		planted.append(at)
		placed += 1

## The least two trees in one lot may stand apart, centre to centre — read off the pictures rather
## than asked for: the widest tree picture at its own size (`TreePictures.widest_canopy()`) times
## the largest scale `_dress_block()` rolls (`PARK_TREE_SCALES`), the widest either canopy is ever
## drawn. Two canopies planted any closer than their own width overlap and read as one shape rather
## than as two trees, which is the clump this spacing exists to stop.
static func _min_tree_spacing() -> float:
	return TreePictures.widest_canopy() * PARK_TREE_SCALES.y

## Whether `at` lands within `spacing` (`_min_tree_spacing()`) of a tree this lot has already
## planted — pulled out from the loop above so the spacing rule is one line to read.
static func _too_close_to_a_planted_tree(at: Vector2, planted: Array[Vector2],
		spacing: float) -> bool:
	for other in planted:
		if at.distance_to(other) < spacing:
			return true
	return false

## A line of posts across the carriageway at each mouth of every precinct, so a street that
## meets one reads as closed on purpose rather than as the road running out. Placed from the map
## alone, with no rng: a closed mouth is geometry, not a roll, so `CityMap.post_positions()` needs
## no seed and a test can call it without building a scene.
func _dress_precincts() -> void:
	for at in _map.post_positions():
		var bollard := Prop.new()
		bollard.dress(_atlas, Prop.Kind.BOLLARD)
		bollard.position = at
		_add_prop(bollard)

func _add_prop(prop: Node2D) -> void:
	if not _recipe_contains(prop.position):
		prop.free()
		return
	_props.append(prop)
	add_entity(prop)
	if prop is ScenerySprite:
		scenery.register((prop as ScenerySprite).residence())

## The framing of the whole city plus its border band, for the cameras that look at the city
## rather than follow her: the `--overview` view, the dev rig and the trailer's zoom-out. The
## player's own camera has no limits, so it follows her centered with the look-ahead wherever she
## stands, and the ground past the edge is painted for whatever view asks
## (`scenery_ground_source()`). The rectangle is the map grown by the band painted outside it,
## less `look_ahead`, the reach a glance toward a corner costs, which the caller hands in because it
## is the player camera's own number (`Stroller.CAMERA_LOOK_AHEAD`), not the city's.
func camera_bounds(look_ahead: float) -> Rect2:
	if _map.has_recipe_exterior() or _map.has_stretch():
		return Rect2(-100000000, -100000000, 200000000, 200000000)
	var depth := CityMap.OUTSIDE_DEPTH_TILES * float(Tuning.TILE_SIZE)
	return Rect2(Vector2.ZERO, _map.world_size()).grow(depth - look_ahead)

## Walls just outside the map, so the player cannot walk off the edge of the world.
func _spawn_boundary() -> void:
	if _map.has_recipe_exterior() or _map.has_stretch():
		return
	var extent := _map.world_size()
	var t := BOUNDARY_THICKNESS
	var walls: Array[Rect2] = [
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

# ------------------------------------------------------------------ ground ---

## Configures the ground from `assets/ground_tileset.tres` and prepares its initial nearby chunks.
##
## This used to be ~120 lines of draw_rect and computed dashes. Kerbs, centre lines and
## zebra crossings are authored art now, chosen per cell by GroundTiles — which means they
## can be edited in a drawing program instead of by changing arithmetic, and it is one
## place rather than four.
func _paint_ground() -> void:
	_tinted_route = null
	scenery_ground.configure(_map, scenery_ground_source, _composed_ground_tile_set())
	var initial := scenery.view() if scenery.view().has_area() else _home_scenery_view()
	for key in scenery_ground.keys_in(initial.grow(SceneryResidency.LOAD_MARGIN)):
		scenery_ground.prepare(key)

func _home_scenery_view() -> Rect2:
	return Rect2(_map.doorstep_world_position() - Tuning.VIEW_HALF_EXTENT,
			Tuning.VIEW_HALF_EXTENT * 2)

## Current source, independent of residency. Border and route paint use this same answer
## at boot, on approach, after a closure, and when a distant chunk returns.
func scenery_ground_source(tile: Vector2i) -> int:
	if _map.has_stretch() and not _map.in_stretch(tile):
		return -1
	if _map.has_recipe_exterior() and not _map.recipe_window().has_point(tile):
		return GroundTiles.ALLEY
	if tile.x < 0 or tile.y < 0 or tile.x >= _map.size_in_tiles().x or tile.y >= _map.size_in_tiles().y:
		return _paint_outside_the_map(tile)
	var source := GroundTiles.source_for(_map, tile, _day)
	if source in GroundTiles.ROUTE_KERB_SOURCES and _is_on_the_tinted_route(tile):
		var twin := GroundTiles.route_twin_of(source)
		if twin >= 0 and scenery_ground.tile_set().has_source(twin):
			return twin
	return source

func _recipe_contains(at: Vector2) -> bool:
	if _map.has_stretch():
		return _map.in_stretch(_map.world_to_tile(at))
	return not _map.has_recipe_exterior() \
			or _map.recipe_window().has_point(_map.world_to_tile(at))

## Whether a building on `lot` is shown: every one in a city, those inside a bounded recipe's
## rectangle, and in a stretch only the recipe's own (`CityMap.stretch_building_lots()`).
func _recipe_shows_building(lot: Rect2i) -> bool:
	if _map.has_stretch():
		return _map.has_stretch_building_on(lot)
	return not _map.has_recipe_exterior() or _map.recipe_window().encloses(lot)

## Applies a stretch building's listed district, variant and wall height before any derived
## geometry or shared tint is computed, so a change to the seed roll cannot change either the
## handcrafted building or a roof joined to it. Nothing for any other city.
func _draw_as_the_recipe_says(building: Building) -> void:
	var listed: Dictionary = _map.stretch_building_on(building.lot_rect())
	if listed.is_empty():
		return
	building.draw_as(int(listed.district) as GameEnums.BlockPurpose, int(listed.variant),
			float(listed.height) * Tuning.TILE_SIZE)

## The walls round a stretch, where the void meets one of its tiles and no building of its own
## stands: a body on every such tile, one row of them at a time, so she, a pursuer and a nudge from
## the crowd all stop at the edge of the scene the way they stop at a frontage. Nothing is drawn.
func _spawn_the_void_edge() -> void:
	var walled := {}
	for lot: Rect2i in _map.stretch_building_lots():
		for tile in _map.rect_tiles(lot):
			walled[tile] = true
	var edge := {}
	for y in _map.size_in_tiles().y:
		for x in _map.size_in_tiles().x:
			var tile := Vector2i(x, y)
			if not _map.in_stretch(tile):
				continue
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var beside := tile + Vector2i(dx, dy)
					if not _map.in_stretch(beside) and not walled.has(beside):
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
			var strip := _map.tile_rect_to_world(Rect2i(start, y, last - start + 1, 1))
			var shape := CollisionShape2D.new()
			var rectangle := RectangleShape2D.new()
			rectangle.size = strip.size
			shape.shape = rectangle
			shape.position = strip.get_center()
			body.add_child(shape)
			if i < xs.size():
				start = xs[i]
				last = xs[i]
	add_child(body)

func _recipe_litter(day: int) -> Array[Litter.Placed]:
	var shown: Array[Litter.Placed] = []
	if _map.has_stretch():
		for listed in _map.stretch_litter_list():
			var entry := Litter.Placed.new()
			entry.position = listed.at
			entry.texture_index = int(listed.texture)
			shown.append(entry)
		return shown
	for placed in Litter.placed(_map, day):
		if _recipe_contains(placed.position):
			shown.append(placed)
	return shown

## Starts each repaint from the scene's authored TileSet, so the composition stays stable when a
## new day chooses different damage or grass cells — the authored resource names each source's
## baked region and holds no picture, so composing it twice can never accumulate layers.
func _composed_ground_tile_set() -> TileSet:
	if _authored_ground_tile_set == null:
		_authored_ground_tile_set = scenery_ground.tile_set()
	return GroundLayers.build_tile_set(_authored_ground_tile_set, _ground_recipe, _atlas)

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
	var south := y - (_map.size_in_tiles().y - 1)
	var west := -x
	var east := x - (_map.size_in_tiles().x - 1)

	if _leaves_by_the_spine(x):
		var on_to_the_bridge := south > 0
		var into_the_tunnel := north > 0 and north <= CityEdge.TUNNEL_DEPTH_TILES
		if on_to_the_bridge or into_the_tunnel:
			return GroundTiles.source_for(_map, Vector2i(x, clampi(y, 0, _map.size_in_tiles().y - 1)), _day)
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
	var offset := x - _map.main_road_corridor() * CityMap.period()
	return offset >= Tuning.SIDEWALK_WIDTH \
			and offset < Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH

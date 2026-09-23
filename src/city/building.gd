class_name Building
extends StaticBody2D
## A 2.5D extruded block, assembled from 32px facade and roof tiles.
##
## The node origin is the SOUTH edge centre of the lot, so y-sorting against the player
## uses the same ground plane the collision does. The lot spans local y in [-depth, 0].
##
## The building's drawn mass fills exactly its lot: the front wall takes the southern
## `height` px and the roof takes what is left. That is what an oblique view of a taller
## building actually looks like — more wall, less roof — and it keeps every extrusion off
## the *ground* the player walks on.
##
## **It does not follow that she is never hidden by one**, and that is the trap in the paragraph
## above. The mass extends a whole block north of the origin y-sort compares, so on its own a
## building draws in front of everything on the pavement beside it wherever the two also overlap in
## x. What is true is the stronger thing, and it is why the answer lives in `city.gd` rather than
## here: nothing can ever legitimately be *behind* a building, so nothing sorts against one.
##
##      lot top ─▶ ┌──────────┐  roof   y = -depth .. -height
##                 ├──────────┤
##                 │          │  wall   y = -height .. 0
##   origin (0,0)  └──────────┘
##
## Both bands are whole tiles. Heights used to be continuous floats, which meant a facade
## tile had to be stretched to fit; snapping to the tile grid is what lets the art be
## authored art. It also makes the old "a roof always shows" clamp exact rather than
## approximate — see `wall_tiles()`.
##
## Fills are authored near-white and multiplied by the variant's colour; edges, plinth and
## windows are overlays drawn at full colour on top. That is why a corner cell needs no
## dedicated corner tile: it simply takes two edge overlays and the parapet turns.

const TILE := float(Tuning.TILE_SIZE)

## How far the collision body's own north edge sits south of the lot's own north edge — the top
## of the wall in this projection, which is ground she may step a little way into rather than a
## wall she stops a tile short of. *(2026-09-11, the player, PLAYTEST-57.md: "also allow going in
## a little bit for northern edges of roofs.")* 6px, pinned here and open to overturn. The south
## edge is untouched: `_rebuild()` shrinks `shape.half_extents.y` by half of this and shifts the
## shape's centre south by the same half, so the south edge (the lot's own kerb, where the
## building meets the street) stays exactly where it was.
const NORTH_EDGE_INSET := 6.0

## Every picture below is a region name on the `buildings` atlas group — `AtlasLibrary.
## region_name_for()`'s own rule, written as a literal since the group is baked before this file
## ever runs. `_enter_tree()`/`_exit_tree()` acquire and release the group, so `AtlasLibrary.
## region()` only ever runs while it is held.
const WALL := &"buildings/wall"
const WALL_BASE := &"buildings/wall_base"
const WALL_EDGE_W := &"buildings/wall_edge_w"
const WALL_EDGE_E := &"buildings/wall_edge_e"
const ROOF := &"buildings/roof"
const ROOF_EDGE_N := &"buildings/roof_edge_n"
const ROOF_EDGE_S := &"buildings/roof_edge_s"
const ROOF_EDGE_W := &"buildings/roof_edge_w"
const ROOF_EDGE_E := &"buildings/roof_edge_e"
const WINDOW_DARK := &"buildings/window_dark"
const WINDOW_LIT := &"buildings/window_lit"
const WINDOW_TALL_DARK := &"buildings/window_tall_dark"
const WINDOW_TALL_LIT := &"buildings/window_tall_lit"
const WINDOW_SHUTTERED_DARK := &"buildings/window_shuttered_dark"
const WINDOW_SHUTTERED_LIT := &"buildings/window_shuttered_lit"

## Share of the wall cells that are lit at all. Fixed at build time, never per frame.
const LIT_WINDOW_CHANCE := 0.28
## Which window pair a building's upper floors use — rolled once per building, ordinary street
## variety rather than anything `condition` or the day changes. `SHUTTERED` here is a building that
## was built that way, lit or dark like any other; a `BOARDED` block forces every building to it
## regardless of this roll, and forces it dark, since `_lit()` already answers false off
## `LIVED_IN` — see `_window_texture()`.
enum _WindowStyle { PLAIN, TALL, SHUTTERED }
const TALL_WINDOW_CHANCE := 0.3
const SHUTTERED_WINDOW_CHANCE := 0.15

# ------------------------------------------------------------------- fronts ---
# A storefront replaces `WALL_BASE` across a two-column ground row (its own fill is opaque over the
# wall it sits on, the same way `WALL_BASE`'s plinth sits over the wall); an entrance door, a fire
# escape and a civic portico are overlays drawn after the wall, in front of everything a
# ground-floor cell already drew. The tint rules are untouched either way: none of these
# textures is multiplied by `Palette.building_wall` — they are already-coloured overlays, the
# same footing `WINDOW_DARK`/`WINDOW_LIT` already stand on. A door's transparent margin is what
# lets the building's own tinted wall show round its surround.

const STOREFRONT_TEXTURES: Array[StringName] = [
	&"buildings/storefront_a",
	&"buildings/storefront_b",
	&"buildings/storefront_c",
	&"buildings/storefront_d",
]
const STOREFRONT_AWNING_TEXTURES: Array[StringName] = [
	&"buildings/storefront_a_awning",
	&"buildings/storefront_b_awning",
	&"buildings/storefront_c_awning",
	&"buildings/storefront_d_awning",
]
## A shuttered shopfront: always on a `BOARDED` block, and — beneath the curve's own threshold —
## on a share of ordinary `LIVED_IN` commercial ground too, the city's own services failing ahead
## of any one block turning. See `_ground_floor_texture()`.
const STOREFRONT_SHUTTERED_TEXTURES: Array[StringName] = [
	&"buildings/storefront_a_shuttered",
	&"buildings/storefront_b_shuttered",
	&"buildings/storefront_c_shuttered",
	&"buildings/storefront_d_shuttered",
]
const FIRE_ESCAPE_A := &"buildings/fire_escape_a"
const FIRE_ESCAPE_B := &"buildings/fire_escape_b"
const CIVIC_PORTICO := &"props/civic_portico"
## The one way in a multi-story front with no storefront and no portico has — see
## `entrance_door_col()`. 32×36px, a whole wall cell wide and rising four pixels into the row above
## the way a storefront does, drawn standing on the ground line at its column's centre. An
## `INDUSTRIAL` front gets the heavier steel one; every other purpose that gets a door gets the
## plain one.
const ENTRANCE_DOOR := &"buildings/entrance_door"
const ENTRANCE_DOOR_INDUSTRIAL := &"buildings/entrance_door_industrial"

# ------------------------------------------------------------- power station ---
# The power station is a big building drawn as two parts: a hall over its door block and the
# street it was built across, with the front door on its facade and two stacks on its roof, and a
# fenced transformer yard over its other block, drawn as ground with the yard's upright things
# standing on it rather than as wall and roof. The collision is the whole lot either way — the
# yard is fenced, not walkable.

const POWER_STATION_DOOR := &"buildings/power_station_door"
const POWER_STATION_STACK := &"buildings/power_station_stack"
const POWER_STATION_YARD := &"buildings/power_station_yard"
const POWER_STATION_WALL := &"buildings/power_station_wall"
const POWER_STATION_BASE := &"buildings/power_station_base"
const POWER_STATION_CLERESTORY := &"buildings/power_station_clerestory"
## Where the two stacks stand on the hall's roof, as a column counted from the hall's own west end
## and a roof row counted from the south — back to front, so the nearer one is drawn over the
## farther one's foot. Taste, open to overturn.
const _STACK_CELLS: Array[Vector2i] = [Vector2i(9, 2), Vector2i(4, 1)]

## Share of a storefront cell that gets the sloped-awning variant instead of the plain one.
const STOREFRONT_AWNING_SHARE := 0.35
## Share of `RESIDENTIAL` buildings tall enough for one (`wall_tiles() >= 2`) that get a fire
## escape at all.
const FIRE_ESCAPE_SHARE := 0.3
## Share of a `LIVED_IN` commercial storefront that has gone shuttered by the time
## `Tuning.degradation_for(day)` reaches 1.0 — read against each cell's own fixed severity roll
## the same way `GroundTiles._cracked()` reads the ground's. A `BOARDED` block ignores this and
## shutters every storefront outright; this is the ordinary street closing a few shops early.
const AMBIENT_SHUTTER_SHARE := 0.3

# ------------------------------------------------------------- roof furniture ---
# One roof unit per interior cell: never on the perimeter row or column, so nothing overhangs
# the silhouette the parapet and edge tiles already draw. Drawn by this node, above its own roof
# tiles and inside the Buildings layer, so a roof unit never enters the y-sorted comparison the
# class doc's own warning is about.

const VENT_A := &"props/industrial_vent"
const VENT_B := &"props/industrial_vent_b"
const HVAC_A := &"props/roof_hvac_unit"
const HVAC_B := &"props/roof_hvac_unit_b"
const DUCT_STRAIGHT := &"props/roof_duct_straight"
const DUCT_CORNER := &"props/roof_duct_corner"
const SKYLIGHT_A := &"props/roof_skylight"
const SKYLIGHT_B := &"props/roof_skylight_b"
const VENT_STACK := &"props/roof_vent_stack"
const WATER_TANK := &"props/roof_water_tank"

## What stands on a roof. `VENT` is the one that animates; everything else is fixed art.
enum _Furniture { VENT, HVAC_A, HVAC_B, DUCT_STRAIGHT, DUCT_CORNER, SKYLIGHT_A, SKYLIGHT_B,
	VENT_STACK, WATER_TANK }

## Which units a district's roof may roll. `INDUSTRIAL` also gets a duct run — see
## `_place_duct_run()` — on top of whatever this list places. Repeating `WATER_TANK` three times
## against one `VENT` is "the odd vent" the milestone asked for: mostly tanks, occasionally a fan.
const _INDUSTRIAL_KINDS: Array = [_Furniture.HVAC_A, _Furniture.HVAC_B, _Furniture.VENT,
	_Furniture.VENT_STACK]
const _CIVIC_KINDS: Array = [_Furniture.SKYLIGHT_A, _Furniture.SKYLIGHT_B]
const _RESIDENTIAL_KINDS: Array = [_Furniture.WATER_TANK, _Furniture.WATER_TANK,
	_Furniture.WATER_TANK, _Furniture.VENT]
const _KINDS_BY_DISTRICT := {
	GameEnums.BlockPurpose.INDUSTRIAL: _INDUSTRIAL_KINDS,
	GameEnums.BlockPurpose.CIVIC: _CIVIC_KINDS,
	GameEnums.BlockPurpose.RESIDENTIAL: _RESIDENTIAL_KINDS,
	GameEnums.BlockPurpose.COMMERCIAL: _RESIDENTIAL_KINDS,
}

## Share of a district's interior cells that carry a unit at all — the count the milestone asked
## to scale with the footprint, stated as a density rather than a fixed number so a wide roof
## carries more of them than a narrow one without a second table to keep in step with the first.
const _FURNITURE_DENSITY := {
	GameEnums.BlockPurpose.INDUSTRIAL: 0.4,
	GameEnums.BlockPurpose.CIVIC: 0.22,
	GameEnums.BlockPurpose.RESIDENTIAL: 0.15,
	GameEnums.BlockPurpose.COMMERCIAL: 0.15,
}

## How often the vent's rotor swaps frames, in seconds. Purely cosmetic — nothing a route
## decision is stated over — so it lives beside the art it times rather than in `Tuning`.
const VENT_FRAME_INTERVAL := 1.4

## Lot size in px: x = width, y = depth (how far north it extends).
@export var footprint := Vector2(96.0, 96.0):
	set(value):
		footprint = value
		_rebuild()

## Requested extruded height in px. Snapped down to whole tiles, and always left at least
## one tile of roof unless the lot is a single tile deep.
@export var height := 64.0:
	set(value):
		height = value
		_rebuild()

## Selects the roof colour and the window pattern.
@export var variant := 0:
	set(value):
		variant = value
		_rebuild()

## The block's own starting purpose — fixed for the run, the same fact `City._height_for` already
## reads — and what picks the roof furniture's district table. Never today's purpose: a requisitioned
## park does not change what is bolted to a roof.
@export var district := GameEnums.BlockPurpose.RESIDENTIAL:
	set(value):
		district = value
		_rebuild()

## What has happened to this building's block. The footprint never changes — the street
## lattice and the block boundaries are fixed for the run — so a block that goes dark or
## burns says so here rather than by moving walls around.
enum Condition {
	LIVED_IN, ## Lights on after dark, as generated.
	BOARDED,  ## Nobody home. Every window dark.
	BURNT,    ## Blackened, roofless, windows gone.
}

## Whether this building is the city's power station — see the section above, and
## `CityMap.power_station`. `station_door_col` and `station_yard_cols` say where its parts are.
@export var power_station := false:
	set(value):
		power_station = value
		_rebuild()

## The facade column the power station's door starts at (it is `CityMap.POWER_STATION_DOOR_TILES`
## wide), counted from the west end of the lot. Read only when `power_station` is set.
@export var station_door_col := 0:
	set(value):
		station_door_col = value
		queue_redraw()

## The columns the transformer yard covers, as `(first, count)` from the west end of the lot — one
## whole block, the one without the door. Everything else is the hall.
@export var station_yard_cols := Vector2i.ZERO:
	set(value):
		station_yard_cols = value
		queue_redraw()

## Whether this building is her own — the one exception to the ground floor's blank-wall-or-shops
## rule (`_draws_window_at()`): every other multi-story building's ground floor never shows a
## window. Set by `City._spawn_buildings()` from the building's own lot and `CityMap.home_block`,
## so every Building on the home block counts as hers, not only whichever lot the door notch
## happens to touch. Never rolls anything of its own, so flipping it only ever needs a redraw.
@export var is_home_building := false:
	set(value):
		is_home_building = value
		queue_redraw()

@export var condition := Condition.LIVED_IN:
	set(value):
		if condition == value:
			return
		condition = value
		queue_redraw()

## Today's day number, for the ambient-shutter roll in `_ground_floor_texture()` — read against
## `Tuning.degradation_for(day)`, not stored anywhere the roll itself depends on, so changing it
## only ever needs a redraw rather than a full `_rebuild()`.
@export var day := 1:
	set(value):
		if day == value:
			return
		day = value
		queue_redraw()

## The tile rect this building stands on, so the city can find its block again.
var lot := Rect2i()

## This building's own ground shape — a rectangle the one place `GroundShape` is a rectangle
## rather than a point or a band: nothing else in the game has a footprint that is not already one
## of those two. Half `footprint` on the south-north axis less `NORTH_EDGE_INSET`, not half
## `footprint` outright — see `_rebuild()` — so the body's own north edge sits `NORTH_EDGE_INSET`
## south of the lot's. Kept in step with `footprint` in `_rebuild()`, since the `@export` setter
## can still reassign it. Read for its body alone: the one-tile shadow every building casts is
## computed from the whole city's lot rectangles at once (`BuildingShadows`, so two buildings that
## share an edge shade as one), not from this shape.
var shape: GroundShape

var _collision: CollisionShape2D
## One entry per wall cell, row-major from the ground up: true where the light is on.
var _windows: Array[bool] = []
## This building's own upper-floor window style — one of `_WindowStyle`, rolled once with
## `_windows` itself. A building keeps its own style once a `BOARDED` block that forced
## `SHUTTERED` un-boards.
var _window_style := _WindowStyle.PLAIN
## One entry per two-column storefront, index into `STOREFRONT_TEXTURES`/`STOREFRONT_AWNING_
## TEXTURES`/`STOREFRONT_SHUTTERED_TEXTURES` — populated only for a `COMMERCIAL` building.
var _storefront_variant: Array[int] = []
var _storefront_awning: Array[bool] = []
## One fixed roll per two-column storefront, compared against `Tuning.degradation_for(day) *
## AMBIENT_SHUTTER_SHARE` in `_ground_floor_texture()` — a shop with a low roll here closes early
## in the run and stays shuttered, the same "fixed severity, the day decides how far it has been
## crossed" shape `GroundTiles._cracked()` uses for a crack.
var _storefront_shutter_severity: Array[float] = []
## The one ground-floor column a `RESIDENTIAL` building's fire escape stands against, or -1 for
## the share that rolled none.
var _fire_escape_col := -1
var _fire_escape_variant_b := false
## The ground-floor column an entrance door would stand in, rolled for every building by
## `_build_entrance()` whether or not it ends up with one — `entrance_door_col()` is what decides
## that, so the home flag and the district's own entrance can change without rolling anything.
var _door_col := 0
## One entry per roof unit: `{"cell": Vector2i, "kind": _Furniture, "span": int}`. Sorted
## north-most (highest row) first at build time, so `_draw_roof_furniture` can paint far units
## before near ones without re-sorting every frame — the same back-to-front order a unit taller
## than one tile (the water tank) needs to lie correctly over whatever is in the row behind it.
var _roof_furniture: Array[Dictionary] = []
## Whether any roof unit this building rolled is the animated vent, so `_process` only runs — and
## `queue_redraw()` only fires on a timer — for the buildings that have something moving on them.
var _has_vent := false
var _vent_frame_b := false
var _vent_timer := 0.0

## Acquires the `buildings` atlas group rather than `_ready()`, so a building added and removed
## from the tree more than once stays paired with `_exit_tree()` — `_ready()` only ever runs the
## first time. `AtlasLibrary` reference-counts, so any number of buildings acquiring the same
## group is one page load.
func _enter_tree() -> void:
	AtlasLibrary.acquire(&"buildings")

func _exit_tree() -> void:
	AtlasLibrary.release(&"buildings")

func _ready() -> void:
	_collision = CollisionShape2D.new()
	add_child(_collision)
	_rebuild()

func _process(delta: float) -> void:
	_vent_timer += delta
	if _vent_timer < VENT_FRAME_INTERVAL:
		return
	_vent_timer = 0.0
	_vent_frame_b = not _vent_frame_b
	queue_redraw()

func _rebuild() -> void:
	if not is_inside_tree():
		return
	# Collision is the whole lot, including the strip the roof is drawn over, so the player
	# can never walk into the space the building's mass occupies on screen — except a few pixels
	# of the north edge, `NORTH_EDGE_INSET`, ground she may step into rather than a wall she stops
	# a tile short of. Built from `shape` rather than a `RectangleShape2D` sized separately, so the
	# body and the shape cannot disagree. The south-north half-extent shrinks by half the inset and
	# the shape's centre (`_collision.position`) shifts south by the same half, which is what keeps
	# the south edge — the lot's own kerb — exactly where it was.
	var depth := maxf(footprint.y - NORTH_EDGE_INSET, TILE)
	shape = GroundShape.rect(Vector2(footprint.x * 0.5, depth * 0.5))
	_collision.shape = shape.collision_shape()
	_collision.position = Vector2(0.0, -shape.half_extents.y)
	_build_windows()
	_build_front()
	_build_entrance()
	_build_roof_furniture()
	set_process(_has_vent)
	queue_redraw()

# ------------------------------------------------------------------- layout ---

## Lot width in whole tiles.
func columns() -> int:
	return maxi(1, roundi(footprint.x / TILE))

## Lot depth in whole tiles.
func rows() -> int:
	return maxi(1, roundi(footprint.y / TILE))

## Rows of front wall. A one-tile sliver is all wall and no roof — anything else would have
## to overhang the lot behind it, and the whole point of the layout is that it never does.
func wall_tiles() -> int:
	return clampi(roundi(height / TILE), 1, maxi(1, rows() - 1))

## Rows of visible roof once the wall has taken its share of the lot.
func roof_tiles() -> int:
	return rows() - wall_tiles()

## Whether a window is showing a light. Only a lived-in block ever does: a boarded street is
## the same street with nobody in it, and that reads at a glance where a colour shift alone
## would not.
func _lit(index: int) -> bool:
	if condition != Condition.LIVED_IN:
		return false
	return _windows[index] if index < _windows.size() else false

## Window lighting is fixed at build time, not rolled per frame, or the city would flicker.
func _build_windows() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%d" % [variant, int(global_position.x), int(global_position.y)])
	_windows.clear()
	for i in columns() * wall_tiles():
		_windows.append(rng.randf() < LIT_WINDOW_CHANCE)
	var style_roll := rng.randf()
	if style_roll < SHUTTERED_WINDOW_CHANCE:
		_window_style = _WindowStyle.SHUTTERED
	elif style_roll < SHUTTERED_WINDOW_CHANCE + TALL_WINDOW_CHANCE:
		_window_style = _WindowStyle.TALL
	else:
		_window_style = _WindowStyle.PLAIN

## The ground floor's own shops, and the one fire escape a `RESIDENTIAL` facade may carry. A
## district's own seed, distinct from `_build_windows()`'s, so an awning roll or a fire-escape
## roll never shifts which windows are lit.
func _build_front() -> void:
	_storefront_variant.clear()
	_storefront_awning.clear()
	_storefront_shutter_severity.clear()
	_fire_escape_col = -1
	var cols := columns()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("front:%d:%d:%d" % [variant, int(global_position.x), int(global_position.y)])
	if district == GameEnums.BlockPurpose.COMMERCIAL and wall_tiles() >= 2:
		# A shuffled bag gives one frontage a varied mixture while keeping the same building's
		# storefront choices stable across redraws, day changes, and condition changes.
		var bag: Array[int] = []
		var previous_variant := -1
		for col in range(0, cols - 1, 2):
			if bag.is_empty():
				for index in STOREFRONT_TEXTURES.size():
					bag.append(index)
				for index in range(bag.size() - 1, 0, -1):
					var swap_index := rng.randi_range(0, index)
					var swapped := bag[index]
					bag[index] = bag[swap_index]
					bag[swap_index] = swapped
				if previous_variant >= 0 and bag.size() > 1 and bag[0] == previous_variant:
					var swapped := bag[0]
					bag[0] = bag[1]
					bag[1] = swapped
			_storefront_variant.append(bag.pop_front())
			previous_variant = _storefront_variant[-1]
			_storefront_awning.append(rng.randf() < STOREFRONT_AWNING_SHARE)
			_storefront_shutter_severity.append(rng.randf())
	elif district == GameEnums.BlockPurpose.RESIDENTIAL and wall_tiles() >= 2 \
			and rng.randf() < FIRE_ESCAPE_SHARE:
		# Away from the corner columns where there is room to choose one, so the escape does not
		# sit on top of `WALL_EDGE_W`/`WALL_EDGE_E`'s own parapet turn.
		_fire_escape_col = rng.randi_range(1, cols - 2) if cols >= 3 else rng.randi_range(0, cols - 1)
		_fire_escape_variant_b = rng.randf() < 0.5

## Which ground-floor column the entrance door stands in. A seed of its own, distinct from
## `_build_windows()`'s and `_build_front()`'s, so the door moves no window, style, storefront,
## awning, shutter or fire-escape roll. Read after `_build_front()`, since the door keeps clear of
## the fire escape — see `_door_col_from()`.
func _build_entrance() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("door:%d:%d:%d" % [variant, int(global_position.x), int(global_position.y)])
	_door_col = _door_col_from(columns(), _fire_escape_col, rng)

## The door's column, rolled from the first non-empty tier: an interior column clear of the fire
## escape and both its neighbours, then any column clear of all three, then any column but the
## escape's own. The escape's landings reach eight pixels into both neighbouring columns at the
## ground floor, so a door beside it would be half hidden; the corner columns come second only as
## the courtesy the fire escape pays `WALL_EDGE_W`/`WALL_EDGE_E`, since the door's own margin
## clears the edge line. Static so a test can replay it against the same stream.
static func _door_col_from(cols: int, escape: int, rng: RandomNumberGenerator) -> int:
	var tiers: Array[Array] = [[], [], []]
	for col in cols:
		var clear := escape < 0 or absi(col - escape) > 1
		var interior := cols < 3 or (col > 0 and col < cols - 1)
		if clear and interior:
			tiers[0].append(col)
		if clear:
			tiers[1].append(col)
		if col != escape:
			tiers[2].append(col)
	for tier in tiers:
		if not tier.is_empty():
			var picked: int = tier[rng.randi_range(0, tier.size() - 1)]
			return picked
	return 0

## The ground-floor column this front's entrance door stands in, or -1 for a front that has none:
## a multi-story front is a way in, and a front that already has one gets no second. A storefront
## is a commercial front's way in and the portico is a civic front's; her own building keeps its
## ground-floor windows and her own door is already cut into her block; a one-row facade keeps its
## windows and has no door; the power station draws its own. A commercial front too narrow for a
## single complete storefront — one column — is the one commercial front that gets a door.
func entrance_door_col() -> int:
	if power_station or is_home_building or wall_tiles() < 2:
		return -1
	if district == GameEnums.BlockPurpose.CIVIC:
		return -1
	if district == GameEnums.BlockPurpose.COMMERCIAL and not _storefront_variant.is_empty():
		return -1
	return _door_col

## The door picture for this front's district: steel on an `INDUSTRIAL` block, the plain one on
## every other.
func _entrance_door_texture() -> StringName:
	if district == GameEnums.BlockPurpose.INDUSTRIAL:
		return ENTRANCE_DOOR_INDUSTRIAL
	return ENTRANCE_DOOR

# ------------------------------------------------------------------ drawing ---

## Whether `row` draws a window at all. Every row does, except the ground floor (`row == 0`) of a
## multi-story building that is not her own: a ground floor is shops or blank wall, never windows
## (`docs/CITY.md`, "A front is district and block purpose"), and a one-row facade has no upper
## floor to make it multi-story in the first place. Reads no RNG of its own — `_build_windows()`
## still rolls exactly the same `_windows` array and `_window_style` it always has, so which upper
## windows are lit and the window style are unaffected by this rule.
func _draws_window_at(row: int) -> bool:
	return row > 0 or is_home_building or wall_tiles() < 2

func _draw() -> void:
	var cols := columns()
	var wall_rows := wall_tiles()
	var roof_rows := roof_tiles()
	var wall_colour := Palette.building_wall(variant)
	var roof_colour := Palette.building_roof(variant)
	if condition == Condition.BURNT:
		wall_colour = Palette.burnt(wall_colour)
		roof_colour = Palette.burnt(roof_colour)

	# The columns the wall and roof are drawn over: all of them, except a power station's yard.
	var hall := _hall_cols()
	if power_station:
		_draw_station_facade(wall_rows, hall)
	for row in (0 if power_station else wall_rows):
		for col in range(hall.x, hall.y):
			var at := _cell(col, row)
			draw_texture(AtlasLibrary.region(WALL), at, wall_colour)
			if _draws_window_at(row):
				var index := row * cols + col
				var window_at := at
				if row == 1 and (not _storefront_variant.is_empty() or entrance_door_col() >= 0):
					# A 36px storefront or door rises four pixels into this row; lift every upper
					# window two pixels so its sill remains visible, the whole row alike.
					window_at.y -= 2.0
				draw_texture(AtlasLibrary.region(_window_texture(index)), window_at)
			if col == hall.x:
				draw_texture(AtlasLibrary.region(WALL_EDGE_W), at)
			if col == hall.y - 1:
				draw_texture(AtlasLibrary.region(WALL_EDGE_E), at)
			# With no roof at all, the parapet is what stops the wall.
			if roof_rows == 0 and row == wall_rows - 1:
				draw_texture(AtlasLibrary.region(ROOF_EDGE_N), at)

	# Ground-floor substitutions are drawn after every wall cell, so a 64px storefront cannot be
	# painted over by the neighboring half of its pair. A 36px source is offset four pixels north
	# to keep its bottom edge on the shared ground line; facades with only one wall row keep the
	# ordinary wall base because there is not enough height for the complete entrance.
	for col in range(hall.x, hall.y if not power_station else hall.x):
		var ground_name := _ground_floor_texture(col)
		if ground_name != &"":
			var texture := AtlasLibrary.region(ground_name)
			var y_offset := TILE - texture.get_height()
			draw_texture(texture, _cell(col, 0) + Vector2(0.0, y_offset))

	_draw_front_overlay()

	for row in roof_rows:
		for col in range(hall.x, hall.y):
			var at := _cell(col, wall_rows + row)
			draw_texture(AtlasLibrary.region(ROOF), at, roof_colour)
			if row == 0:
				draw_texture(AtlasLibrary.region(ROOF_EDGE_S), at)
			if row == roof_rows - 1:
				draw_texture(AtlasLibrary.region(ROOF_EDGE_N), at)
			if col == hall.x:
				draw_texture(AtlasLibrary.region(ROOF_EDGE_W), at)
			if col == hall.y - 1:
				draw_texture(AtlasLibrary.region(ROOF_EDGE_E), at)

	_draw_roof_furniture(wall_rows)
	if power_station:
		_draw_power_station(wall_rows, hall)

## The power station hall's own facade in place of the ordinary wall, windows and ground floor —
## industrial rather than a block of flats: steel cladding, a hazard-striped ground course, and a
## clerestory band of tall, narrow, unlit windows filling the top two wall rows. Its own colours,
## never the variant's tint. The parapet turns at either end are the ordinary edge overlays. A
## station's lot is always eight tiles deep, so its wall is always tall enough for the base and a
## two-row clerestory; a shorter one would simply lose the band.
func _draw_station_facade(wall_rows: int, hall: Vector2i) -> void:
	var has_band := wall_rows >= 3
	for row in wall_rows:
		for col in range(hall.x, hall.y):
			var at := _cell(col, row)
			var tile := POWER_STATION_WALL
			if row == 0:
				tile = POWER_STATION_BASE
			draw_texture(AtlasLibrary.region(tile), at)
	if has_band:
		for col in range(hall.x, hall.y):
			draw_texture(AtlasLibrary.region(POWER_STATION_CLERESTORY), _cell(col, wall_rows - 1))
	for row in wall_rows:
		draw_texture(AtlasLibrary.region(WALL_EDGE_W), _cell(hall.x, row))
		draw_texture(AtlasLibrary.region(WALL_EDGE_E), _cell(hall.y - 1, row))

## The `[first, end)` columns the wall and roof cover: the whole facade, or for the power station
## everything but its yard, which is one block at one end of the lot.
func _hall_cols() -> Vector2i:
	var cols := columns()
	if not power_station or station_yard_cols.y <= 0:
		return Vector2i(0, cols)
	if station_yard_cols.x == 0:
		return Vector2i(station_yard_cols.y, cols)
	return Vector2i(0, station_yard_cols.x)

## The power station's own parts, after the hall's wall and roof: the yard over its block, then the
## stacks on the hall's roof. The yard picture's lines run off its west edge towards the hall, so a
## yard west of the hall is drawn mirrored — through `Sprites.draw_standing`, the one place that
## mirrors, anchored at the yard's own bottom centre on the lot's south edge.
func _draw_power_station(wall_rows: int, hall: Vector2i) -> void:
	if station_yard_cols.y > 0:
		var yard := AtlasLibrary.region(POWER_STATION_YARD)
		var left := _cell(station_yard_cols.x, 0).x
		var foot := Vector2(left + station_yard_cols.y * TILE * 0.5, 0.0)
		var mirrored := station_yard_cols.x < hall.x
		Sprites.draw_standing(self, yard, foot, Vector2.ZERO, mirrored)
	var stack := AtlasLibrary.region(POWER_STATION_STACK)
	var roof_rows := roof_tiles()
	for cell in _STACK_CELLS:
		var col := hall.x + mini(cell.x, hall.y - hall.x - 1)
		var row := mini(cell.y, roof_rows - 1)
		var at := _cell(col, wall_rows + row)
		Sprites.draw_standing(self, stack, at + Vector2(TILE * 0.5, TILE))

## Top-left corner of a cell, counting rows northward from the ground line.
func _cell(col: int, row: int) -> Vector2:
	return Vector2(-columns() * TILE * 0.5 + col * TILE, -(row + 1) * TILE)

## `WALL_BASE`, unless `col` is the first column of a complete two-column `COMMERCIAL` shopfront —
## its own fill is opaque, which is what lets this stay a plain substitution rather than a second
## draw call skipping the windows. The second column returns `null` because its partner already
## paints both cells; an odd final column stays `WALL_BASE`.
##
## A `BOARDED` block shutters every one of its own storefronts outright. Short of that, a shop
## still shutters early once `Tuning.degradation_for(day) * AMBIENT_SHUTTER_SHARE` has passed the
## cell's own fixed roll — the city's services failing ahead of any one block's arc, which is why
## this reads `condition` and `day` as two separate questions rather than one.
func _ground_floor_texture(col: int) -> StringName:
	if _storefront_variant.is_empty():
		return WALL_BASE
	if col % 2 == 1:
		return &""
	var store := col / 2
	if store >= _storefront_variant.size() or col + 1 >= columns():
		return WALL_BASE
	var index: int = _storefront_variant[store]
	var ambient_shutter := _storefront_shutter_severity[store] < Tuning.degradation_for(day) * AMBIENT_SHUTTER_SHARE
	if condition == Condition.BOARDED or ambient_shutter:
		return STOREFRONT_SHUTTERED_TEXTURES[index]
	return STOREFRONT_AWNING_TEXTURES[index] if _storefront_awning[store] else STOREFRONT_TEXTURES[index]

## The ground-floor cells with nothing on them but the plain wall and its plinth — no window, no
## storefront, no civic entrance, no entrance door and not the column a fire escape stands against.
## Local space, one `Vector2(TILE, TILE)` rect per blank column, in
## the same top-left convention `_cell()` already uses for every draw call in this file. Empty for
## the power station (it draws its own front), her own building (the blank-wall rule's one
## exception) and a one-row facade (not multi-story, so the rule never reaches it). Nothing calls
## this yet — it is the ground a poster crew pastes on.
func blank_ground_floor_cells() -> Array[Rect2]:
	var result: Array[Rect2] = []
	if power_station or is_home_building or wall_tiles() < 2:
		return result
	var entrance_cols := _civic_entrance_cols()
	var door_col := entrance_door_col()
	for col in columns():
		if entrance_cols.has(col) or col == door_col or col == _fire_escape_col:
			continue
		if _ground_floor_texture(col) == WALL_BASE:
			result.append(Rect2(_cell(col, 0), Vector2(TILE, TILE)))
	return result

## The column(s) `civic_portico.svg` actually paints over, read back from `_cell()` rather than
## assumed: the portico is a fixed 32px overlay centred on the facade (`_draw_front_overlay()`),
## which straddles two columns whenever `columns()` is even rather than landing on one exactly.
func _civic_entrance_cols() -> Array[int]:
	var result: Array[int] = []
	if district != GameEnums.BlockPurpose.CIVIC:
		return result
	for col in columns():
		var x := _cell(col, 0).x
		if x < 16.0 and x + TILE > -16.0:
			result.append(col)
	return result

## The window pair for a wall cell, from `_window_style` — except a `BOARDED` block, which forces
## `SHUTTERED` regardless of the building's own roll. Never lit there either, but only because
## `_lit()` already answers false off `LIVED_IN`; an ordinary `SHUTTERED` building lights up like
## any other.
func _window_texture(index: int) -> StringName:
	var style := _WindowStyle.SHUTTERED if condition == Condition.BOARDED else _window_style
	match style:
		_WindowStyle.SHUTTERED:
			return WINDOW_SHUTTERED_LIT if _lit(index) else WINDOW_SHUTTERED_DARK
		_WindowStyle.TALL:
			return WINDOW_TALL_LIT if _lit(index) else WINDOW_TALL_DARK
		_:
			return WINDOW_LIT if _lit(index) else WINDOW_DARK

## The overlays on a front: its entrance door, a fire escape bolted to a `RESIDENTIAL` facade or a
## portico at a `CIVIC` entrance, drawn after every ground-floor cell so each stands in front of the
## shopfront or plinth rather than under it. The door goes first, since it is set in the wall plane
## the escape stands out from. Anchored at local `y = 0`, the ground
## line `_cell`'s own row 0 already sits on, so `Sprites.draw_standing()`'s bottom-centre contract
## needs no offset math here.
func _draw_front_overlay() -> void:
	var door_col := entrance_door_col()
	if door_col >= 0:
		var door_x := _cell(door_col, 0).x + TILE * 0.5
		Sprites.draw_standing(self, AtlasLibrary.region(_entrance_door_texture()), Vector2(door_x, 0.0))
	if _fire_escape_col >= 0:
		var name := FIRE_ESCAPE_B if _fire_escape_variant_b else FIRE_ESCAPE_A
		var x := _cell(_fire_escape_col, 0).x + TILE * 0.5
		Sprites.draw_standing(self, AtlasLibrary.region(name), Vector2(x, 0.0))
	if district == GameEnums.BlockPurpose.CIVIC:
		Sprites.draw_standing(self, AtlasLibrary.region(CIVIC_PORTICO), Vector2(0.0, 0.0))
	if power_station:
		var x := _cell(station_door_col, 0).x + TILE * CityMap.POWER_STATION_DOOR_TILES * 0.5
		Sprites.draw_standing(self, AtlasLibrary.region(POWER_STATION_DOOR), Vector2(x, 0.0))

# ------------------------------------------------------------- roof furniture ---

## Rolls this building's roof units, once per `_rebuild()` rather than once per frame — the same
## contract `_build_windows()` already keeps. Nothing is placed on a roof too shallow to have an
## interior cell at all (`roof_tiles() < 3` or `columns() < 3`), which most `INDUSTRIAL` and
## `CIVIC` roofs are not, and most single-tile-deep slivers are.
func _build_roof_furniture() -> void:
	_roof_furniture.clear()
	_has_vent = false
	var roof_rows := roof_tiles()
	var cols := columns()
	if roof_rows < 3 or cols < 3:
		return
	var kinds: Array = _KINDS_BY_DISTRICT.get(district, [])
	var density: float = _FURNITURE_DENSITY.get(district, 0.0)
	if kinds.is_empty() or density <= 0.0:
		return
	var interior: Array[Vector2i] = []
	for row in range(1, roof_rows - 1):
		for col in range(1, cols - 1):
			interior.append(Vector2i(col, row))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("roof:%d:%d:%d" % [variant, int(global_position.x), int(global_position.y)])
	_shuffle(interior, rng)
	var wanted := clampi(roundi(interior.size() * density), 1, interior.size())
	var used := {}
	if district == GameEnums.BlockPurpose.INDUSTRIAL:
		wanted -= _place_duct_run(cols, roof_rows, used, rng)
	var placed := 0
	for cell in interior:
		if placed >= wanted:
			break
		if used.has(cell):
			continue
		var kind: int = kinds[rng.randi() % kinds.size()]
		_roof_furniture.append({"cell": cell, "kind": kind, "span": 1})
		if kind == _Furniture.VENT:
			_has_vent = true
		placed += 1
	# Farthest (highest row) first, so `_draw_roof_furniture` paints back to front without
	# re-sorting on every redraw.
	_roof_furniture.sort_custom(func(a, b): return (a["cell"] as Vector2i).y > (b["cell"] as Vector2i).y)

## `INDUSTRIAL` only: a straight duct run and, where there is a second interior row to turn into,
## one elbow continuing it — "a duct run laid as a straight-and-corner chain" rather than loose
## units. Returns how many interior cells it used, which is subtracted from the district's own
## furniture budget so a duct run is not extra furniture on top of the density table.
func _place_duct_run(cols: int, roof_rows: int, used: Dictionary, rng: RandomNumberGenerator) -> int:
	if cols < 4 or roof_rows < 3:
		return 0
	var row := rng.randi_range(1, roof_rows - 2)
	var start_col := rng.randi_range(1, cols - 3)
	var straight := Vector2i(start_col, row)
	var straight_far := Vector2i(start_col + 1, row)
	used[straight] = true
	used[straight_far] = true
	_roof_furniture.append({"cell": straight, "kind": _Furniture.DUCT_STRAIGHT, "span": 2})
	var consumed := 2
	var corner := Vector2i(start_col + 1, row + 1)
	if row + 1 <= roof_rows - 2 and not used.has(corner):
		used[corner] = true
		_roof_furniture.append({"cell": corner, "kind": _Furniture.DUCT_CORNER, "span": 1})
		consumed += 1
	return consumed

## A Fisher-Yates shuffle over `rng` rather than `Array.shuffle()`, which reads the engine's own
## global RNG and would make the roll different every launch — every other seeded pick in this
## file (and `_build_windows()` beside it) stays reproducible from `variant` and position alone.
static func _shuffle(cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := cells[i]
		cells[i] = cells[j]
		cells[j] = tmp

## Paints every roof unit, back to front (`_build_roof_furniture` sorted them), above the roof
## tiles this same `_draw()` call has just finished — see the class doc for why nothing here may
## ever be y-sorted against the street: this is still the one `_draw()` the Buildings layer calls.
func _draw_roof_furniture(wall_rows: int) -> void:
	for entry in _roof_furniture:
		var cell: Vector2i = entry["cell"]
		var span: int = entry["span"]
		var at := _cell(cell.x, wall_rows + cell.y)
		var anchor := at + Vector2(TILE * span * 0.5, TILE)
		Sprites.draw_standing(self, AtlasLibrary.region(_furniture_texture(entry["kind"])), anchor)

func _furniture_texture(kind: int) -> StringName:
	match kind:
		_Furniture.VENT:
			return VENT_B if _vent_frame_b else VENT_A
		_Furniture.HVAC_A:
			return HVAC_A
		_Furniture.HVAC_B:
			return HVAC_B
		_Furniture.DUCT_STRAIGHT:
			return DUCT_STRAIGHT
		_Furniture.DUCT_CORNER:
			return DUCT_CORNER
		_Furniture.SKYLIGHT_A:
			return SKYLIGHT_A
		_Furniture.SKYLIGHT_B:
			return SKYLIGHT_B
		_Furniture.VENT_STACK:
			return VENT_STACK
		_:
			return WATER_TANK

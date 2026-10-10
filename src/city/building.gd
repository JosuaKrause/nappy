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
## here: nothing can ever legitimately be *behind* a building's lot, so nothing sorts against one.
## Roof equipment and power station stacks can rise past the lot. They are not drawn here: each is
## a `RoofObject` or `StationStack` in the entities' own depth order.
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
##
## **A column with no walkable ground directly south of it draws no facade at all** —
## `covered_ground_cols` — and whichever building stands there instead draws its own roof further
## north to meet it, `roof_extension_rows` deep past its own lot's own north edge, so the two
## roofs read as one continuous surface rather than a floating wall with nobody able to stand in
## front of it. See each property's own doc.

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
## The four parapet overlays as flags, the answer `roof_cell_edges()` gives for one roof cell.
const ROOF_EDGE_BIT_N := 1
const ROOF_EDGE_BIT_S := 2
const ROOF_EDGE_BIT_W := 4
const ROOF_EDGE_BIT_E := 8
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
## One floor of a fire escape — a balcony with its flight hanging below it to the balcony one floor
## down — and the same balcony with the flight taken out, for the first floor's floor line. `a` has a
## potted plant on its balcony, `b` does not, and which one shows is rolled balcony by balcony
## rather than once for the whole escape — see `FIRE_ESCAPE_POT_SHARE` and `_draw_fire_escape()`.
## Every flight faces the same way on both.
const FIRE_ESCAPE_A := &"buildings/fire_escape_a"
const FIRE_ESCAPE_B := &"buildings/fire_escape_b"
const FIRE_ESCAPE_PLATFORM_A := &"buildings/fire_escape_platform_a"
const FIRE_ESCAPE_PLATFORM_B := &"buildings/fire_escape_platform_b"
const CIVIC_PORTICO := &"props/civic_portico"
## The one way in a multi-story front with no storefront and no portico has — see
## `entrance_door_col()`. 32×36px, a whole wall cell wide and rising four pixels into the row above
## the way a storefront does, drawn standing on the ground line at its column's centre. An
## `INDUSTRIAL` front gets the heavier steel one; every other purpose that gets a door gets the
## plain one.
const ENTRANCE_DOOR := &"buildings/entrance_door"
const ENTRANCE_DOOR_INDUSTRIAL := &"buildings/entrance_door_industrial"
## The neighbor's boarded window, from day 11 on: a 32×32 overlay, the same cell and registration
## as `WINDOW_DARK`, drawn over whichever window picture `neighbor_window_col` already has so the
## front's own lintel and sill stay. `City.board_neighbor_window()` is the only setter.
const NEIGHBOR_WINDOW_SEALED := &"buildings/window_boarded_sealed"
## **A burnt building is drawn burnt, not only dark**: *"the *building* is what needs to be burnt"*
## (olive-koala, statement 4). Under `Condition.BURNT` every window of every style is the burnt-out
## one (black to the back of the room, glass in shards, soot over the lintel), an entrance door is
## the burnt doorway boarded shut, a storefront pair is the gutted shop, and the front parapet is
## the charred, broken coping — each in its intact picture's own canvas and registration, drawn
## where the intact one would be. The wall and roof keep their own tinted fills: the wall drained
## to ash (`Palette.burnt_wall()`) so the soot shows black on it, the roof blackened
## (`Palette.burnt()`).
const WINDOW_BURNT := &"buildings/window_burnt"
const ENTRANCE_DOOR_BURNT := &"buildings/entrance_door_burnt"
const STOREFRONT_BURNT := &"buildings/storefront_burnt"
## The charred parapet comes as two pictures broken in different places, drawn on alternate
## columns, so a long front does not repeat one bite every tile.
const ROOF_EDGE_S_BURNT: Array[StringName] = [
	&"buildings/roof_edge_s_burnt",
	&"buildings/roof_edge_s_burnt_b",
]

# ------------------------------------------------------------- power station ---
# The power station is a big building drawn as two parts: a hall over its door block and the
# street it was built across, with the front door on its facade and two stacks on its roof, and a
# fenced transformer yard over its other block, drawn as ground with the yard's upright things
# standing on it rather than as wall and roof. The collision is the whole lot either way — the
# yard is fenced, not walkable. The stacks alone are not drawn by the building: they rise past the
# lot's north edge and stand in the entities' own depth order (`StationStack`).

const POWER_STATION_DOOR := &"buildings/power_station_door"
const POWER_STATION_STACK := &"buildings/power_station_stack"
const POWER_STATION_YARD := &"buildings/power_station_yard"
const POWER_STATION_WALL := &"buildings/power_station_wall"
const POWER_STATION_BASE := &"buildings/power_station_base"
const POWER_STATION_CLERESTORY := &"buildings/power_station_clerestory"
## The same band with the hall lit inside, registering with it exactly: dim, since a turbine hall
## at night is lit for the men on shift rather than for anybody outside. Drawn only on the last
## night and only while the city has power — see `_clerestory_texture()` — so the hall is seen to go
## out with everything else.
const POWER_STATION_CLERESTORY_LIT := &"buildings/power_station_clerestory_lit"
## Where the two stacks stand on the hall's roof, as a column counted from the hall's own west end
## and a roof row counted from the south. Taste, open to overturn. Which one is drawn over the
## other's foot is the `Entities` layer's y-sort, like everything else in it — see `StationStack`.
const _STACK_CELLS: Array[Vector2i] = [Vector2i(9, 2), Vector2i(4, 1)]

## Share of a storefront cell that gets the sloped-awning variant instead of the plain one.
const STOREFRONT_AWNING_SHARE := 0.35
## Share of `RESIDENTIAL` buildings tall enough for one (`FIRE_ESCAPE_MIN_WALL_ROWS`) that get a
## fire escape at all.
const FIRE_ESCAPE_SHARE := 0.3
## The fewest wall rows a front carries a fire escape on — three floors, the top one plain, one
## flight and the ground floor's platform (`fire_escape_landings()`). *(2026-09-23, the player,
## PLAYTEST-124.md statement 17: "a two floor building cannot have a fire escape".)* On two, the
## escape would be the platform alone, a balcony with no way down.
const FIRE_ESCAPE_MIN_WALL_ROWS := 3
## Share of any one balcony — a stair piece or the ground-floor platform, on either escape a front
## carries — that shows the potted-plant picture, rolled independently balcony by balcony rather
## than once for the whole escape. *(2026-09-23, the player, PLAYTEST-124.md statement 19: "the
## flower pot version should be chosen at random.")* A third reads as lived-in without turning busy.
const FIRE_ESCAPE_POT_SHARE := 1.0 / 3.0
## How far apart (in whole columns, centre to centre) two escapes on the same front must stand.
## *(2026-09-23, the player, PLAYTEST-124.md statement 20: "a wide building front could support two
## fire escapes but only if there is enough of a gap between them (at least 1.5 full fire escape
## widths between them)".)* The escape picture is 48px wide (1.5 columns of `TILE`, 32px), so 1.5
## widths of gap between the pictures' own edges is 1.5 × 48 = 72px; each picture's own half-width
## off its centre column is half of 48px, 0.75 columns, so the centres sit at least
## 0.75 + 72.0 / TILE + 0.75 = 3.75 columns apart, rounded up to the nearest whole column a column
## index can actually move to.
const FIRE_ESCAPE_GAP_COLUMNS := 4
## The fewest columns a front needs to even try for a second escape. Both escapes keep off the
## corner columns, so each is drawn from the interior range `[1, cols - 2]`, `cols - 2` values
## wide; fitting two picks `FIRE_ESCAPE_GAP_COLUMNS` apart inside it needs that range to span at
## least the gap, i.e. `(cols - 2) - 1 >= FIRE_ESCAPE_GAP_COLUMNS`, so `cols >= 7`.
const SECOND_FIRE_ESCAPE_MIN_COLUMNS := 7
## Share of a front wide enough for a second escape (`SECOND_FIRE_ESCAPE_MIN_COLUMNS`, and already
## carrying the first) that rolls one.
const SECOND_FIRE_ESCAPE_SHARE := 0.4
## Share of a `LIVED_IN` commercial storefront that has gone shuttered by the time
## `Tuning.degradation_for(day)` reaches 1.0 — read against each cell's own fixed severity roll
## the same way `GroundTiles._cracked()` reads the ground's. A `BOARDED` block ignores this and
## shutters every storefront outright; this is the ordinary street closing a few shops early.
const AMBIENT_SHUTTER_SHARE := 0.3

# ------------------------------------------------------------- roof furniture ---
# One roof unit per interior cell: never on the perimeter row or column, so nothing overhangs
# the silhouette the parapet and edge tiles already draw. City-owned roof objects are placed in
# Entities at their feet, because tall art can reach into the walkable row north of its roof.

const VENT_HOUSING := &"illustrated/roof-equipment/industrial_vent"
const VENT_ROTOR := &"props/industrial_vent_rotor"
const VENT_ROTOR_B := &"props/industrial_vent_rotor_b"
## Both authored rotor frames' source crop in the old complete housing canvas.
const VENT_ROTOR_SOURCE_RECT := Rect2(21, 19, 6, 6)
## The generated housing's circular opening, relative to its new 44×44 canvas.
const VENT_ROTOR_RECT := Rect2(22, 15, 14, 14)
const HVAC_A := &"illustrated/roof-equipment/hvac_large"
const HVAC_B := &"illustrated/roof-equipment/condenser"
const DUCT_RUN := &"illustrated/roof-equipment/duct_run"
const SKYLIGHT_A := &"illustrated/roof-equipment/skylight_long"
const SKYLIGHT_B := &"illustrated/roof-equipment/skylight_pyramid"
const VENT_STACK := &"illustrated/roof-equipment/vent_stack"
const WATER_TANK := &"illustrated/roof-equipment/water_tank"
const SERVICE_BULKHEAD := &"illustrated/roof-equipment/service_bulkhead"
const EXHAUST_FAN := &"illustrated/roof-equipment/exhaust_fan"
const PIPE_MANIFOLD := &"illustrated/roof-equipment/pipe_manifold"
## Relative equipment proportions: standalone pipes and fans are smaller than HVAC cabinets;
## the access room's door reads at the same height as a regular building doorway.
const STANDALONE_EQUIPMENT_SCALE := 2.0 / 3.0
const ACCESS_ROOM_SCALE := 4.0 / 3.0

## What stands on a roof. Existing values stay fixed because they are part of the seeded roof
## layout: removing the old separate corner may not reroll every water tank and skylight.
enum _Furniture { VENT = 0, HVAC_A = 1, HVAC_B = 2, DUCT_RUN = 3,
	_UNUSED_DUCT_CORNER = 4, SKYLIGHT_A = 5, SKYLIGHT_B = 6, VENT_STACK = 7,
	WATER_TANK = 8, SERVICE_BULKHEAD = 9, EXHAUST_FAN = 10, PIPE_MANIFOLD = 11 }
## Public recipe names are independent of the internal seeded layout enum.
const RECIPE_FURNITURE_KINDS := ["VENT", "HVAC_A", "HVAC_B", "DUCT_STRAIGHT", "DUCT_CORNER",
	"SKYLIGHT_A", "SKYLIGHT_B", "VENT_STACK", "WATER_TANK", "SERVICE_BULKHEAD",
	"EXHAUST_FAN", "PIPE_MANIFOLD"]

## Which units a district's roof may roll. Industrial ducts reserve connected interior cells
## before the remaining furniture is placed, sharing the same roof budget.
const _INDUSTRIAL_KINDS: Array = [_Furniture.HVAC_A, _Furniture.HVAC_B, _Furniture.VENT,
	_Furniture.VENT_STACK, _Furniture.EXHAUST_FAN, _Furniture.PIPE_MANIFOLD]
const _CIVIC_KINDS: Array = [_Furniture.SKYLIGHT_A, _Furniture.SKYLIGHT_B,
	_Furniture.SERVICE_BULKHEAD]
const _RESIDENTIAL_KINDS: Array = [_Furniture.WATER_TANK, _Furniture.WATER_TANK,
	_Furniture.WATER_TANK, _Furniture.VENT, _Furniture.SERVICE_BULKHEAD,
	_Furniture.EXHAUST_FAN, _Furniture.PIPE_MANIFOLD]
const _KINDS_BY_DISTRICT := {
	GameEnums.BlockPurpose.INDUSTRIAL: _INDUSTRIAL_KINDS,
	GameEnums.BlockPurpose.CIVIC: _CIVIC_KINDS,
	GameEnums.BlockPurpose.RESIDENTIAL: _RESIDENTIAL_KINDS,
	GameEnums.BlockPurpose.COMMERCIAL: _RESIDENTIAL_KINDS,
}
## A one-cell fallback per district. Each named PNG is at most 32px wide at its roof foot, so a
## narrow roof or a shuffled last cell keeps the ordinary-unit count without overlapping a base.
const _COMPACT_KINDS_BY_DISTRICT := {
	GameEnums.BlockPurpose.INDUSTRIAL: [_Furniture.HVAC_B, _Furniture.EXHAUST_FAN],
	GameEnums.BlockPurpose.CIVIC: [_Furniture.SKYLIGHT_B],
	GameEnums.BlockPurpose.RESIDENTIAL: [_Furniture.EXHAUST_FAN],
	GameEnums.BlockPurpose.COMMERCIAL: [_Furniture.EXHAUST_FAN],
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

## The fixed cosmetic cadence the vent keeps after its housing becomes a feet-anchored object.
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
	BURNT,    ## Burnt out: blackened, windows and doors gone, the parapet charred — see `WINDOW_BURNT`.
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
## rule (`_draws_window_at()`) and to a `RESIDENTIAL` front's fire escape (`_build_front()`): every
## other multi-story building's ground floor never shows a window, and a `RESIDENTIAL` front rolls
## one fire escape in `FIRE_ESCAPE_SHARE` of the time; her own building carries neither, since she
## has a stair inside instead (the player, PLAYTEST-128.md: "the home building shouldn't have a fire
## escape (it has a double staircase inside)"). Set by `City._spawn_buildings()` from the building's
## own lot and `CityMap.home_block`, so every Building on the home block counts as hers, not only
## whichever lot the door notch happens to touch. The fire-escape roll itself still runs on every
## front regardless of this flag — only whether the column is kept depends on it — so flipping this
## never moves any other roll on `_build_front()`'s own stream. Flipping it after the front is
## already built rebuilds the front (`_rebuild()`), so a fire escape rolled before the flag was set
## does not survive it. The door's own column(s) still draw no window — see `door_world_x_range`.
@export var is_home_building := false:
	set(value):
		if is_home_building == value:
			return
		is_home_building = value
		_rebuild()

## The door's own world-space x-span, `[min, max)`, or `Vector2.INF` for a building nobody told
## about one — the same "no such point" sentinel `touch_controls.gd`'s `set_direction()` reads as
## "her own position" and `home_arrow.gd`'s `target` already use, and `_column_under_door()`'s overlap test always answers
## false against it, since nothing is ever greater than `INF`. Set by `City._spawn_buildings()` for
## every building on the home block, from the same `map.home_rect` centre `City._spawn_home()`
## places the door sprite at: the door is a separate sprite standing in front of whatever the wall
## would otherwise draw, so the column(s) behind it (`_column_under_door()`) draw plain wall
## instead of a window regardless of `is_home_building`. Meaningless off `is_home_building`, since
## nobody else ever draws a ground-floor window to begin with. A geometry fact, not a roll, so
## setting it only needs a redraw.
@export var door_world_x_range := Vector2.INF:
	set(value):
		door_world_x_range = value
		queue_redraw()

## Per-column: true where the tile directly south of this front's own ground row is another
## building rather than walkable ground, so nobody can ever stand in front of that column, and that
## building's roof reaches up to cover it (`docs/CITY.md`, "A front is district and block
## purpose"); a column nothing covers stays false and keeps its facade. Set by `City`,
## read off `CityMap.is_walkable()` — the fixed lattice fact, never `is_open()`'s per-day closures,
## since "no purpose change may move a walkable tile" (the **city** skill) — so a covered column
## stays covered for the whole run and never for her own building, which `_spawn_buildings()` never
## asks this of. Sized to `columns()`, or empty for a front with nothing in front of it;
## `_is_covered()` reads an index past the end as false, the same "nobody told this building about
## one" convention `_windows`' own out-of-range read already uses. A geometry fact, not a roll, but
## the door's own column depends on it (`_build_entrance()` filters covered columns out of every
## tier), so the setter rebuilds rather than only redrawing — before `add_child()`, where `City`
## already sets it, that is a no-op, the same way every other export setter here is. `_draw()`
## skips a covered column's whole facade, wall and window alike — see `roof_extension_rows` for
## what stands in its place.
@export var covered_ground_cols: Array[bool] = []:
	set(value):
		covered_ground_cols = value
		_rebuild()

## Whether ground-floor column `col` is covered (`covered_ground_cols`), defaulting to false for an
## index the array does not reach.
func _is_covered(col: int) -> bool:
	return covered_ground_cols[col] if col >= 0 and col < covered_ground_cols.size() else false

## Per-column: how many extra roof rows this front draws north of its own lot, continuing its own
## roof tiles and colour up to the roof line of whichever building stands north of it and covers
## one of its columns — so a covered front's hidden facade reads as one roof meeting another,
## never a patch. Set by `City._assign_roof_extensions()` for every building, hers included (a
## building providing the cover is a fact about what stands north of it, not about whose front it
## covers — the exemption in `covered_ground_cols` is the other side of this relationship). The
## count at column `col` is exactly the covered building's own `wall_tiles()`: enough rows of roof
## to reach the exact world row that building's own roof already starts at, so the two textures
## meet edge to edge with no gap and no overlap. Sized to `columns()`, or empty for a front covering
## nothing; `_extension_rows()` reads an index past the end as 0, the same convention
## `_is_covered()` already uses. A geometry fact, not a roll, but the roof furniture's own pool
## reaches onto the extension (`_build_roof_furniture()`), so the setter rebuilds rather than only
## redrawing — before `add_child()`, where `City` already sets it, that is a no-op.
@export var roof_extension_rows: Array[int] = []:
	set(value):
		roof_extension_rows = value
		_rebuild()

## Per-column: whether this front's own extension at that column reaches into another rectangle
## of the *same* courtyard lot rather than a genuinely separate building. A single-block or
## apartment-complex courtyard is cut into up to four rectangles around its hole
## (`City._assign_roof_extensions()`'s own doc), each its own `Building`, but physically it is one
## building with one roof that turns its corners — so where one piece's extension meets another
## piece's roof, neither draws a lip: this piece withholds `ROOF_EDGE_N` at the extension's top,
## and the covered piece withholds `ROOF_EDGE_S` at that column (`seamless_cover_cols`). Between
## two separate buildings the extension still caps, since that lip is the real, visible step
## between two roofs. Sized to `columns()`, or empty when nothing needs the distinction;
## `_extension_is_seamless()` reads an index past the end as false, the same convention
## `roof_extension_rows` and `covered_ground_cols` already use. Drawing only, so a redraw is all a
## change needs.
@export var roof_extension_seamless: Array[bool] = []:
	set(value):
		roof_extension_seamless = value
		queue_redraw()

## Per-column: true where this front's covered column is covered by another piece of the same
## courtyard lot (the covered side of `roof_extension_seamless`), so the roof in front carries on
## into this one and this column's first roof row draws no `ROOF_EDGE_S` lip. Set by
## `City._assign_roof_extensions()`; empty for everything else, read as false past the end
## (`_is_seamlessly_covered()`). Drawing only, so a redraw is all a change needs.
@export var seamless_cover_cols: Array[bool] = []:
	set(value):
		seamless_cover_cols = value
		queue_redraw()

## The palette entry this building's wall and roof are tinted from, or -1 for its own `variant`.
## `City` sets it so every piece of one courtyard lot carries the same colour, since the pieces are
## one building and three tints read as three. A separate field rather than a shared `variant`,
## because `variant` also seeds the windows, the front, the door, the fire escape and the roof
## furniture, and sharing it would give every piece the same rolls as well as the same colour.
## Drawing only, so a redraw is all a change needs.
@export var tint_variant := -1:
	set(value):
		tint_variant = value
		queue_redraw()

## How many extra roof rows column `col` draws (`roof_extension_rows`), defaulting to 0 for an
## index the array does not reach.
func _extension_rows(col: int) -> int:
	return roof_extension_rows[col] if col >= 0 and col < roof_extension_rows.size() else 0

## Whether column `col`'s own extension is seamless (`roof_extension_seamless`), defaulting to
## false for an index the array does not reach.
func _extension_is_seamless(col: int) -> bool:
	return roof_extension_seamless[col] if col >= 0 and col < roof_extension_seamless.size() \
			else false

## Whether column `col` is covered by another piece of its own courtyard lot
## (`seamless_cover_cols`), defaulting to false for an index the array does not reach.
func _is_seamlessly_covered(col: int) -> bool:
	return seamless_cover_cols[col] if col >= 0 and col < seamless_cover_cols.size() else false

## The upper-floor column the neighbor's boarded window (`NEIGHBOR_WINDOW_SEALED`) draws over,
## from day 11 on, or -1 for every building but the one `City.board_neighbor_window()` picked: the
## one lot the door notch stands in front of, on its third floor — row index 3, since the ground
## floor is row 0 and the first floor the one above it, as the escape counts them — the nearest
## column above the door itself. Her own floor, down the hall from her own door (PLAYTEST-131).
## That lot's height is fixed rather than rolled (`City.HOME_BUILDING_WALL_ROWS`), always at least
## four wall rows, so the third floor `neighbor_window_row()` names is always there — off the top
## of the screen at the normal camera on her doorstep, facing away down the street, but in frame
## once she turns to face the building. Set once and never rolled itself, so a redraw is all a
## change needs.
@export var neighbor_window_col := -1:
	set(value):
		neighbor_window_col = value
		queue_redraw()

## The posters on this front's blank ground-floor cells: column -> a cell as `PosterState` holds
## it (`kind`, `tear`, `under`, `under_tear`, `side`). Handed over whole by `PosterWalls.refresh()`,
## which owns what is pasted where; this only draws it. A column that is not blank is never handed
## one, so nothing here re-checks the window or door rules.
var posters: Dictionary = {}:
	set(value):
		posters = value
		queue_redraw()

@export var condition := Condition.LIVED_IN:
	set(value):
		if condition == value:
			return
		condition = value
		queue_redraw()

## Today's day number, for the ambient-shutter roll in `_ground_floor_texture()` — read against
## `Tuning.degradation_for(day)`, not stored anywhere the roll itself depends on, so changing it
## only ever needs a redraw rather than a full `_rebuild()` — and for whether the power station's
## hall is lit (`_clerestory_texture()`).
@export var day := 1:
	set(value):
		if day == value:
			return
		day = value
		queue_redraw()

## Whether the city has power. With it off every window is dark whatever `condition` and the
## build-time roll say, and the power station's hall is dark too — the blackout's whole effect on a
## building, set on every one of them in the same frame by `Blackout`. Only a redraw: which windows
## *would* be lit is still `_windows`, untouched, so the power coming back (a retried day) puts
## exactly the same lights back on.
@export var powered := true:
	set(value):
		if powered == value:
			return
		powered = value
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
## Identity and frontage facts remain live for collision and poster placement. Only windows,
## roof descriptions and retained drawing are resident around the camera.
var scenery_resident := true
var scenery_clock: SceneryGround
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
## The column(s) a `RESIDENTIAL` building's fire escape(s) climb, floor by floor: empty for the
## share that rolled none, one entry for the ordinary share, two for a wide front that also rolled
## the second (`SECOND_FIRE_ESCAPE_MIN_COLUMNS`, `SECOND_FIRE_ESCAPE_SHARE`), first-rolled first.
var _fire_escape_cols: Array[int] = []
## Per escape column, whether each of its landings (`fire_escape_landings()`'s own rows) shows the
## potted-plant picture — `col` to `{row: bool}` — rolled independently balcony by balcony rather
## than once for the whole escape (`FIRE_ESCAPE_POT_SHARE`). Empty wherever `_fire_escape_cols` is.
var _fire_escape_pots: Dictionary = {}
## The ground-floor column an entrance door would stand in, rolled for every building by
## `_build_entrance()` whether or not it ends up with one — `entrance_door_col()` is what decides
## that, so the home flag and the district's own entrance can change without rolling anything.
var _door_col := 0
## One entry per roof unit: `{"cell": Vector2i, "kind": _Furniture, "span": int}`. Sorted
## north-most (highest row) first at build time, so the roof layers can paint far units
## before near ones without re-sorting every frame — the same back-to-front order a unit taller
## than one tile (the water tank) needs to lie correctly over whatever is in the row behind it.
var _roof_furniture: Array[Dictionary] = []
## Null uses the ordinary seeded layout; an authored array replaces this roof's units.
var recipe_roof_furniture: Variant = null
var _has_vent := false
var _vent_frame_b := false
var _vent_timer := 0.0
var _rotor_layers: Array[SceneryLayer] = []
var _roof_objects: Array[RoofObject] = []
var _station_layer: Node2D
## Parent for roof art that must participate in world y-sorting. City sets this before the building
## enters the tree; a null parent retains the standalone Building path used by focused fixtures.
var roof_object_parent: Node2D

## Acquires the `buildings` atlas group rather than `_ready()`, so a building added and removed
## from the tree more than once stays paired with `_exit_tree()` — `_ready()` only ever runs the
## first time. `AtlasLibrary` reference-counts, so any number of buildings acquiring the same
## group is one page load.
func _enter_tree() -> void:
	AtlasLibrary.acquire(&"buildings")

func _exit_tree() -> void:
	_clear_roof_layers()
	_clear_roof_objects()
	AtlasLibrary.release(&"buildings")
	request_ready()

func _ready() -> void:
	if _collision == null:
		_collision = CollisionShape2D.new()
		add_child(_collision)
	_rebuild()

func _process(delta: float) -> void:
	_vent_timer += delta
	if _vent_timer < VENT_FRAME_INTERVAL:
		return
	_vent_timer = fmod(_vent_timer, VENT_FRAME_INTERVAL)
	_vent_frame_b = not _vent_frame_b
	for rotor in _rotor_layers:
		rotor.frame_b = _vent_frame_b

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
	_build_front()
	_build_entrance()
	if scenery_resident:
		_prepare_scenery()
	else:
		set_process(false)

func set_scenery_resident(resident: bool) -> void:
	if scenery_resident == resident:
		return
	scenery_resident = resident
	if resident:
		_prepare_scenery()
	else:
		_clear_roof_layers()
		_clear_roof_objects()
		_windows.clear()
		_roof_furniture.clear()
		set_process(false)
		RenderingServer.canvas_item_clear(get_canvas_item())
		queue_redraw()

func scenery_bounds() -> Rect2:
	var extension := 0
	for rows_above in roof_extension_rows:
		extension = maxi(extension, rows_above)
	# Furniture may rise above the extended roof; the bound includes the full tile canvases.
	return Rect2(global_position - Vector2(footprint.x * 0.5 + TILE,
			footprint.y + extension * TILE + TILE * 2),
			footprint + Vector2(TILE * 2, extension * TILE + TILE * 3))

func _prepare_scenery() -> void:
	if scenery_clock:
		_vent_timer = fmod(scenery_clock.elapsed, VENT_FRAME_INTERVAL)
		_vent_frame_b = int(scenery_clock.elapsed / VENT_FRAME_INTERVAL) % 2 == 1
	_build_windows()
	_build_roof_furniture()
	_build_roof_layers()
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
	if condition != Condition.LIVED_IN or not powered:
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

## The ground floor's own shops, and the fire escape(s) a `RESIDENTIAL` facade may carry. A
## district's own seed, distinct from `_build_windows()`'s, so an awning roll or a fire-escape
## roll never shifts which windows are lit. The first escape's own presence and column are this
## stream's own roll, unchanged from before there was a second escape or a per-balcony pot; both
## of those newer rolls come from `_build_fire_escape_extras()`'s own stream instead, so neither can
## move this one on any seed.
func _build_front() -> void:
	_storefront_variant.clear()
	_storefront_awning.clear()
	_storefront_shutter_severity.clear()
	_fire_escape_cols.clear()
	_fire_escape_pots.clear()
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
		var first_col := rng.randi_range(1, cols - 2) if cols >= 3 else rng.randi_range(0, cols - 1)
		# Rolled on every front of two rows or more and only then dropped from the ones too short
		# to carry it, so the stream is consumed exactly as far on every front and the bound can
		# move without moving a roll. Her own building rolls this the same as any other
		# `RESIDENTIAL` front and then drops it the same way this front already drops one that is
		# too short to carry it — she has a stair inside instead (the player, PLAYTEST-128.md:
		# "the home building shouldn't have a fire escape (it has a double staircase inside)") — so
		# `is_home_building` moves nothing else on this stream either. A covered column
		# (`_is_covered()`) drops it the same way: no platform or brackets ever reach a
		# column nobody can stand in front of, and no picture exists for a stair with nothing
		# under its lowest landing, so the whole escape goes rather than only its ground floor.
		if wall_tiles() >= FIRE_ESCAPE_MIN_WALL_ROWS and not is_home_building and not _is_covered(first_col):
			_fire_escape_cols.append(first_col)
	if not _fire_escape_cols.is_empty():
		_build_fire_escape_extras(cols)

## The rolls a fire escape needs beyond whether it exists and its own column — which balconies show
## the potted-plant picture, and whether a wide front carries a second escape — drawn from a seed of
## their own so that neither can shift `_build_front()`'s own `front:` stream: "the flower pot
## version should be chosen at random" and "a wide building front could support two fire escapes"
## (PLAYTEST-124.md statements 19 and 20). Read only once the first escape's own column is fixed, so
## the second escape's own gap check always has a first column to measure against.
##
## A second escape's own column can land on a covered one (`_is_covered()`) even where the
## first did not, since the two are independent columns; dropped afterward, the same "roll still
## runs, only the result is dropped" way `_build_front()` already drops a covered first column,
## rather than reaching into `_roll_fire_escape_extras()`'s own candidate list to keep that pure
## function's stream untouched by anything but its own four arguments.
func _build_fire_escape_extras(cols: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("escape:%d:%d:%d" % [variant, int(global_position.x), int(global_position.y)])
	var extras := _roll_fire_escape_extras(cols, _fire_escape_cols[0], fire_escape_landings(), rng)
	var kept_cols: Array[int] = []
	var kept_pots := {}
	for col: int in extras["cols"]:
		if not _is_covered(col):
			kept_cols.append(col)
			kept_pots[col] = extras["pots"][col]
	_fire_escape_cols = kept_cols
	_fire_escape_pots = kept_pots

## The pure roll behind `_build_fire_escape_extras()`, split out so a test can replay it against the
## same stream the way `_door_col_from()` already is. `first_col` is the column `_build_front()`'s
## own `front:` stream already fixed; `landing_rows` is `fire_escape_landings()`'s own row list,
## the same for every escape on one front since it comes from `wall_tiles()` alone. Returns
## `{"cols": Array[int], "pots": Dictionary}` — `cols` holds `first_col` alone, or both, if the
## front is wide enough (`SECOND_FIRE_ESCAPE_MIN_COLUMNS`) and the second escape's own roll lands;
## `pots` maps each of those columns to its own `{row: bool}`, from `_roll_pots()`.
static func _roll_fire_escape_extras(cols: int, first_col: int, landing_rows: Array[int],
		rng: RandomNumberGenerator) -> Dictionary:
	var escape_cols: Array[int] = [first_col]
	var pots := {first_col: _roll_pots(landing_rows, rng)}
	if cols >= SECOND_FIRE_ESCAPE_MIN_COLUMNS and rng.randf() < SECOND_FIRE_ESCAPE_SHARE:
		var candidates: Array[int] = []
		for col in range(1, cols - 1):
			if absi(col - first_col) >= FIRE_ESCAPE_GAP_COLUMNS:
				candidates.append(col)
		if not candidates.is_empty():
			var second_col: int = candidates[rng.randi_range(0, candidates.size() - 1)]
			escape_cols.append(second_col)
			pots[second_col] = _roll_pots(landing_rows, rng)
	return {"cols": escape_cols, "pots": pots}

## One `randf() < FIRE_ESCAPE_POT_SHARE` draw per landing, in the order `landing_rows` lists them —
## lowest first, the same order `fire_escape_landings()` returns.
static func _roll_pots(landing_rows: Array[int], rng: RandomNumberGenerator) -> Dictionary:
	var pots := {}
	for row in landing_rows:
		pots[row] = rng.randf() < FIRE_ESCAPE_POT_SHARE
	return pots

## Which ground-floor column the entrance door stands in. A seed of its own, distinct from
## `_build_windows()`'s and `_build_front()`'s, so the door moves no window, style, storefront,
## awning, shutter or fire-escape roll. Read after `_build_front()`, since the door keeps clear of
## every fire escape the front has — see `_door_col_from()`. `_fire_escape_cols` already holds both
## columns by the time this runs, since `_rebuild()` calls `_build_front()` first, so a second
## escape is avoided the same way the first always was and the door's own roll — its tiering and
## how many values it draws from the `door:` stream — is unchanged on any front that still has zero
## or one. `covered_ground_cols` is read the same way: it only narrows which columns the tiers
## already offer, so a front with nothing in front of it rolls exactly as before.
func _build_entrance() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("door:%d:%d:%d" % [variant, int(global_position.x), int(global_position.y)])
	_door_col = _door_col_from(columns(), _fire_escape_cols, covered_ground_cols, rng)

## The door's column, rolled from the first non-empty tier: an interior column clear of every fire
## escape and both its neighbours, then any column clear of all of them, then any column but an
## escape's own. `escapes` holds zero, one or two columns — empty or one entry reads exactly the way
## the old single `escape` int (`-1` or a column) did, so a front with no second escape rolls this
## the same as before. The escapes' landings reach eight pixels into both neighbouring columns at
## the ground floor, so a door beside one would be half hidden; the corner columns come second only
## as the courtesy a fire escape pays `WALL_EDGE_W`/`WALL_EDGE_E`, since the door's own margin
## clears the edge line. `covered` is excluded from every tier before any of them is even
## built, the same as an escape's own column, so the door only ever *lands* on a reachable column
## — re-placed onto whichever one the tiers still offer rather than simply dropped — without
## spending a second `randi_range()` call: exactly one tier still yields exactly one call, whatever
## it excludes. Returns -1 where every column is covered, escaped or otherwise excluded from all
## three tiers — a front with no reachable column has no door. Static so a test can replay it
## against the same stream.
static func _door_col_from(cols: int, escapes: Array[int], covered: Array[bool],
		rng: RandomNumberGenerator) -> int:
	var tiers: Array[Array] = [[], [], []]
	for col in cols:
		if col < covered.size() and covered[col]:
			continue
		var clear := true
		for escape in escapes:
			if absi(col - escape) <= 1:
				clear = false
				break
		var interior := cols < 3 or (col > 0 and col < cols - 1)
		if clear and interior:
			tiers[0].append(col)
		if clear:
			tiers[1].append(col)
		if not escapes.has(col):
			tiers[2].append(col)
	for tier in tiers:
		if not tier.is_empty():
			var picked: int = tier[rng.randi_range(0, tier.size() - 1)]
			return picked
	return -1

## The ground-floor column this front's entrance door stands in, or -1 for a front that has none:
## a multi-story front is a way in, and a front that already has one gets no second. A storefront
## is a commercial front's way in and the portico is a civic front's; her own building keeps its
## ground-floor windows and her own door is already cut into her block; a one-row facade keeps its
## windows and has no door; the power station draws its own. A commercial front too narrow for a
## single complete storefront — one column — is the one commercial front that gets a door. Reading
## whether the storefront or portico actually *draws* (`_has_visible_storefront()`,
## `_portico_is_drawn()`) rather than only whether one was rolled matters: a front whose only way
## in rolled entirely onto covered columns still needs its own door, on whatever reachable column
## `_door_col` already is.
func entrance_door_col() -> int:
	if power_station or is_home_building or wall_tiles() < 2:
		return -1
	if district == GameEnums.BlockPurpose.CIVIC and _portico_is_drawn():
		return -1
	if district == GameEnums.BlockPurpose.COMMERCIAL and _has_visible_storefront():
		return -1
	return _door_col

## Where this front's way in stands, as a local x on its ground line: the entrance door's column
## (`entrance_door_col()`), else the civic portico, centred on the facade (`_draw_front_overlay()`),
## else the drawn storefront pair nearest `near` — and `near` itself on a front with none of them,
## a one-row facade, which keeps its windows and has no door. Day 8's task ends at the burnt
## building's door (`City.way_in_behind()`): *"or better to the door"* (sandy-egret).
func way_in_local_x(near: float) -> float:
	var door := entrance_door_col()
	if door >= 0:
		return _cell(door, 0).x + TILE * 0.5
	if _portico_is_drawn():
		return 0.0
	var best_x := near
	var best := INF
	for store in _storefront_variant.size():
		if not _pair_is_storefront(store * 2):
			continue
		var x := _cell(store * 2, 0).x + TILE
		if absf(x - near) < best:
			best = absf(x - near)
			best_x = x
	return best_x

## The door picture for this front's district: steel on an `INDUSTRIAL` block, the plain one on
## every other — and on a burnt building, whatever its district, the burnt doorway boarded shut.
func _entrance_door_texture() -> StringName:
	if condition == Condition.BURNT:
		return ENTRANCE_DOOR_BURNT
	if district == GameEnums.BlockPurpose.INDUSTRIAL:
		return ENTRANCE_DOOR_INDUSTRIAL
	return ENTRANCE_DOOR

# ------------------------------------------------------------------ drawing ---

## Whether `row` draws a window at ground-floor column `col`. Every row does, except the ground
## floor (`row == 0`) of a multi-story building that is not her own: a ground floor is shops or
## blank wall, never windows (`docs/CITY.md`, "A front is district and block purpose"), and a
## one-row facade has no upper floor to make it multi-story in the first place. Her own building
## keeps its ground-floor windows too, except the column(s) `door_world_x_range` covers
## (`_column_under_door()`) — the door is a separate sprite standing in front of whatever the wall
## would otherwise draw there, so a window behind it never showed anything but the door's own back.
## `col` defaults to 0 for every caller that does not care, since it only matters where
## `is_home_building` and the door might actually overlap. Reads no RNG of its own —
## `_build_windows()` still rolls exactly the same `_windows` array and `_window_style` it always
## has, so which upper windows are lit and the window style are unaffected by this rule. **Never
## asked at all for a covered column (`_is_covered()`)**: `_draw()`'s own wall loop skips one
## outright, facade and all, before this is ever called there — see the class doc's own section on
## the roof extension that stands in its place.
func _draws_window_at(row: int, col: int = 0) -> bool:
	if row == 0 and is_home_building and _column_under_door(col):
		return false
	return row > 0 or is_home_building or wall_tiles() < 2

## Whether ground-floor column `col`'s own world-space footprint overlaps `door_world_x_range`.
## The door is 26px wide against a `TILE` (32px) column, so it may straddle two of them; both then
## draw plain wall instead of a window. Called only from `_draws_window_at()`, and only once
## `is_home_building` already is.
func _column_under_door(col: int) -> bool:
	var min_x := global_position.x + _cell(col, 0).x
	return min_x < door_world_x_range.y and min_x + TILE > door_world_x_range.x

## Column `col`'s own world-space horizontal centre — `City.board_neighbor_window()`'s own way of
## finding the column nearest the door without reaching into `_cell()`, which stays private to
## this file.
func column_centre_x(col: int) -> float:
	return global_position.x + _cell(col, 0).x + TILE * 0.5

## The wall row `neighbor_window_col` draws the boarded overlay on — row index 3, the third floor,
## since the ground floor is row 0. The one building this is ever set on always has at least four
## wall rows (`City.HOME_BUILDING_WALL_ROWS`, fixed rather than rolled), so row 3 is always there —
## no fallback needed, since the height that guarantees it is fixed rather than rolled.
func neighbor_window_row() -> int:
	return 3

func _draw() -> void:
	if FrameRecord.on:
		FrameRecord.drew(FrameLedger.DRAWS_SCENERY)
	if not scenery_resident:
		return
	var cols := columns()
	var wall_rows := wall_tiles()
	var roof_rows := roof_tiles()
	var tint := variant if tint_variant < 0 else tint_variant
	var wall_colour := Palette.building_wall(tint)
	var roof_colour := Palette.building_roof(tint)
	if condition == Condition.BURNT:
		wall_colour = Palette.burnt_wall(wall_colour)
		roof_colour = Palette.burnt(roof_colour)

	# The columns the wall and roof are drawn over: all of them, except a power station's yard.
	var hall := _hall_cols()
	if power_station:
		_draw_station_facade(wall_rows, hall)
	for row in (0 if power_station else wall_rows):
		for col in range(hall.x, hall.y):
			# A covered column's whole facade is skipped — wall, window and every edge — since nobody
			# can ever stand in front of it; the roof loop below draws the front that covers it up to
			# that front's own roof line instead.
			if _is_covered(col):
				continue
			var at := _cell(col, row)
			draw_texture(AtlasLibrary.region(WALL), at, wall_colour)
			if _draws_window_at(row, col):
				var index := row * cols + col
				var window_at := at
				if row == 1 and (not _storefront_variant.is_empty() or entrance_door_col() >= 0):
					# A 36px storefront or door rises four pixels into this row; lift every upper
					# window two pixels so its sill remains visible, the whole row alike.
					window_at.y -= 2.0
				draw_texture(AtlasLibrary.region(_window_texture(index)), window_at)
				if col == neighbor_window_col and row == neighbor_window_row():
					draw_texture(AtlasLibrary.region(NEIGHBOR_WINDOW_SEALED), window_at)
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

	_draw_posters()
	_draw_front_overlay()

	# A covered column's own extension (`roof_extension_rows`) makes this roof taller than
	# `roof_rows` there, continuing this same fill and colour north to meet the covered front's own
	# roof, so the row bound is read per column rather than once for the whole building. Which lips
	# each cell draws is `roof_cell_edges()`'s answer, the one place it is decided.
	var max_rows := roof_rows
	for col in range(hall.x, hall.y):
		max_rows = maxi(max_rows, roof_rows + _extension_rows(col))
	for row in max_rows:
		for col in range(hall.x, hall.y):
			if row >= roof_rows + _extension_rows(col):
				continue
			var at := _cell(col, wall_rows + row)
			draw_texture(AtlasLibrary.region(ROOF), at, roof_colour)
			var edges := roof_cell_edges(col, row)
			if edges & ROOF_EDGE_BIT_S:
				draw_texture(AtlasLibrary.region(_front_parapet_texture(col)), at)
			if edges & ROOF_EDGE_BIT_N:
				draw_texture(AtlasLibrary.region(ROOF_EDGE_N), at)
			if edges & ROOF_EDGE_BIT_W:
				draw_texture(AtlasLibrary.region(ROOF_EDGE_W), at)
			if edges & ROOF_EDGE_BIT_E:
				draw_texture(AtlasLibrary.region(ROOF_EDGE_E), at)

	if _station_layer != null:
		_station_layer.queue_redraw()

## Which parapet overlays roof cell (`col`, `row`) draws, as `ROOF_EDGE_BIT_*` flags, or 0 for a
## cell that is not roof at all. Row 0 is the roof's front lip, directly above the wall, and a
## column's roof runs `roof_tiles()` rows plus its own extension. `_draw()` draws exactly this, so
## a test can ask what a seam looks like without rendering it.
## - **S** on row 0, except where another piece of the same courtyard lot carries its roof on into
##   this one (`_is_seamlessly_covered()`).
## - **N** on a column's top row, except where that top is a seamless extension, which the covered
##   piece's own roof carries on above.
## - **W**/**E** on the building's own ends, and on a taller column's face wherever the
##   neighbouring column's roof has already stopped: the step between an extended column and a
##   shorter one, the same picture the building's true end uses, so a partly covered front reads
##   as one roof with a step in it rather than a taller patch dropped beside a shorter one.
func roof_cell_edges(col: int, row: int) -> int:
	var hall := _hall_cols()
	var roof_rows := roof_tiles()
	var col_rows := roof_rows + _extension_rows(col)
	if col < hall.x or col >= hall.y or row < 0 or row >= col_rows:
		return 0
	var edges := 0
	if row == 0 and not _is_seamlessly_covered(col):
		edges |= ROOF_EDGE_BIT_S
	if row == col_rows - 1 and not (_extension_rows(col) > 0 and _extension_is_seamless(col)):
		edges |= ROOF_EDGE_BIT_N
	if col == hall.x or row >= roof_rows + _extension_rows(col - 1):
		edges |= ROOF_EDGE_BIT_W
	if col == hall.y - 1 or row >= roof_rows + _extension_rows(col + 1):
		edges |= ROOF_EDGE_BIT_E
	return edges

## The front parapet over column `col`: the charred one on a burnt building, alternating between
## its two pictures column by column, and the ordinary one everywhere else.
func _front_parapet_texture(col: int) -> StringName:
	if condition == Condition.BURNT:
		return ROOF_EDGE_S_BURNT[posmod(col, ROOF_EDGE_S_BURNT.size())]
	return ROOF_EDGE_S

## The power station hall's own facade in place of the ordinary wall, windows and ground floor —
## industrial rather than a block of flats: steel cladding, a hazard-striped ground course, and a
## clerestory band of tall, narrow windows filling the top two wall rows, lit or unlit by
## `_clerestory_texture()`. Its own colours, never the variant's tint. The parapet turns at either
## end are the ordinary edge overlays. A station's lot is always eight tiles deep, so its wall is
## always tall enough for the base and a two-row clerestory; a shorter one would simply lose the
## band.
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
		var band := AtlasLibrary.region(_clerestory_texture())
		for col in range(hall.x, hall.y):
			draw_texture(band, _cell(col, wall_rows - 1))
	for row in wall_rows:
		draw_texture(AtlasLibrary.region(WALL_EDGE_W), _cell(hall.x, row))
		draw_texture(AtlasLibrary.region(WALL_EDGE_E), _cell(hall.y - 1, row))

## The hall's high windows: dimly lit on the last night while the city still has power, unlit
## otherwise. The last night only, because that is the night the hall is watched going out — the
## one night she is sent to its door (`docs/NARRATIVE.md`, "What the tasks are for"); on every
## other day the station is a building she passes, drawn as it was approved, unlit.
func _clerestory_texture() -> StringName:
	if powered and day == Tuning.POWER_STATION_DAY:
		return POWER_STATION_CLERESTORY_LIT
	return POWER_STATION_CLERESTORY

## The `[first, end)` columns the wall and roof cover: the whole facade, or for the power station
## everything but its yard, which is one block at one end of the lot.
func _hall_cols() -> Vector2i:
	var cols := columns()
	if not power_station or station_yard_cols.y <= 0:
		return Vector2i(0, cols)
	if station_yard_cols.x == 0:
		return Vector2i(station_yard_cols.y, cols)
	return Vector2i(0, station_yard_cols.x)

## The power station's yard over its block, after the hall's wall and roof. The yard picture's
## lines run off its west edge towards the hall, so a yard west of the hall is drawn mirrored —
## through `Sprites.draw_standing`, the one place that mirrors, anchored at the yard's own bottom
## centre on the lot's south edge. The stacks are not drawn here: they rise past the lot's north
## edge, so they stand in `City`'s y-sorted layer instead (`stack_feet()`, `StationStack`).
func _draw_station_yard(hall: Vector2i, canvas: CanvasItem = self) -> void:
	if station_yard_cols.y <= 0:
		return
	var yard := AtlasLibrary.region(POWER_STATION_YARD)
	var left := _cell(station_yard_cols.x, 0).x
	var foot := Vector2(left + station_yard_cols.y * TILE * 0.5, 0.0)
	var mirrored := station_yard_cols.x < hall.x
	Sprites.draw_standing(canvas, yard, foot, Vector2.ZERO, mirrored)

## Where the power station's stacks stand, in this building's own coordinates: the foot of each, at
## its roof cell's bottom centre (`_STACK_CELLS`, clamped to the hall and its roof). Empty for every
## other building. Read once by `City._spawn_buildings()`, which stands a `StationStack` on each
## foot in its `Entities` layer; it reads nothing but the exports `City` sets before that.
func stack_feet() -> Array[Vector2]:
	var feet: Array[Vector2] = []
	if not power_station:
		return feet
	var hall := _hall_cols()
	var wall_rows := wall_tiles()
	var roof_rows := roof_tiles()
	for cell in _STACK_CELLS:
		var col := hall.x + mini(cell.x, hall.y - hall.x - 1)
		var row := mini(cell.y, roof_rows - 1)
		feet.append(_cell(col, wall_rows + row) + Vector2(TILE * 0.5, TILE))
	return feet

## Top-left corner of a cell, counting rows northward from the ground line.
func _cell(col: int, row: int) -> Vector2:
	return Vector2(-columns() * TILE * 0.5 + col * TILE, -(row + 1) * TILE)

## `WALL_BASE`, unless `col` is the first column of a complete two-column `COMMERCIAL` shopfront —
## its own fill is opaque, which is what lets this stay a plain substitution rather than a second
## draw call skipping the windows. The second column returns `null` because its partner already
## paints both cells; an odd final column stays `WALL_BASE`.
##
## A `BURNT` building's pairs are all the gutted shop, and a `BOARDED` block shutters every one of
## its own storefronts outright. Short of either, a shop
## still shutters early once `Tuning.degradation_for(day) * AMBIENT_SHUTTER_SHARE` has passed the
## cell's own fixed roll — the city's services failing ahead of any one block's arc, which is why
## this reads `condition` and `day` as two separate questions rather than one.
func _ground_floor_texture(col: int) -> StringName:
	if _is_covered(col):
		return &""
	if _storefront_variant.is_empty():
		return WALL_BASE
	if col % 2 == 1:
		return &"" if _pair_is_storefront(col - 1) else WALL_BASE
	if not _pair_is_storefront(col):
		return WALL_BASE
	if condition == Condition.BURNT:
		return STOREFRONT_BURNT
	var store := col / 2
	var index: int = _storefront_variant[store]
	var ambient_shutter := _storefront_shutter_severity[store] < Tuning.degradation_for(day) * AMBIENT_SHUTTER_SHARE
	if condition == Condition.BOARDED or ambient_shutter:
		return STOREFRONT_SHUTTERED_TEXTURES[index]
	return STOREFRONT_AWNING_TEXTURES[index] if _storefront_awning[store] else STOREFRONT_TEXTURES[index]

## Whether the two-column pair starting at even column `first` actually draws as a storefront: a
## complete pair within `_storefront_variant`'s own range, inside the front's own width, and with
## neither of its own two columns covered (`_is_covered()`) — a storefront's own two-column
## span only ever lands on reachable columns, the same as the entrance door. The roll behind
## `first` still ran in `_build_front()` regardless; this only says whether it gets painted.
func _pair_is_storefront(first: int) -> bool:
	if _storefront_variant.is_empty():
		return false
	var store := first / 2
	if store >= _storefront_variant.size() or first + 1 >= columns():
		return false
	return not _is_covered(first) and not _is_covered(first + 1)

## Whether this `COMMERCIAL` front's storefront draws anywhere at all — every rolled pair checked
## through `_pair_is_storefront()`, since a storefront that rolled but landed entirely on covered
## columns offers no way in after all, and `entrance_door_col()` reads this to decide whether
## the front still needs its own door.
func _has_visible_storefront() -> bool:
	for store in _storefront_variant.size():
		if _pair_is_storefront(store * 2):
			return true
	return false

## Whether this `CIVIC` front's portico actually draws: every column of `_civic_entrance_cols()`
## reachable, since one picture cannot show a door on one column and no facade at all on its
## covered neighbour. `entrance_door_col()` reads this the same way it reads
## `_has_visible_storefront()`.
func _portico_is_drawn() -> bool:
	if district != GameEnums.BlockPurpose.CIVIC:
		return false
	for col in _civic_entrance_cols():
		if _is_covered(col):
			return false
	return true

## The ground-floor cells with nothing on them but the plain wall and its plinth — no window, no
## storefront, no civic entrance, no entrance door and not a column a fire escape stands against.
## Local space, one `Vector2(TILE, TILE)` rect per blank column, in
## the same top-left convention `_cell()` already uses for every draw call in this file. Empty for
## the power station (it draws its own front), her own building (the blank-wall rule's one
## exception) and a one-row facade (not multi-story, so the rule never reaches it). A covered column
## is excluded too, but needs no check of its own here: `_ground_floor_texture()` already
## answers `&""` rather than `WALL_BASE` for one, so the loop below leaves it out on its own. Read by
## `PosterWalls` — it is the ground a poster crew pastes on.
func blank_ground_floor_cells() -> Array[Rect2]:
	var result: Array[Rect2] = []
	if power_station or is_home_building or wall_tiles() < 2:
		return result
	var entrance_cols: Array[int] = []
	if _portico_is_drawn():
		entrance_cols = _civic_entrance_cols()
	var door_col := entrance_door_col()
	for col in columns():
		if entrance_cols.has(col) or col == door_col or _fire_escape_cols.has(col):
			continue
		if _ground_floor_texture(col) == WALL_BASE:
			result.append(Rect2(_cell(col, 0), Vector2(TILE, TILE)))
	return result

## The sheets on the blank ground-floor cells (`posters`), after the plinth and before the door and
## fire escapes, so a fire escape's platform, whose brackets reach eight pixels into the columns
## beside it, still stands in front of a sheet pasted there. Drawn at their own colours, never the
## wall's tint. A burnt front has lost them with its paint. An older sheet showing under a newer
## one is drawn first, shifted the other way — see `PosterArt.UNDER_OFFSET`.
func _draw_posters() -> void:
	if posters.is_empty() or condition == Condition.BURNT:
		return
	for col: int in posters:
		var cell: Dictionary = posters[col]
		var at := _cell(col, 0)
		var side := float(cell["side"])
		var over := Vector2.ZERO
		if int(cell["under"]) != PosterState.NONE:
			draw_texture(PosterArt.texture_for(int(cell["under"]), int(cell["under_tear"])),
					at + PosterArt.UNDER_OFFSET * Vector2(side, 1.0))
			over = PosterArt.OVER_OFFSET * Vector2(side, 1.0)
		draw_texture(PosterArt.texture_for(int(cell["kind"]), int(cell["tear"])), at + over)

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
	if condition == Condition.BURNT:
		return WINDOW_BURNT
	var style := _WindowStyle.SHUTTERED if condition == Condition.BOARDED else _window_style
	match style:
		_WindowStyle.SHUTTERED:
			return WINDOW_SHUTTERED_LIT if _lit(index) else WINDOW_SHUTTERED_DARK
		_WindowStyle.TALL:
			return WINDOW_TALL_LIT if _lit(index) else WINDOW_TALL_DARK
		_:
			return WINDOW_LIT if _lit(index) else WINDOW_DARK

## The overlays on a front: its entrance door, the fire escape(s) bolted to a `RESIDENTIAL` facade
## or a portico at a `CIVIC` entrance, drawn after every ground-floor cell so each stands in front of
## the shopfront or plinth rather than under it. The door goes first, since it is set in the wall
## plane the escape stands out from. Anchored at local `y = 0`, the ground
## line `_cell`'s own row 0 already sits on, so `Sprites.draw_standing()`'s bottom-centre contract
## needs no offset math here.
func _draw_front_overlay() -> void:
	var door_col := entrance_door_col()
	if door_col >= 0:
		var door_x := _cell(door_col, 0).x + TILE * 0.5
		Sprites.draw_standing(self, AtlasLibrary.region(_entrance_door_texture()), Vector2(door_x, 0.0))
	if not _fire_escape_cols.is_empty():
		_draw_fire_escape()
	if _portico_is_drawn():
		Sprites.draw_standing(self, AtlasLibrary.region(CIVIC_PORTICO), Vector2(0.0, 0.0))
	if power_station:
		var x := _cell(station_door_col, 0).x + TILE * CityMap.POWER_STATION_DOOR_TILES * 0.5
		Sprites.draw_standing(self, AtlasLibrary.region(POWER_STATION_DOOR), Vector2(x, 0.0))

## The rows whose floor line carries one of this front's fire-escape balconies, lowest first, or
## empty for a front with none. The same rows for every escape the front has — a floor's height
## does not depend on which column the escape stands in. A row's floor line is its bottom edge, so
## row 1's balcony is the first floor's, standing on the ground floor's top edge, and the last is
## the top floor's: "you start at the bottom of the top floor then the same texture gets placed on
## each floor" (PLAYTEST-124.md, statement 13). Every balcony but the lowest hangs a flight down
## through the floor below it to the next balcony down; the lowest is the platform alone, so the
## ground floor carries only the brackets under it and nothing comes down to the sidewalk.
func fire_escape_landings() -> Array[int]:
	var result: Array[int] = []
	if _fire_escape_cols.is_empty():
		return result
	for row in range(1, wall_tiles()):
		result.append(row)
	return result

## The picture for the balcony on `row`'s floor line of the escape standing in `col`: the platform
## alone on the lowest, the balcony and its flight on every other; the potted-plant picture or the
## plain one, per `_fire_escape_pots[col][row]` — rolled balcony by balcony rather than once for the
## whole escape, so the two pictures mix within one escape and between the two on a wide front.
func fire_escape_texture(col: int, row: int) -> StringName:
	var pots: Dictionary = _fire_escape_pots.get(col, {})
	var pot: bool = pots.get(row, false)
	if row <= 1:
		return FIRE_ESCAPE_PLATFORM_A if pot else FIRE_ESCAPE_PLATFORM_B
	return FIRE_ESCAPE_A if pot else FIRE_ESCAPE_B

## Every fire escape the front carries, one picture per floor (`fire_escape_landings()`) per column
## (`_fire_escape_cols`). Each picture's balcony sits one row above its bottom edge and its flight
## hangs through the row below, so the balcony on `row`'s floor line is anchored on the floor line
## of `row - 1`. Each escape is drawn from the top down, so each balcony's railing stands in front
## of the foot of the flight that comes down onto it. Every picture is drawn the same way round: the
## flights all face one direction, never alternating, on either escape.
func _draw_fire_escape() -> void:
	var landings := fire_escape_landings()
	for col in _fire_escape_cols:
		var x := _cell(col, 0).x + TILE * 0.5
		for i in range(landings.size() - 1, -1, -1):
			var row := landings[i]
			var foot := Vector2(x, _cell(col, row - 1).y + TILE)
			Sprites.draw_standing(self, AtlasLibrary.region(fire_escape_texture(col, row)), foot)

# ------------------------------------------------------------- roof furniture ---

## Rolls this building's roof units, once per `_rebuild()` rather than once per frame — the same
## contract `_build_windows()` already keeps — over the cells `roof_interior_cells()` offers.
## Nothing is placed on a roof too shallow to have an interior cell at all: one under three
## columns wide, or whose tallest column, extension included, is under three rows deep.
##
## **An extended roof carries furniture too** (`roof_extension_rows`): the pool reaches onto the
## extension as anywhere else on the roof, so a building whose own roof is too shallow for an
## interior cell carries units once its extension gives it one. The roll is keyed on `variant` and
## position alone, so a fixed seed gives the same roof every time — but a covering building's pool
## is larger than its unextended roof's, so its whole layout is a different shuffle from the one
## the same building would have with nothing to cover. A unit never sits on a cell the roof's own
## lips already draw: the perimeter, as on every roof, and on the extension any cell
## `roof_cell_edges()` gives a lip, which is where a taller column steps down beside a shorter one.
func _build_roof_furniture() -> void:
	_roof_furniture.clear()
	_has_vent = false
	if recipe_roof_furniture != null:
		_roof_furniture.assign(recipe_roof_furniture)
		for entry: Dictionary in _roof_furniture:
			_has_vent = _has_vent or entry.kind == _Furniture.VENT
		_roof_furniture.sort_custom(func(a, b): return (a.cell as Vector2i).y > (b.cell as Vector2i).y)
		return
	var kinds: Array = _KINDS_BY_DISTRICT.get(district, [])
	var compact_kinds: Array = _COMPACT_KINDS_BY_DISTRICT.get(district, [])
	var density: float = _FURNITURE_DENSITY.get(district, 0.0)
	if kinds.is_empty() or density <= 0.0:
		return
	var interior := roof_interior_cells()
	if interior.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("roof:%d:%d:%d" % [variant, int(global_position.x), int(global_position.y)])
	_shuffle(interior, rng)
	var wanted := clampi(roundi(interior.size() * density), 1, interior.size())
	var used := {}
	var interior_set := {}
	for candidate in interior:
		interior_set[candidate] = true
	if district == GameEnums.BlockPurpose.INDUSTRIAL:
		wanted -= _place_duct_network(interior, wanted, used, rng)
	var placed := 0
	for cell in interior:
		if placed >= wanted:
			break
		if used.has(cell):
			continue
		var kind: int = kinds[rng.randi() % kinds.size()]
		var span := _furniture_span(kind)
		var east := cell + Vector2i.RIGHT
		if span == 2 and (not interior_set.has(east) or used.has(east)):
			# Falling back changes only which ordinary unit fills this already-counted roll. It
			# prevents a broad base from silently dropping the unit on a one-column or fragmented row.
			kind = compact_kinds[rng.randi() % compact_kinds.size()]
			span = 1
		used[cell] = true
		var cells: Array[Vector2i] = [cell]
		if span == 2:
			used[east] = true
			cells.append(east)
		_roof_furniture.append({"cell": cell, "kind": kind, "span": span, "cells": cells})
		if kind == _Furniture.VENT:
			_has_vent = true
		placed += 1
	# Farthest (highest row) first, so the roof layers paint back to front without
	# re-sorting on every redraw.
	_roof_furniture.sort_custom(func(a, b): return (a["cell"] as Vector2i).y > (b["cell"] as Vector2i).y)

## Displayed bases up to one tile stand on one cell. Wider equipment is centered across two reserved
## cells; height is deliberately unrelated to this footprint and may extend several tiles north.
func _furniture_span(kind: int) -> int:
	var key := _furniture_texture(kind)
	return ceili(AtlasLibrary.native_size(key).x * roof_equipment_scale(key) / TILE)

static func roof_equipment_scale(key: StringName) -> float:
	if key in [VENT_STACK, VENT_HOUSING, EXHAUST_FAN, PIPE_MANIFOLD]:
		return STANDALONE_EQUIPMENT_SCALE
	if key == SERVICE_BULKHEAD:
		return ACCESS_ROOM_SCALE
	return 1.0

## Exact recipe fixtures use the production interior, district and displayed equipment width.
## Validate the entire replacement before changing the resident or streamed description.
func author_roof_furniture(entries: Array) -> Array[String]:
	var errors: Array[String] = []
	var placed: Array[Dictionary] = []
	var used := {}
	var interior := roof_interior_cells()
	var kinds: Array = _KINDS_BY_DISTRICT.get(district, []).duplicate()
	if district == GameEnums.BlockPurpose.INDUSTRIAL:
		kinds.append(_Furniture.DUCT_RUN)
	for entry: Dictionary in entries:
		var public_kind := str(entry.kind).to_upper()
		if not RECIPE_FURNITURE_KINDS.has(public_kind):
			errors.append("roof_fixtures.kind: unknown fixture kind")
			continue
		var duct := public_kind in ["DUCT_STRAIGHT", "DUCT_CORNER"]
		var kind: int = _Furniture.DUCT_RUN if duct else _Furniture.get(public_kind, -1)
		var cell := Vector2i(int(entry.cell[0]), int(entry.cell[1]))
		if power_station or not kinds.has(kind):
			errors.append("roof_fixtures.kind: fixture is not available on this production roof")
			continue
		var span := _furniture_span(kind) if not duct else (2 if public_kind == "DUCT_STRAIGHT" else 1)
		var cells: Array[Vector2i] = []
		for offset in span:
			var occupied := cell + Vector2i(offset, 0)
			if not interior.has(occupied) or used.has(occupied):
				errors.append("roof_fixtures.cell: outside the roof interior or overlapping another fixture")
			used[occupied] = true
			cells.append(occupied)
		if duct:
			# Public recipe shapes retain their reserved cells while sharing the mounted
			# component renderer: a two-cell east/west span or a west/north elbow.
			for occupied in cells:
				var duct_cells: Array[Vector2i] = [occupied]
				placed.append({"cell": occupied, "kind": kind, "span": 1,
					"cells": duct_cells, "links": 3 if span == 2 else 9})
		else:
			placed.append({"cell": cell, "kind": kind, "span": span, "cells": cells})
	if errors.is_empty():
		recipe_roof_furniture = placed
		_rebuild()
	return errors

## The cells a roof unit may stand on, in the fixed order `_build_roof_furniture()` shuffles:
## row by row from row 1, each row west to east over the interior columns, keeping a cell only
## below its own column's top (extension included) and leaving out any extension cell
## `roof_cell_edges()` gives a lip. Empty for a roof under three columns wide or whose tallest
## column is under three rows deep, which has no interior cell at all. **The order is
## load-bearing:** the shuffle permutes positions, so a building with nothing to cover lands its
## units where an unextended roof always has only because its pool is the same cells in the same
## row-major order. The rows below `roof_tiles()` take no lip check, since no step or seam lip
## reaches them.
func roof_interior_cells() -> Array[Vector2i]:
	var interior: Array[Vector2i] = []
	var roof_rows := roof_tiles()
	var cols := columns()
	var tallest := roof_rows
	for col in cols:
		tallest = maxi(tallest, roof_rows + _extension_rows(col))
	if tallest < 3 or cols < 3:
		return interior
	for row in range(1, tallest - 1):
		for col in range(1, cols - 1):
			if row >= roof_rows + _extension_rows(col) - 1:
				continue
			if row >= roof_rows and roof_cell_edges(col, row) != 0:
				continue
			interior.append(Vector2i(col, row))
	return interior

## Grow one connected tree inside the actual eligible roof, extensions included. A free cell
## joins only one occupied neighbor, so branches stay readable rather than filling a solid patch.
## Leave at least one ordinary equipment roll; a tiny roof keeps its compact furniture instead.
func _place_duct_network(interior: Array[Vector2i], budget: int, used: Dictionary,
		rng: RandomNumberGenerator) -> int:
	if budget < 4:
		return 0
	var target := rng.randi_range(3, budget - 1)
	var network := {interior[0]: true}
	while network.size() < target:
		var frontier: Array[Vector2i] = []
		for cell in interior:
			if network.has(cell):
				continue
			var neighbors := 0
			for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				neighbors += int(network.has(cell + direction))
			if neighbors == 1:
				frontier.append(cell)
		if frontier.is_empty():
			break
		network[frontier[rng.randi_range(0, frontier.size() - 1)]] = true
	if network.size() < 3:
		return 0
	for cell: Vector2i in network:
		var links := 0
		for index in 4:
			var direction: Vector2i = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN][index]
			if network.has(cell + direction):
				links |= 1 << index
		used[cell] = true
		var cells: Array[Vector2i] = [cell]
		_roof_furniture.append({"cell": cell, "kind": _Furniture.DUCT_RUN, "span": 1,
			"cells": cells, "links": links})
	return network.size()

## A Fisher-Yates shuffle over `rng` rather than `Array.shuffle()`, which reads the engine's own
## global RNG and would make the roll different every launch — every other seeded pick in this
## file (and `_build_windows()` beside it) stays reproducible from `variant` and position alone.
static func _shuffle(cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := cells[i]
		cells[i] = cells[j]
		cells[j] = tmp

## A live City supplies `roof_object_parent`, so each roof unit becomes a feet-anchored entity and
## y-sorts against street actors. A standalone fixture parents the same visual-only objects to the
## building at their local feet; it does not retain a second rendering path for the direct PNGs.
func _build_roof_layers() -> void:
	_clear_roof_layers()
	_clear_roof_objects()
	var parent: Node2D = roof_object_parent if roof_object_parent != null else self
	for entry in _roof_furniture:
		var cell: Vector2i = entry["cell"]
		var span: int = entry["span"]
		var at := _cell(cell.x, wall_tiles() + cell.y)
		var anchor := at + Vector2(TILE * span * 0.5, TILE)
		var object := RoofObject.new()
		object.name = "RoofObject_%d_%d" % [cell.x, cell.y]
		object.texture_key = _furniture_texture(entry["kind"])
		object.duct_links = entry.get("links", -1)
		object.position = parent.to_local(to_global(anchor)) if parent != self else anchor
		parent.add_child(object)
		_roof_objects.append(object)
		if entry["kind"] == _Furniture.VENT:
			_rotor_layers.append(object.add_rotor(_vent_frame_b))
	if power_station:
		_station_layer = Node2D.new()
		add_child(_station_layer)
		_station_layer.draw.connect(_draw_station_layer)

func _clear_roof_layers() -> void:
	if _station_layer != null:
		_station_layer.free()
		_station_layer = null

func _clear_roof_objects() -> void:
	_rotor_layers.clear()
	for object in _roof_objects:
		if is_instance_valid(object):
			object.free()
	_roof_objects.clear()

func _draw_station_layer() -> void:
	if FrameRecord.on:
		FrameRecord.drew(FrameLedger.DRAWS_SCENERY)
	_draw_station_yard(_hall_cols(), _station_layer)

func _furniture_texture(kind: int) -> StringName:
	match kind:
		_Furniture.VENT:
			return VENT_HOUSING
		_Furniture.HVAC_A:
			return HVAC_A
		_Furniture.HVAC_B:
			return HVAC_B
		_Furniture.DUCT_RUN:
			return DUCT_RUN
		_Furniture.SKYLIGHT_A:
			return SKYLIGHT_A
		_Furniture.SKYLIGHT_B:
			return SKYLIGHT_B
		_Furniture.VENT_STACK:
			return VENT_STACK
		_Furniture.SERVICE_BULKHEAD:
			return SERVICE_BULKHEAD
		_Furniture.EXHAUST_FAN:
			return EXHAUST_FAN
		_Furniture.PIPE_MANIFOLD:
			return PIPE_MANIFOLD
		_:
			return WATER_TANK

## A roof picture standing in the city's y-sorted entity layer. It has no body: the Building's
## lot collision remains the sole gameplay geometry, while this node gives tall art the correct
## depth origin at its roof foot.
class RoofObject extends Node2D:
	var texture_key: StringName
	## West, east, south and north neighbors in roof-cell coordinates; -1 draws the whole asset.
	var duct_links := -1

	func _enter_tree() -> void:
		AtlasLibrary.acquire(&"buildings")
		# Uniform scale about the foot also scales any rotor child and preserves depth sorting.
		scale = Vector2.ONE * Building.roof_equipment_scale(texture_key)

	func _exit_tree() -> void:
		AtlasLibrary.release(&"buildings")

	func _draw() -> void:
		if FrameRecord.on:
			FrameRecord.drew(FrameLedger.DRAWS_SCENERY)
		var texture := AtlasLibrary.region(texture_key)
		if duct_links >= 0:
			_draw_duct(texture)
			return
		Sprites.draw_standing(self, texture, Vector2.ZERO)

	## Reuse the approved mounted duct's straight spans as joined sections. Source rectangles
	## exclude its elbow and away-facing mouth: no rotation can expose a false west/north opening.
	func _draw_duct(texture: Texture2D) -> void:
		var west := (duct_links & 1) != 0
		var east := (duct_links & 2) != 0
		var south := (duct_links & 4) != 0
		var north := (duct_links & 8) != 0
		if north or south:
			var top := -40.0 if north else -24.0
			var bottom := -8.0
			draw_texture_rect_region(texture, Rect2(-5, top, 10, bottom - top),
					Rect2(53, 26, 10, 16))
		if west or east:
			var left := -16.0 if west else -5.0
			var right := 16.0 if east else 5.0
			draw_texture_rect_region(texture, Rect2(left, -20, right - left, 20),
					Rect2(18, 44, 24, 20))
		else:
			# The upright source span carries no foot; keep its original elbow's support
			# beneath it so a north/south-only network is mounted too.
			draw_texture_rect_region(texture, Rect2(-6, -9, 12, 9), Rect2(52, 55, 12, 9))

	## Adds the independently redrawn rotor over the stationary generated housing. The building
	## owns phase and timing, so rebuilding this child never resets the motion.
	func add_rotor(frame_b: bool) -> SceneryLayer:
		var layer := SceneryLayer.new()
		layer.frame_b = frame_b
		var size := AtlasLibrary.native_size(texture_key)
		var top_left := -Vector2(size.x * 0.5, size.y)
		layer.append(AtlasLibrary.region(VENT_ROTOR),
				Rect2(top_left + VENT_ROTOR_RECT.position, VENT_ROTOR_RECT.size),
				AtlasLibrary.region(VENT_ROTOR_B))
		add_child(layer)
		return layer

## One of the power station's stacks, standing in `City`'s y-sorted `Entities` layer at its foot
## (`Building.stack_feet()`) rather than drawn with the building beneath every entity. A stack is
## the one part of a building that rises past its lot's north edge — 192px tall from a foot a few
## tiles south of that edge, so it reaches well into the street north of it — so she walks where it
## should hide her, and the building layer would draw her over it. *(PLAYTEST-143: "the chimneys of the
## power plant render behind the player. they should be in front.")* In the entities' own depth
## order it hides whatever stands north of its foot and is drawn under whatever stands south of it.
## No walkable ground lies south of a foot within a stack's own width, since the foot is on the
## hall's roof, so in practice it is in front of everything its picture reaches. It acquires the
## `buildings` atlas group itself, since it lives outside the building that otherwise holds it.
class StationStack extends ScenerySprite:
	func _enter_tree() -> void:
		AtlasLibrary.acquire(&"buildings")

	func _exit_tree() -> void:
		AtlasLibrary.release(&"buildings")

	func _draw() -> void:
		if FrameRecord.on:
			FrameRecord.drew(FrameLedger.DRAWS_SCENERY)
		if not scenery_resident:
			return
		Sprites.draw_standing(self, AtlasLibrary.region(Building.POWER_STATION_STACK), Vector2.ZERO)

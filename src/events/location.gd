class_name Location
extends RefCounted
## **One location of a street**, the place a drawn event stands (inbox #1185 in gentle-owl): a street is split
## along its length into three sections, an event that spans the street takes a whole section, and
## otherwise a section holds two locations, one per sidewalk, so a street has up to six. A
## `Location` is either of the two kinds: a sidewalk location (one sidewalk band of one section) or
## a section (the street's whole width over the section's length); `StreetLocations` keeps the two
## kinds apart. See `docs/EVENTS.md`, "The three views and the placement order".
##
## **It knows its view because it is told it once, at dawn** (`PlacementView.View`,
## `Corridor.view_of()` through `DayLocations.lay_out()`), and never works it out again: the view is
## a fact derived once and held by the one object the day hands around (inbox #1156 in
## gray-dolphin).
##
## Made only by `StreetLocations`; what stands on it changes only through `StreetLocations`, which
## `DayLocations` asks. Pure state: no node, nothing that runs.

## What ground a location is, which decides the tiles a row may stand on in it (`takes()`): a
## street's sidewalk, a street's section (its carriageway, for an event that spans the street or
## drives it), an alley, an open lot (a square or a park), or a junction box. *(The player, of ground
## beyond a street's six locations: "yes" to the pick, a group of locations per kind of ground, an
## alley a one-sided street of three, a square or park a grid of section-sized locations, a junction
## box one location its streets share, a carriageway event taking its section; inbox #1185 in gentle-owl.)*
enum Kind { SIDEWALK, SECTION, ALLEY, OPEN, JUNCTION }

var _segment: StreetNetwork.Segment
var _section := 0
var _tiles := Rect2i()
var _centre := Vector2.ZERO
var _view := PlacementView.View.OFF_THE_ROUTE
## False where a fixed part holds the ground for the day (`DayLocations.lay_out()`).
var _available := true
## What a phase put here, or null while nothing has.
var _plan: EventPlan = null
var _kind := Kind.SECTION
## Whether a draw has filled it, with an event or with nothing (`record()`).
var _drawn := false

func _init(segment: StreetNetwork.Segment, section: int, tiles: Rect2i,
		centre: Vector2, view: int, available: bool, kind := Kind.SECTION) -> void:
	_kind = kind
	_segment = segment
	_section = section
	_tiles = tiles
	_centre = centre
	_view = view
	_available = available

## The street the location is part of.
func segment() -> StreetNetwork.Segment:
	return _segment

## The tiles the location covers.
func tiles() -> Rect2i:
	return _tiles

## The middle of the location, in world space.
func centre() -> Vector2:
	return _centre

## The view the location is in (`PlacementView.View`), told it at dawn.
func view() -> int:
	return _view

## Whether the location is open to an event at all today: false on ground a fixed part holds, a
## closure, a hard seal's street, the region wall or one of its doors, or the home's streets.
func is_available() -> bool:
	return _available

## Whether a phase has already put a plan here (`take()`), so no draw happens for it.
func is_taken() -> bool:
	return _plan != null

## Puts `plan` here for the day, as a phase assigns it: by `StreetLocations` on a street, by
## `DayLocations` on the ground beyond the streets.
func take(plan: EventPlan) -> void:
	_plan = plan

## Whether `other` lies inside this location's section: the same street and the same section,
## whichever side. What `StreetLocations` takes along with a section.
func shares_a_section_with(other: Location) -> bool:
	return other.segment() == _segment and other.section() == _section

## Which of its street's three sections the location is in, 0 to 2 along the street from its first
## junction.
func section() -> int:
	return _section

## What ground the location is (`Kind`).
func kind() -> int:
	return _kind

## **Whether a row may stand on a tile of `type` in this location**: a sidewalk location takes
## anything but the carriageway and the crossings, a section its carriageway (`ROAD`), an alley its
## alley, an open lot its park or square, a junction box its street ground (its sidewalk corners,
## its carriageway and its crossings).
func takes(type: int) -> bool:
	match _kind:
		Kind.SIDEWALK:
			return type != GameEnums.TileType.ROAD and type != GameEnums.TileType.CROSSING
		Kind.SECTION:
			return type == GameEnums.TileType.ROAD
		Kind.ALLEY:
			return type == GameEnums.TileType.ALLEY
		Kind.OPEN:
			return type == GameEnums.TileType.PARK or type == GameEnums.TileType.SQUARE
		_:
			return type == GameEnums.TileType.CROSSING or type == GameEnums.TileType.SIDEWALK \
					or type == GameEnums.TileType.ROAD

## Whether a draw has filled it yet, with an event or with nothing.
func is_drawn() -> bool:
	return _drawn

## Records what the draw put here: `plan`, or nothing for the empty event.
func record(plan: EventPlan) -> void:
	_drawn = true
	if plan:
		_plan = plan

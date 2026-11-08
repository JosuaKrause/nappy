class_name Location
extends RefCounted
## **One location of a street**, the place a drawn event stands (inbox #1185): a street is split
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

var _segment: StreetNetwork.Segment
var _section := 0
var _tiles := Rect2i()
var _centre := Vector2.ZERO
var _view := PlacementView.View.OFF_THE_ROUTE
## False where a fixed part holds the ground for the day (`DayLocations.lay_out()`).
var _available := true
## What a phase put here, or null while nothing has.
var _plan: EventScheduler.Planned = null

func _init(segment: StreetNetwork.Segment, section: int, tiles: Rect2i,
		centre: Vector2, view: int, available: bool) -> void:
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

## Puts `plan` here for the day. Called by `StreetLocations` alone, as a phase assigns it.
func take(plan: EventScheduler.Planned) -> void:
	_plan = plan

## Whether `other` lies inside this location's section: the same street and the same section,
## whichever side. What `StreetLocations` takes along with a section.
func shares_a_section_with(other: Location) -> bool:
	return other.segment() == _segment and other.section() == _section

## Which of its street's three sections the location is in, 0 to 2 along the street from its first
## junction.
func section() -> int:
	return _section

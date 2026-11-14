class_name PlacementUnit
extends RefCounted
## **One unit of the day's locations, the thing a draw fills in one go**: a street (its three
## sections and six sidewalk locations), a junction box, an alley (its up to three locations) or one
## park or square (its cells). *(The player: "agree on all design review points. let's do it", to
## the proposal of drawing a whole street at once, seeded by the day and the street, so a street
## holds the same events whatever her path; inbox #1268 in olive-ferret. `docs/EVENTS.md`, "The
## three views and the placement order".)*
##
## **Its name is its kind and its tiles**, so a unit has the same name on every start of the same
## city and day: nothing about an object's identity or an array's order enters a seed. Its rank and
## its stream are hashes of the day's seed and the name. **The rank orders two touching units'
## draws** (`DayUnits`, `UnitDraw`): of two that touch, the lower rank always draws first, which is
## what makes a unit's draw the same whatever her path.
##
## Pure state: no node, and **no reference to another unit**, since two `RefCounted` objects holding
## each other leak at exit; `DayUnits` holds which touch which, by name. What it drew is written
## once, by `UnitDraw`. Model.

enum Kind { STREET, JUNCTION, ALLEY, OPEN }

const _KIND_NAMES: Array[String] = ["street", "junction", "alley", "open"]

var _kind := Kind.STREET
var _tiles := Rect2i()
var _bounds := Rect2()
var _locations: Array[Location] = []
var _day_seed := 0
var _name := ""
var _rank := 0
var _drawn := false
var _placed: Array[EventPlan] = []

## `tiles` is the ground the unit is: its street's rect, its box, its alley's rect, its lot's
## bounds (`Location.part_of()`); `bounds` the same in world space; `locations` its locations, a
## street's sections first, then its sidewalks, as laid out.
func _init(kind: Kind, tiles: Rect2i, bounds: Rect2, locations: Array[Location],
		day_seed: int) -> void:
	_kind = kind
	_tiles = tiles
	_bounds = bounds
	_locations = locations
	_day_seed = day_seed
	_name = "%s:(%d, %d, %d, %d)" % [_KIND_NAMES[kind], tiles.position.x, tiles.position.y,
			tiles.size.x, tiles.size.y]
	_rank = hash("%d:unit-rank:%s" % [day_seed, _name])

## What ground the unit is (`Kind`).
func kind() -> Kind:
	return _kind

## The unit's name for the day: its kind and its tiles, the same on every start of the day.
func name() -> String:
	return _name

## The tiles the unit is.
func tiles() -> Rect2i:
	return _tiles

## The unit's tiles in world space.
func bounds() -> Rect2:
	return _bounds

## Its locations: a street's sections first, then its sidewalks, as laid out.
func locations() -> Array[Location]:
	return _locations

## Its fixed rank for the day, a hash of the day's seed and its name.
func rank() -> int:
	return _rank

## **Whether this unit draws before `other`** where the two touch: the lower rank first, a tie
## broken by the name, so every two units are ordered.
func draws_before(other: PlacementUnit) -> bool:
	if _rank != other.rank():
		return _rank < other.rank()
	return _name < other.name()

## **The unit's own stream**: a new generator each call, seeded by the day's seed and the name, so
## the unit keeps no generator and no draw is handed one part-way through.
func stream() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:unit:%s" % [_day_seed, _name])
	return rng

## Whether the unit has drawn.
func is_drawn() -> bool:
	return _drawn

## What its draw placed, in the order drawn, a row handed to her walk among them unplaced; empty
## until it has drawn.
func drawn() -> Array[EventPlan]:
	return _placed.duplicate()

## Records what the unit's draw placed (`UnitDraw`), once.
func record_draw(plans: Array[EventPlan]) -> void:
	assert(not _drawn, "PlacementUnit.record_draw(): %s has drawn already" % _name)
	_drawn = true
	_placed = plans.duplicate()

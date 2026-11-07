class_name CalmAreas
extends RefCounted
## **The day's calm areas as dawn sees them**: which they are, the calm ground and the calm tiles of
## each, which of them she settled in this act, and the one that does not count today. A calm area
## is a park or a quiet block where the baby can settle; its calm ground is the part of its lot she
## settles on (`ClosurePlanner.calm_area_rect()`: a courtyard's court, a park's open rect).
##
## **Worked out once and handed to whoever asks** (inbox #1156): `DayPlanner` makes one per walk with
## `of()` and hands it to `EventScheduler.build_day()`, which hands it to its passes, to `DayEvents`
## and to `WinnableDay`. Nothing that reads it works any of it out again, so no two answers about one
## area can disagree.
##
## **Never saved.** What it is derived from is: the city (its seed and `CityState`), and where she
## settled (`SettledState`, read through `RunCalendar.settled_this_act()`). A load plans the day
## again from those, and the same areas come back.
##
## **The constructor derives nothing**, so a test hands in a stand-in that overrides the questions
## below and answers what the test set, with no city built.

## "No area": the answer `besides()` gives on a day where every calm area counts.
const NONE := Vector2i(-1, -1)

var _blocks: Array[Vector2i] = []
## Calm block -> its calm ground, in tiles (`Rect2i`).
var _rects := {}
## Calm block -> the same ground in world space (`Rect2`).
var _grounds := {}
## Calm block -> its calm tiles (`Array[Vector2i]`), in the order `CityMap.rect_tiles()` walks them.
var _calm_tiles := {}
## The areas she settled in this act, most recent first, as handed in.
var _used: Array[Vector2i] = []
var _besides := NONE

## **The calm areas of `map` today.** `used` is every area she has settled in this act, most recent
## first (`RunCalendar.settled_this_act()`); it may name an area that is no longer calm, which counts
## for nothing here. `besides` is the area that does not count today: day 12's swing park, which is
## taken once she has reached it, so the clean ground the day owes her has to be somewhere else.
## `NONE` on every other day.
##
## `map` is read as it stands when this is called, so it is called once the map is repainted for the
## day; the calm blocks and their tiles do not move again before the day is planned.
static func of(map: CityMap, used: Array[Vector2i] = [], besides := NONE) -> CalmAreas:
	var areas := CalmAreas.new()
	for block in map.calm_blocks:
		var rect := ClosurePlanner.calm_area_rect(map, block)
		var tiles: Array[Vector2i] = []
		for tile in map.rect_tiles(rect):
			if Tile.is_calm(map.tile_at(tile)):
				tiles.append(tile)
		areas._blocks.append(block)
		areas._rects[block] = rect
		areas._grounds[block] = map.tile_rect_to_world(rect)
		areas._calm_tiles[block] = tiles
	areas._used = used.duplicate()
	areas._besides = besides
	return areas

## Today's calm blocks, in the map's order.
func blocks() -> Array[Vector2i]:
	return _blocks.duplicate()

## `block`'s calm ground, in tiles.
func rect_of(block: Vector2i) -> Rect2i:
	return _rects.get(block, Rect2i())

## `block`'s calm ground in world space: what an event's field reaching it is measured against.
func ground_of(block: Vector2i) -> Rect2:
	return _grounds.get(block, Rect2())

## The calm tiles of `block`'s calm ground.
func calm_tiles_of(block: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	tiles.assign(_calm_tiles.get(block, []))
	return tiles

## Every area she settled in this act, most recent first, calm today or not.
func used() -> Array[Vector2i]:
	return _used.duplicate()

## The calm areas she has not settled in this act, in the map's order.
func unused() -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for block in blocks():
		if not _used.has(block):
			found.append(block)
	return found

## **The calm ground nothing may be placed near today**: the ground of every calm area she has not
## settled in this act. *(2026-08-31: "why are 7-9 unvisited calm areas spoiled? Just don't place
## events there!")* A placement rule rather than a repair: the events go somewhere else instead,
## which is the **city** skill's *checked before they are accepted, never repaired afterwards*.
##
## The areas she *has* used are not in it: `EventScheduler._spoil_the_parks_she_used` is aimed at
## exactly those, and this rule would otherwise cancel it. An `AMBIENT` row and a scar are not
## placed through the catalogue's judge, so neither is refused by it, which is what keeps a park
## contested rather than sterile.
func unused_ground() -> Array[Rect2]:
	var ground: Array[Rect2] = []
	for block in unused():
		ground.append(ground_of(block))
	return ground

## The area that does not count today, or `NONE`. See `of()`.
func besides() -> Vector2i:
	return _besides

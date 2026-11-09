class_name HeldStreets
extends RefCounted
## **Which street segments are held today, and why**, worked out once when the day is dawned and
## asked by everyone after: the catalogue's siting (`CityMap.is_held_at()`), the crowd's lanes
## (`LaneMover`), the crowd's pockets (`CrowdPockets`). A segment is held so that no catalogue row
## lands on it, and the reason decides what else is true of it: a closure, a region wall and a hard
## seal have a body across them, which shuts the street to the crowd; a region door is a crossing
## the day means to keep open, and the streets around the home block are held only so no row lands
## on the home block's own street — she walks out onto one of them every morning. A segment held
## for several reasons answers every one of them.
##
## A reason is a bit, so a segment's record is the mask of the reasons it was held for.

## Why a segment is held.
enum Why {
	## A road closure's segment.
	CLOSURE = 1,
	## A region wall's segment: shut outright.
	WALL = 2,
	## A region door's segment: a crossing the day keeps open, a car queues for its gate.
	DOOR = 4,
	## A street bordering the home block: held for the catalogue only, never shut to the crowd.
	HOME = 8,
	## A hard seal's segment.
	SEAL = 16,
}

## Segment key (`StreetNetwork.Segment.key()`) -> the mask of the `Why`s it is held for.
var _reasons := {}

## Holds the segment `key` for `why`, beside whatever it is already held for.
func hold(key: Vector3i, why: Why) -> void:
	_reasons[key] = int(_reasons.get(key, 0)) | int(why)

## Forgets every hold.
func clear() -> void:
	_reasons.clear()

## Whether the segment `key` is held for any reason.
func has(key: Vector3i) -> bool:
	return _reasons.has(key)

## Whether the segment `key` is held for `why` (among others, perhaps).
func is_for(key: Vector3i, why: Why) -> bool:
	return (int(_reasons.get(key, 0)) & int(why)) != 0

## Whether the crowd may cross the held segment `key` anyway: it is a region door or borders the
## home block, held so that no catalogue row lands on it and not because a body stands across it.
## Neither is a wall of a pocket, and a car does not turn away from one. Whether a walker turns back
## at a door is the walker's own answer (`WalkerStrategy.door_is_shut()`).
func is_crossable(key: Vector3i) -> bool:
	return is_for(key, Why.DOOR) or is_for(key, Why.HOME)

## Every held segment's key.
func keys() -> Array:
	return _reasons.keys()

## How many segments are held.
func size() -> int:
	return _reasons.size()

## A copy that holds the same segments for the same reasons.
func duplicate() -> HeldStreets:
	var twin := HeldStreets.new()
	twin._reasons = _reasons.duplicate()
	return twin

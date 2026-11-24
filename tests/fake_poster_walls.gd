class_name FakePosterWalls
extends PosterWalls
## A stand-in for the poster walls, handed to what is handed `PosterWalls` (an authored scene,
## `SceneRecipeRuntime.install()`) in place of the real ones, so the check builds no city and no
## wall. `fronts()` answers the dictionary of front tiles a suite sets, the shape the real walls
## answer (`tile -> true`); `refresh()` is counted. A helper, not a suite: the runner loads only
## `test_*.gd`. A node: the suite frees it.

var _fake_fronts := {}
var _fake_refreshes := 0

## Sets the front tiles `fronts()` answers.
func fronts_are(fronts: Dictionary) -> FakePosterWalls:
	_fake_fronts = fronts
	return self

## How many times `refresh()` was asked.
func refreshes() -> int:
	return _fake_refreshes

## Overrides PosterWalls.fronts.
func fronts() -> Dictionary:
	return _fake_fronts

## Overrides PosterWalls.refresh.
func refresh() -> void:
	_fake_refreshes += 1

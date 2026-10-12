class_name PelicanState
extends RefCounted
## How many cyclists this run has drawn from its pelican bag: how far into the bag the next cyclist
## draws. Run-scoped, owned by `GameState.pelican`, and the whole state of the bag — it is rebuilt
## from the run's seed and `MarbleBag.skip()`ped to this count, the way the poster tears' bag is
## (`PosterState.tears`). *(pebbly-ibis, inbox #575 in feathery-lynx: "let's do a bag per run but
## save it in the standard save file to reset the bag to the beginning of the day on a lost day".)*
##
## **A lost day sets the bag back to the beginning of that day.** `photograph()` is taken where
## `GameState` photographs the rest of the run and `give_back()` where it gives the rest back, so
## the retry meets the same cyclists, and the same pelican, the day first did.

## Cyclists drawn from the bag so far this run.
var draws := 0

var _dawn := 0

func reset() -> void:
	draws = 0
	_dawn = 0

## Photographs the count as the attempt about to be played found it.
func photograph() -> void:
	_dawn = draws

## Puts the count back where the photograph found it.
func give_back() -> void:
	draws = _dawn

## Everything a save carries, the photograph included, as plain JSON-safe values.
func to_data() -> Dictionary:
	return {"draws": draws, "dawn": _dawn}

## The other half of `to_data()`. JSON has no integer type, so every number is cast.
func restore(data: Dictionary) -> void:
	draws = int(data.get("draws", 0))
	_dawn = int(data.get("dawn", 0))

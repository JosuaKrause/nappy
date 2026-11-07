class_name FakeCityFronts
extends CityFronts
## A stand-in for the building fronts the story changes, handed to what is handed `CityFronts` (the
## resistance's happenings, `ResistanceHappenings.setup()`) in place of the city's, so the check
## builds no city and no building. It records what it is asked to change and changes nothing: her
## street door sealed (`seal_home_door()`), as the raid asks the city's fronts once, the moment it
## arrives. The real fronts' own logic, the door's picture swapped, is checked with the city's.
## A helper, not a suite: the runner loads only `test_*.gd`.

var _seals := 0

## Counts the seal and changes nothing.
##
## Overrides CityFronts.seal_home_door.
func seal_home_door() -> void:
	_seals += 1

## How many times her street door has been asked to be sealed.
func seals() -> int:
	return _seals

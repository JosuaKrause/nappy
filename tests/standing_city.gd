class_name StandingCity
extends DayWorldSource
## A city that already stands, answered for every spec as the walk's world with her put down on its
## doorstep and the walk won at her front door on its map: what a suite that builds a real city and
## starts its days through the real `DayDirector` hands the director in place of the main scene's
## worlds, whose day branch answers the city it built at boot the same way
## (`main._stand_the_world()`). It only stands the world; the director hands the day's clock her and
## the home's map. A helper, not a suite: the runner loads only `test_*.gd`.

var _city: City
var _player: Stroller
var _baby: Baby

func _init(city: City, player: Stroller, baby: Baby) -> void:
	_city = city
	_player = player
	_baby = baby

## The city, with her and the baby in it, put down on its doorstep facing the street, the walk won
## at her front door on its map and no way out of it.
##
## Overrides DayWorldSource.stand.
func stand(_spec: DaySpec) -> DayWorld:
	return DayWorld.in_the_city(_city, _city.map, _city.events, _player, _baby,
			_city.map.doorstep_world_position(), _city.map, {})

class_name CityDressing
extends WorldContext
## **What the day director asks of the city a walk starts in**: dress it for the day, put it under
## the act's cast and the light, refresh its street trees once the day's seals are planned, tint the
## kerbs of a walk handed in, and prepare the scenery round where she is put down
## (`DayDirector.start()`). The city scene is the one that does each, so `City` extends this and
## overrides every method; the director is handed it through the world it stands
## (`DayWorld.dressing()`) in place of the whole city, and a test hands a fake that notes what it
## was asked.
##
## **A base class, not a part the city builds**, because every method here is the city scene acting
## on its own nodes (its ground, its barriers, its street trees, its light), which no other object
## holds. GDScript gives a class one base, and the city's was already `WorldContext`, the baby's
## questions about the ground, so this sits between the two: a fake of it is a world that answers
## the baby the neutral way and dresses nothing.
##
## **This base dresses nothing**: every method does nothing, as a world with no city to dress would.

## Today's city: the run's city state `state` brought to `day`, the streets closed on `rng` where
## `spec` closes them, the street trees and the posters (`City.start_day()`). `spec` left out is a
## day's (`DaySpec.for_day()`).
func start_day(_state: CityState, _day: int, _rng: RandomNumberGenerator,
		_spec: DaySpec = null) -> void:
	pass

## Today's city for an authored scene: the same dressing, with the recipe's own closures in place of
## a day's (`City.start_recipe_day()`).
func start_recipe_day(_state: CityState, _day: int, _rng: RandomNumberGenerator,
		_spec: DaySpec = null) -> void:
	pass

## Which act's cast the city is under (`Palette.act_tint()`).
func set_act(_act: int) -> void:
	pass

## How much of the day's light is left: 1.0 at dawn, 0.0 at dusk.
func set_daylight(_fraction: float) -> void:
	pass

## The street trees shown or taken away by what today's plan took their pits for, once the day's
## seals are planned (`City.refresh_street_trees()`).
func refresh_street_trees() -> void:
	pass

## The kerbs of `route` tinted, for a walk handed in rather than grown (`City.tint_the_route()`).
func tint_the_route(_route: RouteSource) -> void:
	pass

## Everything the scenery draws within `view` prepared now rather than over the frames to come, so
## the first frame drawn round where she was put down has it all.
func prepare_scenery_in(_view: Rect2) -> void:
	pass

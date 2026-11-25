class_name CityDressing
extends WorldContext
## **What the day director and an authored scene ask of the city a walk starts in**: dress it for
## the day, put it under the act's cast and the light, refresh its street trees once the day's seals
## are planned, tint the kerbs of a walk handed in, and prepare the scenery round where she is put
## down (`DayDirector.start()`); and, for an authored scene, set a recipe's roof furniture, start
## the traffic signals at the scene's moment and answer which buildings and props it stands
## (`AuthoredScene.install()`). The city scene is the one that does each, so `City` extends this and
## overrides every method; the director and the scene are handed it through the world it stands
## (`DayWorld.dressing()`) in place of the whole city, and a test hands a fake that notes what it
## was asked.
##
## **A base class, not a part the city builds**, because every method here is the city scene acting
## on its own nodes (its ground, its barriers, its street trees, its light), which no other object
## holds. GDScript gives a class one base, and the city's was already `WorldContext`, the baby's
## questions about the ground, so this sits between the two: a fake of it is a world that answers
## the baby the neutral way and dresses nothing.
##
## **This base dresses nothing**: every method does nothing or answers nothing, as a world with no
## city to dress would.

## **The city is dressed for `day` under `spec`, and its streets stand as the day's dawn left
## them** (`start_day()`, `start_recipe_day()`, once the closures are placed): said for what the
## simulation lays on the dressed city, the poster walls pasting the dawn's sheets
## (`PosterWalls.dress_for()`). `spec` is the walk's, a day's where the caller handed none.
signal day_dressed(day: int, spec: DaySpec)

## What `furnish_a_roof()` answers when no building stands on the lot a recipe names.
const NO_BUILDING_ON_THE_LOT := "roof_fixtures.lot: no complete production building at the authored footprint"

## Today's city: the run's city state `state` brought to `day`, the streets closed on `rng` where
## `spec` closes them and the street trees, then the day said dressed (`day_dressed`), which the
## poster walls paste by (`City.start_day()`). `spec` left out is a day's (`DaySpec.for_day()`).
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

## **How bright the sky over the city is lit by a blast, 0 for not at all**, over the day's own
## light (`City.light_the_sky()`; `BlastLight`).
func light_the_sky(_level: float) -> void:
	pass

## The street trees shown or taken away by what today's plan took their pits for, once the day's
## seals are planned (`City.refresh_street_trees()`).
func refresh_street_trees() -> void:
	pass

## The kerbs of `route` tinted, for a walk handed in rather than grown (`City.tint_the_route()`).
func tint_the_route(_route: RouteSource) -> void:
	pass

## Sets a recipe's roof furniture `fixtures` on the building standing on `lot`. Answers what kept
## any from standing, and one problem naming the lot when no building stands on it, which is all
## this base can say.
func furnish_a_roof(_lot: Rect2i, _fixtures: Array) -> Array[String]:
	return [NO_BUILDING_ON_THE_LOT]

## Restarts the traffic signals' cycle and runs it on `into_the_cycle` seconds, then cuts their
## power when `dark`: a scene set in the last night's blackout.
func start_the_signals(_into_the_cycle: float, _dark: bool) -> void:
	pass

## The buildings the city stands, none in this base.
func buildings() -> Array[Building]:
	return []

## The props the city stands, none in this base.
func props() -> Array[Node2D]:
	return []

## The fronts the run's story changes (`CityFronts`): the neighbor's boarded window, her sealed door
## and the rest, which an authored scene hands the happenings it starts. None in this base.
func fronts() -> CityFronts:
	return null

## Everything the scenery draws within `view` prepared now rather than over the frames to come, so
## the first frame drawn round where she was put down has it all.
func prepare_scenery_in(_view: Rect2) -> void:
	pass

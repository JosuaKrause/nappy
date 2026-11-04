class_name AuthoredScene
extends Node
## What the run asks of an authored scene — one fixed day or section played from a saved setup
## rather than drawn from the run's seed — when `RunFlow` is configured with one (`RunFlow.author()`).
## `SceneRecipeRuntime` (`src/dev/`, the scene recipe's playback) is the one there is; a test hands a
## bare `AuthoredScene`, whose answers are the empty ones below.
##
## A node because a scene plays on the game's own ticks once it begins.

## The map the scene's city is built on, in place of the one the run's seed generates.
func city_map() -> CityMap:
	return null

## Whether the scene starts after the ordinary control lessons have been learned, so the HUD says
## none of them; danger warnings and the rest of the HUD stay.
func lessons_learned() -> bool:
	return false

## Installs the scene's own setup — its events, actors, crowd and her start — into the world the
## run flow started for it, under `spec`, the walk its clock and HUD run on. Returns the problems
## that kept the setup from standing, empty when it stands.
func install(_city: City, _player: Stroller, _baby: Baby, _spec: DaySpec,
		_resistance: ResistanceDirector = null) -> Array[String]:
	return []

## The scene starts playing: called once the world stands and her own camera is the current one.
func begin() -> void:
	pass

## A section of the scene was lost: `true` when the scene has dealt with it itself, `false` for the
## run to play the scene again.
func lose_the_attempt() -> bool:
	return false

## Whether the scene plays by script on its own physics clock, so a screenshot is timed off
## `elapsed()` and prepared by `prepare_capture()`.
func plays_by_script() -> bool:
	return false

## Seconds of the scene's own physics clock since it began.
func elapsed() -> float:
	return 0.0

## Holds the scene's exact moment while a screenshot draws.
func prepare_capture() -> void:
	pass

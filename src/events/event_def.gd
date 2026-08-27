class_name EventDef
extends Resource
## Authored data for one kind of event. See docs/EVENTS.md.
##
## Defs are constructed in code by `EventCatalogue` rather than saved as .tres files: they
## are reviewable in a diff, they can be validated on load, and the fairness contract can be
## asserted over the whole catalogue in a test. Nothing here needs an editor to tune.

## How the instance is drawn. Data rather than a script per event, since most events differ
## only in their numbers.
enum Look {
	NONE,     ## Invisible — something else already draws it (a park's playground frame).
	ANIMAL,
	PERSON,
	VEHICLE,
	OBJECT,
	FIRE,
	DOG_WALKER, ## A person, a dog, and the taut lead between them.
	TABLES,     ## A café spilling across the pavement.
	# M31. Each of these earned its own row rather than reusing `PERSON` or `VEHICLE`, and the
	# reason is the known-shaky-ground note in `CLAUDE.md`: three act I events already draw the
	# same `person.svg`, so what tells them apart is a caret, which is the vocabulary covering
	# for art nobody drew. Adding seven more events on that footing would have made it the rule.
	CYCLIST,      ## A kid on a bike, leaning into it. Act I's first lethal thing.
	LOOSE_DOG,    ## A dog running with the lead still trailing behind it.
	STALL,        ## A market trestle, repeated across the pavement it takes.
	LEAF_BLOWER,  ## A groundskeeper and the nozzle that makes the noise.
	BIRDS,        ## A flock going up all at once.
	ICE_CREAM_VAN,
	LORRY,        ## A box lorry: the biggest silhouette in act I, and a wall.
}

## Where AMBIENT instances come from. Ambient events are features of the map, not rolls.
enum AmbientSource {
	NONE,
	PLAYGROUND,  ## One per playground.
}

## How the scheduler builds a mobile event's route.
enum PathMode {
	NONE,
	CROSS_STREET,  ## Straight across the traffic, like a cat bolting.
	ALONG_STREET,  ## Down the corridor it starts on.
}

## Where an instance comes from. *(M27, playtest 04.)*
enum SpawnMode {
	## Placed on a tile when the day is planned, and streamed into the world when the player
	## comes near it. Almost everything: an event that is *somewhere* is half of what makes a
	## route a decision, because it can be routed around.
	MAP,
	## Placed in front of the player, while she walks, by `EventDirector`. For the small number
	## of events whose whole content is *the moment it happens to you* — a cat bolting out of a
	## doorway is nothing at all if it does it two blocks away and you arrive at an empty road.
	## The day still budgets it: the scheduler counts one instead of placing one.
	AHEAD_OF_PLAYER,
}

@export var id := ""
@export var display_name := ""
@export var kind := GameEnums.EventKind.RECURRING
@export var look := Look.OBJECT
@export var ambient_source := AmbientSource.NONE

## Day gating, 1-based and inclusive. `last_day = 0` means it never expires.
@export var first_day := 1
@export var last_day := 0
## For SCRIPTED events: the exact day it fires.
@export var scripted_day := 0

## Relative likelihood when filling the recurring budget, and what one costs of it.
@export var weight := 1.0
@export var cost := 1
@export var max_per_day := 1

## Tile types an instance may be placed on.
@export var placement: Array[int] = []

## Peak excitement per second at the centre.
@export var intensity := 6.0
@export var inner_radius := 40.0
@export var outer_radius := 150.0

## Seconds at full strength. 0 means it lasts the whole day.
@export var duration := 0.0
## Seconds of visible warning before full intensity, during which it emits only
## TELEGRAPH_INTENSITY_FRACTION of `intensity`.
@export var telegraph_time := 2.5
## Seconds per intensity cycle, for events that pulse rather than hold. 0 is constant.
@export var pulse_period := 0.0

@export var spawn_mode := SpawnMode.MAP

## Moves along a path at `speed` px/s. The scheduler builds the path.
@export var mobile := false
@export var speed := 0.0
@export var path_mode := PathMode.NONE
## Route length for ALONG_STREET, in tiles.
@export var path_length_tiles := 24
## Holds still until the telegraph is over, then goes.
##
## The default is to move from the first frame, which is right for anything whose telegraph is
## *the approach*: a fire engine is warning you by being audible three streets away, and it has
## to cover those three streets to arrive.
##
## It is wrong for anything whose telegraph is a *posture*. The cat crouches and then bolts,
## and a crouch that is already travelling at 240px/s is not a crouch. Worse, it made the cat
## silent: its path is one street wide, so at full speed the whole run was over by the time the
## telegraph ended — it never reached full intensity, and the running sprite never drew once.
@export var still_while_telegraphing := false

## Radius of solid obstruction, in px. 0 for events you can walk through. Scaffolding does
## not politely step aside, and being *forced* to reroute is a different pressure from
## choosing to.
@export var obstructs_radius := 0.0

## Event id to spawn where this one ends. How a fire engine leaves a fire behind it.
@export var spawns_on_finish := ""

## Entering the inner radius ends the day immediately.
@export var hard_fail := false

## Applies everywhere at once, ignoring distance — a floor under the whole city rather
## than a place to avoid. Loudspeaker masts, not a man shouting.
@export var city_wide := false

## Intensity multiplier reached at the end of `duration`. 1.0 holds steady; above 1.0
## swells (a protest gathering), below 1.0 fades.
@export var intensity_ramp := 1.0

## Event id to leave permanently at this event's position for the rest of the RUN. A fire
## leaves a burnt-out shell; the shell is still there on day 12.
@export var scar_id := ""

## Narrative act, for palette and audio in M7.
@export var act_tag := 1

func available_on(day: int) -> bool:
	if kind == GameEnums.EventKind.SCRIPTED:
		return scripted_day == day
	if day < first_day:
		return false
	return last_day == 0 or day <= last_day

## Checks the telegraph fairness contract from docs/EVENTS.md.
##
## AMBIENT events are exempt, and have to be: they are permanent features of a fixed map,
## so there is no moment they appear and nothing to warn about. The player learns where the
## playgrounds are on day 1 and that knowledge holds for the rest of the run — which is the
## whole point of a city that does not change.
func validate() -> bool:
	if kind == GameEnums.EventKind.AMBIENT:
		return true
	# A city-wide event has no edge to walk out of, so the escape-distance rule is
	# meaningless for it. It is never a hazard on its own — see the loudspeaker.
	if city_wide:
		return true
	# An `AHEAD_OF_PLAYER` event has no tile, so `_ensure_the_city_is_still_walkable` never sees
	# it and cannot check that what it blocks leaves a route to a park. Anything that stands in
	# the way therefore has to be sited on the map, where the day can reason about it. A
	# transient one that merely *emits* is fine, and so is a lethal one — it appears in front of
	# her and it is gone in three seconds, so it can never seal a street.
	if spawn_mode == SpawnMode.AHEAD_OF_PLAYER and obstructs_radius > 0.0:
		push_error("event '%s' spawns ahead of the player and obstructs %.0fpx: nothing checks "
				% [id, obstructs_radius] + "that it leaves a route to a park")
		return false
	return Tuning.validate_event(id, telegraph_time, inner_radius, outer_radius, hard_fail,
			speed if mobile else 0.0)

## Shortest telegraph this geometry may fairly have.
func minimum_telegraph() -> float:
	return Tuning.required_telegraph_time(inner_radius, outer_radius, hard_fail,
			speed if mobile else 0.0)

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
	CHARGING_DOG, ## Stretched out flat and coming at you. The one thing running is for.
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

## Comes after **her**, rather than along a path. *(Playtest 07: "the run button is a trap
## shouldn't be an invariant — there should be legitimate cases where running is required.")*
##
## This is the mechanic M25 said had to exist before running could ever be correct, and the reason
## it is a mechanic rather than a number: running is worse than walking against everything that
## merely *emits*, because `EXCITEMENT_FROM_RUNNING` outweighs the shorter exposure every time.
## The only way it can be right is if the alternative is losing the day — so a pursuer is lethal,
## it is faster than a walk, and it is slower than a run. Those three together mean walking away
## does not work and running away does, which is the whole lesson.
##
## Its fairness contract is `Tuning.validate_pursuit()` and is stated over `RUN_SPEED`, exactly as
## `docs/TODO.md` said it would have to be.
@export var pursues := false
## How fast it comes. Must sit strictly between `WALK_SPEED` and `RUN_SPEED`.
@export var pursue_speed := 0.0

## Radius of solid obstruction, in px. 0 for events you can walk through. Scaffolding does
## not politely step aside, and being *forced* to reroute is a different pressure from
## choosing to.
##
## **Anything that stands still is solid at the width it is drawn.** *(M34, playtest 07 finding
## 16: "none of the non-moving obstacles do anything — I can freely walk over them", and finding
## 13: "I can walk over the robber and he doesn't do anything".)* This was a list of five rows
## out of thirty for six milestones, which is why a delivery van was scenery and a man standing
## in a courtyard could be occupied rather than walked around. It is a rule now, and the number
## is not a balance value: it is half of the silhouette, because `_draw_spread` draws a blocking
## object at exactly the width it obstructs and anything else is a lie about where she can walk.
##
## Three things are exempt and each for its own reason:
##
## - **Anything mobile.** A moving wall on a two-tile pavement pins her against a building, which
##   is a different game from being priced out of a street. See `dog_walker`, where the decision
##   is written up at length.
## - **`AHEAD_OF_PLAYER`**, which `validate()` refuses outright: nothing checks that a thing sited
##   out of where she happens to be walking leaves a route to a park.
## - **Anything with no silhouette** — a city-wide source, a playground the park already draws.
##
## And one constraint rather than an exemption, which is `validate()`'s job below: a `hard_fail`
## event's body has to fit *inside* its lethal radius with her own body to spare.
@export var obstructs_radius := 0.0

## Which lane of a two-tile pavement an event wants. *(M34, playtest 07 findings 7 and 15.)*
##
## Almost nothing cares, and `ANY` is the honest default: a café spills out of whichever frontage
## it has and a shouting man stands where he likes. Two things do care, and in both cases the
## complaint was that the thing was standing somewhere that made no sense of it — a parked van
## *in a traffic lane* ("a still car standing on the road doing nothing"), and a lorry reversing
## into a yard that "does not connect to the building".
enum Pavement {
	ANY,
	## Against the kerb, with the carriageway on the other side of it. Where a vehicle parks.
	AT_THE_KERB,
	## Against the frontage, with a building wall behind it. Where a lorry backs in.
	AGAINST_THE_BUILDING,
}

@export var pavement_side := Pavement.ANY

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
	# **A lethal radius and a solid body are the same mechanism**, and putting both on one event
	# is a way of turning the first one off. She is stopped with her centre `obstructs_radius +
	# PLAYER_BODY_RADIUS` from his, so if that reaches the inner radius the kill can never fire
	# however carelessly she walks into it — a silent difficulty setting, and exactly the shape of
	# the "walk over the robber" complaint rather than a fix for it. Under it, the body is only
	# ever felt during the telegraph, which is the phase where the event is not lethal yet and
	# walking through a wall of metal would be the visible lie.
	if hard_fail and obstructs_radius > 0.0 \
			and obstructs_radius + Tuning.PLAYER_BODY_RADIUS >= inner_radius:
		push_error("event '%s' is lethal inside %.0fpx and solid to %.0fpx: with her own %.0fpx "
				% [id, inner_radius, obstructs_radius, Tuning.PLAYER_BODY_RADIUS]
				+ "she is stopped before she can ever reach it")
		return false
	if pursues and not Tuning.validate_pursuit(id, pursue_speed, duration, inner_radius,
			telegraph_time):
		return false
	if pursues:
		# A pursuer has no line to be walked out of — it follows — so the ordinary escape-distance
		# rule says nothing about it and `validate_pursuit` is the contract instead. What its
		# telegraph has to buy is the moment of *noticing*, which is checked there.
		return true
	return Tuning.validate_event(id, telegraph_time, inner_radius, outer_radius, hard_fail,
			speed if mobile else 0.0)

## Shortest telegraph this geometry may fairly have.
##
## A pursuer's is a different quantity and is stated in `Tuning.PURSUIT_MIN_NOTICE`: the ordinary
## rule buys the time to walk out of a *field*, and there is no walking out of something that
## follows. What its telegraph buys is the time to see it coming and change what you are doing.
func minimum_telegraph() -> float:
	if pursues:
		return Tuning.PURSUIT_MIN_NOTICE
	return Tuning.required_telegraph_time(inner_radius, outer_radius, hard_fail,
			speed if mobile else 0.0)

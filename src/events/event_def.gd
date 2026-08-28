class_name EventDef
extends Resource
## Authored data for one kind of event. See docs/EVENTS.md.
##
## Defs are constructed in code by `EventCatalogue` rather than saved as .tres files: they
## are reviewable in a diff, they can be validated on load, and the fairness contract can be
## asserted over the whole catalogue in a test. Nothing here needs an editor to tune.

## How the instance is drawn. Data rather than a script per event, since most events differ
## only in their numbers.
##
## **One look per row, and every look is a thing rather than a category.** *(M37, playtest 07
## finding 2: "not sure what that person was supposed to be".)* This used to open with `ANIMAL`,
## `PERSON`, `VEHICLE`, `OBJECT` and `FIRE`, and those five names were doing the damage all by
## themselves: a category is something you can always put one more row into, so sixteen of the
## twenty-eight visible rows in the catalogue drew five pictures between them. A man shouting, a
## busker, a poster crew, a protest and the robbery that ends the day were one `person.svg`; a
## delivery van, a fire engine, a police car, a riot van, an army truck and the unmarked van that
## takes the baby were one van.
##
## That is not a missing art pass, it is the first row of the visual vocabulary failing —
## *the entity itself carries most of it* — and it had already cost a finding: M34 spent a
## milestone fixing `alley_robbery` for a complaint about `homeless_yeller`, because the player
## could only say "the robber" and the two draw the same man. It cost a second one in playtest 09,
## where *"who is the person killing me?"* is a question the screen should have answered.
##
## So a look is now the name of one picture, and `tests/test_events.gd` holds both halves of the
## rule: **no two rows share a look**, and **no two looks share a silhouette**. There is
## deliberately no generic left to reach for — the cost of adding an event is a drawing.
enum Look {
	NONE,     ## Invisible — something else already draws it (a park's playground frame).
	# ---- act I ----
	CAT,          ## Crouched, then stretched out flat. The crouch is the telegraph.
	YELLER,       ## A long coat, a raised arm, a beard. One shape where a passer-by is two.
	DOG_WALKER,   ## A person, a dog, and the taut lead between them.
	CAFE,         ## Tables across the pavement, with people at them.
	DELIVERY_VAN, ## Shutter up, hazards on. The plain van the others used to borrow.
	BUSKER,       ## The guitar and the open case.
	ROADWORKS,    ## Municipal barriers, repeated across what they close.
	FIRE_ENGINE,  ## The longest silhouette in the game, and the only red one.
	BURNING_BUILDING, ## Flames that scale with what it is emitting.
	BURNT_SHELL,  ## Charred brick and window holes with nothing behind them.
	# M31. Each of these earned its own row rather than reusing `PERSON` or `VEHICLE` — which is
	# the rule above being kept one milestone before it was written down.
	LOOSE_DOG,    ## A dog running with the lead still trailing behind it.
	STALL,        ## A market trestle, repeated across the pavement it takes.
	LEAF_BLOWER,  ## A groundskeeper and the nozzle that makes the noise.
	BIRDS,        ## A flock going up all at once.
	CYCLIST,      ## A kid on a bike, leaning into it. Act I's first lethal thing.
	ICE_CREAM_VAN,
	LORRY,        ## A box lorry: the biggest silhouette in act I, and a wall.
	CHARGING_DOG, ## Stretched out flat and coming at you. The one thing running is for.
	# ---- acts II-IV ----
	POLICE_CAR,   ## Low and pale where everything else in act II is a tall dark box.
	POSTER_CREW,  ## The poster is the event; the man holding it is scenery.
	CHECKPOINT,   ## Poured concrete and a hazard stripe. A street being *held*.
	UNMARKED_VAN, ## No windows, no livery, a door standing open. The one with a hole in it.
	ROBBER,       ## Two postures — waiting in the hood, and coming.
	RIOT_VAN,     ## The same dark box as the unmarked van, with mesh over every window.
	ARMY_TRUCK,   ## Olive, and the only canvas back in the game.
	BARRICADE,    ## Whatever was on the street, stacked by somebody.
	PROTEST,      ## A rank of placards, as wide as the ground it takes.
	FIREFIGHT,    ## People behind cover, not a building on fire.
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
## No default worth having: it was `OBJECT` — a category, so a row that never chose was drawn as
## roadworks and looked deliberate. Every visible row states its own picture, and
## `tests/test_events.gd` names the three that are legitimately invisible.
@export var look := Look.NONE
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

## Walks its route and turns round at the ends, for ever. *(M36, playtest 09: "if it's the homeless
## person it needs to walk up and down the sidewalk".)*
##
## The difference between a **journey** and a **beat**, and it is the difference between two kinds
## of event. A dog walker is going somewhere: its route is thirty tiles, it is gone at the end of
## them, and what it costs you is the stretch of pavement it happens to own while you are there. A
## man shouting is not going anywhere — he is *at* a place — and until now the only way to say that
## was to make him stationary, which is what got him reported as "it didn't move".
##
## A paced event never reaches the end of its path, so it never departs and never expires: it is a
## fixture that moves, which is exactly what it looks like from the street.
@export var paces := false
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

## How fast it removes itself from the scene when it is over, in px/s. *(M35, playtest 08 findings
## 2 and 3.)*
##
## **Nothing vanishes while you are looking at it.** The end of an event used to be a deletion
## wherever it stood, which for the two shortest-lived rows in the game is directly in front of her:
## *"running dog events etc — things that move disappear on screen; they should at least run
## offscreen before despawning"*, and *"pigeons are also completely ineffective"*, which is the same
## sentence about a flock that hangs in the air for a fifth of a second and is then not there.
##
## Anything **mobile** already has somewhere to go and leaves at its own `speed` — that is the whole
## of finding 3 and it costs no data. This field is for the rest: a flock that has to fly off, a dog
## that has lost interest and trots away. Zero means it simply ends, which is right for anything
## that was a *place* rather than a moment — a café does not walk home.
@export var departs_at := 0.0

## How many individual creatures this event is, rather than one thing drawn several times.
## 0 for everything that is one body. *(M38: "the birds are broken — they start the flying
## animation but then freeze. Turn them into individual entities and let each fly.")*
##
## **A flock was one sprite drawn seven times at seven fixed offsets**, and the offsets were derived
## from the instance's own position so they would not boil — which is the right trick for a *static*
## picture and the wrong one for a moving one, because it means the seven birds can only ever move
## together. The whole animation was a single `rise` term that ramped to 1.0 at the end of the
## telegraph and then sat there: the flock went up in one movement and hung motionless in the air
## for the three seconds that were supposed to be the event.
##
## With this set, `EventInstance` gives every bird its own position, its own heading, its own speed,
## its own height and its own wingbeat, and steps them one at a time. There is nothing generic about
## the field — it is the number of bodies — and nothing else in the catalogue wants it yet. It is a
## field rather than a script per event for the reason the whole of `EventDef` is: a flock differs
## from a bird by a number.
@export var flock_size := 0
## How far from the middle a flock spreads, in px. Its `outer_radius` is the field it emits over;
## this is the ground it stands on and the air it wheels in, and it is deliberately much smaller —
## a flock she can see the shape of is a flock she can walk round.
@export var flock_spread := 0.0

## What it leaves at, which is its own speed if it had one. See `EventInstance._be_done`.
func departure_speed() -> float:
	if departs_at > 0.0:
		return departs_at
	return speed if mobile else 0.0

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

## How close she has to come before it takes an interest. 0 means *immediately*. *(M36, playtest 09:
## "a robber should increase excitement on sight and getting close to them should be day ending",
## and "if you get close they should start moving towards you".)*
##
## A pursuer with no trigger is a **moment**: `charging_dog` is sited in front of her by the
## director and the chase is the whole of it. A pursuer with one is a **place** that becomes a
## moment — a man in an alley who is standing there, who is worth avoiding from the far end of it,
## and who comes after you if you walk up to him. That is a different thing from both an obstacle
## and an ambush, and it is the shape the player asked for.
##
## Three states rather than two, and the middle one is new: **waiting** (standing there, emitting at
## full strength, not lethal and not moving), **noticing** (`telegraph_time` of visibly coming, the
## notice the fairness contract owes), then the chase. `telegraph_time` and `duration` are both
## measured from the moment it notices, not from the moment it was put in the world — a robbery that
## spent its telegraph at dawn, four streets away, would have no notice in it at all.
@export var pursues_within := 0.0

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
			telegraph_time, pursues_within, outer_radius):
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

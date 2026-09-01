class_name GameEnums
extends RefCounted
## Shared enums.
##
## These live outside the autoloads because autoload names cannot also be `class_name`
## types, and signals/exports need real types to annotate.

enum BabyState {
	AWAKE,
	ASLEEP,
	CRYING, ## Day is lost.
}

enum DayPhase {
	WALKING,   ## Getting the baby to sleep.
	RETURNING, ## Baby asleep; carry her home without waking her.
	OVER,
}

enum DayResult {
	WON,
	LOST_CRYING,
	LOST_TIMEOUT,
	LOST_HARD_FAIL,
}

enum Ending {
	NONE,
	BAD,     ## Nerves ran out.
	NEUTRAL, ## Survived the run, resistance incomplete.
	GOOD,    ## Resistance complete and the day-14 sabotage succeeded.
}

enum EventKind {
	AMBIENT,   ## Always present, part of the map.
	RECURRING, ## Can be rolled on any eligible day.
	ONE_SHOT,  ## Fires on exactly one day per run, then never again.
	SCRIPTED,  ## The scheduler is told exactly which day it fires.
}

## What a blocker does to a route that meets it. *(docs/CITY.md, "The words for it", adopted from
## the player 2026-08-31.)*
##
## **`LETHAL` is not the top of a scale**, it is a different thing: the other two are prices and it
## is an ending. And a body is not `IMPASSABLE` — almost everything that stands still is solid at
## the width it is drawn, and a café she walks round is `COSTLY` like the dog walker
## beside it. What is impassable is a thing that takes the **street**, which in this game is a
## closure and nothing else.
enum BlockerEffect {
	LETHAL,      ## Ends the day.
	IMPASSABLE,  ## Stops passage, does not kill.
	COSTLY,      ## Passable at a price she can read before committing.
}

## What the scheduler placed a blocker **for** — the third of the three axes in docs/CITY.md,
## "The words for it".
##
## The three are stated relative to the day's **corridor** and none of them means anything without
## one, so they only make sense alongside `RouteTree`. `NONE` is not a fourth
## kind: it is everything the day puts down for a reason that is not about the route at all, so an
## ambient playground, a scar the run left and the spoilers of a park she used carry it.
enum BlockerRole {
	NONE,       ## Not placed against the corridor.
	WALL,       ## Placed to bound it: off the routes, ideally on a turning off one.
	FRICTION,   ## Placed inside it, on the route she is meant to take.
	SET_PIECE,  ## Placed so that she meets it, whichever way she goes.
}

enum TileType {
	BUILDING,
	SIDEWALK,
	ROAD,
	CROSSING,
	PARK,
	SQUARE,
	ALLEY,
	PLAYGROUND,
	HOME,
	FOREST,        ## Denser, darker, no playground. Calm.
	QUIET_SQUARE,  ## A paved square nobody trades in. Calm, unlike SQUARE.
	COURTYARD,     ## The court inside a residential block. Calm.
	SPOILED,       ## Calm ground that has been taken or burnt. Walkable, not calm.
}

## What a street corridor is, as opposed to how it is laid out.
##
## The lattice is uniform — every corridor is `sidewalk | road | sidewalk` and the layout maths
## is a modulo — so a kind never moves a tile. What it changes is the **decision**: with one kind
## of street the only route question is *which way*, and with three it is also *which kind*, which
## is the trade the whole game is made of.
##
## Fixed for the run, like everything else about the lattice. A player learns where the spine is
## on day 1 and it is still there on day 14.
##
## **Two of the three are places rather than classes.** There is one main road,
## running north to south, and there are two precincts of three blocks each — not a kind every
## corridor is asked to be. A spine that crosses itself is two spines and a precinct on every
## third street is what a street is, and either way the hierarchy this exists to build is gone.
enum StreetKind {
	ORDINARY,   ## Two lanes, a zebra at every junction, traffic that gives way at it.
	MAIN,       ## The spine. Dense, fast, signalled, and it does not stop for anybody mid-block.
	PEDESTRIAN, ## A retail precinct. No carriageway at all: loud with people, and safe.
}

enum District {
	RESIDENTIAL,
	PARK,
	COMMERCIAL,
	INDUSTRIAL,
	CIVIC,
}

## What a block *is* on a given day, as opposed to how it is laid out.
##
## The street lattice and the block boundaries are fixed for the run; this is not. Each
## block is generated with an arc — an ordered list of the purposes it may pass through —
## and presents whichever one the run's history has brought it to. See docs/CITY.md,
## "Block purposes", and `CityState`.
##
## The four calm purposes are the reason the route is a choice: a day can only be won on calm
## ground, so which kinds of calm are left, and where, is the run's real difficulty curve.
enum BlockPurpose {
	PARK,          ## Grass, trees, a playground. Contested calm.
	FOREST,        ## Denser trees, no playground. The quietest ground in the city.
	QUIET_SQUARE,  ## Paved, benched, empty. Calm without being green.
	COURTYARD,     ## A calm court inside a residential block. Hidden calm.
	RESIDENTIAL,
	COMMERCIAL,
	INDUSTRIAL,
	CIVIC,
	REQUISITIONED, ## Calm ground taken by the regime. Same ground, no longer calm.
	BOARDED_UP,    ## A commercial block gone dark. Still built, still not calm.
	BURNT_OUT,     ## A built block that burned and stayed burnt.
	BIG_BUILDING,  ## One solid mass with no street around it. A hard blocker and a landmark.
}

## Why a block moved to the next purpose in its arc. A step is only taken when its cause
## actually happens, so a block never invents a plausible next state at runtime.
enum BlockCause {
	SCHEDULED, ## The day arrived. Requisitions and boardings work this way.
	FIRE,      ## Something burned here.
	MILITARY,  ## The army came down this street.
}

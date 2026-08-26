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
## The four calm purposes are the reason the route is a choice: a day can only be won on
## calm ground (M14), so which kinds of calm are left, and where, is the run's real
## difficulty curve.
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
}

## Why a block moved to the next purpose in its arc. A step is only taken when its cause
## actually happens, so a block never invents a plausible next state at runtime.
enum BlockCause {
	SCHEDULED, ## The day arrived. Requisitions and boardings work this way.
	FIRE,      ## Something burned here.
	MILITARY,  ## The army came down this street.
}

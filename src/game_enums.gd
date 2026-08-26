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
}

enum District {
	RESIDENTIAL,
	PARK,
	COMMERCIAL,
	INDUSTRIAL,
	CIVIC,
}

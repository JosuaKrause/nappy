class_name DaySpec
extends RefCounted
## What one day is: its number, its words, its clock, its goal and what losing or winning it costs.
##
## **The escape is a day with special settings, run by the day's own code** *(minty-lemur #785)*.
## A run is a sequence of these — the fourteen days, then the building, then the city — and one
## `DayController` is handed whichever is being walked (`DayController.spec`), so the clock, the
## goal, the loss and its cause, the finish path, the counters and the run log are the same code for
## all sixteen. What differs between a day and a section of the escape is written here, as values,
## and read where it matters, rather than asked of a global "are we in the escape" anywhere else.
##
## Data only: no node, no autoload, nothing that runs, and no words of its own — whoever builds one
## hands it its title, so this layer names nothing of the UI's. `for_day()` and `for_section()` are
## the two shapes the run uses; a test builds one either way, or by hand.

## Where the walk is: the city, or the building the escape starts in.
enum World { CITY, BUILDING }

## What winning the day is.
enum Goal {
	## Her own front door, reached with the baby asleep — every one of the fourteen days.
	HOME,
	## The building's service exit. The world says when she is through it, once its fade has
	## covered the screen (`InteriorScene.exit_requested`), and `DayController.reach_the_exit()` is
	## what that reaches.
	SERVICE_EXIT,
	## The tunnel mouth or the bridge deck (`exits`), reached however the baby is.
	CITY_EDGE,
}

## The escape's two sections, and `NONE` for every one of the fourteen days. **The values are the
## save's**: `GameState.escape_section` holds one as a plain `int` and `GameSave` writes it, so a
## save written before this enum moved here reads the same.
enum Section { NONE, BUILDING, CITY }

## The day number every counter, loss line and run log header names: 1 to 14 for the days, and
## `BUILDING_DAY` and `CITY_DAY` for the escape's two sections. **Not the calendar**:
## `GameState.day` stays on the last day while the escape is walked, since the run has not moved
## past it — its plan's random streams and its save are keyed by it.
var number := 1
## The day's own words where "Day N of 14" stands, on its brief and its outcome screen, and the
## line the HUD says once she is walking it: "" for a day, "Escape the building" or "Escape the
## city" for a section.
var title := ""
## Which section of the escape this is, `Section.NONE` for a day.
var section := Section.NONE
var world := World.CITY
var goal := Goal.HOME
## Where `Goal.CITY_EDGE`'s two ways out stand, in world space — `CityEdge.Kind` -> position, the
## last walkable tile of the spine at each end rather than where the portal's picture is anchored.
## Handed in once the city exists; empty for any other goal.
var exits := {}
## Seconds on the clock.
var length := Tuning.DAY_LENGTH_SECONDS
## Whether the clock reads to the hundredth and tells the HUD every frame, rather than to the whole
## second *(inbox #746 in woolly-penguin)*: the escape's tension is its clock.
var clock_hundredths := false
## Whether the light follows the clock from dawn to dusk, or stays at night all the way through:
## the escape happens after the last day, and its tension is the clock rather than the light.
var daylight_runs_down := true
## Whether the city is dark from its first frame, all its power off, rather than going dark only
## once the sabotage is done and she is far from the station: the escape is the same night as the
## blackout.
var dark_from_the_start := false

# --------------------------------------------------------------- what is on it ---

## Whether falling asleep owes her a walk home, and with it the return leg's own pressure on the
## events (`EventManager._owe_the_return()`): every day's does. A section is outbound from its first
## frame to its last, and the baby is put to sleep at the top of each attempt, so it owes none.
var owes_a_return := true
## Whether a torn poster sends a pursuer on foot at her (`EventManager.send_a_pursuer()`): on every
## day, and never in the escape.
var poster_pursuits := true

# --------------------------------------------------------------- what it costs ---

## Whether a normal run spends a Nerve on a loss. A hard run always does. The escape's sections
## cost a normal run nothing *("sounds good at that point you earned it")*, and a hard run's
## escape has normal nerve counts and ends when they run out *(gentle-osprey)*.
var a_loss_costs_a_normal_run_a_nerve := true
## Whether a lost attempt gives back what it spent of the run — the resistance's work, the
## one-shots, the scars, the arcs — so the retry is the same day exactly as it was first met. The
## escape touches none of it, so a lost section has nothing to give back.
var a_loss_gives_back_the_attempt := true
## Whether a win gives a normal run a Nerve back. Walking out of the building or the city gives
## none *("the escape doesn't have nerves")*.
var a_win_gives_a_nerve_back := true
## The section a win leads into, `Section.NONE` when a win ends the walk: the building's leads
## into the city, and nothing of the run is settled until she is out of that.
var a_win_leads_into := Section.NONE
## Whether the save says a day is under way while it is walked, so a game closed mid-day loses that
## day when it is opened again. The escape's sections are saved only at their brief, as a
## checkpoint: closed inside one, it opens on that section's brief again at no cost.
var saved_as_under_way := true

## The first of the escape's two day numbers: the building, the day after the last.
const BUILDING_DAY := Tuning.RUN_LENGTH_DAYS + 1
## The city.
const CITY_DAY := Tuning.RUN_LENGTH_DAYS + 2

## One of the fourteen days, `length` seconds long.
static func for_day(day: int, day_length: float) -> DaySpec:
	var spec := DaySpec.new()
	spec.number = day
	spec.length = day_length
	return spec

## One of the escape's two sections, `section_length` seconds long, titled `section_title` — its own
## words, handed in by whoever builds it (`main.escape_section_spec()`). `which` is a `Section`
## passed as an `int`, the way `GameState.escape_section` holds it.
static func for_section(which: int, section_length: float, section_title := "") -> DaySpec:
	var spec := DaySpec.new()
	spec.section = which
	spec.length = section_length
	spec.title = section_title
	spec.clock_hundredths = true
	spec.daylight_runs_down = false
	spec.dark_from_the_start = true
	spec.a_loss_costs_a_normal_run_a_nerve = false
	spec.a_loss_gives_back_the_attempt = false
	spec.a_win_gives_a_nerve_back = false
	spec.saved_as_under_way = false
	spec.owes_a_return = false
	spec.poster_pursuits = false
	if which == Section.BUILDING:
		spec.number = BUILDING_DAY
		spec.world = World.BUILDING
		spec.goal = Goal.SERVICE_EXIT
		spec.a_win_leads_into = Section.CITY
	else:
		spec.number = CITY_DAY
		spec.world = World.CITY
		spec.goal = Goal.CITY_EDGE
	return spec

## Whether losing it spends a Nerve, in this run's mode.
func a_loss_costs_a_nerve(hard_mode: bool) -> bool:
	return hard_mode or a_loss_costs_a_normal_run_a_nerve

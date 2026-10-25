class_name DaySpec
extends RefCounted
## What one day is: its number, its words, its clock, its goal, who is on its streets, what stands
## on them and how it is placed, and what losing or winning it costs.
##
## **The escape is a day with special settings, run by the day's own code** *(minty-lemur #785)*.
## A run is a sequence of these — the fourteen days, then the building, then the city — and one
## `DayController` is handed whichever is being walked (`DayController.spec`), so the clock, the
## goal, the loss and its cause, the finish path, the counters and the run log are the same code for
## all sixteen; the city's dressing (`City.start_day()`), its seals (`SealPlanner.plan_day()`) and
## its events (`EventScheduler.build_day()`) are the same code for the fourteen days and the city's
## section. What differs between a day and a section of the escape is written here, as values, and
## read where it matters, rather than asked of a global "are we in the escape" anywhere else.
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
## save's**: `GameState.facts.escape_section` holds one as a plain `int` and `GameSave` writes it, so a
## save written before this enum moved here reads the same.
enum Section { NONE, BUILDING, CITY }

## The day number every counter, loss line and run log header names: 1 to 14 for the days, and
## `BUILDING_DAY` and `CITY_DAY` for the escape's two sections. **Not the calendar**:
## `GameState.header.day` stays on the last day while the escape is walked, since the run has not moved
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
## How many of the act's walkers and cars are on its streets, as a share of the act's own
## (`Tuning.crowd_pedestrians()`, `crowd_cars()`): all of them on a day, and nobody in either of the
## escape's sections — *"no regular cars or regular people on the street"*.
var crowd_density := 1.0
## Whether the poster crews paste at dawn and the posters can be torn (`PosterWalls.start_day()`),
## or the walls only show what the run left on them (`PosterWalls.show_only()`): a day pastes, and
## the escape shows.
var pastes_posters := true

# ------------------------------------------------------- how its events are placed ---

## What stands on the walk and how it is drawn (`EventScheduler.build_day()`).
enum Draw {
	## The catalogue's day: the ambient rows, the scars, the masts, the scripted rows, the
	## one-shots, the spoilers in a park she used, then the recurring rows bought from the day's
	## budget (`EventScheduler.budget_for()`) — every one of the fourteen days.
	CATALOGUE,
	## Every street of the walk draws `slots_per_street` marbles from one bag holding `bag`, and a
	## marble stands one of its row (`bag_rows`), or nothing where it has no row — the escape's city,
	## which knows every street she can take before she sets off.
	BAG_PER_STREET,
}
var draw := Draw.CATALOGUE
## `Draw.BAG_PER_STREET`'s marbles: a marble -> how many of it one fill of the bag holds. One bag for
## the whole walk, so the mix is exact over each fill of it rather than over each street.
var bag := {}
## What each of `bag`'s marbles stands, a marble -> `EventDef`; `EMPTY_MARBLE` has none.
var bag_rows := {}
## How many marbles each street of the walk draws.
var slots_per_street := 0
## Whether nothing dangerous may reach a calm area she has not used yet, and one stays usable
## (`EventScheduler._calm_to_leave_alone()`, `_ensure_one_usable_park()`): every day's rule. The
## escape is the climax and its chains pass a calm area at every stop, so the player kept it off
## there (minty-lemur #785).
var keeps_unused_calm_clear := true
## Whether the home's streets are the day's: nothing on the street her front door opens onto
## (`EventScheduler._open_ground_for()`) or round the home block (`CityMap.held_segments`). The
## escape keeps its own rule instead, by the player's word (minty-lemur #785): she sets off from the
## service exit, which opens onto one of those streets, and only the ground she stands on is
## refused (`EventScheduler._clearance_around_her()`).
var holds_the_home_streets := true
## Whether a row stands at most its `EventDef.max_per_day` copies: a day's caps, which the escape
## does without (minty-lemur #785) — what stands there is the slots and the bag's draws.
var caps_per_day := true
## Whether no two waiting guards may notice her from the same ground
## (`EventScheduler._keeps_its_notice_to_itself()`), so she deals with one at a time: the escape's.
var one_notice_at_a_time := false
## Whether everything standing on the walk leaves each street of it a sidewalk open and the walk
## joined, past every body and every standing lethal reach (`WalkGround`): the escape's, whose
## bodies stand on the one walk rather than off it. A day keeps its routes through its corridor's own
## rules instead (`EventScheduler._judge()`).
var keeps_the_walk_open := false

# --------------------------------------------------------- how its streets are sealed ---

## Which seal pictures close the streets off the walk (`SealPlanner.plan_day()`).
enum SealPictures {
	## The day's eight, soft and hard, each from its own act on (`SealPlanner.candidates()`).
	DAY,
	## The escape's four, all hard (`SealPlanner.escape_candidates()`).
	ESCAPE,
}
var seal_pictures := SealPictures.DAY
## Whether the walk's streets are grown as a day's route tree and closed off it
## (`City._close_streets()`: the tree, the region wall, the closures), or handed in with the walk
## (`City.tint_the_route()`): the escape's chains are planned after the city is dressed.
var closes_streets := true
## Whether the main road is sealed off the walk like any other street. A day's tree never routes
## along the spine and sealing it too would wall the one street she is meant to cross freely; the
## escape's chains end on it, so leaving the rest of it open would join them at the one street that
## touches both exits.
var seals_the_main_road := false
## Whether every street and every through-alley off the walk is sealed, rather than a share of them
## from `Tuning.REGION_WALL_FIRST_DAY` on and a `Tuning.ALLEY_MOUTH_SEAL_CHANCE` of the alleys: a
## day lets a wrong turn be taken and found; in the escape one open alley is a second way through.
var seals_every_street_off_the_walk := false

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

## The marble a slot that stands nothing draws.
const EMPTY_MARBLE := ""

## One of the fourteen days, `day_length` seconds long.
static func for_day(day: int, day_length := Tuning.DAY_LENGTH_SECONDS) -> DaySpec:
	var spec := DaySpec.new()
	spec.number = day
	spec.length = day_length
	return spec

## One of the escape's two sections, `section_length` seconds long, titled `section_title` — its own
## words, handed in by whoever builds it (`main.escape_section_spec()`). `which` is a `Section`
## passed as an `int`, the way `GameState.facts.escape_section` holds it.
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
	spec.crowd_density = 0.0
	spec.pastes_posters = false
	spec.closes_streets = false
	if which == Section.BUILDING:
		spec.number = BUILDING_DAY
		spec.world = World.BUILDING
		spec.goal = Goal.SERVICE_EXIT
		spec.a_win_leads_into = Section.CITY
	else:
		spec.number = CITY_DAY
		spec.world = World.CITY
		spec.goal = Goal.CITY_EDGE
		_place_the_escape_city(spec)
	return spec

## **The escape city's placement**: the streets the chains walk are known before she sets off, so
## each is filled from one marble bag rather than sited round her as a day does *(minty-lemur #785:
## "so you prefill the events for escape but that doesn't justify not using a marble bag. those
## concepts are orthogonal")*, in the player's order of how many — *"frequency order is trucks >
## explosions > vans > barriers > empty"* — at `Tuning`'s counts. The rows are the escape's own
## copies: the convoy as traffic, with the barricade it leaves on a day stripped; the masked men in
## their van; the roadblock at full heat, whose guards leave the post and come for her on foot; and
## the explosion.
static func _place_the_escape_city(spec: DaySpec) -> void:
	spec.draw = Draw.BAG_PER_STREET
	spec.bag = {
		"military_convoy": Tuning.FINALE_BAG_TRUCKS,
		"finale_explosion": Tuning.FINALE_BAG_EXPLOSIONS,
		"abduction": Tuning.FINALE_BAG_VANS,
		"roadblock": Tuning.FINALE_BAG_ROADBLOCKS,
		EMPTY_MARBLE: Tuning.FINALE_BAG_EMPTY,
	}
	spec.bag_rows = {
		"military_convoy": EventCatalogue.without_its_aftermath(
				EventCatalogue.by_id("military_convoy")),
		"finale_explosion": EventCatalogue.by_id("finale_explosion"),
		"abduction": EventCatalogue.by_id("abduction"),
		"roadblock": EventCatalogue.escape_roadblock(),
	}
	spec.slots_per_street = Tuning.FINALE_SLOTS_PER_STREET
	spec.keeps_unused_calm_clear = false
	spec.holds_the_home_streets = false
	spec.caps_per_day = false
	spec.one_notice_at_a_time = true
	spec.keeps_the_walk_open = true
	spec.seal_pictures = SealPictures.ESCAPE
	spec.seals_the_main_road = true
	spec.seals_every_street_off_the_walk = true

## Whether losing it spends a Nerve, in this run's mode.
func a_loss_costs_a_nerve(hard_mode: bool) -> bool:
	return hard_mode or a_loss_costs_a_normal_run_a_nerve

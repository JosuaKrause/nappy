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

const FINALE_BAG_EMPTY := 1
const FINALE_BAG_EXPLOSIONS := 8
const FINALE_BAG_ROADBLOCKS := 2
## The escape's marble bag, in the player's order of how many *(inbox #785 in minty-lemur:
## "frequency order is trucks > explosions > vans > barriers > empty")*: army trucks, off-screen
## explosions, unmarked vans, roadblocks (the barriers) and empty marbles, where the street that draws
## one stands nothing. **The two rows that take her have the fewest marbles the order allows**, vans
## 3 and roadblocks 2 over the one empty marble, and the trucks and explosions, which only wake the
## baby, make up the rest: a van's catch and a guard's end the section, and a van's field is most of
## what the probe's walks that cried had landed. With these a walk to an exit meets about three
## trucks, three explosions, one van and one roadblock; the order's smallest bag, 5, 4, 3, 2 and 1,
## meets a van and a roadblock more often and gets out on 44 walks of 48. A fill is 24 marbles and
## a plan has about 31 open streets, so an escape draws one whole fill and about seven marbles of
## the next. About a third of the streets stand nothing all the same, since a danger the placement
## rules refuse is spent unmet.
const FINALE_BAG_TRUCKS := 10
const FINALE_BAG_VANS := 3

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
## save's**: `run.facts.escape_section` holds one as a plain `int` and `GameSave` writes it, so a
## save written before this enum moved here reads the same.
enum Section { NONE, BUILDING, CITY }

## The day number every counter, loss line and run log header names: 1 to 14 for the days, and
## `BUILDING_DAY` and `CITY_DAY` for the escape's two sections. **Not the calendar**:
## `run.header.day` stays on the last day while the escape is walked, since the run has not moved
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
## Handed in by the start once the world it stands in is stood (`DayWorld.exits()`); empty for any
## other goal.
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

# ------------------------------------------------------------------ how it starts ---

## Where she is put down as the walk starts, each a place in the world the walk stands in
## (`DayWorldSource.stand()` answers the point).
enum Start {
	## Her own front door, on the street: every one of the fourteen days.
	DOORSTEP,
	## Her own flat's door, inside the building: the escape's first section.
	FLAT,
	## The building's service exit, on the street beside the home block: the escape's city.
	SERVICE_EXIT,
}
var _start := Start.DOORSTEP
## Whether the run photographs what it holds at the walk's dawn (`RunCalendar.begin_day()`), which is
## what a lost attempt gives back and where a checkpoint is kept: every day's. A section of the
## escape gives nothing back (`a_loss_gives_back_the_attempt`) and keeps no checkpoint of its own.
var _photographs_the_dawn := true
## Whether the resistance's day runs (`ResistanceDirector.start_day()`): its mark, its contact and
## its task on every day; the escape has no subquest to advance.
var _runs_the_resistance := true
## Whether the baby is asleep in her arms as the walk starts, sleepiness full: the escape's *"the
## player holding the sleeping baby (sleep bar is full)"*, which is also what makes a retry playable
## at all, since the meter that just reached a hundred is what lost the section. A day starts with
## her awake.
var _starts_asleep := false
## Whether the walk's plan draws on the run's one-shots and spends them
## (`AttemptSpendState.consumed_one_shots`, appended to as the day's plan spends one): every day's.
## The escape plans from a list of its own, empty, and spends none of the run's.
var _spends_the_one_shots := true
## The run's random stream the walk's events are planned on (`RunCalendar.day_rng()`): `"events"` for
## a day, `"finale"` for the escape's city, so a restarted section is the same city rather than a
## thinner one. The building is planned on a seed of its own, which its night shares
## (`DayWorld.plan_rng()`).
var _events_stream := "events"
## Whether the act's calm areas she has already used are handed to the dawn's repaint to shut where
## they can, and the one park fenced this run is fenced again (`CityMap.set_spent_calm()`,
## `set_fenced_park_state()`): every day's. The escape's repaint comes with no handover and shuts
## nothing.
var _shuts_the_spent_calm := true

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
	## one-shots, the spoilers in a park she used, then every one of the day's locations drawn from
	## its view's bag of the recurring rows (`EventScheduler._draw_the_locations()`) — every one of
	## the fourteen days.
	CATALOGUE,
	## Every street of the walk draws one marble from one bag holding `bag`, and a marble stands one
	## of its row (`bag_rows`) at the first of the street's locations it is valid at, the rest of the
	## street empty, or nothing where it has no row — the escape's city, which knows every street she
	## can take before she sets off. *(Inbox #1185 in gentle-owl's board answer: "one per street. fill empty in if
	## any segment or location in the street has an event".)* One a street also keeps the section
	## the climax and every walk out of it walkable (`tests/probes/escape_winnable.gd`), and stands one
	## roadblock a street at most, so a crossing is one band and one guard on her side of it to lure
	## *(inbox #771 in minty-lemur: "Luring away one guard (the challenge) is not enough to make the
	## obstacle survivable")*.
	BAG_PER_STREET,
}
var draw := Draw.CATALOGUE
## `Draw.BAG_PER_STREET`'s marbles: a marble -> how many of it one fill of the bag holds. One bag for
## the whole walk, so the mix is exact over each fill of it rather than over each street.
var bag := {}
## What each of `bag`'s marbles stands, a marble -> `EventDef`; `EMPTY_MARBLE` has none.
var bag_rows := {}
## Whether nothing dangerous may reach a calm area she has not used yet, and one stays usable
## (`CalmAreas.unused_ground()`, `EventScheduler._calm_kept_clean()`): every day's rule. The
## escape is the climax and its chains pass a calm area at every stop, so the player kept it off
## there (minty-lemur #785).
var keeps_unused_calm_clear := true
## Whether the home's streets are the day's: nothing on the street her front door opens onto
## (`RowGround.tiles_for()`) or round the home block (`CityMap.held`). The
## escape keeps its own rule instead, by the player's word (minty-lemur #785): she sets off from the
## service exit, which opens onto one of those streets, and only the ground she stands on is
## refused (`EventScheduler.clearance_around_her()`).
var holds_the_home_streets := true
## Whether a row stands at most its `EventDef.max_per_day` copies: a day's caps, which the escape
## does without (minty-lemur #785) — what stands there is one draw a street from its bag.
var caps_per_day := true
## The share of its **wall**-role rows the day draws: every wall-role row's weight in the view bags
## is scaled by it (`EventScheduler.view_weight()`), while the empty marbles are set for every wall
## weighed in full, so a location draws a wall that much less often; and its cap is scaled by it too
## (`EventScheduler._caps_of()`), so a wall whose cap binds is thinned as well. The day holds about
## that share of its walls. `1.0` keeps every wall: every day the region wall does not stand
## (`region_wall_stands()`) and every section of the escape. On a day it stands, `for_day()` hands
## `GATEHOUSE_DAY_WALL_ROW_SHARE`: the gatehouse day holds about half its walls, not all of them.
var wall_row_share := 1.0
## The share `wall_row_share` is on a day the region wall stands, set by `for_day()`.
const GATEHOUSE_DAY_WALL_ROW_SHARE := 0.5
## Whether no two waiting guards may notice her from the same ground
## (`OneNoticeRule._keeps_its_notice_to_itself()`), so she deals with one at a time: the escape's.
var one_notice_at_a_time := false
## Whether everything standing on the walk leaves each street of it a sidewalk open and the walk
## joined, past every body and every standing lethal reach (`WalkGround`): the escape's, whose
## bodies stand on the one walk rather than off it. A day keeps its routes through its corridor's own
## rules instead (`StreetInvalidation`: a route's junctions, its walked sidewalk, a beat's opening).
var keeps_the_walk_open := false

# --------------------------------------------------------- how its streets are sealed ---

## Which seal pictures close the streets off the walk (`SealPlanner.plan_day()`).
enum SealPictures {
	## The day's eight, soft and hard, each from its own act on (`SealPlanner.candidates()`).
	DAY,
	## The escape's four, all hard (`SealPlanner._escape_candidates()`).
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
## from `Tuning.REGION_WALL_FIRST_DAY` on and a `SealPlanner.ALLEY_MOUTH_SEAL_CHANCE` of the alleys: a
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

## Whether the region wall divides the city today, set by `for_day()` and read through
## `region_wall_stands()`.
var _region_wall_stands := false

## One of the fourteen days, `day_length` seconds long.
static func for_day(day: int, day_length := Tuning.DAY_LENGTH_SECONDS) -> DaySpec:
	var spec := DaySpec.new()
	spec.number = day
	spec.length = day_length
	spec._region_wall_stands = day >= Tuning.REGION_WALL_FIRST_DAY
	if spec.region_wall_stands():
		spec.wall_row_share = GATEHOUSE_DAY_WALL_ROW_SHARE
	return spec

## One of the escape's two sections, `section_length` seconds long, titled `section_title` — its own
## words, handed in by whoever builds it (`main._escape_section_spec()`). `which` is a `Section`
## passed as an `int`, the way `run.facts.escape_section` holds it.
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
	spec._photographs_the_dawn = false
	spec._runs_the_resistance = false
	spec._starts_asleep = true
	spec._spends_the_one_shots = false
	spec._shuts_the_spent_calm = false
	if which == Section.BUILDING:
		spec.number = BUILDING_DAY
		spec.world = World.BUILDING
		spec.goal = Goal.SERVICE_EXIT
		spec._start = Start.FLAT
		spec.a_win_leads_into = Section.CITY
	else:
		spec.number = CITY_DAY
		spec.world = World.CITY
		spec.goal = Goal.CITY_EDGE
		spec._start = Start.SERVICE_EXIT
		spec._events_stream = "finale"
		_place_the_escape_city(spec)
	return spec

## **The escape city's placement**: the streets the chains walk are known before she sets off, so
## each is filled from one marble bag rather than sited round her as a day does *(minty-lemur #785:
## "so you prefill the events for escape but that doesn't justify not using a marble bag. those
## concepts are orthogonal")*, in the player's order of how many — *"frequency order is trucks >
## explosions > vans > barriers > empty"* — at `Tuning`'s counts. The rows: the convoy, as traffic;
## the masked men in their van; the escape's own roadblock at full heat, whose guards leave the post
## and come for her on foot; and the explosion.
static func _place_the_escape_city(spec: DaySpec) -> void:
	spec.draw = Draw.BAG_PER_STREET
	spec.bag = {
		"military_convoy": FINALE_BAG_TRUCKS,
		"finale_explosion": FINALE_BAG_EXPLOSIONS,
		"abduction": FINALE_BAG_VANS,
		"roadblock": FINALE_BAG_ROADBLOCKS,
		EMPTY_MARBLE: FINALE_BAG_EMPTY,
	}
	spec.bag_rows = {
		"military_convoy": EventCatalogue.by_id("military_convoy"),
		"finale_explosion": EventCatalogue.by_id("finale_explosion"),
		"abduction": EventCatalogue.by_id("abduction"),
		"roadblock": EventCatalogue.escape_roadblock(),
	}
	spec.keeps_unused_calm_clear = false
	spec.holds_the_home_streets = false
	spec.caps_per_day = false
	spec.one_notice_at_a_time = true
	spec.keeps_the_walk_open = true
	spec.seal_pictures = SealPictures.ESCAPE
	spec.seals_the_main_road = true
	spec.seals_every_street_off_the_walk = true

## The day number every counter, loss line and run log header names (`number`).
func day_number() -> int:
	return number

## What ends the day for a win (`Goal`).
func goal_kind() -> Goal:
	return goal

## Which section the day is, `Section.NONE` for a day of the calendar.
func section_kind() -> Section:
	return section

## The seconds the walk's clock starts with (`length`).
func seconds_on_the_clock() -> float:
	return length

## How many of the act's walkers and cars are on the walk's streets, as a share of the act's own
## (`crowd_density`): nobody at `0.0`.
func crowd_share() -> float:
	return crowd_density

## The finale's exits by `CityEdge.Kind`, each the point the walk ends at.
func exit_points() -> Dictionary:
	return exits

## Whether the countdown is shown and ticked to the hundredth (the escape's).
func counts_in_hundredths() -> bool:
	return clock_hundredths

## Whether the day grows its closures at dawn.
func closes_the_streets() -> bool:
	return closes_streets

## Where she is put down as the walk starts (`Start`).
func start_point() -> Start:
	return _start

## Whether the run photographs what it holds at the walk's dawn (`_photographs_the_dawn`).
func photographs_the_dawn() -> bool:
	return _photographs_the_dawn

## Whether the resistance's day runs on this walk (`_runs_the_resistance`).
func runs_the_resistance() -> bool:
	return _runs_the_resistance

## Whether the baby is asleep in her arms as the walk starts (`_starts_asleep`).
func starts_with_the_baby_asleep() -> bool:
	return _starts_asleep

## Whether the walk's plan draws on and spends the run's one-shots (`_spends_the_one_shots`).
func spends_the_one_shots() -> bool:
	return _spends_the_one_shots

## The run's random stream the walk's events are planned on (`_events_stream`).
func events_stream() -> String:
	return _events_stream

## Whether the act's used calm areas are shut at dawn (`_shuts_the_spent_calm`).
func shuts_the_spent_calm() -> bool:
	return _shuts_the_spent_calm

## Whether the light runs from dawn to dusk with the clock (`daylight_runs_down`).
func runs_the_daylight_down() -> bool:
	return daylight_runs_down

## Whether the city is dark from its first frame (`dark_from_the_start`).
func is_dark_from_the_start() -> bool:
	return dark_from_the_start

## Hands the walk its ways out, as the world it is walked in answers them (`DayWorld.exits()`): a
## `Goal.CITY_EDGE` walk's two, and none for any other (`exits`).
func use_exits(the_exits: Dictionary) -> void:
	exits = the_exits


## Whether the crews paste posters at dawn.
func pastes_the_posters() -> bool:
	return pastes_posters

## **Whether the region wall divides the city today**, with its doors and the gatehouses at them:
## every day from the gatehouse day (`Tuning.REGION_WALL_FIRST_DAY`) to the last, and neither section
## of the escape, since the building has no streets and the escape's city grows no day's tree to
## stand a wall against (`closes_streets` is off). Worked out once, by `for_day()`, and asked by
## what the wall makes harder to navigate rather than compared with the day number again: the
## catalogue's walls kept (`wall_row_share`), the closures (`ClosurePlanner.closures_wanted()`) and
## the seals (`SealPlanner.plan_day()`), each thinned by a share of its own. *(azure-puffin, point
## 4: "when the guard houses are set up the city gets much harder to navigate".)*
func region_wall_stands() -> bool:
	return _region_wall_stands

## Whether losing it spends a Nerve, in this run's mode.
func a_loss_costs_a_nerve(hard_mode: bool) -> bool:
	return hard_mode or a_loss_costs_a_normal_run_a_nerve

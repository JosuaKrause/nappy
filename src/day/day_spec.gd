class_name DaySpec
extends RefCounted
## What one day is: its number, its words, its clock, its goal, who is on its streets, what stands
## on them and how it is placed, and what losing or winning it costs.
##
## **The escape is a day with special settings, run by the day's own code** *(minty-lemur #785)*.
## A run is a sequence of these — the fourteen days, then the building, then the city — and one
## `DayController` is handed whichever is being walked (`DayController.use_the_spec()`), so the
## clock, the goal, the loss and its cause, the finish path, the counters and the run log are
## the same code for all sixteen; the city's dressing (`City.start_day()`), its seals
## (`SealPlanner.plan_day()`) and its events (`EventScheduler.build_day()`) are the same code
## for the fourteen days and the city's
## section. What differs between a day and a section of the escape is written here, as values, and
## read where it matters, rather than asked of a global "are we in the escape" anywhere else: the
## walk's bag, what it holds standing and its seals, what the event director may send her while she
## walks (`director_sends()`), who is on its streets, and what losing it costs.
##
## Data only: no node, no autoload, nothing that runs, and no words of its own — whoever builds one
## hands it its title, so this layer names nothing of the UI's. `for_day()` and `for_section()` are
## the two shapes the run uses; a test builds one either way, or by hand.

const FINALE_BAG_EMPTY := 9
const FINALE_BAG_EXPLOSIONS := 8
const FINALE_BAG_ROADBLOCKS := 2
## The escape's marble bag. Its four rows are in the player's order of how many *(inbox #785 in
## minty-lemur: "frequency order is trucks > explosions > vans > barriers > empty")*: army trucks,
## off-screen explosions, unmarked vans and roadblocks (the barriers). **The two rows that take her
## have the fewest marbles of the four**, vans 3 and roadblocks 2, and the trucks and explosions,
## which only wake the baby, make up the rest: a van's catch and a guard's end the section, and a
## van's field is most of what the probe's walks that cried had landed.
##
## The empty marbles, where the street that draws one stands nothing, are counted apart from that
## order: a marble a street's rules refuse stays in the bag (`ViewBag`), so the empty marbles are
## what leaves a street with nothing, and `FINALE_BAG_EMPTY` is the count at which about a third of
## the streets stand nothing, the share the escape had when a refused marble was spent. Nine puts
## the empty marble second most numerous, against the player's order with empty last: the
## orchestrator's reading of the player's approval of the design review (inbox #1268 in
## olive-ferret), open to the player. One measurement (`tests/probes/escape_winnable.gd`), not a
## fit; the entry lilac-marten (the fuller escape) sets the count from here. A fill is the sum of
## the five and a plan has about 31 open streets.
const FINALE_BAG_TRUCKS := 10
const FINALE_BAG_VANS := 3

## What the event director may send her while she walks (`director_sends()`). A walk that sends
## something of its own (the escape's army trucks on her route) adds a value here.
enum DirectorSends {
	## The rows the calendar's day sends, by the day's number: the route's bag of cats, cyclists, dog
	## walkers, patrols and the rest, with the day-one rig and the sprinkled charging dog.
	THE_DAYS_ROWS,
	## Nothing: no route bag, nothing owed from the plan, no rig and no sprinkled dog.
	NOTHING,
}

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
	## The tunnel mouth or the bridge deck (`exit_points()`), reached however the baby is.
	CITY_EDGE,
}

## The escape's two sections, and `NONE` for every one of the fourteen days. **The values are the
## save's**: `run.facts().escape_section()` holds one as a plain `int` and `GameSave` writes it, so a
## save written before this enum moved here reads the same.
enum Section { NONE, BUILDING, CITY }

## The day number (`day_number()`): 1 to 14 for the days, and `BUILDING_DAY` and `CITY_DAY` for the
## escape's two sections.
var _number := 1
## The day's own words where "Day N of 14" stands, on its brief and its outcome screen, and the
## line the HUD says once she is walking it: "" for a day, "Escape the building" or "Escape the
## city" for a section. Read through `title()`.
var _title := ""
## Which section of the escape this is, `Section.NONE` for a day. Read through `section_kind()`.
var _section := Section.NONE
## Where the walk is (`World`). Read through `world_kind()`.
var _world := World.CITY
var goal := Goal.HOME
## Where `Goal.CITY_EDGE`'s two ways out stand, in world space — `CityExit.Kind` -> position, the
## last walkable tile of the spine at each end rather than where the portal's picture is anchored.
## Handed in by the start once the world it stands in is stood (`DayWorld.exits()`, through
## `use_exits()`); empty for any other goal. Read through `exit_points()`.
var _exits := {}
## Seconds on the clock.
var _length := Tuning.DAY_LENGTH_SECONDS
## Whether the clock reads to the hundredth and tells the HUD every frame, rather than to the whole
## second *(inbox #746 in woolly-penguin)*: the escape's tension is its clock.
var clock_hundredths := false
## Whether the light follows the clock from dawn to dusk, or stays at night all the way through:
## the escape happens after the last day, and its tension is the clock rather than the light. Read
## through `runs_the_daylight_down()`.
var _daylight_runs_down := true
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
## escape gives nothing back (`a_loss_undoes_the_attempt()`) and keeps no checkpoint of its own.
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
## (`AttemptSpendState.consumed_one_shots()`, appended to as the day's plan spends one): every day's.
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
var _owes_a_return := true
## What the event director may send her (`director_sends()`).
var _director_sends := DirectorSends.THE_DAYS_ROWS
## Whether a torn poster sends a pursuer on foot at her (`EventManager.send_a_pursuer()`): on every
## day, and never in the escape.
var _poster_pursuits := true
## How many of the act's walkers and cars are on its streets, as a share of the act's own
## (`Tuning.crowd_pedestrians()`, `crowd_cars()`): all of them on a day, and nobody in either of the
## escape's sections — *"no regular cars or regular people on the street"*.
var crowd_density := 1.0
## Whether the poster crews paste at dawn and the posters can be torn (`PosterWalls.dress_for()`),
## or the walls only show what the run left on them (`PosterWalls.show_only()`): a day pastes, and
## the escape shows.
var pastes_posters := true

# ------------------------------------------------------- how its events are placed ---

## **The one bag the whole walk draws from**: a marble -> how many of it one fill holds,
## `EMPTY_MARBLE` among them, so the mix is exact over each fill of it rather than over each
## street. Empty where the walk has no such bag and each of its units draws from a fresh bag of its
## view's fill: every one of the fourteen days. Set by `_place_the_escape_city()`; a suite or a
## probe sets another mix to plan with. `src/` reads it through `walk_bag()`.
var bag := {}
## What each of `bag`'s marbles stands, a marble -> `EventDef`; `EMPTY_MARBLE` has none. Read
## through `walk_bag_rows()`.
var _bag_rows := {}
## Whether a unit of the walk draws one marble and no more (`MarbleDraw`): a row's stands alone in
## the unit, an empty one leaves it with nothing. *(Inbox #1185 in gentle-owl's board answer: "one
## per street. fill empty in if any segment or location in the street has an event".)* It also
## stands one roadblock a street at most, so a crossing is one band and one guard on her side of it
## to lure *(inbox #771 in minty-lemur: "Luring away one guard (the challenge) is not enough to make
## the obstacle survivable")*. A day's unit draws until its room is spoken for. Read through
## `stands_one_event_a_street()`.
var _one_event_a_street := false
## Whether every unit of the walk is drawn at dawn, in the order the walk names its streets, each
## judged among everything drawn before it (`UnitDraw.draw_in_their_order()`): a walk that knows
## every street she can take before she sets off. A day's units draw as she comes near them. Read
## through `draws_before_she_sets_off()`.
var _drawn_before_she_sets_off := false
## Whether nothing dangerous may reach a calm area she has not used yet, and one stays usable
## (`CalmAreas.unused_ground()`, `DawnCalmKeptClean`): every day's rule. The
## escape is the climax and its chains pass a calm area at every stop, so the player kept it off
## there (minty-lemur #785).
var _keeps_unused_calm_clear := true
## Whether the home's streets are the day's: nothing on the street her front door opens onto
## (`RowGround.tiles_for()`) or round the home block (`CityMap.held`). The
## escape keeps its own rule instead, by the player's word (minty-lemur #785): she sets off from the
## service exit, which opens onto one of those streets, and only the ground she stands on is
## refused (`EventScheduler.clearance_around_her()`). Read through `keeps_the_home_streets_clear()`.
var _holds_the_home_streets := true
## The share of its **wall**-role rows the day draws: every wall-role row's weight in a unit's bag
## is scaled by it, while its row marbles are measured against every wall weighed in full
## (`UnitFills`), so a wall's place goes to empty and a unit draws a wall that much less often.
## The day holds about that share of its walls. `1.0` keeps every wall: every day the region wall does not stand
## (`region_wall_stands()`) and every section of the escape. On a day it stands, `for_day()` hands
## `GATEHOUSE_DAY_WALL_ROW_SHARE`: the gatehouse day holds about half its walls, not all of them.
var wall_row_share := 1.0
## The share `wall_row_share` is on a day the region wall stands, set by `for_day()`.
const GATEHOUSE_DAY_WALL_ROW_SHARE := 0.5
## Whether no two waiting guards may notice her from the same ground
## (`OneNoticeRule._keeps_its_notice_to_itself()`), so she deals with one at a time: the escape's.
var _one_notice_at_a_time := false
## Whether everything standing on the walk leaves each street of it a sidewalk open and the walk
## joined, past every body and every standing lethal reach (`WalkGround`): the escape's, whose
## bodies stand on the one walk rather than off it. A day keeps its routes through its corridor's own
## rules instead (`StreetInvalidation`: a route's junctions, its walked sidewalk, a beat's opening).
var _keeps_the_walk_open := false

# --------------------------------------------------------- how its streets are sealed ---

## Which seal pictures close the streets off the walk (`SealPlanner.plan_day()`).
enum SealPictures {
	## The table's pictures, soft and hard, each from its own act on (`SealPlanner.candidates()`).
	DAY,
	## The escape's four, all hard (`SealPlanner._escape_candidates()`).
	ESCAPE,
}
## Read through `seal_pictures()`.
var _seal_pictures := SealPictures.DAY
## Whether the walk's streets are grown as a day's route tree and closed off it
## (`City._close_streets()`: the tree, the region wall, the closures), or handed in with the walk
## (`City.tint_the_route()`): the escape's chains are planned after the city is dressed. Read
## through `closes_the_streets()`.
var _closes_streets := true
## Whether the main road is sealed off the walk like any other street. A day's tree never routes
## along the spine and sealing it too would wall the one street she is meant to cross freely; the
## escape's chains end on it, so leaving the rest of it open would join them at the one street that
## touches both exits. Read through `seals_off_the_main_road()`.
var _seals_the_main_road := false
## Whether every street and every through-alley off the walk is sealed, rather than a share of them
## from `Tuning.REGION_WALL_FIRST_DAY` on and a `SealPlanner.ALLEY_MOUTH_SEAL_CHANCE` of the alleys: a
## day lets a wrong turn be taken and found; in the escape one open alley is a second way through.
## Read through `seals_off_every_other_street()`.
var _seals_every_street_off_the_walk := false

# --------------------------------------------------------------- what it costs ---

## Whether a normal run spends a Nerve on a loss. A hard run always does. The escape's sections
## cost a normal run nothing *("sounds good at that point you earned it")*, and a hard run's
## escape has normal nerve counts and ends when they run out *(gentle-osprey)*.
var a_loss_costs_a_normal_run_a_nerve := true
## Whether a lost attempt gives back what it spent of the run — the resistance's work, the
## one-shots, the scars, the arcs — so the retry is the same day exactly as it was first met. The
## escape touches none of it, so a lost section has nothing to give back. Read through
## `a_loss_undoes_the_attempt()`.
var _a_loss_gives_back_the_attempt := true
## Whether a win gives a normal run a Nerve back. Walking out of the building or the city gives
## none *("the escape doesn't have nerves")*. Read through `a_win_regains_a_nerve()`.
var _a_win_gives_a_nerve_back := true
## The section a win leads into, `Section.NONE` when a win ends the walk: the building's leads
## into the city, and nothing of the run is settled until she is out of that. Read through
## `a_win_leads_into()`.
var _a_win_leads_into := Section.NONE
## Whether the save says a day is under way while it is walked, so a game closed mid-day loses that
## day when it is opened again. The escape's sections are saved only at their brief, as a
## checkpoint: closed inside one, it opens on that section's brief again at no cost. Read through
## `is_saved_as_under_way()`.
var _saved_as_under_way := true

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
	spec._number = day
	spec._length = day_length
	spec._region_wall_stands = day >= Tuning.REGION_WALL_FIRST_DAY
	if spec.region_wall_stands():
		spec.wall_row_share = GATEHOUSE_DAY_WALL_ROW_SHARE
	return spec

## One of the escape's two sections, `section_length` seconds long, titled `section_title` — its own
## words, handed in by whoever builds it (`main._escape_section_spec()`). `which` is a `Section`
## passed as an `int`, the way `run.facts().escape_section()` holds it.
static func for_section(which: int, section_length: float, section_title := "") -> DaySpec:
	var spec := DaySpec.new()
	spec._section = which
	spec._length = section_length
	spec._title = section_title
	spec.clock_hundredths = true
	spec._daylight_runs_down = false
	spec.dark_from_the_start = true
	spec.a_loss_costs_a_normal_run_a_nerve = false
	spec._a_loss_gives_back_the_attempt = false
	spec._a_win_gives_a_nerve_back = false
	spec._saved_as_under_way = false
	spec._owes_a_return = false
	spec._poster_pursuits = false
	spec.crowd_density = 0.0
	spec.pastes_posters = false
	spec._closes_streets = false
	spec._photographs_the_dawn = false
	spec._runs_the_resistance = false
	spec._starts_asleep = true
	spec._spends_the_one_shots = false
	spec._shuts_the_spent_calm = false
	if which == Section.BUILDING:
		spec._number = BUILDING_DAY
		spec._world = World.BUILDING
		spec.goal = Goal.SERVICE_EXIT
		spec._start = Start.FLAT
		spec._a_win_leads_into = Section.CITY
	else:
		spec._number = CITY_DAY
		spec._world = World.CITY
		spec.goal = Goal.CITY_EDGE
		spec._start = Start.SERVICE_EXIT
		spec._events_stream = "finale"
		_place_the_escape_city(spec)
	return spec

## **The escape city's placement**: the streets the chains walk are known before she sets off, so
## every street is drawn before she sets off, one marble a street from one bag for the whole walk, by
## the day's own draw under three settings, rather than sited round her as a day does *(minty-lemur #785:
## "so you prefill the events for escape but that doesn't justify not using a marble bag. those
## concepts are orthogonal")*, in the player's order of how many — *"frequency order is trucks >
## explosions > vans > barriers > empty"* — at `Tuning`'s counts. The rows: the convoy, as traffic;
## the masked men in their van; the escape's own roadblock at full heat, whose guards leave the post
## and come for her on foot; and the explosion.
static func _place_the_escape_city(spec: DaySpec) -> void:
	spec.bag = {
		"military_convoy": FINALE_BAG_TRUCKS,
		"finale_explosion": FINALE_BAG_EXPLOSIONS,
		"abduction": FINALE_BAG_VANS,
		"roadblock": FINALE_BAG_ROADBLOCKS,
		EMPTY_MARBLE: FINALE_BAG_EMPTY,
	}
	spec._bag_rows = {
		"military_convoy": EventCatalogue.by_id("military_convoy"),
		"finale_explosion": EventCatalogue.by_id("finale_explosion"),
		"abduction": EventCatalogue.by_id("abduction"),
		"roadblock": EventCatalogue.escape_roadblock(),
	}
	spec._director_sends = DirectorSends.NOTHING
	spec._keeps_unused_calm_clear = false
	spec._holds_the_home_streets = false
	spec._one_event_a_street = true
	spec._drawn_before_she_sets_off = true
	spec._one_notice_at_a_time = true
	spec._keeps_the_walk_open = true
	spec._seal_pictures = SealPictures.ESCAPE
	spec._seals_the_main_road = true
	spec._seals_every_street_off_the_walk = true

## The day number every counter, loss line and run log header names: 1 to 14 for the days, and
## `BUILDING_DAY` and `CITY_DAY` for the escape's two sections. **Not the calendar**:
## `run.header().day()` stays on the last day while the escape is walked, since the run has not moved
## past it — its plan's random streams and its save are keyed by it (`_number`).
func day_number() -> int:
	return _number

## What ends the day for a win (`Goal`).
func goal_kind() -> Goal:
	return goal

## Which section the day is, `Section.NONE` for a day of the calendar (`_section`).
func section_kind() -> Section:
	return _section

## Where the walk is, the city or the building (`_world`).
func world_kind() -> World:
	return _world

## The day's own words where "Day N of 14" stands, "" for a day of the calendar (`_title`).
func title() -> String:
	return _title

## The seconds the walk's clock starts with (`_length`).
func seconds_on_the_clock() -> float:
	return _length

## How many of the act's walkers and cars are on the walk's streets, as a share of the act's own
## (`crowd_density`): nobody at `0.0`.
func crowd_share() -> float:
	return crowd_density

## The finale's exits by `CityExit.Kind`, each the point the walk ends at (`_exits`).
func exit_points() -> Dictionary:
	return _exits

## Whether the countdown is shown and ticked to the hundredth (the escape's).
func counts_in_hundredths() -> bool:
	return clock_hundredths

## Whether the day grows its closures at dawn.
func closes_the_streets() -> bool:
	return _closes_streets

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

## Whether the light runs from dawn to dusk with the clock (`_daylight_runs_down`).
func runs_the_daylight_down() -> bool:
	return _daylight_runs_down

## Whether the city is dark from its first frame (`dark_from_the_start`).
func is_dark_from_the_start() -> bool:
	return dark_from_the_start

## The share of its wall-role rows the day draws (`wall_row_share`), which a unit's bag fill scales
## each wall by (`UnitFills`).
func share_of_walls_drawn() -> float:
	return wall_row_share

## **The walk's one bag** (`bag`): empty for a walk with none, and an empty bag is the only way a
## walk says so, so no yes-or-no beside it can disagree with it.
func walk_bag() -> Dictionary:
	return bag

## The rows the walk bag's marbles stand, a marble -> its row; `EMPTY_MARBLE` has none
## (`_bag_rows`).
func walk_bag_rows() -> Dictionary:
	return _bag_rows

## Whether a street of the walk stands one event at most (`_one_event_a_street`): its unit draws
## one marble (`MarbleDraw`).
func stands_one_event_a_street() -> bool:
	return _one_event_a_street

## Whether every unit of the walk is drawn before she sets off (`_drawn_before_she_sets_off`).
func draws_before_she_sets_off() -> bool:
	return _drawn_before_she_sets_off

## Hands the walk its ways out, as the world it is walked in answers them (`DayWorld.exits()`): a
## `Goal.CITY_EDGE` walk's two, and none for any other (`_exits`).
func use_exits(the_exits: Dictionary) -> void:
	_exits = the_exits

## Whether nothing stands on the street her front door opens onto or round the home block
## (`_holds_the_home_streets`): every day's rule, and not the escape's.
func keeps_the_home_streets_clear() -> bool:
	return _holds_the_home_streets

## Whether falling asleep owes her a walk home on this walk (`_owes_a_return`): every day's does, a
## section of the escape does not.
func owes_her_a_return() -> bool:
	return _owes_a_return

## What the event director may send her while she walks this walk (`DirectorSends`): an ordinary
## day's rows on a day, nothing on the escape's city, whose every danger is placed before she sets
## off. The day's number decides none of it.
func director_sends() -> DirectorSends:
	return _director_sends

## Whether a torn poster sends a pursuer on foot at her on this walk (`_poster_pursuits`): every
## day's does, the escape's never.
func sends_a_pursuer_for_a_torn_poster() -> bool:
	return _poster_pursuits

## Whether everything standing on the walk leaves each street of it a sidewalk open and the walk
## joined (`_keeps_the_walk_open`): the escape's.
func keeps_her_walk_open() -> bool:
	return _keeps_the_walk_open

## Whether no two waiting guards may notice her from the same ground (`_one_notice_at_a_time`): the
## escape's.
func notices_one_at_a_time() -> bool:
	return _one_notice_at_a_time

## Whether the calm areas she has not used this act are kept clear of everything the dawn places
## (`_keeps_unused_calm_clear`).
func keeps_the_unused_calm_clean() -> bool:
	return _keeps_unused_calm_clear

## Which seal pictures close the streets off the walk (`_seal_pictures`).
func seal_pictures() -> SealPictures:
	return _seal_pictures

## Whether the main road is sealed off the walk like any other street (`_seals_the_main_road`).
func seals_off_the_main_road() -> bool:
	return _seals_the_main_road

## Whether every street and through-alley off the walk is sealed, rather than a share of them
## (`_seals_every_street_off_the_walk`).
func seals_off_every_other_street() -> bool:
	return _seals_every_street_off_the_walk


## Whether the crews paste posters at dawn.
func pastes_the_posters() -> bool:
	return pastes_posters

## **Whether the region wall divides the city today**, with its doors and the gatehouses at them:
## every day from the gatehouse day (`Tuning.REGION_WALL_FIRST_DAY`) to the last, and neither section
## of the escape, since the building has no streets and the escape's city grows no day's tree to
## stand a wall against (`closes_the_streets()` is off). Worked out once, by `for_day()`, and asked by
## what the wall makes harder to navigate rather than compared with the day number again: the
## catalogue's walls kept (`wall_row_share`), the closures (`ClosurePlanner.closures_wanted()`) and
## the seals (`SealPlanner.plan_day()`), each thinned by a share of its own. *(azure-puffin, point
## 4: "when the guard houses are set up the city gets much harder to navigate".)*
func region_wall_stands() -> bool:
	return _region_wall_stands

## Whether losing it spends a Nerve, in this run's mode.
func a_loss_costs_a_nerve(hard_mode: bool) -> bool:
	return hard_mode or a_loss_costs_a_normal_run_a_nerve

## Whether a lost attempt gives back what it spent of the run, so the retry is the same day
## (`_a_loss_gives_back_the_attempt`).
func a_loss_undoes_the_attempt() -> bool:
	return _a_loss_gives_back_the_attempt

## Whether a win gives a normal run a Nerve back (`_a_win_gives_a_nerve_back`).
func a_win_regains_a_nerve() -> bool:
	return _a_win_gives_a_nerve_back

## The section a win leads into, `Section.NONE` when a win ends the walk (`_a_win_leads_into`).
func a_win_leads_into() -> Section:
	return _a_win_leads_into

## Whether the save says the walk is under way while it is walked (`_saved_as_under_way`).
func is_saved_as_under_way() -> bool:
	return _saved_as_under_way

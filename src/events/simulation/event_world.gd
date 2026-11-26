class_name EventWorld
extends RefCounted
## **What every part of a day's events works over, as the manager was handed it**: the world they
## stand in, the run they belong to, the player and what she can see, and the live instances. One
## object, shared by `EventManager` and the parts it hands its work to (`EventStreaming`,
## `EventSpawner`, `WarningBoard`, `EventsAhead`, `CheckpointController`), so a world handed over
## once — a city's day, the escape's building, a rig's open ground — is the world every part sees.
## Nothing here is fetched: the manager hands each part in (`use_run()`, `use_player()`,
## `take_in()` and the rest), and every other part asks through the methods. What the world is in
## (its map, navigator, trace, drawing and where she is) is the one `EventSurroundings` it was made
## over, and every live event is set up in that same object (`surroundings()`).

## The live instances, in the order they came into the world (`instances()`). Shared by reference —
## the danger edge and the halo hold it across frames — so it is changed in place, never
## reassigned.
var _instances: Array[EventInstance] = []
## What the events are set up in (`surroundings()`): the map they stand on and the city's own, the
## navigator they move by, the run log, the world they are drawn in, the lights, the atlas and where
## she is. Handed in once, as the world is made, and the same object for every live event.
var _surroundings: EventSurroundings

## **A world over `surroundings`**, or over open ground with every default where none is handed (a
## suite's).
func _init(surroundings: EventSurroundings = null) -> void:
	_surroundings = surroundings if surroundings else EventSurroundings.new()

## The run these events belong to (`run()`).
var _run: RunState
## The player (`player()`), or null for none in the world.
var _player: Node2D
## Today's own day number (`day()`).
var _day := 0
## The run's mast sites (`MastSites.compute()`), worked out once when the manager is handed its city
## (`work_out_mast_sites()`) and handed to every dawn after (`mast_sites()`); none before.
var _mast_sites: Array[MastSites.Site] = []
## What she can see this frame — the one answer to "can she see it" for everything on a day
## (`VisibleView`): the screen-edge badge, the placing of what arrives from off screen, the
## fire's sighting, a chalk mark's notice and day 13's task guard's warning
## (`ResistanceDirector.set_sight()`, handed `EventManager.visible_view()` by `main`), the
## poster crews, the page's counter, and a charger already in the world or a vehicle letting men
## out, which warn only in sight (`WhereSheIs.view()`, which `EventManager` tells it each tick).
## What the resistance places and removes asks the siting's `DRAWING_OFF_THE_VIEW` of the same
## view instead. One instance for the day, never replaced, so a caller may keep it. Set at the
## top of each physics tick by `EventManager._look_through_the_camera()`. Asked as
## `visible_view()`.
var _visible := VisibleView.new()

## Today's streets (`streets()`), handed in by `EventManager.setup()`; null where the world is
## not the city.
var _streets: DayStreets
## The city's poster walls (`poster_walls()`), handed in by `EventManager.setup()`; null where there
## are none.
var _poster_walls: PosterWalls
## Builds a plan at a tile of the city (`plan_builder()`), handed in by `EventManager.setup()`; null
## where the world is not the city.
var _plan_builder: PlanBuilder

## Where she is this tick (`WhereSheIs`), told once a physics tick by
## `EventManager._tell_them_where_she_is()` while she is in the world: the surroundings' own, one
## for the world's whole life, so an instance keeps it.
func where_she_is() -> WhereSheIs:
	return _surroundings.where_she_is()

## What these events report to whoever listens (`reports()`): one for the world's whole life, never
## replaced, so a part and a live event keep it. Silent until the manager is handed a bus
## (`EventManager.use_bus()`).
var _reports := EventReports.new()

## **Where every part of these events says what happened** (`EventReports`): the manager, its
## spawner, `EventsAhead` and the doors' controller ask it here, and the encounter watch, each live
## event and its charge's record are handed the same one as they are made.
func reports() -> EventReports:
	return _reports

## **Today's streets as dawn left them** (`DayStreets`): the route tree, the region wall and doors
## and the closures a day is planned against (`DayPlanner`), and the region a siting reads. The
## city's own, handed in once and begun again every dawn; a rig that builds no city hands one it
## began itself. Null where the world is not the city (`EventSurroundings.city_map()`).
func streets() -> DayStreets:
	return _streets

## Hands the world today's streets. See `streets()`.
func use_streets(streets: DayStreets) -> void:
	_streets = streets

## **The city's poster walls** (`PosterWalls`), whose blank fronts a crew may paste on: asked for
## its fronts when a walk's siting is made (`EventsAhead`), never copied at setup, since the walls
## paste every dawn and the fronts are today's on each ask. Null where the world has none (the
## building, a rig that hands none).
func poster_walls() -> PosterWalls:
	return _poster_walls

## Hands the world the city's poster walls. See `poster_walls()`.
func use_poster_walls(walls: PosterWalls) -> void:
	_poster_walls = walls

## **The city's plan builder** (`PlanBuilder`), made once a city over its map: what the dawn
## (`DayPlanner`, handing it to its `DawnContext`), a siting made while she walks, the resistance's
## and the happenings' build a plan at a tile with. Null where
## the world is not the city (`EventSurroundings.city_map()`).
func plan_builder() -> PlanBuilder:
	return _plan_builder

## **The live instances**, in the order they came into the world: the one array, shared by
## reference (the danger edge and the halo hold it across frames), changed only by `take_in()`,
## `let_go()`, `keep_only()` and `let_go_of_every_event()`. A caller that changes the world while
## it walks the array walks a `duplicate()`.
func instances() -> Array[EventInstance]:
	return _instances

## Brings `instance` into the world, after the ones already there.
func take_in(instance: EventInstance) -> void:
	_instances.append(instance)

## Lets `instance` go from the world's list: it stays alive for whoever holds it.
func let_go(instance: EventInstance) -> void:
	_instances.erase(instance)

## Keeps only `survivors`, in their order, in the one shared array.
func keep_only(survivors: Array[EventInstance]) -> void:
	_instances.assign(survivors)

## Empties the world's list; the instances themselves are the caller's to take out.
func let_go_of_every_event() -> void:
	_instances.clear()

## **The map of the world these events stand in** (`WorldMap`): every instance is made on it and
## stopped by its walls, and its blocked record holds their bodies.
func map() -> WorldMap:
	return _surroundings.map()

## **The city's own map**, for planning a day over it — its holds, its route tree, its blocks — or
## null where the world is not the city; asked by a class that makes something over it
## (`SitingMaker`).
func city_map() -> CityMap:
	return _surroundings.city_map()

## The run these events belong to (`RunState`): its seed and day streams, its scars, its heat, the
## calm she has used this act and the pelican bag's draws. Null for a rig that hands none.
func run() -> RunState:
	return _run

## Hands the world the run its events belong to (`EventManager.setup()`).
func use_run(run: RunState) -> void:
	_run = run

## The player, or null for none in the world.
func player() -> Node2D:
	return _player

## Hands the world the player (`EventManager.use_player()`); null for none.
func use_player(player: Node2D) -> void:
	_player = player

## Today's own day number, kept for the streams drawn while the day runs (a summoned row's entry, a
## pursuer's start, the dusk fire) and for the rows a day sends.
func day() -> int:
	return _day

## Tells the world which day it is (`EventManager`, as a walk starts).
func take_the_day(day: int) -> void:
	_day = day

## Where the manager, the day's planning and every instance it creates write their own account for
## the run log (`EventSurroundings.trace()`).
func trace() -> RunTrace:
	return _surroundings.trace()

## What she can see this frame (`VisibleView`): the one instance for the world's life, so a caller
## may keep it. Named for what it answers, since `visible()` would read as a yes-or-no question.
func visible_view() -> VisibleView:
	return _visible

## A stream of the run's own for `day`, named `stream` (`RunState.run_rng()`): the same stream
## whenever it is asked, and a different one on another run's seed, so a part of the events seeds
## what it draws from it without reaching into the run (`SitingMaker`).
func day_stream(for_day: int, stream: String) -> RandomNumberGenerator:
	return _run.run_rng("%s:%d" % [stream, for_day])

## Hands the world the city's plan builder. See `plan_builder()`.
func use_plan_builder(builder: PlanBuilder) -> void:
	_plan_builder = builder

## How every figure made here moves over the map (`EventSurroundings.navigator()`).
func navigator() -> Navigator:
	return _surroundings.navigator()

## The world these events are drawn in (`WorldContext`): what every instance is added to
## (`EventSpawner.create()`) and handed (`EventInstance.setup()`), and what shows a row coming from
## outside the walls. Null for none, or one freed since, for a rig that draws nowhere.
func drawn_in() -> WorldContext:
	return _surroundings.world_drawn_in()

## Whether she is in the world: handed in, not freed since, and not stood aside for the title
## screen. `Stroller.stand_aside()` takes her out of the `player` group, which is the whole of
## "nobody is playing": the city plays on behind the title, and nothing streams around her, notices
## her, warns her or strikes her there, so a lethal thing on the doorstep cannot end a day nobody is
## playing. A rig's stand-in that is not a `Stroller` has no title to stand aside for.
func has_player() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	return not (_player is Stroller) or _player.is_in_group("player")

## **What a live event made here is set up in** (`EventSurroundings`): the one object the world was
## made over, the same for every event of it.
func surroundings() -> EventSurroundings:
	return _surroundings

## The run's catalogue every part of the world looks its rows up in
## (`EventSurroundings.rows()`).
func rows() -> EventCatalogue:
	return _surroundings.rows()

## **Works out the run's mast sites on `map`**, once, when the manager is handed its city: a mast's
## location is known from the start of the run (inbox #1185 in gentle-owl; `docs/EVENTS.md`, "The three views and
## the placement order"). The sites are the city's as built and are kept for the run: worked out on
## a later day's paint, a calm area grown or a tile changed can let a newly eligible candidate win
## the pick, so they are worked out once, here, and never again.
func work_out_mast_sites(map: CityMap) -> void:
	_mast_sites = MastSites.compute(rows(), map)

## The run's mast sites, as `work_out_mast_sites()` found them; empty before.
func mast_sites() -> Array[MastSites.Site]:
	return _mast_sites

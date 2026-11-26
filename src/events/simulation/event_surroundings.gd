class_name EventSurroundings
extends RefCounted
## **What every live event of a world is set up in** (`EventInstance.setup()`): the map it
## stands on and the navigator it moves by, where she is, the world it is drawn in, the pictures
## and the drawer it paints through, the screen box its look is gated by, whether it draws at
## all, which riders are drawn as the pelican, where it charges its time, the run log it writes to,
## the lights a car of it stops at and where a protest of it points its placards.
## **One value for a world's whole life**, built where the world is built and handed to its manager
## (`EventManager.new()`), which keeps it in its `EventWorld`: every live event of the world is
## handed the same one (`EventWorld.surroundings()`). An event keeps what it read of it when it was
## set up, so a later hand-in reaches only the events made after it; what an event asks each time
## follows a later hand-in: where a protest points (`pointing_protests_with()`) and the pelican rig
## the spawner asks on every roll (`rigging_the_pelican()`). It
## hears where she is through a handle on the one `WhereSheIs`, which the manager tells each tick.
## The game hands it nothing after the manager is set up but where a protest points, since the
## resistance that answers is built over the events.
##
## **Built by chaining**: `EventSurroundings.new().on(map).hearing(where)` and so on, each call
## returning the same object. It is the one place each default is stated: what is not handed is
## open ground with a navigator over it, a `WhereSheIs` that says she is nowhere, no world, a
## silent trace, the null timing sink, an atlas and a drawer of its own, a view with no screen
## (everything is drawn), drawn, the pelican left to the run's bag, no lights, protests pointing at
## nothing.

var _map: WorldMap = null
var _city_map: CityMap = null
var _navigator: Navigator = null
var _where_she_is := WhereSheIs.nowhere()
var _drawn_in: WorldContext = null
var _atlas: AtlasLibrary = null
var _drawer: EventDrawer = null
var _drawn_view := DrawnView.new()
var _draws := true
var _pelican_rig := EventSpawner.PelicanRig.BAG
var _timing := FrameTiming.new()
var _trace := RunTrace.new()
var _lights: TrafficSignals = null
var _where_protests_point := Callable()
var _rows: EventCatalogue = null

# ------------------------------------------------------------------- built with ---

## The map of the world it stands in (`WorldMap`).
func on(map: WorldMap) -> EventSurroundings:
	_map = map
	return self

## The map of a city's world (`CityMap`), which is the map it stands on and the city's own, to
## plan a day over (`city_map()`).
func in_the_city(map: CityMap) -> EventSurroundings:
	_map = map
	_city_map = map
	return self

## How a figure moves over the map (`Navigator`).
func moving_by(navigator: Navigator) -> EventSurroundings:
	_navigator = navigator
	return self

## Where she is (`WhereSheIs`), in place of the one it makes itself: the one its manager tells
## once a physics tick. Never null: hand none to keep its own.
func hearing(where: WhereSheIs) -> EventSurroundings:
	assert(where != null, "hearing() is handed a WhereSheIs, or none to keep its own")
	_where_she_is = where
	return self

## The world it is drawn in (`WorldContext`), or null for a rig that draws it in none.
func drawn_in(world: WorldContext) -> EventSurroundings:
	_drawn_in = world
	return self

## The baked atlas pages its pictures come from, which the drawer it makes for itself is built over.
func drawn_from(atlas: AtlasLibrary) -> EventSurroundings:
	_atlas = atlas
	return self

## What its look paints its pictures through (`EventDrawer`).
func drawing_through(drawer: EventDrawer) -> EventSurroundings:
	_drawer = drawer
	return self

## The box its look asks whether any of its drawing can be on the screen (`DrawnView`).
func shown_by(view: DrawnView) -> EventSurroundings:
	_drawn_view = view
	return self

## Nothing of it is drawn (`--skip events`).
func drawing_nothing() -> EventSurroundings:
	_draws = false
	return self

## Makes every rider the pelican, or none, or leaves it to the run's bag
## (`EventSpawner.rolls_a_pelican()`): `--pelican` is `PelicanRig.ALWAYS` (`SimulationBuilder`).
func rigging_the_pelican(rig: EventSpawner.PelicanRig) -> EventSurroundings:
	_pelican_rig = rig
	return self

## Where it charges its time to the frame record (`FrameTiming`).
func timed_by(timing: FrameTiming) -> EventSurroundings:
	_timing = timing
	return self

## Where it writes its account for the run log (`RunTrace`).
func tracing_to(trace: RunTrace) -> EventSurroundings:
	_trace = trace
	return self

## The lights a car that drives stops at (`TrafficSignals`): the crowd's own.
func stopping_at(lights: TrafficSignals) -> EventSurroundings:
	_lights = lights
	return self

## What a protest points its placards at: a Callable answering a world point, or `Vector2.INF`
## for nothing, asked each time a placard is drawn.
func pointing_protests_with(where: Callable) -> EventSurroundings:
	_where_protests_point = where
	return self

## **The run's catalogue** (`EventCatalogue`), what its events look a row up in by id: the row a
## thing calls in or leaves behind, a door's guard, the day's rows. The composition root's own,
## handed down from `main`; none where none was handed, and a world handed none looks no row up.
func reading(rows: EventCatalogue) -> EventSurroundings:
	_rows = rows
	return self

# --------------------------------------------------------------------- asked for ---

## The map it stands in: open ground where none was handed, where every street question answers "no
## street" and nothing is walled.
func map() -> WorldMap:
	if _map == null:
		_map = WorldMap.open_ground()
	return _map

## How a figure moves: the one handed, or one over `map()`, so a rig that walks a straight line on
## purpose gets exactly the unclamped movement it asks for.
func navigator() -> Navigator:
	if _navigator == null:
		_navigator = Navigator.new(map())
	return _navigator

## The city's own map, for planning a day over it, or null where the world is not the city.
func city_map() -> CityMap:
	return _city_map

## Where she is this tick: the one handed, or the one it made, which says she is nowhere until her
## manager tells it otherwise.
func where_she_is() -> WhereSheIs:
	return _where_she_is

## The world it is drawn in, or null where none was handed or it was freed since.
func world_drawn_in() -> WorldContext:
	if _drawn_in == null or not is_instance_valid(_drawn_in):
		return null
	return _drawn_in

## The baked atlas pages its pictures come from: the one handed, or one of its own.
func atlas() -> AtlasLibrary:
	if _atlas == null:
		_atlas = AtlasLibrary.new()
	return _atlas

## What its look paints through: the one handed, or one of its own over `atlas()`.
func drawer() -> EventDrawer:
	if _drawer == null:
		_drawer = EventDrawer.new(atlas())
	return _drawer

## The box its look asks, or one with no screen, which shows everything.
func drawn_view() -> DrawnView:
	return _drawn_view

## The run's catalogue its events look rows up in (`reading()`), or null where none was handed:
## a suite's world whose events look no row up.
func rows() -> EventCatalogue:
	return _rows

## Whether it draws at all.
func draws() -> bool:
	return _draws

## Which riders are drawn as the pelican: the run's bag's own marble unless a rig says otherwise
## (`rigging_the_pelican()`).
func pelican_rig() -> EventSpawner.PelicanRig:
	return _pelican_rig

## Where it charges its time; the null sink where none was handed.
func timing() -> FrameTiming:
	return _timing

## Where it writes its account for the run log; silent where none was handed.
func trace() -> RunTrace:
	return _trace

## The lights a car stops at, or null where there are none (a rig with no city).
func lights() -> TrafficSignals:
	return _lights

## Where a protest points its placards now, or `Vector2.INF` where it was handed nothing to ask.
func where_protests_point() -> Vector2:
	if not _where_protests_point.is_valid():
		return Vector2.INF
	return _where_protests_point.call()

class_name EventSurroundings
extends RefCounted
## **What every live event of a world is set up in** (`EventInstance.setup()`): the map it stands
## on and the navigator it moves by, where she is, the world it is drawn in, the pictures and the
## drawer it paints through, whether it draws at all, where it charges its time, the run log it
## writes to, the lights a car of it stops at and where a protest of it points its placards.
## One value built for each live event (`EventWorld.surroundings()`, from the world's own
## hand-ins), so the event keeps what it asks and nothing writes to it after it is set up.
##
## **Built by chaining**: `EventSurroundings.new().on(map).hearing(where)` and so on, each call
## returning the same object. What is not handed has a default a rig that names nothing gets: open
## ground with a navigator over it, nowhere, no world, a silent trace, the null timing sink, a
## drawer of its own over the atlas, drawn, no lights, protests pointing at nothing.

var _map: WorldMap = null
var _navigator: Navigator = null
var _where_she_is: WhereSheIs = null
var _drawn_in: WorldContext = null
var _atlas: AtlasLibrary = null
var _drawer: EventDrawer = null
var _draws := true
var _timing := FrameTiming.new()
var _trace := RunTrace.new()
var _lights: TrafficSignals = null
var _where_protests_point := Callable()

# ------------------------------------------------------------------- built with ---

## The map of the world it stands in (`WorldMap`).
func on(map: WorldMap) -> EventSurroundings:
	_map = map
	return self

## How a figure moves over the map (`Navigator`).
func moving_by(navigator: Navigator) -> EventSurroundings:
	_navigator = navigator
	return self

## Where she is (`WhereSheIs`), the one its manager tells once a physics tick.
func hearing(where: WhereSheIs) -> EventSurroundings:
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

## Nothing of it is drawn (`--skip events`).
func drawing_nothing() -> EventSurroundings:
	_draws = false
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

## Where she is, or null where none was handed (the event is then told she is nowhere).
func where_she_is() -> WhereSheIs:
	return _where_she_is

## The world it is drawn in, or null (what `drawn_in()` handed).
func world_drawn_in() -> WorldContext:
	return _drawn_in

## What its look paints through: the one handed, or one of its own over the atlas.
func drawer() -> EventDrawer:
	if _drawer == null:
		_drawer = EventDrawer.new(_atlas)
	return _drawer

## Whether it draws at all.
func draws() -> bool:
	return _draws

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

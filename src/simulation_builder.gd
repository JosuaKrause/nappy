class_name SimulationBuilder
extends RefCounted
## **Stands the simulation in a world already built** (`WorldSimulation`): the one place an event
## manager and a crowd are made, so the city and the escape's building get theirs the same way
## *(minty-lemur #785: "the escape is just like a normal day with some special settings")*. Part of
## the composition root: `main` makes one a boot, hands it what every part is equipped with and what
## the developer's flags decide, and asks it for the city's simulation and the building's.
##
## **Handed everything, and its defaults are an ordinary run's**: a builder handed nothing stands a
## silent, unrecorded simulation with a library of its own, which is what a suite's own city gets.
##
## **A world scene builds no part of this.** The city scene (`City`) and the building
## (`InteriorScene`) draw their ground and furniture and name nothing that moves on it; the builder
## is handed the parts of the world each simulation part reads, and tells the world what charges her
## there (`WorldContext.use_excitement_sources()`).

## The event bus script, so the bus handed on has a class.
const _BUS := preload("res://src/autoload/event_bus.gd")

## Where every part writes its own account for the run log; silent until handed one.
var _trace := RunTrace.new()
## The baked atlas pages every part draws from; a part handed none makes its own.
var _atlas: AtlasLibrary = null
## Where the events charge their time to the frame record; none until handed, and until then the
## events charge it to the null sink their surroundings hold.
var _timing: FrameTiming = null
## The bus the events, the crowd, the poster walls and the blackout report on; none, and they tell
## nobody.
var _bus: _BUS = null
## The torn posters' textures, composed once a boot and handed to every city's walls.
var _poster_art := PosterArt.new()
## What the crowd is handed of the screen and of the frame record: no screen (always drawn) and
## the null sink until handed others.
var _crowd_view: CrowdView = null
## The box every live event's look is asked against, put in the events' surroundings; a view
## with no screen (everything drawn) until handed one.
var _drawn_view := DrawnView.new()
var _crowd_timing := CrowdTiming.new()
## `--skip events`, `--skip crowd` and `--skip motion`: what a frame reading leaves out.
var _skip_event_drawing := false
var _skip_crowd_drawing := false
var _skip_crowd_motion := false
## `--pelican`: every cyclist is drawn as the pelican.
var _every_cyclist_a_pelican := false
## `--force <id> [seconds]`: the one row the city's director hands out, and how often.
var _forced_row := ""
var _forced_interval := 0.0
## `--blackout`: a city counts as sabotaged.
var _blackout_forced := false

## Hands the builder what every part is equipped with: the trace it writes to, the atlas pages it
## draws from and the frame record's sink the events charge their time to.
func equip(trace: RunTrace, atlas: AtlasLibrary, timing: FrameTiming) -> void:
	_trace = trace
	_atlas = atlas
	_timing = timing

## Hands the builder the bus the events, the crowd, the poster walls and the blackout report on.
func use_bus(bus: _BUS) -> void:
	_bus = bus

## Hands the builder the torn posters' textures every city's walls draw through.
func use_poster_art(art: PosterArt) -> void:
	_poster_art = art

## Hands the builder the one drawn view of the screen (`DrawnView`) every live event of a world is
## set up with.
func use_the_drawn_view(view: DrawnView) -> void:
	_drawn_view = view

## Hands the builder what a crowd is handed of the screen (`CrowdView`, null for none: always
## drawn) and of the frame record (`CrowdTiming`).
func use_the_crowds_screen(view: CrowdView, timing: CrowdTiming) -> void:
	_crowd_view = view
	_crowd_timing = timing

## `--skip events`, `--skip crowd` and `--skip motion` (`DevFlags.skip_words()`): the events' and
## the crowd's own drawing left out, and the crowd standing still.
func leave_out(event_drawing: bool, crowd_drawing: bool, crowd_motion: bool) -> void:
	_skip_event_drawing = event_drawing
	_skip_crowd_drawing = crowd_drawing
	_skip_crowd_motion = crowd_motion

## `--pelican`: every cyclist is drawn as the pelican (`EventSpawner.PelicanRig.ALWAYS`).
func make_every_cyclist_a_pelican() -> void:
	_every_cyclist_a_pelican = true

## `--force <id> [seconds]`: the one row a city's director hands out, every `interval` seconds, or
## "" for the ordinary day (`EventManager.force()`).
func force_a_row(row: String, interval: float) -> void:
	_forced_row = row
	_forced_interval = interval

## `--blackout`: every city stood from here on counts as sabotaged (`Blackout`).
func force_the_blackout() -> void:
	_blackout_forced = true

## **A city's simulation**, standing under `world`, the city scene: the poster walls over
## `buildings`, the day's events on `map` against today's `streets` and the `signals`, the crowd,
## and the blackout, in that order (the walls before the events, which site a crew in front of a
## blank front; the events before the crowd, whose cars a body placed after dawn recycles; all
## three before the blackout, which silences the events' masts). `run` is the run they belong to.
## `dark_from_the_start` is the escape's city, dark from its first frame
## (`DaySpec.is_dark_from_the_start()`).
##
## `navigator` is the city's own (`City.navigator()`), the one the events and the crowd move by (`main`
## hands the same to the resistance).
##
## `world` is told what charges her on its streets, and its day's dressing is what the walls paste
## by (`CityDressing.day_dressed`).
func in_the_city(world: CityDressing, map: CityMap, navigator: Navigator, streets: DayStreets,
		signals: TrafficSignals, buildings: Array[Building], run: RunState,
		dark_from_the_start := false) -> WorldSimulation:
	var simulation := _stand_under(world)

	var posters := PosterWalls.new()
	posters.name = "Posters"
	posters.equip(_trace, _poster_art, _atlas)
	posters.use_bus(_bus)
	simulation.add_child(posters)
	posters.setup(buildings, map, run, streets)
	world.day_dressed.connect(posters.dress_for)

	var events := _new_events(_the_events_surroundings(world).in_the_city(map)
			.moving_by(navigator).stopping_at(signals))
	simulation.add_child(events)
	events.setup(run, streets, posters)
	events.force(_forced_row, _forced_interval)
	posters.watch_events(events)

	var crowd := Crowd.new()
	crowd.name = "Crowd"
	crowd.skip_agent_drawing = _skip_crowd_drawing
	crowd.skip_motion = _skip_crowd_motion
	crowd.view = _crowd_view
	crowd.timing = _crowd_timing
	crowd.atlas = _atlas
	crowd.use_bus(_bus)
	simulation.add_child(crowd)
	crowd.setup(world, map, signals, streets, navigator)
	# A body placed on her walk that stands on a lane takes the car there away, where she cannot see.
	events.use_body_listener(crowd.recycle_cars_on)

	var blackout := Blackout.new()
	blackout.name = "Blackout"
	blackout.use_bus(_bus)
	simulation.add_child(blackout)
	blackout.setup(map, buildings, signals, events, run.resistance(), _blackout_forced,
			dark_from_the_start)

	simulation.hold_the_events(events)
	simulation.hold_the_city_parts(crowd, posters, blackout)
	world.use_excitement_sources(simulation.excitement_sources())
	return simulation

## **The simulation of a world that is not the city**, standing under `world`: the escape's
## building, whose events stand on `map` and belong to `run`. The whole plan is in the world at
## once (`EventManager.stream_within()`), since the building is walked part by part through doors;
## no crowd, no walls to paste, no power to cut. `navigator` is the building's own
## (`InteriorScene.navigator()`), the one its events move by.
func in_the_building(world: WorldContext, map: WorldMap, navigator: Navigator,
		run: RunState) -> WorldSimulation:
	var simulation := _stand_under(world)
	var events := _new_events(_the_events_surroundings(world).on(map).moving_by(navigator))
	events.stream_within(INF)
	simulation.add_child(events)
	events.setup(run)
	simulation.hold_the_events(events)
	world.use_excitement_sources(simulation.excitement_sources())
	return simulation

## The simulation's own node, under the world it stands in. A builder handed no atlas makes one
## library here, for every part it stands from now on, as a city handed none makes its own.
func _stand_under(world: WorldContext) -> WorldSimulation:
	if _atlas == null:
		_atlas = AtlasLibrary.new()
	var simulation := WorldSimulation.new()
	simulation.name = WorldSimulation.NODE_NAME
	world.add_child(simulation)
	return simulation

## **What the events of a world are set up in, the one way for every world**: its trace, its
## atlas, its frame timing, the drawn view, and whether they skip their drawing, drawn in
## `world`. The caller adds the map and what it moves by.
func _the_events_surroundings(world: WorldContext) -> EventSurroundings:
	var surroundings := EventSurroundings.new().drawn_in(world).tracing_to(_trace) \
			.drawn_from(_atlas).shown_by(_drawn_view)
	if _timing != null:
		surroundings.timed_by(_timing)
	if _skip_event_drawing:
		surroundings.drawing_nothing()
	return surroundings

## **An event manager over `surroundings`, equipped the one way for every world**: the bus it
## reports on, and the pelican rig, which only a cyclist asks. Not yet in the tree: it takes its
## atlas page as it enters.
func _new_events(surroundings: EventSurroundings) -> EventManager:
	var events := EventManager.new(surroundings)
	events.name = "Events"
	events.use_bus(_bus)
	if _every_cyclist_a_pelican:
		events.rig_the_pelican(EventSpawner.PelicanRig.ALWAYS)
	return events

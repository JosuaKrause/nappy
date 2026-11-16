class_name WorldSimulation
extends Node
## **Everything that moves or happens in one world, as its builder stood it** (`SimulationBuilder`):
## the day's events, and in a city the crowd on its streets, the posters on its fronts and the last
## night's blackout. The escape's building has its events and nothing else.
##
## **A node under the world it stands in**, with its parts as its children, so the whole simulation
## pauses, runs on behind the title and is freed with its world (`process_mode` is inherited), and
## so whoever built the world holds one thing for it: `main` holds the city's and the building's,
## and hands their parts on to the day director (`DayWorld`), the resistance, the observers and the
## rigs. Nothing below fetches it.
##
## **A world has its events; a city has all four parts** (`is_in_a_city()`'s answer on `DayWorld`
## is the one the run flow keys on): `crowd()` and `poster_walls()` are null in the building.

## The name its builder gives the node, under the world it stands in.
const NODE_NAME := "Simulation"

var _events: EventManager
var _crowd: Crowd
var _posters: PosterWalls
var _blackout: Blackout
## What charges her in this world, in the order the pairs are summed: the events, then the crowd
## where there is one. The same sets the world was handed (`WorldContext.use_excitement_sources()`).
var _sources: Array[ExcitementSources] = []

## Takes the events standing in the world: every simulation has them. Called once by the builder.
func hold_the_events(events: EventManager) -> void:
	_events = events
	_sources = [events.sources]

## Takes a city's own parts beside its events: the crowd, the poster walls and the blackout. Called
## once by the builder, for a city.
func hold_the_city_parts(crowd: Crowd, posters: PosterWalls, blackout: Blackout) -> void:
	_crowd = crowd
	_posters = posters
	_blackout = blackout
	_sources = [_events.sources, crowd.sources]

## The day's events in this world.
func events() -> EventManager:
	return _events

## The crowd on the city's streets, or null in a world with no streets.
func crowd() -> Crowd:
	return _crowd

## The posters on the city's fronts, or null in a world with none.
func poster_walls() -> PosterWalls:
	return _posters

## The sets of things that charge her in this world (`ExcitementSources`), the events' first and
## then the crowd's where there is one: what the halo is handed, and the same sets the world answers
## the baby from.
func excitement_sources() -> Array[ExcitementSources]:
	return _sources

## **Hands her to what meets her on the streets**: the crowd, which makes way for her, bumps her
## and may strike her; the poster walls, whose sheets she tears and whose crews paste while she
## watches; and the blackout, which waits until she is far enough from the station. Called from the
## moment the world is live and she walks it (`main._hand_the_streets_her()`), never behind the
## title, where she stands aside. The events are handed her when she is put into the world
## (`EventManager.use_player()`), a different moment. Nothing in a world with no city parts.
func meet_her(player: Stroller) -> void:
	if _crowd:
		_crowd.use_player(player)
	if _posters:
		_posters.use_player(player)
	if _blackout:
		_blackout.use_player(player)

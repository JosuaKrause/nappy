class_name KeepingSitingMaker
extends SitingMaker
## The game's maker (`SitingMaker`) that keeps every siting it makes, for a suite or a probe that
## reads what the day's siting did (`WalkSiting.waits()`) or asks it a
## question of its own, since `EventsAhead` keeps its siting to itself. It is handed to
## `EventsAhead.use_sitings()` before the day starts (`on()`). A helper, not a suite: the runner
## loads only `test_*.gd`.

## Every siting made, in order.
var made: Array[WalkSiting] = []

## A keeping maker over `events`' world and walk, handed to its events as the maker of every siting
## from here on.
static func on(events: EventManager) -> KeepingSitingMaker:
	var keeper := KeepingSitingMaker.new(events.world, events.walk_events())
	events.ahead.use_sitings(keeper)
	return keeper

## The siting made last: the day's once the day has one; else the one a queued mast made (a day with
## none of its own makes it, keeps it nowhere and asks again for the next mast); null where none
## was made since `on()`. A keeper left on across two days answers the earlier day's siting on a day
## that made none, so a caller installs it before the day it reads.
func latest() -> WalkSiting:
	return made.back() if not made.is_empty() else null

## Overrides SitingMaker.make.
func make(day: int, tree: RouteTree, ground: RowGround) -> WalkSiting:
	var siting := super(day, tree, ground)
	made.append(siting)
	return siting

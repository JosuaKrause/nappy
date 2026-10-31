class_name BuildingPlan
extends RefCounted
## **What the escape's building places, and where**: the building's own hand on the day's machinery.
## The player allows the building its own way of placing events and nothing else of its own
## (minty-lemur #785), so this is the whole of what is the building's: a list of plans
## (`EventScheduler.Planned`), asked for by the day's planner when the walk is the building's
## (`DayPlanner`), that the day's `EventManager` runs exactly as it runs any plan — streamed in, told
## where she is, summed into the meter, its catches ending the section with their cause — with the
## building's map under them (`InteriorMapPlan`).
##
## *"We can keep the events inside the house relatively minimal"*, so at most one of each: the fire
## on one stairwell, the masked man coming up the other again and again, the mouse and the steam in
## the basement, and the explosions outside. **Deterministic from the stream handed in**, so a retry
## handed the same seed is the same building rather than an easier one.

## Which stairwell the fire closes, and it is **always the left one** *(2026-09-19: "there should be
## a fire on the left like it is right now but the top floor right side should be completely blocked
## off with rubble")*. The two have to agree: the rubble shuts the right stairwell off the top floor,
## so a fire on the right as well would leave her nothing to walk down from her own door. The masked
## man takes the other shaft, which is the whole of why the fire is worth having: the way past a fire
## is the other egress, and the other egress has somebody on it.
const BURNING_SIDE := "left"
## The shaft the masked man runs, the one the fire did not take.
const PURSUED_SIDE := "right"

## The building's plans, from `map` and `rng`, in the order they come into the world.
static func plan(map: InteriorMapPlan, rng: RandomNumberGenerator) -> Array[EventScheduler.Planned]:
	var plans: Array[EventScheduler.Planned] = []
	_place_the_fire(map, plans)
	_place_the_masked_man(map, plans)
	_place_the_basement(map, rng, plans)
	_place_the_explosions_outside(plans)
	return plans

## The fire, on the **inner** cell of the second floor's level approach in the burning shaft
## (`InteriorMapPlan.inner_floor_approaches()`), **always that floor, never a roll**: named rather
## than taken from the head of that list, which would quietly become the first floor's if the
## second floor's cell stopped being walkable. It closes the flight from the second floor down, so
## her walk from the top is left, then right: the rubble sends her down the burning shaft from the
## third floor and the fire makes her cross over at the second. The way on from the first floor is
## not forced: the right shaft reaches the lobby and the left stays open too, which is where the
## masked man coming up the right shaft pushes her.
##
## On the outer cell — the door's own — its body would close the way out of the stairwell as well as
## the way down it. One cell in it closes exactly the flight that approach leads onto, and every door
## in the shaft stays reachable: its reach is its own 30px body plus her 14px, and the door tile is
## 64px from the cell it stands on.
static func _place_the_fire(map: InteriorMapPlan, plans: Array[EventScheduler.Planned]) -> void:
	var landing := map.waypoint("stairwell_%s:landing_second" % BURNING_SIDE)
	var at := landing + Vector2i.DOWN
	if landing == InteriorMapPlan.NOWHERE or not map.is_walkable(at):
		push_error("the second floor's approach in the %s shaft is not walkable" % BURNING_SIDE)
		return
	plans.append(EventScheduler.Planned.new(EventCatalogue.building_fire(), map.tile_to_world(at)))

## The masked man, at the foot of the shaft the fire did not take, running its whole height, and
## another of him this long after the last has run out of the top (`masked_pursuer.repeat_after`).
##
## **His path is the staircase itself** (`InteriorMapPlan.stairwell_walk()`): the shaft's own
## branchless walk, landing to landing, so every step he takes is ground she could be standing on.
## **Which is also what leaves her the answer the brief gives him**, *"going into a corridor and
## letting them pass"*: a shaft's walk never stands on a door's cell, so a door is always further
## from his line than the radius that takes the baby (`tests/test_interior.gd` measures the gap).
static func _place_the_masked_man(map: InteriorMapPlan,
		plans: Array[EventScheduler.Planned]) -> void:
	var walk := map.stairwell_walk("stairwell_%s" % PURSUED_SIDE)
	if walk.size() < 2:
		return
	var path := PackedVector2Array()
	for tile in walk:
		path.append(map.tile_to_world(tile))
	plans.append(EventScheduler.Planned.new(EventCatalogue.by_id("masked_pursuer"), path[0], path))

## The mouse a third of the way along the basement's own corridor, and the vents on its narrows.
##
## Measured as a walk from the entry rather than written as tile offsets, so nothing here depends on
## the basement's bands staying where they are: the corridor is one route with no branches, so "a
## third of the way along it" stands somewhere she has to pass.
##
## **The vents are not rolled** — *"multiple fixed locations"* — so a lost section is the same puzzle
## again: each on its own narrow (`InteriorMapPlan.vent_sites()`), each coming again on its own period
## out of `Tuning.FINALE_STEAM_PERIODS`, and staggered so the three do not open the whole corridor at
## once on the first pass; after that their own periods do it. Between blows there is no instance at
## all, so a vent that is off costs nothing and stops nobody; its grate stays on the floor
## (`grates()`).
static func _place_the_basement(map: InteriorMapPlan, rng: RandomNumberGenerator,
		plans: Array[EventScheduler.Planned]) -> void:
	var walk := map.basement_walk()
	if walk.size() < 4:
		return
	var mouse_at: Vector2i = walk[walk.size() / 3]
	plans.append(EventScheduler.Planned.new(EventCatalogue.by_id("alley_mouse"),
			map.tile_to_world(mouse_at)))
	# Spent to keep the stream where it has always been: the mouse's dash is its own short
	# crossing indoors (`EventInstance._alley_crossing_path()`), with no alley to roll one from.
	rng.randf()
	var sites := map.vent_sites()
	var periods: Array[float] = Tuning.FINALE_STEAM_PERIODS
	if sites.size() != periods.size():
		push_error("the basement corridor offers %d one-tile gates for %d steam vents"
				% [sites.size(), periods.size()])
		return
	var steam := EventCatalogue.by_id("basement_steam")
	for i in sites.size():
		var vent := EventScheduler.Planned.new(steam, sites[i])
		vent.repeat_every = periods[i]
		vent.comes_in = periods[i] * float(i + 1) / float(sites.size())
		plans.append(vent)

## The explosions outside: every `Tuning.FINALE_EXPLOSION_INTERVAL`, the first one interval in, the
## row's charge where she is with its notice over (`EventCatalogue.explosion_outside()`), and every
## window lit as it comes.
static func _place_the_explosions_outside(plans: Array[EventScheduler.Planned]) -> void:
	var row := EventCatalogue.explosion_outside()
	var bang := EventScheduler.Planned.new(row, Vector2.INF)
	bang.at_her = true
	bang.comes_in = row.repeat_every
	bang.arrives_aged = row.telegraph_time
	bang.age = bang.arrives_aged
	plans.append(bang)

## **Where each vent's floor grate lies, for the whole escape**: on each vent's own point
## (`InteriorMapPlan.vent_sites()`). A gate she can see only while it is shut is one she finds by
## walking into its notice; a grate lying in the corridor, blowing or not, is one she sees from the
## corner and times. So the grate is floor owned by the vent's place rather than by any blow's
## picture, and each blow's cloud rises out of it. Where it lies is the building's; drawing it is a
## view's (`SteamGrates.lay()`).
static func grates(map: InteriorMapPlan) -> Array[Vector2]:
	return map.vent_sites()

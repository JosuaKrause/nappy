extends RefCounted
## **The escape's building with its events, as the game runs them**: the day's own `EventManager`
## handed the building's map (`EventManager.setup_world()`), the whole plan in the world at once, and
## the building's own placements started on it (`BuildingPlan.plan()`, `start_planned()`), from the
## seed `rng` draws, as `main` draws it from the run's. Shared by `tests/test_interior.gd`,
## `tests/test_wall_shield.gd`, `tests/basement_walk_rig.gd` and the probes that walk the building.

## The building's events in `scene`, added under `parent`, started from `rng`'s next draw. The seed
## is kept on the manager's metadata so `restart()` starts the same building again.
static func events_in(parent: Node, scene: InteriorScene,
		rng: RandomNumberGenerator) -> EventManager:
	var events := EventManager.new()
	events.stream_radius = INF
	parent.add_child(events)
	events.setup_world(scene.map, GameState)
	scene.events = events
	events.set_meta(&"building_seed", rng.randi())
	restart(events, scene)
	return events

## Starts the building's plan over on `events`, as every entry into the section does: the same
## seed, so the same building.
static func restart(events: EventManager, scene: InteriorScene) -> void:
	var seed: int = events.get_meta(&"building_seed")
	events.start_planned(spec(), BuildingPlan.plan(scene.map, seed),
			scene.map.start_world_position())
	scene.start_the_night(seed)

## The building section's own spec.
static func spec() -> DaySpec:
	return DaySpec.for_section(DaySpec.Section.BUILDING, Tuning.FINALE_LENGTH_SECONDS)

## The basement's vents: the steam plans, in the order she meets them.
static func vents(events: EventManager) -> Array[EventScheduler.Planned]:
	var found: Array[EventScheduler.Planned] = []
	for plan in events.plans():
		if plan.def.id == "basement_steam":
			found.append(plan)
	return found

## The live instance of the row `id`, or null.
static func live(events: EventManager, id: String) -> EventInstance:
	for instance in events.instances():
		if instance.def.id == id:
			return instance
	return null

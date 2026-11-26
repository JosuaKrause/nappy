extends RefCounted
## **The escape's building with its events, as the game runs them**: the day's own `EventManager`
## over the building's map (`EventSurroundings.on()`), the whole plan in the world at once, and
## the building's walk started on it (`EventManager.start_day()` with the building's spec, which
## plans the building's own placements, `BuildingPlan.plan()`), from the seed `rng` draws, as
## `main` draws it from the run's. Shared by `tests/test_interior.gd`,
## `tests/test_wall_shield.gd`, `tests/basement_walk_rig.gd` and the probes that walk the building.

## The building's events in `scene`, added under `parent`, started from `rng`'s next draw. The seed
## is kept on the manager's metadata so `restart()` starts the same building again. The manager is
## handed `run`, the caller's own `RunState`, and `atlas` as the pages it draws from where the caller
## holds them (a manager handed none makes its own on entering the tree).
static func events_in(parent: Node, scene: InteriorScene,
		rng: RandomNumberGenerator, run: RunState, atlas: AtlasLibrary = null) -> EventManager:
	var surroundings := EventSurroundings.new().reading(Shipped.rows()) \
			.on(scene.map()).moving_by(scene.navigator()) \
			.drawn_in(scene)
	if atlas != null:
		surroundings.drawn_from(atlas)
	var events := EventManager.new(surroundings)
	events.use_bus(EventBus)
	events.stream_within(INF)
	parent.add_child(events)
	events.setup(run)
	var sets: Array[ExcitementSources] = [events.excitement_sources()]
	scene.use_excitement_sources(sets)
	events.set_meta(&"building_seed", rng.randi())
	restart(events, scene)
	return events

## Starts the building's plan over on `events`, as every entry into the section does: the same
## seed, so the same building.
static func restart(events: EventManager, scene: InteriorScene) -> void:
	var seed: int = events.get_meta(&"building_seed")
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var none: Array[String] = []
	events.start_day(spec(), rng, none, scene.map().start_world_position())
	scene.start_the_night(seed)

## The building section's own spec.
static func spec() -> DaySpec:
	return DaySpec.for_section(DaySpec.Section.BUILDING, RunConfig.FINALE_LENGTH_SECONDS)

## The basement's vents: the steam plans, in the order she meets them.
static func vents(events: EventManager) -> Array[EventPlan]:
	var found: Array[EventPlan] = []
	for plan in events.plans():
		if plan.row_id() == "basement_steam":
			found.append(plan)
	return found

## **The masked man in the world, for a case about his line, his catch or his field**, where how he
## came does not matter: made by the manager on his plan's own line from the foot of his shaft
## (`EventManager.spawn_extra()`), his telegraph spent as a place that set him off spends it
## (`EventSpawner.age_when_warned()`). How a place sets him off is `test_interior_masked_man.gd`'s.
## Null where the building plans none.
static func masked_man(events: EventManager) -> EventInstance:
	for plan in events.plans():
		if plan.row_id() == "masked_pursuer":
			var man := events.spawn_extra(plan.row(), plan.placed_at(), plan.walks())
			man.restore(EventSave.aged(EventSpawner.age_when_warned(plan.row())))
			return man
	return null

## The live instance of the row `id`, or null.
static func live(events: EventManager, id: String) -> EventInstance:
	for instance in events.instances():
		if instance.row_id() == id:
			return instance
	return null

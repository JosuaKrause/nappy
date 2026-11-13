class_name DawnScripted
extends DawnPhase
## **The scripted rows' dawn phase**: each scripted row of the day (day 10's night raid, day 13's
## firefight) draws one of the day's open locations its ground takes and is assigned it
## (`ScriptedPhase`), offered through the dawn draw's own path (`RuledLocationGround`) and judged by
## the day's rules, so the draw after passes over it. A row sited while she walks is owed here with
## no position, as every such row is. The glue only: which location a row draws is
## `ScriptedPhase`'s. Model: no node.

## The phase's stream salt off the day's seed (`DawnContext.stream()`).
const SALT := 1

## Overrides DawnPhase.run.
func run(context: DawnContext) -> void:
	var day := context.day()
	var map := context.map()
	var events := context.events()
	var ground := context.ground()
	var phase_ground := RuledLocationGround.new(day, context.day_seed(), map, events,
			context.corridor(), LocationFit.new(day, map, context.builder(), ground),
			context.rules(), ground)
	var weigh := func(def: EventDef, location: Location) -> float:
		return _weight_in(def, location, day, map, ground)
	var phase := ScriptedPhase.new(context.locations(), phase_ground, weigh)
	var rng := context.stream(SALT)
	for def in EventCatalogue.of_kind(GameEnums.EventKind.SCRIPTED, day, context.heat()):
		# A row sited while she walks is owed here with no position, as every such row is.
		if def.spawn_mode_on(day) != EventDef.SpawnMode.MAP:
			events.add(EventPlan.new(def, Vector2.INF))
			continue
		phase.place(def.for_day(day), rng)

## How strongly `def`'s dawn phase draws `location`: how many times the day's ground offers the row,
## placed for its role, each tile of the location it may stand on
## (`RowGround.offers_for_role()`, whose role weights keep a wall off the route and draw friction
## onto it), summed; 0 where it may stand on none.
static func _weight_in(def: EventDef, location: Location, day: int, map: CityMap,
		ground: RowGround) -> float:
	var by_tile := ground.offers_for_role(def, EventScheduler.role_for(def, day))
	var weight := 0
	var rect := location.tiles()
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var tile := Vector2i(x, y)
			if by_tile.has(tile) and location.takes(map.tile_at(tile)):
				weight += int(by_tile[tile])
	return float(weight)

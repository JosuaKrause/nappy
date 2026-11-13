class_name DawnMoments
extends DawnPhase
## **The moments' dawn phase**: the moments the day owes her (`AHEAD_OF_PLAYER` and
## `TOWARD_PLAYER` rows, the cat that bolts across, the cyclist, the loose dog): sited in front of
## her by the director, on its own clock and from its own bag (`EventDirector`; the orchestrator's
## reading of fork 9: a moment is not a place), so the day only says how many.
## `EventScheduler.MOMENTS_PER_DAY` of them, as today's placement bought on that day, each a row
## drawn by weight among today's, at most its `max_per_day` where the spec keeps the caps.
##
## Model: no node.

## The phase's stream salt off the day's seed (`DawnContext.stream()`).
const SALT := 7

## Overrides DawnPhase.run.
func run(context: DawnContext) -> void:
	var day := context.day()
	var events := context.events()
	var caps := context.spec().caps_per_day
	var rng := context.stream(SALT)
	var rows: Array[EventDef] = []
	for def in EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day, context.heat()):
		var mode := def.spawn_mode_on(day)
		if mode == EventDef.SpawnMode.AHEAD_OF_PLAYER or mode == EventDef.SpawnMode.TOWARD_PLAYER:
			rows.append(def)
	var owed := {}
	for _i in int(EventScheduler.MOMENTS_PER_DAY[clampi(day, 1, 14) - 1]):
		var open: Array[EventDef] = []
		var total := 0.0
		for def in rows:
			if not caps or int(owed.get(def.id, 0)) < def.most_in_a_day():
				open.append(def)
				total += def.drawn_as_often()
		if open.is_empty():
			return
		var roll := rng.randf() * total
		var chosen: EventDef = open.back()
		for def in open:
			roll -= def.drawn_as_often()
			if roll <= 0.0:
				chosen = def
				break
		owed[chosen.id] = int(owed.get(chosen.id, 0)) + 1
		events.add(EventPlan.new(chosen, Vector2.INF))

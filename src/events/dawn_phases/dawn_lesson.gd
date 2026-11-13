class_name DawnLesson
extends DawnPhase
## **The run lesson's dawn phase.**
##
## The day the run is taught cannot leave the lesson to a weighted roll.
##
## `EventDirector._teach_the_run` moves a pursuit to the head of the owed list on `RUN_TAUGHT_DAY`,
## and if the day happened to owe none there is nothing to teach. `charging_dog` is weight 1.4 of
## a day-3 pool, so whole day 3s with none of them exist — and a player can reach act II never
## having been shown the one control the game will later require.
##
## It is added **outside** the day's draws rather than competing in them, and that is the exception
## being made honestly: everywhere else at dawn the density is the bags', and a lesson that only
## happens when the dice agree is not a lesson. One event on one day of fourteen.
##
## Model: no node.

## Overrides DawnPhase.run.
func run(context: DawnContext) -> void:
	var day := context.day()
	var events := context.events()
	if day != Tuning.RUN_TAUGHT_DAY or events.has_a_pursuit():
		return
	for def in EventCatalogue.available_on(day, context.heat()):
		if def.pursuit == null or def.spawn_mode != EventDef.SpawnMode.AHEAD_OF_PLAYER:
			continue
		events.add(EventPlan.new(def, Vector2.INF))
		context.note("plan", "day %d owes no pursuit, so the run lesson is added: %s"
				% [day, def.id])
		return

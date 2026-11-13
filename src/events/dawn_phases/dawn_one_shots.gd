class_name DawnOneShots
extends DawnPhase
## **The one-shots' dawn phase**: every one-shot of the day the run has not spent
## (`DawnContext.spent_one_shots()`) is owed to her walk, planned with its role and no position.
##
## **A one-shot is owed to her walk, never rolled for.** Every one-shot is sited from her walk
## (`EventDef.validate()` refuses one that is not): it is the day's authored beat and has to
## happen whichever way she goes, so the plan is made here, at dawn, and only its *position* is
## left for `EventDirector.site_what_is_on_her_way()` to choose, the same split an
## `AHEAD_OF_PLAYER` row is owed and sited under.
##
## **And it is not consumed here.** It has no position yet, so planning it promises nothing.
## It is spent where it becomes real instead — `EventStreaming.stream_in()`. What that buys is
## the retry: *"what the run has spent stays spent ... a fire that burnt a block down did
## happen"* (`RunCalendar.finish_day`), and a fire that was never lit did not, so a lost day 3
## is offered it again.
##
## Model: no node.

## Overrides DawnPhase.run.
func run(context: DawnContext) -> void:
	var day := context.day()
	var events := context.events()
	var consumed := context.spent_one_shots()
	for def in EventCatalogue.of_kind(GameEnums.EventKind.ONE_SHOT, day, context.heat()):
		if def.id in consumed:
			continue
		var owed := EventPlan.new(def, Vector2.INF)
		owed.role = EventScheduler.role_for(def, day)
		events.add(owed)
		context.note("roll", "one-shot %s: owed to her walk, sited when her heading is clear"
				% def.id)

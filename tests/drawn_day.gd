extends RefCounted
## **A planned day with every location drawn**, as a walk that went everywhere would leave it: what
## a suite reads when it asks the day's rules of the day's rows rather than of one walk. The dawn
## leaves the open locations to the walk (`WalkDraw`); this draws them all at once, nearest her
## start first, through the same draw (`WalkDraw.draw_everywhere()`), so a suite planning a day sees
## the rows its draw would stand, a capped row where a walk from her door would meet it. A helper, not a suite: the runner loads only `test_*.gd`.

## `events` with every open location drawn, the rows standing in it.
static func everywhere(events: DayEvents) -> DayEvents:
	if events.walk_draw():
		events.walk_draw().draw_everywhere()
	return events

extends RefCounted
## **A planned day with every location drawn**, as a walk that went everywhere would leave it: what
## a suite reads when it asks the day's rules of the day's rows rather than of one walk. The dawn
## leaves the open locations to the walk (`WalkDraw`); this draws them all at once, nearest first
## from the map's corner, through the same draw (`WalkDraw.draw_within()`), so a suite planning a day
## sees the rows its draw would stand. A helper, not a suite: the runner loads only `test_*.gd`.

## `events` with every open location drawn, the rows standing in it.
static func everywhere(events: DayEvents) -> DayEvents:
	if events.walk_draw():
		events.walk_draw().draw_within(Vector2.ZERO, INF)
	return events

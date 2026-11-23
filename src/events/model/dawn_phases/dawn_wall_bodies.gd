class_name DawnWallBodies
extends DawnPhase
## **The region wall's dawn phase**, one of the city's fixed parts: each of the wall's own bodies,
## planned before the day and standing in it (`DayEvents.standing()`), is recorded on the
## location holding it (`DawnContext.hold_fixed_part()`: "a wall makes its location unavailable
## throughout"), so the draw passes over it.
##
## **A seal's bodies hold no location.** They stand at dawn as standing and the day's rules keep
## rows off them: a soft seal is not held, its carriageway still walkable and a row standing on
## it the price of that route (`docs/EVENTS.md`, the held streets), and a hard seal's street is
## held already. The region doors' bodies are not standing: a street door's street is held, and
## an alley door is kept clear by the doors' rule (`Tuning.CHECKPOINT_EVENT_GAP`). Model: no
## node.

## Overrides DawnPhase.run.
func run(context: DawnContext) -> void:
	for part in context.events().standing():
		if part.is_in_the_wall() and part.is_placed():
			context.hold_fixed_part(part)

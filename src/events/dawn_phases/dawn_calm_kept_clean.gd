class_name DawnCalmKeptClean
extends DawnPhase
## **The dawn's one decision about the calm**: where she has settled in every area this act, the
## one the spoilers leave alone joins the calm ground nothing may reach
## (`DawnContext.keep_clean()`). It runs after the fixed parts and the scars stand, whose
## spoiling it reads, and before the first judge asks the day's rules, which are built over that
## ground once. A walk whose spec keeps no calm clear (`DaySpec.keeps_unused_calm_clear`) decides
## nothing. Model: no node.

## Overrides DawnPhase.run.
func run(context: DawnContext) -> void:
	if context.spec().keeps_unused_calm_clear:
		context.keep_clean(_kept_clean(context.calm(), context.events()))

## **The calm area the day keeps clean, where only construction can keep one**: `NONE` while an area
## counted today (any but `calm.besides()`, day 12's swing park) is one she has not used this act,
## since the calm rule keeps every unused area clear (`CalmAreas.unused_ground()`); otherwise the
## counted area she used longest ago that nothing standing spoils yet, else the least spoiled. The
## spoilers pass over it and its ground joins what nothing may reach, so the day has clean calm
## ground by construction (`docs/CITY.md`, "Guarantees").
static func _kept_clean(calm: CalmAreas, events: DayEvents) -> Vector2i:
	var used := calm.used()
	var counted: Array[Vector2i] = []
	for block in calm.blocks():
		if block == calm.besides():
			continue
		if not used.has(block):
			return CalmAreas.NONE
		counted.append(block)
	var oldest_first: Array[Vector2i] = []
	for i in range(used.size() - 1, -1, -1):
		if counted.has(used[i]):
			oldest_first.append(used[i])
	var least := CalmAreas.NONE
	for block in oldest_first:
		if not events.is_spoiled(block):
			return block
		if least == CalmAreas.NONE \
				or events.spoilers_of(block).size() < events.spoilers_of(least).size():
			least = block
	return least

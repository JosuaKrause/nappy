class_name CatalogueRows
extends RefCounted
## **Every row of the catalogue, asked the way the game asks for rows**: by the day each is
## available (`EventCatalogue.available_on()`, which the scheduler and the dawn read),
## over every day a run has plus day 0, the day nobody plays, where the scripted rows
## (`barricade`, `door_guard`) stand. A suite that holds a fairness contract to every row loops
## `every()`, so it walks the same rows the game can roll or script, once each, the cold row
## itself. `tools/cost_table.gd`, run by `tools/cost-table.sh --check` in CI, fails on a row of
## the catalogue available on none of those days, so no row drops out of the sweeps unseen. The
## order is the days' order (first availability, then catalogue order within a day), not the
## catalogue's. A helper, not a suite: the runner loads only `test_*.gd`.

## Each row of the shipped catalogue (`Shipped.rows()`) that is available on some day,
## once.
static func every() -> Array[EventDef]:
	return of(Shipped.rows())

## Each row of the catalogue `rows` that is available on some day, once: what a suite walks at a
## charger timing of its own (`EventCatalogue.new()`).
static func of(rows: EventCatalogue) -> Array[EventDef]:
	var found: Array[EventDef] = []
	for day: int in range(0, Tuning.RUN_LENGTH_DAYS + 1):
		for def in rows.available_on(day):
			if not found.has(def):
				found.append(def)
	return found

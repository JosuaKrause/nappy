class_name RouteBagMoments
extends RefCounted
## What `EventDirector.start_day()` is handed on a day it was recorded for: the day's moments, the
## plans the dawn leaves unsited, in the order the dawn planned them, and the one placed plan its
## answers depend on. A helper, not a suite: the runner loads only `test_*.gd`.
##
## Read once off a real day and committed as the mock: `tests/test_route_bag.gd` stands the
## director on it. Each key is `day:seed`, the seed of the generated map the day was planned on. A
## day is read again by calling `CityState.begin_day()` and `CityMap.repaint()` on that map for the
## day, then `GameDawn.of(DaySpec.for_day(day), rng, map)
## .on(RouteTree.for_day(map, day, null)).plan()`
## and `placements()` on the result, with `rng` seeded from the hash of `route-bag:<seed>` for
## day 2, `route-bag:day-one:<seed>` for day 1 and `route-bag:lesson:<seed>` for day 3. A moment is the row of a plan the dawn left unsited
## (`EventPlan.row_id()`): the director reads its row and nothing else of it.
##
## **Placed plans are left out but one.** A walk reads a placed plan only to refuse a row sent
## ahead of her the room beside it (`EventDirector.clear_to_send()`) and to keep clear of the doors.
## Placed plans were taken out of each recorded day in halves, for as long as the rows the walk
## handed out and the seconds they came at stayed the same: `PLACED` is the one plan whose removal
## changed a walk (day 1 on seed 31337), at the place it was read.
##
## **When to read a day again:** when the rows, or their order, that the scheduler's plan leaves
## unsited for one of these days and seeds change, since the cases then walk a day the dawn no
## longer plans. Nothing fails when it does: no check compares the fixture with the dawn, and none
## is cheap, because planning a day on a generated map is the slow setup this fixture replaces.

## The rows of each day's unsited plans, in the order planned, separated by a space.
const MOMENTS := {
	"1:77": "loose_dog dog_walker cat_dash loose_dog loose_dog dog_walker " +
			"dog_walker dog_walker dog_walker dog_walker dog_walker loose_dog dog_walker " +
			"dog_walker cat_dash loose_dog dog_walker dog_walker cat_dash dog_walker " +
			"loose_dog loose_dog cat_dash dog_walker dog_walker loose_dog",
	"1:1301": "dog_walker dog_walker cat_dash loose_dog cat_dash cat_dash " +
			"dog_walker dog_walker loose_dog dog_walker dog_walker loose_dog cat_dash " +
			"cat_dash dog_walker dog_walker dog_walker loose_dog loose_dog loose_dog " +
			"dog_walker dog_walker dog_walker dog_walker dog_walker loose_dog",
	"1:4242": "dog_walker dog_walker dog_walker cat_dash cat_dash cat_dash " +
			"dog_walker dog_walker dog_walker cat_dash dog_walker dog_walker dog_walker " +
			"dog_walker dog_walker dog_walker cat_dash cat_dash loose_dog loose_dog " +
			"dog_walker dog_walker loose_dog loose_dog dog_walker dog_walker",
	"1:31337": "loose_dog cat_dash cat_dash dog_walker dog_walker loose_dog " +
			"dog_walker dog_walker loose_dog cat_dash dog_walker dog_walker loose_dog " +
			"dog_walker loose_dog dog_walker dog_walker loose_dog loose_dog dog_walker " +
			"cat_dash dog_walker cat_dash cat_dash dog_walker loose_dog",
	"1:90210": "loose_dog loose_dog dog_walker loose_dog dog_walker cat_dash " +
			"dog_walker dog_walker cat_dash loose_dog dog_walker loose_dog dog_walker " +
			"dog_walker cat_dash cat_dash cat_dash loose_dog dog_walker cat_dash " +
			"loose_dog dog_walker dog_walker cat_dash dog_walker loose_dog",
	"1:1234567": "dog_walker dog_walker loose_dog dog_walker dog_walker " +
			"dog_walker cat_dash dog_walker dog_walker dog_walker dog_walker loose_dog " +
			"loose_dog loose_dog cat_dash loose_dog dog_walker dog_walker loose_dog " +
			"loose_dog loose_dog cat_dash loose_dog dog_walker cat_dash dog_walker",
	"2:4242": "loose_dog cat_dash dog_walker cat_dash cyclist cyclist cat_dash " +
			"cat_dash dog_walker dog_walker dog_walker cat_dash dog_walker loose_dog " +
			"dog_walker cyclist cat_dash cat_dash loose_dog dog_walker loose_dog cat_dash " +
			"dog_walker dog_walker loose_dog dog_walker",
	"2:90210": "dog_walker loose_dog loose_dog loose_dog dog_walker loose_dog " +
			"cat_dash cyclist cat_dash dog_walker cyclist dog_walker loose_dog dog_walker " +
			"dog_walker dog_walker loose_dog dog_walker dog_walker dog_walker cyclist " +
			"cat_dash dog_walker dog_walker cat_dash dog_walker",
	"2:1234567": "cyclist cat_dash dog_walker loose_dog cyclist cat_dash " +
			"dog_walker loose_dog loose_dog cat_dash cat_dash loose_dog cat_dash " +
			"dog_walker loose_dog cyclist dog_walker dog_walker cat_dash loose_dog " +
			"dog_walker dog_walker dog_walker cyclist loose_dog loose_dog",
	"3:4242": "burning_building dog_walker cyclist loose_dog loose_dog dog_walker " +
			"dog_walker loose_dog loose_dog dog_walker dog_walker charging_dog dog_walker " +
			"cyclist cat_dash charging_dog loose_dog cat_dash loose_dog dog_walker " +
			"charging_dog cyclist cat_dash loose_dog dog_walker dog_walker dog_walker",
	"3:90210": "burning_building dog_walker cat_dash cat_dash loose_dog loose_dog " +
			"cat_dash dog_walker dog_walker loose_dog cat_dash dog_walker cat_dash " +
			"loose_dog cyclist cat_dash dog_walker dog_walker loose_dog cat_dash cyclist " +
			"loose_dog cat_dash loose_dog dog_walker dog_walker loose_dog charging_dog",
}

## The placed plans a recorded day's walk depends on: `[row id, placed_at]` each, every one a plan
## that stands at its place.
const PLACED := {
	"1:31337": [["cafe_tables", Vector2(2736, 784)]],
}

## The plans of `day` as recorded on the map of `seed_value`, ready for `EventDirector.start_day()`.
static func plans(day: int, seed_value: int) -> Array[EventPlan]:
	var key := "%d:%d" % [day, seed_value]
	var out: Array[EventPlan] = []
	for row_id in (MOMENTS[key] as String).split(" ", false):
		out.append(EventPlan.new(Shipped.rows().by_id(row_id), Vector2.INF))
	for placed: Array in PLACED.get(key, []):
		out.append(EventPlan.new(Shipped.rows().by_id(placed[0]), placed[1]))
	return out

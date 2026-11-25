extends RefCounted
## **Whether a touch from a place completes a contact, asked the way the game asks it**: by standing
## her there for a physics frame. A helper, not a suite: the runner loads only `test_*.gd`.
##
## A contact completes on the first physics frame she is in reach of it (`ContactPoint`), and completing
## is once and for all, so a suite that asks the same contact about many places cannot stand her at
## each in turn. `touches_from()` asks the director's own contact the question its physics frame asks
## (`ContactPoint.would_complete_at()`, pure), so a place answers exactly as it would complete the
## contact, with the contact as the day shaped it.

## For each of `points`, whether standing there for a physics frame would complete `director`'s contact
## (the one `director.contact()` answers): `[true, false, ...]` in the order of `points`. The
## director's own contact, and the day, are left as they were.
static func touches_from(director: ResistanceDirector, points: Array[Vector2]) -> Array[bool]:
	var live := director.contact()
	var touched: Array[bool] = []
	for point in points:
		touched.append(live.would_complete_at(point))
	return touched

## The same for one place.
static func touches_from_one(director: ResistanceDirector, point: Vector2) -> bool:
	var answers: Array[bool] = touches_from(director, [point] as Array[Vector2])
	return answers[0]

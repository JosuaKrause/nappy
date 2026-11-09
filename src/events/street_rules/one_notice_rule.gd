class_name OneNoticeRule
extends StreetRule
## **No two waiting guards notice her from the same ground**, so she deals with one at a time
## (`_keeps_its_notice_to_itself()`): the escape's rule (`DaySpec.one_notice_at_a_time`),
## asked of what the walk has placed.

var _map: CityMap

func _init(map: CityMap) -> void:
	_map = map

## Overrides StreetRule.allows.
func allows(candidate: EventScheduler.Planned, _tile: Vector2i,
		placed: Array[EventScheduler.Planned], _around: Array[EventScheduler.Planned]) -> bool:
	return _keeps_its_notice_to_itself(_map, candidate, placed)

## **One waiting guard at a time** (`DaySpec.one_notice_at_a_time`). A candidate that waits to
## notice her (`EventDef.notice`: the escape's roadblock, whose guard notices her within
## 180px of his band) is refused when the ground it notices her from meets the ground another placed
## one notices her from: the two notice discs, each centred where its band stands, may not overlap,
## so two of the escape's roadblocks stand at least twice that, 360px, apart, on one street or on
## two. *(Inbox #771 in minty-lemur, 2026-10-18: "two roadblocks are right next to each other and the
## second guard is invisible (hidden) until it already charges".)*
##
## **Why the notice is the distance that matters.** Dealing with one roadblock happens inside its
## guard's notice: he warns while she is inside it, charges only if she stays inside it his warning's
## length, and the run that shakes him off goes back out of it. Another guard can come for her only once
## she is inside *his* notice too, so with no ground inside both she deals with one band and its
## guard at a time — wherever the two stand, either side of a junction or round a corner as much
## as on one street.
##
## **That rests on her turning back from the charge, and is not a bound on a chase.** A guard who
## charges is no longer held to his notice: he comes for her for up to `Tuning.PURSUIT_TIME`
## wherever she runs. Running back the way she came, the answer the lure asks for, takes her out of
## every notice but his; running on past his band towards the next one can bring her into that
## band's notice with the first guard still behind her, and then she has both. That is the wrong
## answer to a charge, so the spacing is not widened for it: twice his warning radius keeps the
## notices apart, which is what one guard at a time needs of the right answer. It is also what
## keeps one guard from standing behind another's drawing: the near guard of a band two tiles up
## the street stands between the two bands, where the nearer band and the guard posted on its far
## side are drawn over him.
static func _keeps_its_notice_to_itself(map: CityMap, candidate: EventScheduler.Planned,
		already: Array[EventScheduler.Planned]) -> bool:
	var reach := candidate.row().notice_within()
	if reach <= 0.0:
		return true
	var at := EventScheduler.body_stands_at(map, candidate)
	for plan in already:
		if plan.row().notice_within() <= 0.0 or not plan.is_placed():
			continue
		if at.distance_to(EventScheduler.body_stands_at(map, plan)) < reach + plan.row().notice_within():
			return false
	return true

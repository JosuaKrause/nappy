extends RefCounted
## **Day 1's dog-walker decision is made twice before her door, on the tutorial route**
## *(PLAYTEST-05 6: the dog-walker decision has to be made at least twice on day one)*: she walks
## the route to the tutorial park and back, and meets lesson (3)'s dog walker on its street on her
## way out, and the rig's second on her walk home, each close enough to pass (`within_its_reach()`).
## The director sends both (`EventDirector._send_the_lessons_dog_walker()`) and the events create
## each on the path it sent (`EventsAhead._send_down_her_line()`).
##
## **Combined, and on real cities, for a stated reason**: the guarantee is a day's, made by the
## tutorial route (`TutorialRoute`), the director's hold on it and the events' creation together,
## and met only on a walk; a realistic walk needs what only the generator gives (a home, the route
## to its park, the streets the line runs down). The walk is `tests/tutorial_walk_rig.gd`'s, over
## the city suites' seeds; `tests/probes/grassy_beaver_dog_walkers.gd` counts more.

const Rig := preload("res://tests/tutorial_walk_rig.gd")

func run(t: TestRunner) -> void:
	var walked := 0
	var reach := within_its_reach()
	for seed_value in Rig.seeds():
		var met := Rig.walk(t, seed_value)
		if met.is_empty():
			continue
		walked += 1
		var out_on_three := INF
		var home := INF
		for seen: Dictionary in met:
			var nearest := float(seen["nearest"])
			if seen["where"] == Rig.OUT_ON_THREE:
				out_on_three = minf(out_on_three, nearest)
			elif seen["where"] == Rig.HOME:
				home = minf(home, nearest)
		t.check(out_on_three <= reach,
				"seed %d: she meets lesson (3)'s dog walker on its street on her way to the park (%s)"
				% [seed_value, met])
		t.check(home <= reach,
				"seed %d: she meets a second dog walker on her walk home, before her door (%s)"
				% [seed_value, met])
	t.check(walked > 0, "there were tutorial routes to walk (%d)" % walked)

## **How near a dog walker comes for her to have met it**: inside its field
## (`EventDef.field_reach()`), where passing it is a decision rather than scenery across the street.
static func within_its_reach() -> float:
	return EventCatalogue.by_id(Rig.ROW).field_reach()

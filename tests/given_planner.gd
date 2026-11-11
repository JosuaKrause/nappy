extends DayPlanner
## **A planner that hands back the placements a test chose**, as a walk planned whole before she
## sets off: the stand-in a test hands the manager (`EventManager.planner`) when it puts exactly the
## rows it wants in a walk, and starts the walk the one way every walk starts
## (`EventManager.start_day()`). Shared by `tests/finale_rig.gd` (run by `test_finale_a.gd`, `_b.gd` and `_c.gd`) and `tests/test_interior.gd`.

var _placements: Array[EventPlan] = []

func _init(the_world: EventWorld, placements: Array[EventPlan]) -> void:
	super(the_world)
	_placements = placements

## Hands `events` a planner that plans `placements`, whatever the spec.
static func hand_in(events: EventManager, placements: Array[EventPlan]) -> void:
	events.planner = new(events.world, placements)

## Overrides DayPlanner.plan.
func plan(_spec: DaySpec, _rng: RandomNumberGenerator, _consumed: Array[String]) -> DayPlanner.Plan:
	var result := DayPlanner.Plan.new()
	result.placements = _placements
	result.is_a_day = false
	return result

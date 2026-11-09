@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## `DaySpec`: whether the region wall stands on a day is worked out once, by the spec, on the days
## around the wall's first, and the escape's sections never have it. What each planner does with
## the answer is its own suite's (`tests/test_seals.gd`, `tests/routes_closures_rig.gd`).

func run(t) -> void:
	_test_the_region_wall_stands_from_its_first_day(t)
	_test_neither_section_of_the_escape_has_the_region_wall(t)
	_test_the_walls_kept_follow_the_region_wall(t)

func _test_the_region_wall_stands_from_its_first_day(t) -> void:
	var first := Tuning.REGION_WALL_FIRST_DAY
	t.check(not DaySpec.for_day(first - 1).region_wall_stands(),
			"day %d, the day before the region wall's first, has no region wall" % (first - 1))
	t.check(DaySpec.for_day(first).region_wall_stands(),
			"day %d, the region wall's first, has the region wall" % first)
	t.check(DaySpec.for_day(first + 1).region_wall_stands(),
			"day %d, the day after the region wall's first, has the region wall" % (first + 1))
	t.check(DaySpec.for_day(Tuning.RUN_LENGTH_DAYS).region_wall_stands(),
			"day %d, the last, has the region wall" % Tuning.RUN_LENGTH_DAYS)

## The escape's two day numbers are past the last day, so a comparison with the day number would
## answer yes for both; neither grows a day's tree, so neither has a wall to stand.
func _test_neither_section_of_the_escape_has_the_region_wall(t) -> void:
	for which: int in [DaySpec.Section.BUILDING, DaySpec.Section.CITY]:
		var spec := DaySpec.for_section(which, 60.0)
		t.check(not spec.region_wall_stands(),
				"the escape's section %d (day %d) has no region wall" % [which, spec.number])

## The catalogue's walls are thinned on exactly the days the region wall stands: the spec's own
## share follows its own answer, over every day of the run.
func _test_the_walls_kept_follow_the_region_wall(t) -> void:
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		var spec := DaySpec.for_day(day)
		t.check((spec.wall_row_share < 1.0) == spec.region_wall_stands(),
				"day %d keeps a share %.2f of its walls, and the region wall %s"
				% [day, spec.wall_row_share, "stands" if spec.region_wall_stands() else "does not"])

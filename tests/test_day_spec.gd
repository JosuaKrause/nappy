extends RefCounted
## `DaySpec`: whether the region wall stands on a day is worked out once, by the spec, on the days
## around the wall's first, and the escape's sections never have it. What each planner does with
## the answer is its own suite's (`tests/test_seals.gd`, `tests/routes_closures_rig.gd`).

func run(t: TestRunner) -> void:
	_test_the_region_wall_stands_from_its_first_day(t)
	_test_neither_section_of_the_escape_has_the_region_wall(t)
	_test_the_walls_kept_follow_the_region_wall(t)
	_test_every_marble_of_a_walk_bag_names_a_row(t)

## Every marble of a walk's bag but the empty one names a row, for every spec the run builds, and
## the empty marble is the string the bag itself calls empty, one string two layers each name.
func _test_every_marble_of_a_walk_bag_names_a_row(t: TestRunner) -> void:
	var specs: Array[DaySpec] = []
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		specs.append(DaySpec.for_day(day))
	for which: int in [DaySpec.Section.BUILDING, DaySpec.Section.CITY]:
		specs.append(DaySpec.for_section(which, 60.0))
	var named := 0
	for spec in specs:
		for marble: String in spec.walk_bag():
			if marble == DaySpec.EMPTY_MARBLE:
				continue
			named += 1
			t.check(spec.walk_bag_rows().has(marble),
					"day %d's walk bag marble %s names a row" % [spec.number, marble])
	t.check(named > 0, "some spec walks a bag with rows in it (%d marbles named)" % named)
	t.check(DaySpec.EMPTY_MARBLE == ViewBag.EMPTY, "the spec's empty marble is the bag's")

func _test_the_region_wall_stands_from_its_first_day(t: TestRunner) -> void:
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
func _test_neither_section_of_the_escape_has_the_region_wall(t: TestRunner) -> void:
	for which: int in [DaySpec.Section.BUILDING, DaySpec.Section.CITY]:
		var spec := DaySpec.for_section(which, 60.0)
		t.check(not spec.region_wall_stands(),
				"the escape's section %d (day %d) has no region wall" % [which, spec.number])

## The catalogue's walls are thinned on exactly the days the region wall stands: the spec's own
## share follows its own answer, over every day of the run.
func _test_the_walls_kept_follow_the_region_wall(t: TestRunner) -> void:
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		var spec := DaySpec.for_day(day)
		t.check((spec.share_of_walls_drawn() < 1.0) == spec.region_wall_stands(),
				"day %d keeps a share %.2f of its walls, and the region wall %s"
				% [day, spec.share_of_walls_drawn(), "stands" if spec.region_wall_stands() else "does not"])

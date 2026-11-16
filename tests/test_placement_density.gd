extends RefCounted
## `PlacementDensity`, the declared table: every cell the draw asks for is there, a number of
## events in a hundred draw locations from nothing to under a hundred, and every day owes some
## moments; and no cell and no act's moments fall from the first act to the last, a relation
## between the table's settings that a cell seeded or scaled below its first act breaks. It holds
## the cells, what a unit's bag holds, and not what a day places, which the day's rules thin most
## on her route and the region wall's half share of walls thins from day 9: the ramp over what a
## day places (writing-tests keeps "a late day holds more events than an early one") is
## `tests/test_events_costs.gd`'s, which plans days 1 and 14, and the probe
## `tests/probes/placement_cells.gd` measures it day by day. Plain data: nothing to mock.

func run(t: TestRunner) -> void:
	_test_every_cell_the_draw_asks_for_is_there(t)
	_test_no_cell_falls_from_the_first_act_to_the_last(t)

const VIEWS: Array[PlacementView.View] = [PlacementView.View.ON_THE_ROUTE,
		PlacementView.View.ROUTE_ADJACENT, PlacementView.View.OFF_THE_ROUTE]
const GROUNDS: Array[PlacementGround.Kind] = [PlacementGround.Kind.STREET,
		PlacementGround.Kind.JUNCTION, PlacementGround.Kind.ALLEY, PlacementGround.Kind.OPEN]

## **Every cell the draw asks for is there**: every view, ground and day of the run answers a number
## from nothing to under a hundred (a cell missing from the table fails the lookup), and every day
## answers the moments it owes, at least one.
func _test_every_cell_the_draw_asks_for_is_there(t: TestRunner) -> void:
	var wrong: Array[String] = []
	var asked := 0
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		for view in VIEWS:
			for ground in GROUNDS:
				var cell := PlacementDensity.events_per_hundred(view, ground, day)
				asked += 1
				if cell < 0.0 or cell >= 100.0:
					wrong.append("day %d view %d ground %d: %.2f" % [day, view, ground, cell])
		if PlacementDensity.moments_on(day) < 1:
			wrong.append("day %d owes %d moments" % [day, PlacementDensity.moments_on(day)])
	t.check(asked > 0 and wrong.is_empty(), "every one of %d cells is a share of a hundred and every "
			% asked + "day owes moments (%s)" % [wrong])

## **No cell falls from the first act to the last**: the last day's events per hundred draw
## locations are no fewer than the first day's in every view and ground, and the last day owes her
## no fewer moments than the first. It asks the first act and the last alone: a cell may still dip
## below the act before it, and what a day places is not asked here (the suite's header).
func _test_no_cell_falls_from_the_first_act_to_the_last(t: TestRunner) -> void:
	var last := Tuning.RUN_LENGTH_DAYS
	var fallen: Array[String] = []
	for view in VIEWS:
		for ground in GROUNDS:
			var first_act := PlacementDensity.events_per_hundred(view, ground, 1)
			var last_act := PlacementDensity.events_per_hundred(view, ground, last)
			if last_act < first_act:
				fallen.append("view %d ground %d: %.2f -> %.2f" % [view, ground, first_act,
						last_act])
	t.check(fallen.is_empty(), "no cell falls from the first act to the last (%s)" % [fallen])
	t.check(PlacementDensity.moments_on(last) >= PlacementDensity.moments_on(1),
			"and the last day owes no fewer moments than the first (%d, %d)"
			% [PlacementDensity.moments_on(1), PlacementDensity.moments_on(last)])

extends RefCounted
## The city degrades: `Tuning.degradation_for()`, the cracked ground `GroundTiles` picks from it,
## the litter and garbage sacks it places, and the storefronts and windows a building shutters.
##
## None of this touches a walkable tile, a cost or a lane — it is presentation read off one curve
## — so what is checked here is the curve's own shape and that every downstream picker reads it
## the same way: deterministic per tile, non-decreasing with the day, and off entirely before the
## city has anything to show.

func run(t) -> void:
	_test_the_curve(t)

# ---------------------------------------------------------------------- the curve ---

func _test_the_curve(t) -> void:
	t.check(Tuning.degradation_for(1) == 0.0, "day 1 is before the curve starts")
	t.check(Tuning.degradation_for(Tuning.DEGRADATION_FIRST_DAY - 1) == 0.0,
			"the day before DEGRADATION_FIRST_DAY is still zero")
	t.check(Tuning.degradation_for(Tuning.DEGRADATION_FIRST_DAY) >= 0.0,
			"the curve's own first day does not go negative")
	t.check(Tuning.degradation_for(Tuning.RUN_LENGTH_DAYS) == 1.0,
			"the curve reaches its maximum on the run's last day")
	var last := -1.0
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		var value := Tuning.degradation_for(day)
		t.check(value >= last, "the curve never drops from one day to the next (day %d)" % day)
		last = value

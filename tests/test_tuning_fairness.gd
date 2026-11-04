extends RefCounted
## **The fairness contracts that are about shared numbers rather than about an event**, stated over
## `Tuning` and failing the suite, and so CI, when a number is unfair. A row of the catalogue validates
## itself when it is first asked for (`EventDef.validate()`, which also holds a pursuer to
## `Tuning.validate_pursuit()`); traffic, the signals and the return patrols have no row to hang that on,
## so the three contracts live here.
##
## Each check states the contract in the terms it is felt in, with the numbers in the message, so a
## failure says which number to move and by how much.

func run(t) -> void:
	_test_the_horn_is_long_enough_to_cross_the_carriageway(t)
	_test_the_crowd_watches_far_enough_to_sound_the_horn(t)
	_test_a_door_holds_some_walkers(t)
	_test_a_walker_can_get_round_a_body(t)
	_test_the_side_streets_green_clears_the_carriageway(t)
	_test_the_return_patrols_keep_their_shape(t)

# --------------------------------------------------------------------- traffic ---

## A car is not an event, so `Tuning.validate_event()` never sees it: it has no telegraph, it is not in
## the catalogue, and it is lethal. What stands in for the telegraph is the road itself — the carriageway
## is painted, permanent and learnable, and stepping off the kerb is a choice the player makes. On top of
## that, a car that is actually going to hit somebody sounds its horn `CAR_HORN_TIME` out, and that
## warning must be long enough to walk the whole width of the carriageway with the doubled margin a hard
## fail is owed. The dark junction of the last night's blackout is held to this check too: the spine's
## traffic does not give way at its zebras lit or dark, so what is left between her and a hard fail
## is the painted carriageway and the horn, stated in seconds of the car's own travel.
func _test_the_horn_is_long_enough_to_cross_the_carriageway(t) -> void:
	var required := Tuning.required_horn_time()
	t.check(Tuning.CAR_HORN_TIME + 0.001 >= required,
			"Unfair traffic: CAR_HORN_TIME %.2fs < required %.2fs (carriageway %.0fpx)"
			% [Tuning.CAR_HORN_TIME, required, Tuning.carriageway_width()])

## The duration above is only true if the crowd watches far enough to let a car sound it — see
## `CAR_HORN_SIGHT`. Checked against the fastest car, since a slower one needs less reach.
func _test_the_crowd_watches_far_enough_to_sound_the_horn(t) -> void:
	var required := Tuning.required_horn_sight()
	t.check(Crowd.CAR_HORN_SIGHT + 0.001 >= required,
			("Unfair traffic: CAR_HORN_SIGHT %.0fpx < %.0fpx the fastest car needs "
			+ "(%.0fpx/s x %.2fs CAR_HORN_TIME)")
			% [Crowd.CAR_HORN_SIGHT, required, Tuning.CAR_SPEED.y, Tuning.CAR_HORN_TIME])

## The three answers a walker may be given at a door are one draw of one number, so the two fractions have
## to leave something over — held is the remainder, and a remainder of nothing is a door nobody is ever
## held at with no error anywhere to say so.
func _test_a_door_holds_some_walkers(t) -> void:
	t.check(WalkerStrategy.WALKER_DOOR_PASS_FRACTION + WalkerStrategy.WALKER_DOOR_TURN_BACK_FRACTION < 1.0,
			"No walker is ever held at a door: pass %.3f + turn back %.3f leaves nothing"
			% [WalkerStrategy.WALKER_DOOR_PASS_FRACTION, WalkerStrategy.WALKER_DOOR_TURN_BACK_FRACTION])

## A walker going round a solid body has to have finished crossing to the other lane of its own footway by
## the time it gets there. Stated over the distance rather than the time, because what it is really about
## is where the walker is when it reaches the body.
func _test_a_walker_can_get_round_a_body(t) -> void:
	var lane_gap := float(Tuning.TILE_SIZE) + 2.0 * CrowdLanes.SIDEWALK_LANE_SPREAD
	var crossing_run := lane_gap / CrowdAgent.STEER_SPEED * Tuning.PEDESTRIAN_SPEED.y
	var start := float(WalkerStrategy.WALKER_BODY_SIDESTEP_TILES * Tuning.TILE_SIZE)
	t.check(start >= crossing_run,
			"A walker cannot get round a body: it starts %.0fpx out and needs %.0fpx to cross the %.0fpx "
			% [start, crossing_run, lane_gap] + "to the other lane of its footway")

# --------------------------------------------------------------------- signals ---

## A zebra on an ordinary street is kept by the drivers: traffic gives way to somebody standing at the
## kerb, and `CAR_ZEBRA_SIGHT` is what makes that visible before she steps off. On a main road nobody
## gives way, and the only thing standing between her and a hard fail is the length of the light — so
## the side street's green has to be long enough to cross the carriageway with the same doubled margin
## every other lethal thing in the game owes. Stated over the crossing she is making rather than over
## the light she is watching: it is the side street that is green while the main road is stopped.
func _test_the_side_streets_green_clears_the_carriageway(t) -> void:
	var required := Tuning.required_horn_time()
	t.check(Tuning.SIGNAL_SIDE_GREEN_SECONDS + 0.001 >= required,
			"Unfair signal: side green %.2fs < %.2fs needed to cross %.0fpx of carriageway"
			% [Tuning.SIGNAL_SIDE_GREEN_SECONDS, required, Tuning.carriageway_width()])

# -------------------------------------------------------------- return patrols ---

## The return leg's own pacing is fair by construction as long as its shape holds: one entry per act, none
## of them negative, and an interval that is ordered and strictly shorter than `AHEAD_INTERVAL`'s on both
## ends — the rows this owes have to be able to land inside the return leg they were sized against, not
## merely inside "the day" the ordinary pacing still covers.
func _test_the_return_patrols_keep_their_shape(t) -> void:
	t.check(EventDirector.RETURN_PATROLS_PER_ACT.size() == 4,
			"RETURN_PATROLS_PER_ACT has %d entries, not one per act" % EventDirector.RETURN_PATROLS_PER_ACT.size())
	for count in EventDirector.RETURN_PATROLS_PER_ACT:
		t.check(count >= 0,
				"RETURN_PATROLS_PER_ACT carries a negative count: %s" % [EventDirector.RETURN_PATROLS_PER_ACT])
	t.check(EventDirector.RETURN_PATROL_INTERVAL.x <= EventDirector.RETURN_PATROL_INTERVAL.y,
			"RETURN_PATROL_INTERVAL is not ordered: %s" % EventDirector.RETURN_PATROL_INTERVAL)
	t.check(EventDirector.RETURN_PATROL_INTERVAL.x < EventDirector.AHEAD_INTERVAL.x
			and EventDirector.RETURN_PATROL_INTERVAL.y < EventDirector.AHEAD_INTERVAL.y,
			("RETURN_PATROL_INTERVAL %s is not shorter than AHEAD_INTERVAL %s: the return "
			% [EventDirector.RETURN_PATROL_INTERVAL, EventDirector.AHEAD_INTERVAL])
			+ "would owe patrols no faster than an ordinary walk already gets")

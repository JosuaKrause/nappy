extends RefCounted
## The escalation, asked of the catalogue's rows: act gating, and the protest's swell over its life.
## A row is built as it is and nothing else is: no city, no live event, no day planned. What a
## planned day keeps true across the acts (a scar outliving its day, a park staying reachable) is
## `tests/test_events_scheduler.gd`'s, and the burnt building a fire leaves is
## `tests/test_city_buildings.gd`'s.

const STEP := 1.0 / 60.0

func run(t: TestRunner) -> void:
	_test_acts_are_gated_by_day(t)
	_test_a_protest_grows(t)

# -------------------------------------------------------------------- gating ---

func _test_acts_are_gated_by_day(t: TestRunner) -> void:
	# The boundaries themselves are `Tuning.ACT_START_DAYS` and are not restated here — a check
	# that reads that array back would only ever fail because somebody moved an act on purpose.
	# What is worth pinning is the relationship between two tables that do not know about each
	# other: the run is exactly as long as its last act, so no day falls off the end of the acts.
	t.check(Tuning.act_for_day(Tuning.RUN_LENGTH_DAYS) == 4, "the last day is act IV")

	# Nothing from a later act may leak into an earlier day. Only a `SCRIPTED` row has an act:
	# its own first day is the first day of its act (`EventDef.own_first_day()`), the one place
	# the game reads an act, and it must not come after the day the row fires on. Every other
	# row's own first day is the day it first appears, which `available_on()` already holds
	# back, and it says no act, so there is nothing to hold for it.
	var swept := 0
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		var act := Tuning.act_for_day(day)
		for def in EventCatalogue.shipped().of_kind(GameEnums.EventKind.SCRIPTED, day):
			swept += 1
			var from_act := Tuning.act_for_day(def.own_first_day())
			t.check(from_act <= act,
					"day %d (act %d) does not offer '%s' from act %d"
					% [day, act, def.id(), from_act])
	t.check(swept > 0, "the sweep checked at least one scripted row (%d)" % swept)

# ------------------------------------------------------------------ mechanics ---

## A protest swells over its life rather than holding: the peak its row carries a pulse's length
## after its telegraph, against the same pulse three quarters of the way through its life, asked of
## the row (`EventDef.peak_through()`), which is what a live event carries once its telegraph is over.
func _test_a_protest_grows(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("protest")
	var ceiling := def.peak_through(0.0, def.lasts_for(), 1.0)
	t.check(ceiling > def.peak(), "a protest swells rather than holding")
	t.check(def.pulses_every() > 0.0, "and beats, so the ramp is read over whole pulse periods")

	# Sample across whole pulse periods so the ramp, not the pulse, is what is compared.
	var from := def.telegraphs_for() + 0.05
	var early := _peak_over(def, from, def.pulses_every())
	var late := _peak_over(def, from + def.pulses_every() + def.lasts_for() * 0.75,
			def.pulses_every())
	t.check(late > early * 1.3, "a protest is markedly worse later than when you saw it")
	t.check(late <= ceiling + 0.01, "and never exceeds its stated ceiling")

## The highest peak `def` carries over the `seconds` after it is `age` seconds old, its burst
## running from the end of its telegraph.
func _peak_over(def: EventDef, age: float, seconds: float) -> float:
	var peak := 0.0
	for i in int(round(seconds / STEP)):
		var at := age + float(i + 1) * STEP
		peak = maxf(peak, def.peak_through(at, at - def.telegraphs_for()))
	return peak


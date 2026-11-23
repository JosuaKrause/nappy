extends RefCounted
## What a row's field answers, asked of the row alone: the swing of its pulse and the two parts of a
## two-part field (a louder core inside a quieter field), as relationships between the row's own
## settings. A row is a plain value, so none is built here but the catalogue's own; what a live
## event charges as it moves through its phases is `tests/test_event_phase.gd`'s.

const STEP := 1.0 / 60.0

func run(t: TestRunner) -> void:
	_test_pulse_envelope(t)
	_test_the_leaf_blowers_core_is_in_the_field(t)

## A pulsing row's peak swings over one beat of its pulse and stays inside its stated peak: sampled
## after its telegraph, a burst's length at a time, since `EventDef.peak_through()` is the peak a live
## event carries once the phase's damping is one.
func _test_pulse_envelope(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("homeless_yeller")
	t.check(def.pulses_every() > 0.0, "the yeller pulses rather than holding")
	var from := def.telegraphs_for() + 0.05

	var lowest := INF
	var highest := -INF
	for i in int(def.pulses_every() / STEP):
		var into := float(i + 1) * STEP
		var peak := def.peak_through(from + into, into)
		lowest = minf(lowest, peak)
		highest = maxf(highest, peak)

	t.check(highest > lowest * 2.0, "the pulse envelope has a real swing between beats")
	t.check(lowest > 0.0, "a pulsing event never goes completely silent")
	t.check(highest <= def.peak() + 0.001, "the pulse never exceeds the stated intensity")

## **A two-part field is two parts in the price, not only in the cost table.** The leaf blower is a
## wall close in and a busker further out (the field's core rate / core reach), and the thing
## that makes that a *field* rather than a price is that the row's own emission carries it —
## against the row the outer half was copied from. 32px is inside the leaf blower's core and 100px
## is well outside it, where the two rows are the same numbers and have to answer the same rate.
func _test_the_leaf_blowers_core_is_in_the_field(t: TestRunner) -> void:
	var leaf := EventCatalogue.by_id("leaf_blower")
	var busker := EventCatalogue.by_id("busker")
	t.check(leaf.field().core_rate() > 0.0 and leaf.field().core_reach() > 0.0,
			"the leaf blower carries a core")
	t.check(busker.field().core_rate() == 0.0,
			"the busker is one field, which is what makes it the row to compare against")
	t.check(is_equal_approx(leaf.peak(), busker.peak())
			and is_equal_approx(leaf.heard_within(), busker.heard_within()),
			"away from the core the leaf blower is the busker, number for number")

	var near := 32.0
	var far := 100.0
	t.check(near < leaf.field().core_reach() and far > leaf.field().core_reach(),
			"32px is inside the core and 100px is outside it")

	var blower_near := leaf.emission_at_distance(near, leaf.peak())
	var busker_near := busker.emission_at_distance(near, busker.peak())
	t.check(blower_near > busker_near + 1.0,
			"a leaf blower charges more than a busker inside its core (%.2f/s against %.2f/s)"
			% [blower_near, busker_near])
	t.close_to(blower_near, leaf.field().core_rate(),
			"and what it charges there is the core's own rate")
	t.close_to(leaf.emission_at_distance(far, leaf.peak()),
			busker.emission_at_distance(far, busker.peak()),
			"past the core the two rows charge the same rate")

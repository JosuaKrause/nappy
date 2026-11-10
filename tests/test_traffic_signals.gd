@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## `TrafficSignals`' power: a lit spine junction holds its own traffic for part of the cycle, and once
## the power is out (what `Blackout` does, `tests/test_blackout.gd`) a light decides nothing though it
## still stands there, which leaves the junction to the crowd's own give-way rule exactly as a side
## street's is.
##
## Over a hand-drawn map of just the streets (`tests/fixtures/street_map.gd`); no city is built. What
## the traffic then does at a dark junction is the crowd's (`tests/test_dark_spine.gd`).

const StreetMap := preload("res://tests/fixtures/street_map.gd")

func run(t) -> void:
	_test_a_dark_junction_is_negotiated(t)

## With no light, nothing but the crowd's own box rule decides a spine junction: a car with nobody
## crossing is let through on the spine exactly as on a side street, rather than held at a red that no
## longer shows.
func _test_a_dark_junction_is_negotiated(t) -> void:
	var map := StreetMap.full()
	var signals := TrafficSignals.new(map)
	var junction := Vector2i(map.main_road, 3)
	var reds := 0
	# One cycle of the day's signal clock in 24 steps, as the crowd's ticks advance it.
	for i in 24:
		if not signals.green_for(junction, true):
			reds += 1
		signals.advance(Tuning.signal_cycle_seconds() / 24.0)
	t.check(reds > 0, "a lit spine junction holds its own traffic for part of the cycle (%d/24)"
			% reds)
	t.check(signals.is_signalled(junction), "and its lights decide it")
	signals.powered = false
	t.check(not signals.is_signalled(junction),
			"a dark one is left to the crowd's own give-way, the same as a side street's")
	t.check(signals.has_lights(junction), "though its lights still stand there")

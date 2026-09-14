extends RefCounted
## What a frame cost, as the readout shows it and as the run log writes it down.
##
## **Nothing here can assert a render counter, and that is the engine's doing rather than a gap.**
## A headless process opens the null display server, draws no frame, and so reports zero draw
## calls, zero objects and zero primitives forever — see `FrameCost`'s own class doc. Measuring
## the suspects in a frame is therefore a windowed `tools/shot.sh` run and never a suite.
##
## So what is left for a suite is the part that can still be silently wrong: the **shape** of what
## is written, and the promise that the two places it is written from cannot drift apart. A number
## read off a phone's `run.log` is only comparable with one read off a desktop's readout while both
## are assembled from the same readings under the same names, and nothing about a format string in
## one file warns you when the one in the other file stops matching it.
##
## `FrameCost.sample()`'s own one-second window (M138, "the readout's process and physics lines
## carry a one-second mean and max") is exercised below through the pure arithmetic
## (`_window_mean()`/`_window_max()`, driven with literal arrays rather than a live `Performance`
## reading) and through `sample()`'s own timestamp bookkeeping (driven with literal times, per
## `FrameCost.sample()`'s own doc on why it takes the time from its caller). `reset_samples()` runs
## first below, since this static window is shared with every suite this process runs in the same
## breath — `tests/test_main.gd` drives `main._process()`, which feeds it too, and runs first only
## because `test_main.gd` sorts before `test_performance.gd`.

func run(t) -> void:
	FrameCost.reset_samples()
	_test_the_log_line_names_every_cost(t)
	_test_the_log_line_carries_the_worst_frame_it_was_given(t)
	_test_the_readout_names_what_the_log_names(t)
	_test_the_readout_gains_labelled_columns_the_log_does_not(t)
	_test_the_entry_keeps_the_log_readable_down_a_column(t)
	_test_the_counters_survive_a_headless_frame(t)
	_test_window_mean_and_max_of_known_samples(t)
	_test_window_falls_back_to_the_instantaneous_reading_when_empty(t)
	_test_sample_keeps_a_one_second_window_and_drops_what_falls_out(t)

## The six quantities the milestone was opened to get. A frame rate alone cannot say whether a
## laggy phone is switching too many textures or doing too much before the renderer is reached,
## which is the whole reason the other five are on the line.
const _COSTS := ["fps", "draws", "objects", "primitives", "process", "physics"]

func _test_the_log_line_names_every_cost(t) -> void:
	var line := FrameCost.line(0.0)
	for cost in _COSTS:
		t.check(cost in line, "the frame entry names %s (%s)" % [cost, line])

## Milliseconds, from the seconds the caller measures its interval in. A hitch is what "a bit
## laggy" means, so the conversion being right is the difference between a line that reports a
## 22ms frame and one that reports a 0.0ms frame on the same stutter.
func _test_the_log_line_carries_the_worst_frame_it_was_given(t) -> void:
	t.check("worst frame 22.4ms" in FrameCost.line(0.0224),
			"a 22.4ms frame is written in milliseconds, not seconds")
	t.check("worst frame 0.0ms" in FrameCost.line(0.0),
			"and a frame nobody measured says so rather than printing nothing")

## **The readout and the log may not drift apart.** They are the same six readings shown to two
## different readers — somebody looking at a screen, and somebody reading a `run.log` off a device
## they were not holding — and the comparison only means anything while both name the same things.
## This is the check that goes red when one of the two grows a field the other has not got.
##
## `last`, `mean` and `max` are not in `_COSTS` and never join it: they are readout-only labels
## inside the existing `process`/`physics` lines, not a seventh and eighth cost, and `line()` keeps
## writing a single last-frame reading for both — see `_test_the_readout_gains_labelled_columns_
## the_log_does_not()` below for the asymmetry this test would otherwise miss.
func _test_the_readout_names_what_the_log_names(t) -> void:
	var readout := "\n".join(FrameCost.readout_lines())
	var line := FrameCost.line(0.0)
	for cost in _COSTS:
		t.check(cost in readout, "the readout names %s" % cost)
	t.check(FrameCost.readout_lines().size() == _COSTS.size(),
			"and carries a line per cost and nothing else (%d)" % FrameCost.readout_lines().size())
	for cost in _COSTS:
		t.check((cost in readout) == (cost in line),
				"%s is on both the readout and the log line, or on neither" % cost)

## The one place the readout and the log are allowed to differ, stated as its own check rather
## than left as something `_test_the_readout_names_what_the_log_names()` merely does not catch:
## `process`/`physics` gain `last`, `mean` and `max` columns on the readout, and `line()`'s own
## single reading carries none of those words, since it already writes once a second at the
## interval the mean covers.
func _test_the_readout_gains_labelled_columns_the_log_does_not(t) -> void:
	var readout := "\n".join(FrameCost.readout_lines())
	var line := FrameCost.line(0.0)
	for label in ["last", "mean", "max"]:
		t.check(label in readout, "the readout's process/physics lines carry a %s column" % label)
		t.check(not (label in line), "the log's single frame() line carries no %s label" % label)

## The log is read top to bottom with no tool, down the kind column — so a `frame` entry has to
## land in the same three columns every other entry does. `TelemetryLog` in memory rather than on
## disk, which is what lets this run with no user directory behind it.
func _test_the_entry_keeps_the_log_readable_down_a_column(t) -> void:
	var log := TelemetryLog.new()
	log.note(12.0, "frame", FrameCost.line(0.0166))
	t.check(log.lines.size() == 1, "one entry, one line")
	var written: String = log.lines[0]
	t.check(written.begins_with("  12.0  frame   "),
			"the timestamp and the kind sit in the fixed columns (%s)" % written)
	t.check("fps" in written, "and the sentence follows them")

## A guard that this suite is not vacuously green. The counters are zero headless, and zero is a
## perfectly good number to format — what must never happen is the call failing or the line coming
## back empty, which is how a monitor renamed in an engine update would show up here.
func _test_the_counters_survive_a_headless_frame(t) -> void:
	t.check(FrameCost.draw_calls() >= 0, "draw calls read without error (%d)" % FrameCost.draw_calls())
	t.check(FrameCost.objects() >= 0, "objects read without error (%d)" % FrameCost.objects())
	t.check(FrameCost.primitives() >= 0, "primitives read without error (%d)" % FrameCost.primitives())
	t.check(FrameCost.process_ms() >= 0.0, "process time reads in milliseconds (%.3f)" % FrameCost.process_ms())
	t.check(FrameCost.physics_ms() >= 0.0, "physics time reads in milliseconds (%.3f)" % FrameCost.physics_ms())
	t.check(not FrameCost.line(0.0).is_empty(), "and the line is written whatever they read")

## The bare arithmetic behind `process_mean_ms()`/`process_max_ms()`/`physics_mean_ms()`/
## `physics_max_ms()`, driven with a literal array instead of a live `Performance` reading — the
## same reason `FrameCost.line()`'s own worst-frame test above drives it with a literal seconds
## value rather than an engine's real one. A window this suite fed with known numbers is the only
## way to know the mean is an arithmetic mean and the max is the worst entry, not the last one.
func _test_window_mean_and_max_of_known_samples(t) -> void:
	var samples: Array[float] = [10.0, 30.0, 20.0]
	t.check(is_equal_approx(FrameCost._window_mean(samples, -1.0), 20.0),
			"the mean of three known samples is their arithmetic mean, not their last")
	t.check(is_equal_approx(FrameCost._window_max(samples, -1.0), 30.0),
			"the max of three known samples is the worst one, not the last one")

## **The first frame is never a lie.** Before `sample()` has fed the window anything, `mean` and
## `max` fall back to the instantaneous reading passed in rather than to zero — a zero would read
## as a free frame, which no frame ever is.
func _test_window_falls_back_to_the_instantaneous_reading_when_empty(t) -> void:
	var empty: Array[float] = []
	t.check(FrameCost._window_mean(empty, 42.0) == 42.0,
			"an empty window's mean is the fallback reading it was given")
	t.check(FrameCost._window_max(empty, 42.0) == 42.0,
			"an empty window's max is the same fallback reading")

## `sample()` takes its time from the caller rather than a clock of its own (see its own doc),
## which is what lets this drive the one-second window with literal timestamps instead of waiting
## a real second out. Reads `_process_samples`/`_physics_samples` directly rather than through a
## public counter that would exist for no other reason than this test.
func _test_sample_keeps_a_one_second_window_and_drops_what_falls_out(t) -> void:
	FrameCost.reset_samples()
	FrameCost.sample(0.0)
	FrameCost.sample(0.5)
	t.check(FrameCost._process_samples.size() == 2 and FrameCost._physics_samples.size() == 2,
			"two samples less than a second apart are both kept (%d, %d)" % [
				FrameCost._process_samples.size(), FrameCost._physics_samples.size()])
	FrameCost.sample(1.6)
	t.check(FrameCost._process_samples.size() == 1 and FrameCost._physics_samples.size() == 1,
			"the two samples more than a second behind the newest one drop out (%d, %d)" % [
				FrameCost._process_samples.size(), FrameCost._physics_samples.size()])
	FrameCost.reset_samples()

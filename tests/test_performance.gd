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
## `process_ms()`/`physics_ms()` are already the worst interval of the previous second, straight off
## `Performance.TIME_PROCESS`/`TIME_PHYSICS_PROCESS` (M138, "what the readout's `process` and
## `physics` lines measure"), so there is no window of this suite's own left to drive with literal
## samples — `readout_lines()` labels that reading `worst` and nothing here holds a rolling arithmetic
## mean or max any more.

func run(t) -> void:
	_test_the_log_line_names_every_cost(t)
	_test_the_log_line_carries_the_worst_frame_it_was_given(t)
	_test_the_readout_names_what_the_log_names(t)
	_test_the_readout_gains_a_labelled_column_the_log_does_not(t)
	_test_the_entry_keeps_the_log_readable_down_a_column(t)
	_test_the_counters_survive_a_headless_frame(t)

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
## `worst` is not in `_COSTS` and never joins it: it is a readout-only label inside the existing
## `process`/`physics` lines, not a seventh cost, and `line()` keeps writing the same reading with
## no label — see `_test_the_readout_gains_a_labelled_column_the_log_does_not()` below for the
## asymmetry this test would otherwise miss.
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
## `process`/`physics` gain a `worst` label on the readout, naming the engine's own once-a-second
## reading for what it is (M138), and `line()`'s own single reading carries no such word beside
## either, since it already writes once a second, at the interval the reading covers. Checked
## against `process`/`physics` by name rather than a bare `"worst" in ...`, since `line()` already
## carries the unrelated word in `worst frame` for the run log's own worst-single-frame field.
func _test_the_readout_gains_a_labelled_column_the_log_does_not(t) -> void:
	var readout := "\n".join(FrameCost.readout_lines())
	var line := FrameCost.line(0.0)
	for cost in ["process", "physics"]:
		t.check("%s     worst" % cost in readout,
				"the readout's %s line carries a worst label (%s)" % [cost, readout])
		t.check(not ("%s     worst" % cost in line) and not ("worst %s" % cost in line),
				"the log's %s reading carries no worst label (%s)" % [cost, line])

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

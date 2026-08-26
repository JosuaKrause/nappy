extends RefCounted
## The run log: its format, and the promise that having it on changes nothing.
##
## Two things here are worth more than the rest of the suite put together.
##
## **A trace must not perturb the run it is measuring.** Every entry written from inside a
## gameplay system is a roll hoisted into a variable so it can be printed, and hoisting a roll
## is exactly the kind of edit that quietly consumes one extra number from a deterministic RNG.
## If it ever does, the same seed stops producing the same city and every other guarantee in
## this project — a learnable run, a reproducible bug, a replayable playtest — goes with it.
## `_test_tracing_a_day_does_not_change_it` plans the same days twice, once with the log on,
## and demands the plans be identical event for event.
##
## **Telemetry is off unless a run asks for it.** The suite must never write a file, and
## `Telemetry.note()` on a dormant log must cost nothing. If this fails, every one of the
## fourteen thousand checks below it is running a file write it did not ask for.

func run(t) -> void:
	_test_it_is_off_until_a_run_asks_for_it(t)
	_test_a_line_is_a_time_a_kind_and_a_sentence(t)
	_test_order_is_the_record(t)
	_test_the_formatting_helpers(t)
	_test_the_commit_is_recorded_or_honestly_unknown(t)
	_test_tracing_a_day_does_not_change_it(t)
	_test_tracing_the_arcs_does_not_change_them(t)
	_test_a_day_header_opens_a_day(t)

# ------------------------------------------------------------------ dormancy ---

## The state the whole suite runs in. A dormant `note()` has to be a boolean check and a
## return — not a formatted string thrown away, and above all not a file.
func _test_it_is_off_until_a_run_asks_for_it(t) -> void:
	t.check(not Telemetry.is_active(),
			"telemetry is dormant in the test suite unless a test turns it on")
	t.check(Telemetry.current_log() == null, "and there is no log to write into")
	Telemetry.note("start", "this line has nowhere to go")
	t.check(Telemetry.current_log() == null, "so noting something is a no-op")

# -------------------------------------------------------------------- format ---

## The columns are the whole readability argument: a reader scans down the `kind` column to
## find every `near`, or down the time column to find what happened at 0:48. Both stop working
## the moment a line is formatted by hand somewhere else.
func _test_a_line_is_a_time_a_kind_and_a_sentence(t) -> void:
	var log := TelemetryLog.new()
	log.note(0.0, "start", "doorstep (52,88), facing north")
	log.note(96.42, "home", "WON")
	log.note(1234.5, "near", "busker 62px")

	t.check(log.lines.size() == 3, "three notes make three lines")
	t.check(log.lines[0] == "   0.0  start    doorstep (52,88), facing north",
			"a line is a right-aligned time, two spaces, a padded kind, then the sentence")
	t.check(log.lines[1].begins_with("  96.4  home"), "the time is one decimal place")
	# A four-digit timestamp is a run far longer than fourteen days, but the column must not
	# collapse if one ever happens: an unaligned log is a log nobody scans.
	for line in log.lines:
		t.check(line.substr(6, 2) == "  ", "the kind column starts in the same place")
	t.check(log.path == "", "a log with no path writes no file")

## An aggregate can always be computed from an ordered log; the order can never be recovered
## from an aggregate. This is the property the format exists for, so it is asserted rather
## than assumed.
func _test_order_is_the_record(t) -> void:
	var log := TelemetryLog.new()
	log.header("day 3")
	for i in 20:
		log.note(float(i), "near", "thing %d" % i)
	t.check(log.lines[0] == "day 3", "a header carries no timestamp")
	var in_order := true
	for i in 20:
		if not log.lines[i + 1].ends_with("thing %d" % i):
			in_order = false
	t.check(in_order, "twenty entries come back in the order they were written")

## Shared so that a tile written by the scheduler and a tile written by the observer read the
## same. Two spellings of a position in one log is two things to grep for.
func _test_the_formatting_helpers(t) -> void:
	t.check(TelemetryLog.tile(Vector2i(3, 5)) == "(3,5)", "a tile has no space in it")
	# The city is drawn from above with +y downward, so south is *down*. Getting this backwards
	# would put every `turn` entry in the log 180 degrees out and nothing would ever say so.
	t.check(TelemetryLog.compass(Vector2.DOWN) == "south", "+y is south")
	t.check(TelemetryLog.compass(Vector2.UP) == "north", "-y is north")
	t.check(TelemetryLog.compass(Vector2.RIGHT) == "east", "+x is east")
	t.check(TelemetryLog.compass(Vector2.LEFT) == "west", "-x is west")
	t.check(TelemetryLog.compass(Vector2(3.0, -1.0)) == "east",
			"a diagonal is named by its longer axis")
	t.check(TelemetryLog.compass(Vector2.ZERO) == "nowhere", "and standing still is nowhere")
	t.check(TelemetryLog.purpose(GameEnums.BlockPurpose.QUIET_SQUARE) == "quiet_square",
			"a purpose is its enum name, lower case")

## Without a commit a trace cannot be checked against anything, and a dirty tree has to say so
## rather than claim a hash that does not describe what ran. Which of the two this machine is
## in cannot be asserted — only that the answer is one of the shapes a reader can act on.
func _test_the_commit_is_recorded_or_honestly_unknown(t) -> void:
	var version := Telemetry.source_version()
	t.check(version != "", "a run always records something about where it came from")
	if version == "unknown":
		# An exported build with no repository to ask. Nothing more to check.
		t.check(true, "no repository here, and the log says so rather than guessing")
		return
	var commit := version.trim_suffix("*")
	t.check(commit.length() >= 7 and commit.is_valid_hex_number(),
			"the commit is a short hash (got '%s')" % version)
	t.check(not version.ends_with("**"), "a dirty tree is marked once")

# ----------------------------------------------------- and it changes nothing ---

## The invariant this file exists for.
##
## `_place_one_shots` hoists its roll into a variable so the log can print the number against
## the threshold. That is a one-line edit with a way to be catastrophically wrong: consume one
## more value from the day's RNG and every event placed after it moves. So: plan every day of
## a run with the log off, plan them again with it on, and require the two to agree exactly.
func _test_tracing_a_day_does_not_change_it(t) -> void:
	var map := CityGenerator.generate(31337)

	var quiet: Array[String] = []
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		quiet.append(_plan_signature(map, day))

	Telemetry.begin_memory_log()
	var traced: Array[String] = []
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		traced.append(_plan_signature(map, day))
	var log := Telemetry.current_log()
	var wrote := log.lines.size() if log else 0
	Telemetry.end_run()

	t.check(not Telemetry.is_active(), "the test put telemetry back the way it found it")
	# Day 3 is the one that matters: `fire_truck` is the catalogue's only one-shot and it is
	# the roll that got hoisted. If the log ever stops covering it this test has gone quiet.
	t.check(wrote > 0, "tracing fourteen days wrote something (%d lines)" % wrote)
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		t.check(quiet[day - 1] == traced[day - 1],
				"day %d is planned identically whether or not it is being traced" % day)

## The other hoist: `CityState._advance` now names the purpose it is leaving, which means it
## reads the arc twice instead of once. Reading is free and must stay free.
func _test_tracing_the_arcs_does_not_change_them(t) -> void:
	var map := CityGenerator.generate(8812)
	var quiet := _arc_signature(map)
	Telemetry.begin_memory_log()
	var traced := _arc_signature(map)
	Telemetry.end_run()
	t.check(quiet == traced, "the blocks walk their arcs the same way with the log on")

## A day's entries have to land under that day's header, or a fourteen-day log is one
## undifferentiated column and the reader cannot tell day 1 from day 12.
func _test_a_day_header_opens_a_day(t) -> void:
	Telemetry.begin_memory_log()
	Telemetry.begin_day(3, 1, 8812, 8813, 180.0)
	Telemetry.set_clock(11.3)
	Telemetry.note("turn", "doubled back east")
	Telemetry.end_day()
	# The clock stops with the day: the between-days screen must not advance tomorrow's times.
	Telemetry.set_clock(999.0)
	Telemetry.note("nerve", "spent a nerve")

	var lines := Telemetry.current_log().lines
	Telemetry.end_run()

	t.check(lines.size() == 5, "a preamble, a blank line, a header and two entries")
	t.check(lines[1] == "", "a day is separated from the one above it by a blank line")
	t.check(lines[2] == "day 3  act 1  run seed 8812  city seed 8813  length 180.0s",
			"the header names the day, the act, both seeds and the length (got '%s')" % lines[2])
	t.check(lines[3].begins_with("  11.3  turn"), "an entry is timestamped from dawn")
	t.check(lines[4].begins_with("  11.3  nerve"),
			"and what happens after dusk keeps the time the day ended at (got '%s')" % lines[4])

# ------------------------------------------------------------------ helpers ---

## Everything a planned day is, as one comparable string: what was placed, where, and in what
## order. Positions to the pixel, because a shifted RNG moves an event without changing the
## set of events.
func _plan_signature(map: CityMap, day: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("telemetry:%d:%d" % [map.seed_used, day])
	var consumed: Array[String] = []
	var parts: Array[String] = []
	for plan in EventScheduler.build_day(day, rng, map, consumed):
		parts.append("%s@%.2f,%.2f" % [plan.def.id, plan.position.x, plan.position.y])
	# The one-shot ledger is part of the answer: a roll that fires on day 3 rather than day 4
	# is exactly the divergence this is looking for.
	parts.append("consumed:" + ",".join(consumed))
	return "|".join(parts)

## Where every block ends up after a whole run of scheduled advances.
func _arc_signature(map: CityMap) -> String:
	var state := CityState.new()
	var parts: Array[String] = []
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		state.begin_day(map.block_plans, day)
	var blocks: Array = map.block_plans.keys()
	blocks.sort()
	for block: Vector2i in blocks:
		parts.append("%s=%d:%d" % [TelemetryLog.tile(block),
				state.purpose_of(map.block_plans, block), state.changed_on(block)])
	return "|".join(parts)

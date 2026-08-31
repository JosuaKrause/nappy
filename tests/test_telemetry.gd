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
	_test_the_map_picture_covers_the_city_and_marks_it(t)
	_test_the_map_picture_draws_the_corridor(t)
	_test_the_map_picture_reads_the_map_and_nothing_else(t)
	_test_a_picture_asked_for_by_hand_is_never_capped(t)

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

# ------------------------------------------------------------- the city grid ---
# *(Playtest 13, finding 4.)* What a test can hold about a picture is its geometry and its
# innocence; whether it is *legible* is a thing to open the PNG and look at, which is the
# `check.sh` / screenshot split this project has had since M1.

## The picture covers every tile at the stated scale, and every mark actually lands.
##
## The colours are asserted by **presence** rather than by pixel address: an outline moved a tile
## would still be a correct picture, and a mark that never got drawn is the failure worth catching
## — three of them are stated over data the generator could legitimately return empty
## (`precinct_spans`, closures), so those are asserted only when there is something to assert.
func _test_the_map_picture_covers_the_city_and_marks_it(t) -> void:
	var map := CityGenerator.generate(4242)
	var image := TelemetryMap.render(map)
	t.check(image.get_size() == map.size * TelemetryMap.SCALE,
			"the picture is the whole map at SCALE pixels a tile")

	var seen := {}
	for y in image.get_height():
		for x in image.get_width():
			seen[image.get_pixel(x, y)] = true
	t.check(seen.has(TelemetryMap.HOME_MARK), "the home is marked")
	t.check(seen.has(TelemetryMap.CALM_MARK), "and every calm area is outlined")
	t.check(map.main_road < 0 or seen.has(TelemetryMap.SPINE_MARK), "and the spine is drawn")
	t.check(map.precinct_spans.is_empty() or seen.has(TelemetryMap.PRECINCT_MARK),
			"and the precincts are")
	# A hard blocker nobody can find in the one picture built to check placements might as well
	# not have been placed. It showed through as building at first, which is invisible.
	t.check(map.built_over.is_empty() or seen.has(TelemetryMap.DEAD_END_MARK),
			"and every street a hard blocker took is marked as taken")
	# The ground is under all of it: a picture that is only marks has covered what it describes,
	# which is the one way a debug overlay lies that nobody notices.
	t.check(seen.has(TelemetryMap.BUILDING_GROUND), "and the buildings show through")
	t.check(seen.has(Tile.ground_colour(GameEnums.TileType.SIDEWALK)), "and so do the pavements")
	t.check(seen.has(Tile.ground_colour(GameEnums.TileType.ROAD)), "and so do the roads")

## The day's corridor, drawn. *(M50.)*
##
## Three things, and the middle one is the reason this is a test rather than a look at a PNG. The
## marks land at all; the corridor is drawn **only when there is a tree to draw**, because every
## other mark in the picture is a fact about the ground and this one is a plan, and a picture that
## invents a plan when it was given none is worse than a picture without one; and a stroke lands
## on a **street**, since a line drawn a tile off runs along a frontage and reads as a route
## through a building.
func _test_the_map_picture_draws_the_corridor(t) -> void:
	var map := CityGenerator.generate(4242)
	var tree := RouteTree.for_day(map, 1)
	t.check(not tree.branches.is_empty(), "the day has a corridor to draw")

	var plain := _colours_in(TelemetryMap.render(map))
	t.check(not plain.has(TelemetryMap.CORRIDOR_MARK)
			and not plain.has(TelemetryMap.BUNDLE_MARK),
			"a picture given no tree draws no corridor")

	var drawn := _colours_in(TelemetryMap.render(map, [], tree))
	t.check(drawn.has(TelemetryMap.CORRIDOR_MARK), "and one given a tree draws it")
	t.check(drawn.has(TelemetryMap.BUNDLE_MARK),
			"and draws the stretches more than one area is reached by")

	# Every stroke is on a street, checked at the one place a stroke could be off by a tile and
	# still look right in the small: the middle of the street it belongs to.
	var image := TelemetryMap.render(map, [], tree)
	for key in tree.streets():
		var segment := StreetNetwork.by_key(key)
		var middle := segment.tile_rect().position + segment.tile_rect().size / 2
		var pixel := image.get_pixel(middle.x * TelemetryMap.SCALE,
				middle.y * TelemetryMap.SCALE)
		t.check(pixel == TelemetryMap.CORRIDOR_MARK or pixel == TelemetryMap.BUNDLE_MARK,
				"the corridor down street %s is drawn on the street" % key)

func _colours_in(image: Image) -> Dictionary:
	var seen := {}
	for y in image.get_height():
		for x in image.get_width():
			seen[image.get_pixel(x, y)] = true
	return seen

## Rendering is a **read**. It takes no RNG and changes nothing about the map, which is the same
## promise `_test_tracing_a_day_does_not_change_it` makes about the log — and it is worth its own
## check because this one draws from a `CityMap` that is mutable by design.
func _test_the_map_picture_reads_the_map_and_nothing_else(t) -> void:
	var map := CityGenerator.generate(4242)
	var before := map.tiles.duplicate()
	var calm_before := map.calm_blocks.size()
	var first := TelemetryMap.render(map)
	var second := TelemetryMap.render(map)
	t.check(map.tiles == before, "rendering the grid does not repaint it")
	t.check(map.calm_blocks.size() == calm_before, "and does not disturb what it counted")
	t.check(first.get_data() == second.get_data(),
			"and the same map twice is the same picture, pixel for pixel")

## A person pressing the key is not a heuristic firing. *(Playtest 13, finding 5.)*
##
## `snapshot()`'s two limits are what stop a two-second condition writing a hundred and twenty
## frames; `snapshot_now()` must not have them, because a cap that silently swallows the seventh
## press is a tool that lies about having worked. Asserted through the **log**, which is the only
## part of it that exists headless — there is no viewport to photograph in the suite, and that is
## itself the thing being relied on.
func _test_a_picture_asked_for_by_hand_is_never_capped(t) -> void:
	Telemetry.begin_memory_log()
	Telemetry.begin_day(1, 1, 1, 1, 180.0)
	var log := Telemetry.current_log()
	var before := log.lines.size()
	for i in Telemetry.SHOTS_PER_DAY * 2 + 1:
		Telemetry.snapshot_now("press %d" % i)
	t.check(log.lines.size() - before == Telemetry.SHOTS_PER_DAY * 2 + 1,
			"every press writes its line, well past the heuristic's own daily cap")
	t.check(log.lines[log.lines.size() - 1].contains("shot"),
			"and the line is a shot entry")
	Telemetry.end_run()
	t.check(not Telemetry.is_active(), "and the suite is left dormant again")

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

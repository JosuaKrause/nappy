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
##
## What the `TelemetryObserver` writes into the log, and when, is `tests/test_telemetry_observer.gd`'s,
## on a recording log; this suite is the real log's own, the file and the pictures it writes.

## The burst suite, whose bench (`Bench`) the burst test here hands the run log.
const BurstSuite := preload("res://tests/test_burst_capture.gd")
## What a city's state has recorded, read off the snapshot the save writes.
const CityStateReads := preload("res://tests/city_state_reads.gd")

func run(t) -> void:
	var suite_scratch := "user://telemetry-test-suite-%d" % Time.get_ticks_usec()
	_log = Telemetry.new(suite_scratch)
	_test_it_is_off_until_a_run_asks_for_it(t)
	_test_a_line_is_a_time_a_kind_and_a_sentence(t)
	_test_order_is_the_record(t)
	_test_the_formatting_helpers(t)
	_test_the_commit_is_recorded_or_honestly_unknown(t)
	_test_tracing_a_day_does_not_change_it(t)
	_test_tracing_the_arcs_does_not_change_them(t)
	_test_a_day_header_opens_a_day(t)
	_test_the_escape_opens_a_section_so_its_lines_carry_a_time(t)
	_test_a_retried_section_restarts_its_snapshot_schedule(t)
	_test_the_map_picture_covers_the_city_and_marks_it(t)
	_test_the_map_picture_draws_the_corridor(t)
	_test_the_map_picture_marks_what_the_day_placed(t)
	_test_every_routed_event_is_a_straight_line(t)
	_test_the_map_picture_reads_the_map_and_nothing_else(t)
	_test_a_picture_asked_for_by_hand_is_never_capped(t)
	_test_the_shot_name_is_a_run_wide_counter_shared_by_auto_and_asked(t)
	_test_the_counter_never_resets_across_a_day_or_a_retried_attempt(t)
	_test_a_day_clock_held_at_zero_still_gets_two_distinct_shot_names(t)
	_test_the_map_picture_draws_the_trail_and_distinguishes_running(t)
	_test_a_runs_files_share_one_folder(t)
	_test_the_attempt_suffix_names_every_attempt_including_the_first(t)
	_test_a_second_attempt_at_a_day_writes_a_second_map_instead_of_overwriting(t)
	_test_the_web_override_flag_parses_the_query(t)
	_test_reads_the_url_only_when_debug_and_web(t)
	_test_a_frame_past_twice_the_mean_writes_one_spike_line(t)
	_test_steady_frames_write_no_spike_line(t)
	_test_two_spikes_in_one_second_write_only_the_worse_one(t)
	_test_no_spike_line_with_the_flag_off(t)
	_test_a_baked_page_says_which_moment_loaded_it(t)
	_test_the_day_header_notes_the_invincible_flag_once_per_day(t)
	_test_a_headless_burst_is_refused_without_a_capture_wait(t)
	_test_a_day_or_a_run_ending_cuts_the_active_burst_short(t)
	_log.free()
	_delete_recursive(suite_scratch)

## A screen that can draw, which a headless process has none of: every frame is ready the moment it
## is asked for, and the picture is a small image. Handed to `Telemetry.use_screen()` it makes
## `snapshot()` and `snapshot_now()` write the pictures a window would.
class DrawingScreen extends TelemetryScreen:
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)

	## Overrides TelemetryScreen.can_draw.
	func can_draw() -> bool:
		return true

	## Overrides TelemetryScreen.drawn.
	func drawn() -> void:
		pass

	## Overrides TelemetryScreen.picture.
	func picture() -> Image:
		return image

## Opens a real run in a scratch folder of its own, on a log over that folder photographing a
## screen that can draw, and returns that folder (the run's own is below it).
## `_close_the_scratch_run()` frees that log and puts the suite's own back.
func _open_a_scratch_run(name: String) -> String:
	var scratch := "user://telemetry-test-%s-%d" % [name, Time.get_ticks_usec()]
	_use_a_log_over(scratch)
	_log.use_screen(DrawingScreen.new())
	_log.begin_run(778812400, false)
	return scratch

func _close_the_scratch_run(scratch: String) -> void:
	_put_back_the_suite_log()
	_delete_recursive(scratch)

## The run log every test here drives (`Telemetry`): the suite's own, over a scratch folder made as
## the suite starts and removed as it ends, or for the length of one test a log over a scratch
## folder of that test's own (`_use_a_log_over()`). This suite is the one place a test builds the
## real run log: every other suite that reads what was logged hands a recording fake
## (`tests/recording_log.gd`, or a `RunTrace.recording()`).
var _log: Telemetry
## The suite's own log while `_log` is a test's.
var _suite_log: Telemetry

## Swaps the suite's log for a fresh one over `scratch`, a real folder, until
## `_put_back_the_suite_log()`.
func _use_a_log_over(scratch: String) -> void:
	_suite_log = _log
	_log = Telemetry.new(scratch)

## Frees the test's log and puts the suite's own back.
func _put_back_the_suite_log() -> void:
	_log.free()
	_log = _suite_log

## The file names in one of the open run's picture folders (`auto`, `asked`), sorted.
func _pictures(kind: String) -> PackedStringArray:
	var dir := DirAccess.open("%s/%s" % [_log.current_log().path.get_base_dir(), kind])
	if dir == null:
		return PackedStringArray()
	var names := dir.get_files()
	names.sort()
	return names

# ------------------------------------------------------------------ dormancy ---

## The state the whole suite runs in. A dormant `note()` has to be a boolean check and a
## return — not a formatted string thrown away, and above all not a file.
func _test_it_is_off_until_a_run_asks_for_it(t) -> void:
	t.check(not _log.is_active(),
			"telemetry is dormant in the test suite unless a test turns it on")
	t.check(_log.current_log() == null, "and there is no log to write into")
	_log.note("start", "this line has nowhere to go")
	t.check(_log.current_log() == null, "so noting something is a no-op")

# -------------------------------------------------------------------- format ---

## The columns are the whole readability argument: a reader scans down the `kind` column to
## find every `near`, or down the time column to find what happened at 0:48. Both stop working
## the moment a line is formatted by hand somewhere else.
func _test_a_line_is_a_time_a_kind_and_a_sentence(t) -> void:
	var log := TelemetryLog.new()
	log.note(0.0, "start", "doorstep (52,88), facing 0°")
	log.note(96.42, "home", "WON")
	log.note(1234.5, "near", "busker 62px")

	t.check(log.lines.size() == 3, "three notes make three lines")
	t.check(log.lines[0] == "   0.0  start    doorstep (52,88), facing 0°",
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
	t.check(RunTrace.tile(Vector2i(3, 5)) == "(3,5)", "a tile has no space in it")
	# The city is drawn from above with +y downward, so south is *down*. Getting this backwards
	# would put every `turn` entry in the log 180 degrees out and nothing would ever say so.
	t.check(RunTrace.compass(Vector2.DOWN) == "180°", "+y is a bearing of 180°, south")
	t.check(RunTrace.compass(Vector2.UP) == "0°", "-y is a bearing of 0°, north")
	t.check(RunTrace.compass(Vector2.RIGHT) == "90°", "+x is a bearing of 90°, east")
	t.check(RunTrace.compass(Vector2.LEFT) == "270°", "-x is a bearing of 270°, west")
	t.check(RunTrace.compass(Vector2(3.0, -1.0)) == "72°",
			"a diagonal keeps its own exact bearing rather than rounding to the nearer axis")
	# Two headings four degrees apart used to both read as "east" under the old
	# `absf(x) > absf(y)` split — 44° took it, 46° crossed into "north" — which is the
	# quantisation this format exists to remove: two walks a player can tell apart must not
	# write the same word.
	var at_44 := Vector2(sin(deg_to_rad(44.0)), -cos(deg_to_rad(44.0)))
	var at_46 := Vector2(sin(deg_to_rad(46.0)), -cos(deg_to_rad(46.0)))
	t.check(RunTrace.compass(at_44) == "44°", "44° reads as its own bearing")
	t.check(RunTrace.compass(at_46) == "46°",
			"and a heading two degrees off reads as a different one rather than the same word")
	t.check(RunTrace.compass(Vector2.ZERO) == "nowhere", "and standing still is nowhere")
	t.check(RunTrace.purpose(GameEnums.BlockPurpose.QUIET_SQUARE) == "quiet_square",
			"a purpose is its enum name, lower case")

## Without a version a trace cannot be checked against anything, and a dirty tree has to say so
## rather than claim a build that does not describe what ran. Which of the shapes this machine
## gets cannot be asserted — this repo has a tag reachable from `HEAD` (`v0.0.0`), so in practice
## `source_version()` always returns the tag form here, but a shallow checkout with no tags
## reachable is `git describe --always`'s bare-hash fallback, and neither is wrong.
func _test_the_commit_is_recorded_or_honestly_unknown(t) -> void:
	var version := BuildInfo.source_version()
	t.check(version != "", "a run always records something about where it came from")
	if version == "unknown":
		# An exported build with no repository to ask. Nothing more to check.
		return
	var stripped := version.trim_suffix("-dirty")
	t.check(stripped != "", "a version is never just the dirty marker")
	if stripped.begins_with("v") and stripped.contains("-g"):
		# `git describe`'s tagged form: `<tag>-<commits-since>-g<hash>`.
		var hash_part := stripped.substr(stripped.rfind("-g") + 2)
		t.check(hash_part.length() >= 7 and hash_part.is_valid_hex_number(),
				"the describe form ends in a short hash (got '%s')" % version)
	elif stripped.begins_with("v"):
		# **Standing exactly on a tag, `git describe` prints the tag alone** — no distance and no
		# hash, because there are no commits since it. This is the shape a *released* build has
		# and the only one a player ever sees, since `deploy.yml` checks the tag out to export it.
		# It went unasserted until the first real release cut one, and the bare-hash branch below
		# then rejected it for not being hexadecimal.
		var digits := stripped.substr(1)
		t.check(digits != "" and not digits.contains("-"),
				"an exact tag is the version alone, with nothing appended (got '%s')" % version)
	else:
		# `git describe --always`'s fallback when no tag is reachable: a bare short hash.
		t.check(stripped.length() >= 7 and stripped.is_valid_hex_number(),
				"with no tag reachable, describe falls back to a bare hash (got '%s')" % version)
	t.check(not version.ends_with("-dirty-dirty"), "a dirty tree is marked once")

# ----------------------------------------------------- and it changes nothing ---

## The invariant this file exists for.
##
## `_place_one_shots` hoists its roll into a variable so the log can print the number against
## the threshold. That is a one-line edit with a way to be catastrophically wrong: consume one
## more value from the day's RNG and every event placed after it moves. So: plan every day of
## a run handed no trace, plan them again handed one that keeps every line, and require the two to
## agree exactly.
func _test_tracing_a_day_does_not_change_it(t) -> void:
	var map := CityGenerator.generate(31337)

	var quiet: Array[String] = []
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		quiet.append(_plan_signature(map, day))

	var lines: Array[String] = []
	var traced: Array[String] = []
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		traced.append(_plan_signature(map, day, RunTrace.recording(lines)))

	# Day 3 is the one that matters: `burning_building` is the catalogue's only one-shot, and the
	# `roll` line saying what became of it is written while the day is being planned. If the trace
	# ever stops covering it this test has gone quiet.
	t.check(lines.size() > 0, "tracing fourteen days wrote something (%d lines)" % lines.size())
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		t.check(quiet[day - 1] == traced[day - 1],
				"day %d is planned identically whether or not it is being traced" % day)

## The other hoist: `CityState._advance` names the purpose it is leaving, which means it reads the
## arc twice instead of once. Reading is free and must stay free.
func _test_tracing_the_arcs_does_not_change_them(t) -> void:
	var map := CityGenerator.generate(8812)
	var quiet := _arc_signature(map)
	var lines: Array[String] = []
	var traced := _arc_signature(map, RunTrace.recording(lines))
	t.check(lines.size() > 0, "a run's arcs wrote something (%d lines)" % lines.size())
	t.check(quiet == traced, "the blocks walk their arcs the same way with the log on")

## A day's entries have to land under that day's header, or a fourteen-day log is one
## undifferentiated column and the reader cannot tell day 1 from day 12.
func _test_a_day_header_opens_a_day(t) -> void:
	_log.begin_run(0)
	_log.begin_day(3, 1, 8812, 8813, 180.0)
	_log.set_clock(11.3)
	_log.note("turn", "doubled back east")
	_log.end_day()
	# The clock stops with the day: the between-days screen must not advance tomorrow's times.
	_log.set_clock(999.0)
	_log.note("nerve", "spent a nerve")

	var lines := _log.current_log().lines
	_log.end_run()

	t.check(lines.size() == 5, "a preamble, a blank line, a header and two entries")
	t.check(lines[1] == "", "a day is separated from the one above it by a blank line")
	t.check(lines[2] == "day 3  act 1  run seed 8812  city seed 8813  length 180.0s",
			"the header names the day, the act, both seeds and the length (got '%s')" % lines[2])
	t.check(lines[3].begins_with("  11.3  turn"), "an entry is timestamped from dawn")
	t.check(lines[4].begins_with("  11.3  nerve"),
			"and what happens after dusk keeps the time the day ended at (got '%s')" % lines[4])

## *"Every line in it is stamped `0.0`, so it cannot say when anything happened."*
##
## A line is timed only inside an open section, and each of the escape's sections opens one of its
## own as a day does — `begin_section()`, under its own day number and its own words. This asks
## both halves: that a clock pushed after it actually reaches the line, and that a clock pushed
## **before** any section is open still does not, which is the guarantee relied on and is what
## would hide a section that never opened.
func _test_the_escape_opens_a_section_so_its_lines_carry_a_time(t) -> void:
	_log.begin_run(0)
	# No section open yet: a run that never opens one writes zeroes, which is the behaviour the
	# escape was getting for the whole of its walk.
	_log.set_clock(12.0)
	_log.note("plan", "before any section")
	_log.begin_section(DaySpec.BUILDING_DAY, "Escape the building", 4242, 180.0)
	_log.set_clock(42.5)
	_log.note("plan", "finale: two chains")
	_log.set_clock(96.25)
	_log.note("lost", "lost_hard_fail in the building after 96.2s")

	var lines := _log.current_log().lines
	_log.end_run()
	t.check(lines.size() == 6, "a preamble, an entry, a blank line, a header and two entries (%d)"
			% lines.size())
	t.check(lines[1].begins_with("   0.0  plan"),
			"a line written before any section is open carries no time (got '%s')" % lines[1])
	t.check(lines[2] == "", "the escape's section is separated from what is above it")
	t.check(lines[3] == "day %d Escape the building  run seed 4242  length 180.0s"
			% DaySpec.BUILDING_DAY,
			"its header names its day, its own words, the run seed and its length (got '%s')"
			% lines[3])
	t.check(lines[4].begins_with("  42.5  plan"),
			"and an entry after it carries the elapsed time (got '%s')" % lines[4])
	t.check(lines[5].begins_with("  96.2  lost"),
			"as does the line a lost section writes (got '%s')" % lines[5])

## *"A retried escape section holds its automatic snapshots back until the new clock passes the
## time of the last shot, because a section's clock restarts at zero."* A clock pushed back with
## `Telemetry.set_clock(0.0)` alone leaves the last shot's time sitting at the previous attempt's
## own reading — here, 45s in, well past the retried walk's fresh `0.0`, which is exactly the state
## `snapshot()`'s spacing gate (the clock less the last shot's time under `SHOT_SPACING`) reads as
## "a shot just happened". `restart_section_clock()` clears the schedule the way `begin_section()`
## and `begin_day()` do. Asked through the pictures that land in the run's `auto/` folder, on a
## screen that can draw. That the observer's `start_section()` calls it is
## `tests/test_telemetry_observer.gd`'s.
func _test_a_retried_section_restarts_its_snapshot_schedule(t) -> void:
	var scratch := _open_a_scratch_run("retry")
	_log.begin_section(DaySpec.BUILDING_DAY, "Escape the building", 4242, 180.0)
	_log.set_clock(45.0)
	# The state a real run is in right before a loss: a shot already taken this attempt, with the
	# day's whole allowance not yet spent.
	_log.snapshot("first")
	t.check(_pictures("auto").size() == 1, "a shot is taken on a screen that can draw")
	_log.snapshot("again")
	t.check(_pictures("auto").size() == 1,
			"a shot taken now leaves the spacing running, so a second at once is held back")

	_log.restart_section_clock()

	t.check(_log.clock() == 0.0, "a retry's clock starts over at zero, as it always did")
	_log.snapshot("retry")
	t.check(_pictures("auto").size() == 2,
			"and the snapshot schedule starts over with it, not stuck at the lost attempt's clock")
	# The retried walk's whole allowance: the section opened with one picture already taken in the
	# retry (above), so `PER_DAY - 1` more fit, one `SPACING` apart, and the next is refused.
	for i in range(1, TelemetryShots.PER_DAY):
		_log.set_clock(TelemetryShots.SPACING * i)
		_log.snapshot("walk")
	t.check(_pictures("auto").size() == 1 + TelemetryShots.PER_DAY,
			"so the retried walk has its whole allowance again, not what the lost attempt spent")
	_log.set_clock(TelemetryShots.SPACING * TelemetryShots.PER_DAY)
	_log.snapshot("over")
	t.check(_pictures("auto").size() == 1 + TelemetryShots.PER_DAY,
			"and no more than that allowance")

	_close_the_scratch_run(scratch)

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

	var seen := _colours_in(image)
	t.check(seen.has(TelemetryMap.HOME_MARK), "the home is marked")
	t.check(seen.has(TelemetryMap.CALM_MARK), "and every calm area is outlined")
	t.check(map.main_road < 0 or seen.has(TelemetryMap.SPINE_MARK), "and the spine is drawn")
	_check_a_precinct_shows_as_paving(t, map, image)
	# A hard blocker nobody can find in the one picture built to check placements might as well
	# not have been placed. It showed through as building at first, which is invisible.
	t.check(map.built_over.is_empty() or seen.has(TelemetryMap.DEAD_END_MARK),
			"and every street a hard blocker took is marked as taken")
	# The ground is under all of it: a picture that is only marks has covered what it describes,
	# which is the one way a debug overlay lies that nobody notices.
	t.check(seen.has(TelemetryMap.BUILDING_GROUND), "and the buildings show through")
	t.check(seen.has(Tile.ground_colour(GameEnums.TileType.SIDEWALK)), "and so do the pavements")
	t.check(seen.has(Tile.ground_colour(GameEnums.TileType.ROAD)), "and so do the roads")

## A precinct is legible without a mark on it, which is why it has not got one.
##
## *(2026-08-31: "why blue? why not just take the sidewalk colour and use it for those road
## segments".)* It is the same question the picture answers everywhere else — *is the ground
## telling the truth* — and the answer here is that a pedestrianised corridor is laid `SIDEWALK`
## all the way across, so where every other street has a stripe of asphalt down its middle this one
## has none. Asserted across the corridor rather than by presence: the old assertion could have
## passed on a single blue pixel, and this one fails if the paving ever stops being paving.
func _check_a_precinct_shows_as_paving(t, map: CityMap, image: Image) -> void:
	var paving := Tile.ground_colour(GameEnums.TileType.SIDEWALK)
	for span: Vector4i in map.precinct_spans:
		var vertical := span.x == 1
		var across: int = span.y * CityMap.period()
		var along: int = (span.z + 1) * CityMap.period() - 2
		var paved := true
		for offset in Tuning.STREET_WIDTH:
			var tile := Vector2i(across + offset, along) if vertical \
					else Vector2i(along, across + offset)
			paved = paved and image.get_pixel(tile.x * TelemetryMap.SCALE,
					tile.y * TelemetryMap.SCALE) == paving
		t.check(paved, "the precinct %s is drawn paved from frontage to frontage" % span)

## The day's corridor, drawn. *(M50, and M69's move to cells.)*
##
## Four things, and the middle two are the reason this is a test rather than a look at a PNG. The
## corridor is drawn **only when there is a tree to draw**, because every other mark in the picture
## is a fact about the ground and this one is a plan, and a picture that invents a plan when it was
## given none is worse than a picture without one; a mark lands on a **cell the tree actually
## touches** — since M69 that can be a park cut or an alley as well as a street, so checking a
## street's own middle tile the way this test used to is no longer even the right question; a cell
## the tree never took is left alone, which is what makes the picture an answer rather than a
## decoration; and the ground **survives** the mark.
##
## Asserted as *the pixel changed* rather than as *the pixel is this colour*, because the mark is
## blended into whatever it crosses — see `TelemetryMap.CORRIDOR_ALPHA`. A test naming one colour
## would have to know the ground under every cell, and would be asserting the alpha rather than
## the drawing.
func _test_the_map_picture_draws_the_corridor(t) -> void:
	var map := CityGenerator.generate(4242)
	var tree := RouteTree.for_day(map, 1)
	t.check(not tree.branches.is_empty(), "the day has a corridor to draw")

	var plain := TelemetryMap.render(map)
	var drawn := TelemetryMap.render(map, [], tree)
	t.check(plain.get_data() != drawn.get_data(), "a picture given a tree draws it")

	var on_the_tree := {}
	for cell in tree.cells():
		on_the_tree[cell] = true

	var missed := 0
	for cell in on_the_tree:
		var tile: Vector2i = cell * ReachabilityGrid.CELL
		var before := plain.get_pixel(tile.x * TelemetryMap.SCALE, tile.y * TelemetryMap.SCALE)
		var after := drawn.get_pixel(tile.x * TelemetryMap.SCALE, tile.y * TelemetryMap.SCALE)
		if after == before:
			missed += 1
		# The ground is mixed in rather than painted over, so a mark can never be the mark's own
		# colour: that is the whole of "keep the violet lines transparent".
		t.check(after != TelemetryMap.CORRIDOR_MARK,
				"and the ground under cell %s still shows through it" % cell)
	# Not quite every cell: `render()` draws the calm outline, the closures and the home **over**
	# the corridor on purpose ("those three are what the corridor is drawn to be read against"),
	# and a route legitimately ends right beside a calm area's edge or the doorstep — exactly where
	# one of those later marks can occlude it in both the plain and the drawn picture alike, which
	# reads here as no change at all. A floor with that overlap's own room under it rather than zero.
	t.check(float(missed) / maxf(1.0, float(on_the_tree.size())) < 0.05,
			"nearly every cell of the tree is drawn (%d of %d were not)"
			% [missed, on_the_tree.size()])

	var elsewhere := 0
	var checked := 0
	for cy in map.size.y / ReachabilityGrid.CELL:
		for cx in map.size.x / ReachabilityGrid.CELL:
			var cell := Vector2i(cx, cy)
			if on_the_tree.has(cell):
				continue
			checked += 1
			var tile := cell * ReachabilityGrid.CELL
			var before := plain.get_pixel(tile.x * TelemetryMap.SCALE, tile.y * TelemetryMap.SCALE)
			var after := drawn.get_pixel(tile.x * TelemetryMap.SCALE, tile.y * TelemetryMap.SCALE)
			if after != before:
				elsewhere += 1
	t.check(elsewhere == 0, "and no cell off the tree is marked (%d of %d were)"
			% [elsewhere, checked])

## The colour the legend gives a role, read off its public marks and not off the drawing's own code.
func _mark_of(role: GameEnums.BlockerRole) -> Color:
	match role:
		GameEnums.BlockerRole.WALL:
			return TelemetryMap.WALL_MARK
		GameEnums.BlockerRole.FRICTION:
			return TelemetryMap.FRICTION_MARK
		GameEnums.BlockerRole.SET_PIECE:
			return TelemetryMap.SET_PIECE_MARK
	return TelemetryMap.NO_ROLE_MARK

## What the day placed, carrying what it is. *(M50, and this is the picture the milestone is
## checked against rather than a decoration on one.)*
##
## The thing being asserted is that the **legend is the drawing**: a picture whose colours have
## drifted from the legend's marks (`TelemetryMap.WALL_MARK` and the rest) is worse than no picture, because it answers the one question the
## milestone can get badly wrong — *is that wall on the corridor or beside it* — confidently and
## wrongly. Two days rather than one because the vocabulary has four roles and no single day places
## in all of them: day 9 has walls and friction and no one-shot, day 3 is the day the fire is on her
## way.
##
## What is not asserted here is whether it is **legible**, which is a PNG to open and look at. That
## split is this project's oldest and the marks were moved twice by looking: the route lines were
## drawn at the mark's own strength and read as corridor, and "she reached this one" was a fade
## before it was a pip.
func _test_the_map_picture_marks_what_the_day_placed(t) -> void:
	var map := CityGenerator.generate(4242)
	var consumed: Array[String] = []
	var roles := {}
	for day in [3, 9]:
		var tree := RouteTree.for_day(map, day)
		var plans := EventScheduler.build_day(DaySpec.for_day(day), _rng(day), map,
				CalmAreas.of(map), consumed, [], tree).placements()
		# Day 3's set piece is budgeted with no position and sited from the walk she takes
		# (`EventDef.on_her_way`), so a day's plan on its own carries no set-piece mark to
		# draw. The picture has to be able to draw one, and what it draws is a sited plan — so this
		# stands in for the walk, which is nothing this test has or wants.
		for plan in plans:
			if plan.def.on_her_way != null and not plan.is_placed():
				plan.position = map.tile_to_world(
						map.tiles_of_type(GameEnums.TileType.SIDEWALK)[0])
		var plain := TelemetryMap.render(map, [], tree)
		var drawn := TelemetryMap.render(map, [], tree, plans)
		t.check(plain.get_data() != drawn.get_data(),
				"day %d's placements are drawn over the corridor they were placed against" % day)

		var placed := {}
		for plan in plans:
			if plan.is_placed():
				placed[plan.role] = true
				roles[plan.role] = true
		var seen := _colours_in(drawn)
		for role: GameEnums.BlockerRole in placed:
			t.check(seen.has(_mark_of(role)),
					"and every role day %d placed in is in the picture (%s is not)"
					% [day, GameEnums.BlockerRole.keys()[role]])
		if day == 9:
			_check_a_glyph_says_what_it_is(t, map, plans)
	t.check(roles.size() == 4,
			"and between them the two days draw all four roles (%d of 4)" % roles.size())

## One event's glyph, rendered alone so nothing else can be what the pixels are.
##
## Three claims, and the middle one is the one a whole-picture check cannot make: a lethal row
## **fills** its three tiles and a costly one is a **cross**, so the corners are the difference and
## a corner is where the two would be confused. The third is the `met` pip, which is the only thing
## the dusk picture says that the dawn one does not — and it is checked by handing `render` a `met`
## dictionary directly rather than by playing a day, because what is being tested is the drawing and
## not `TelemetryObserver.watch_met_events`, which has its own test.
func _check_a_glyph_says_what_it_is(t, map: CityMap,
		plans: Array[EventScheduler.Planned]) -> void:
	# **The glyph is only readable where nothing is drawn over it**, and four marks are laid over
	# the events on purpose — the calm outlines, the dead ends, the closures and the home, which
	# `render` calls the picture's fixed points. So a plan standing under one of those is a plan
	# whose shape this test cannot see, and *which* plan the day happens to put there changes with
	# every change to how routes are grown. The bare render is the oracle for that: a tile the
	# overlays touch is a tile that is already not its ground colour before any event is drawn.
	var bare := TelemetryMap.render(map)
	var unobstructed := func(plan: EventScheduler.Planned) -> bool:
		var at := map.world_to_tile(plan.position)
		for probe in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(1, 1)]:
			var tile: Vector2i = at + probe
			if not Rect2i(Vector2i.ZERO, map.size).has_point(tile):
				return false
			if _tile_colour(bare, tile) != Tile.ground_colour(map.tile_at(tile)):
				return false
		return true

	var lethal: EventScheduler.Planned = null
	var costly: EventScheduler.Planned = null
	for plan in plans:
		# A routed event lays a band over its own corners, so the shape is read off a stationary one.
		if not plan.is_placed() or plan.path.size() >= 2:
			continue
		if not unobstructed.call(plan):
			continue
		if plan.def.hard_fail and lethal == null:
			lethal = plan
		elif not plan.def.hard_fail and costly == null:
			costly = plan
	t.check(lethal != null and costly != null, "the day places something lethal and something costly")
	if lethal == null or costly == null:
		return

	var corner := Vector2i(1, 1)
	for plan in [costly, lethal]:
		var only: Array[EventScheduler.Planned] = [plan]
		var image := TelemetryMap.render(map, [], null, only)
		var at := map.world_to_tile(plan.position)
		var colour := _mark_of(plan.role)
		t.check(_tile_colour(image, at) == colour,
				"%s is marked on the tile the day put it on" % plan.def.id)
		t.check(_tile_colour(image, at + Vector2i(1, 0)) == colour, "and reaches a tile across")
		t.check((_tile_colour(image, at + corner) == colour) == plan.def.hard_fail,
				"and %s fills its corners only if it ends the day" % plan.def.id)

		# The pip is the whole of "she got to this one", and it is added rather than taken away:
		# every mark stays at full strength, because a wall in the wrong place in a corner of the
		# map she never walked into is exactly the placement worth seeing.
		t.check(_tile_colour(image, at) != TelemetryMap.MET_MARK,
				"and nothing she has not reached carries a pip")
		var met_image := TelemetryMap.render(map, [], null, only, [], {plan: true})
		t.check(_tile_colour(met_image, at) == TelemetryMap.MET_MARK,
				"while one she reached does, in the middle of the same mark")
		t.check(_tile_colour(met_image, at + Vector2i(1, 0)) == colour,
				"and the pip does not change the glyph around it")

## The trail draws at all, and a point taken while running reads differently from one taken at a
## walk — the two claims `TelemetryObserver.watch_the_trail` makes about a sample, checked the way
## the corridor's own stroke is: by whether the pixel changed, since both are blended into the
## ground rather than painted over it.
func _test_the_map_picture_draws_the_trail_and_distinguishes_running(t) -> void:
	var map := CityGenerator.generate(4242)
	# The middle of the map rather than the home or a calm area: both are drawn *after* the trail
	# on purpose (they are the picture's fixed points) and would silently paint over a trail point
	# placed on top of them, which is a fact about draw order and not about the trail.
	var at := map.tile_to_world(map.size / 2)

	var plain := TelemetryMap.render(map)
	var walked: Array[Vector3] = [Vector3(at.x, at.y, 0.0)]
	var walked_image := TelemetryMap.render(map, [], null, [], walked)
	t.check(plain.get_data() != walked_image.get_data(), "a trail with one point on it is drawn")

	var ran: Array[Vector3] = [Vector3(at.x, at.y, 1.0)]
	var ran_image := TelemetryMap.render(map, [], null, [], ran)
	t.check(ran_image.get_data() != walked_image.get_data(),
			"a point taken while running reads differently from the same point taken at a walk")

## `_route_stroke` draws the band between a route's two ends, which **is** the route only while
## every route in the catalogue is two axis-aligned points.
##
## Asserted rather than assumed because the failure is silent and would be a picture of ground the
## event never covers: a route that ever bent would be drawn as its bounding box, and a bounding box
## is a plausible-looking rectangle rather than an obvious error. It is the same shape as the rest
## of this file — *an identity standing in for the property* — caught before it can happen.
func _test_every_routed_event_is_a_straight_line(t) -> void:
	var map := CityGenerator.generate(4242)
	var consumed: Array[String] = []
	for day in [1, 3, 7, 14]:
		for plan in EventScheduler.build_day(DaySpec.for_day(day), _rng(day), map,
				CalmAreas.of(map), consumed).placements():
			if plan.path.size() < 2:
				continue
			t.check(plan.path.size() == 2, "%s's route is two points, not %d"
					% [plan.def.id, plan.path.size()])
			var along := plan.path[plan.path.size() - 1] - plan.path[0]
			t.check(is_zero_approx(along.x) or is_zero_approx(along.y),
					"and %s's route runs along one axis" % plan.def.id)

## Every colour anywhere in a picture. Presence rather than address, which is what the marks are
## asserted by: an outline moved one tile is still a correct picture, and a mark that never got
## drawn at all is the failure worth catching.
func _colours_in(image: Image) -> Dictionary:
	var seen := {}
	for y in image.get_height():
		for x in image.get_width():
			seen[image.get_pixel(x, y)] = true
	return seen

## The colour of one **tile**, which is what every mark in the picture is drawn in units of.
func _tile_colour(image: Image, tile: Vector2i) -> Color:
	return image.get_pixel(tile.x * TelemetryMap.SCALE, tile.y * TelemetryMap.SCALE)

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
	_log.begin_run(0)
	_log.begin_day(1, 1, 1, 1, 180.0)
	var log := _log.current_log()
	var before := log.lines.size()
	for i in TelemetryShots.PER_DAY * 2 + 1:
		_log.snapshot_now("press %d" % i)
	t.check(log.lines.size() - before == TelemetryShots.PER_DAY * 2 + 1,
			"every press writes its line, well past the heuristic's own daily cap")
	t.check(log.lines[log.lines.size() - 1].contains("shot"),
			"and the line is a shot entry")
	_log.end_run()
	t.check(not _log.is_active(), "and the suite is left dormant again")

## *(2026-09-11, playtest 56: "phot capture must use real time not game time otherwise at the
## end of the day all pictures get overwritten", then, once a real-time name was in place,
## "actually why not just count up the screenshot numbers?".)* `%03d<attempt suffix>-<kind>.png`,
## one counter shared by `snapshot()`'s `auto/` and `snapshot_now()`'s `asked/`, so a picture's own
## number says when in the run — relative to every other picture the run took, from either folder
## — it was taken.
func _test_the_shot_name_is_a_run_wide_counter_shared_by_auto_and_asked(t) -> void:
	var shots := TelemetryShots.new()
	var first := shots.next_name("asked", "-attempt1")
	t.check(first == "001-attempt1-asked.png",
			"the first picture the run takes, from either folder, is 001 (got '%s')" % first)
	var second := shots.next_name("lost_crying", "-attempt1")
	t.check(second == "002-attempt1-lost_crying.png",
			"a picture from the other folder keeps counting from the same sequence (got '%s')"
			% second)

## The counter must not repeat the day clock's own failure: a value that resets can produce the
## same name twice. Crossing into a new day, and a nerve retrying the same day without the
## calendar advancing (`begin_day()`'s own note on `_day_attempts`), both keep counting rather
## than starting over — only the attempt suffix changes. A new day clears the day's allowance and
## spacing (`restart_schedule()`), never the counter; only a new run's names start over.
func _test_the_counter_never_resets_across_a_day_or_a_retried_attempt(t) -> void:
	var shots := TelemetryShots.new()
	t.check(shots.next_name("asked", "-attempt1") == "001-attempt1-asked.png",
			"the first picture of the run")
	shots.restart_schedule()
	t.check(shots.next_name("asked", "-attempt1") == "002-attempt1-asked.png",
			"a new day does not reset the counter")
	shots.restart_schedule()  # a nerve retries day 2 without the calendar advancing
	t.check(shots.next_name("asked", "-attempt2") == "003-attempt2-asked.png",
			"neither does a retried attempt at the same day — only the attempt suffix changes")
	shots.restart_names()
	t.check(shots.next_name("asked", "-attempt1") == "001-attempt1-asked.png",
			"a new run's names start over")

	# The same walk on the run's own counter, with `Telemetry`'s own day boundaries between the
	# names: a new log is a new run, a new day and a retried day are not. The names are the files
	# that land in the run's `asked/` folder.
	var scratch := _open_a_scratch_run("counter")
	_log.begin_day(1, 1, 1, 1, 180.0)
	_log.snapshot_now("one")
	t.check(_pictures("asked") == PackedStringArray(["001-attempt1-asked.png"]),
			"a new log's first picture is 001 (got %s)" % _pictures("asked"))
	_log.begin_day(2, 1, 1, 1, 180.0)
	_log.snapshot_now("two")
	t.check(_pictures("asked").has("002-attempt1-asked.png"),
			"Telemetry's own new day does not reset the run's counter (got %s)" % _pictures("asked"))
	_log.begin_day(2, 1, 1, 1, 180.0)
	_log.snapshot_now("three")
	t.check(_pictures("asked").has("003-attempt2-asked.png"),
			"nor does Telemetry's own retry of the same day (got %s)" % _pictures("asked"))
	_log.begin_section(DaySpec.BUILDING_DAY, "Escape the building", 1, 180.0)
	_log.snapshot_now("four")
	t.check(_pictures("asked").has("004-attempt1-asked.png"),
			"nor an escape section opening (got %s)" % _pictures("asked"))
	_close_the_scratch_run(scratch)

## `--invincible` clamps the countdown to exactly zero once a day runs out rather than ending it
## (`DayController.tick()`), which holds the elapsed day clock at the day's own length for as
## long as the day keeps running afterward — so under a clock-named scheme, every picture taken
## past dusk that day asked for the exact same file and each one silently overwrote the last. A
## counter cannot repeat this way at all, which this checks directly by holding the clock at zero
## across two names and confirming the day clock genuinely never moved between them.
func _test_a_day_clock_held_at_zero_still_gets_two_distinct_shot_names(t) -> void:
	var scratch := _open_a_scratch_run("held-clock")
	_log.begin_day(1, 1, 1, 1, 180.0)
	_log.set_clock(0.0)
	_log.snapshot_now("first")
	_log.snapshot_now("second")
	t.check(_log.clock() == 0.0,
			"the day clock genuinely never moved between the two — the same way --invincible " +
			"holds it at the day's length once the countdown clamps at zero")
	var found := _pictures("asked")
	t.check(found.size() == 2,
			"two pictures asked for at the same held day clock land as two files (got %s)" % found)
	_close_the_scratch_run(scratch)

# ---------------------------------------------------------------- one folder ---
# *(docs/DECISIONS.md, M70 "A run is a folder": the run identity moved from
# a shared filename stem to a folder, `<day>/<run>/`, and a day played twice — a nerve
# retries a lost day without the calendar advancing — has to write a second picture rather than
# overwrite the first's.)*

## Deletes a real path this suite wrote, so a test that opens a real run — the only way to check
## a folder actually landed where `begin_run()` says it does — leaves nothing behind for a person
## to find later. Also removes the `<day>` ancestor once it is empty: nothing in
## the game does that any more (2026-09-03: "no automatic cleanup anymore"), but the suite is a
## guest in the real telemetry directory and should not scatter empty folders through it.
func _delete_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir:
		for sub in dir.get_directories():
			_delete_recursive("%s/%s" % [path, sub])
		for file in dir.get_files():
			DirAccess.remove_absolute("%s/%s" % [path, file])
	DirAccess.remove_absolute(path)
	for ancestor in [path.get_base_dir()]:
		var above := DirAccess.open(ancestor)
		if above and above.get_files().is_empty() and above.get_directories().is_empty():
			DirAccess.remove_absolute(ancestor)

## The only way to check a folder actually landed where `begin_run()` says it does is to open a
## real run of a log over a folder of the test's own. `false` (a rig) because this is a
## scripted check rather than a person at the controls, the same reason `check.sh` and `shot.sh`
## write `rig-`.
func _test_a_runs_files_share_one_folder(t) -> void:
	var map := CityGenerator.generate(4242)
	var scratch := "user://telemetry-test-folder-%d" % Time.get_ticks_usec()
	_use_a_log_over(scratch)
	_log.begin_run(778812345, false)
	var log_path := _log.current_log().path
	t.check(log_path != "", "a real run opens a file")
	t.check(_log.current_log().path.begins_with(scratch + "/"),
			"the run lands under the folder it was handed, not the player's own (got '%s')"
			% _log.current_log().path)
	t.check(log_path.get_file() == "run.log",
			"the log is named plainly — the folder is what says which run it belongs to (got '%s')"
			% log_path.get_file())
	var run_dir := log_path.get_base_dir()
	t.check(run_dir.get_file().begins_with("rig-"),
			"the run folder itself carries the run/rig distinction (got '%s')" % run_dir.get_file())
	t.check(run_dir.get_file().ends_with("-" + BuildInfo.source_version()),
			"and its own name ends with the commit it was played on (got '%s', wanted suffix '-%s')"
			% [run_dir.get_file(), BuildInfo.source_version()])
	var day_dir := run_dir.get_base_dir().get_file()
	t.check(day_dir.count("-") == 2 and day_dir.length() == 10,
			"its parent is the calendar day folder (got '%s')" % day_dir)

	_log.begin_day(1, 1, 778812345, 778812345, 10.0)
	_log.write_map(map, 1)

	var maps_dir := "%s/maps" % run_dir
	t.check(DirAccess.dir_exists_absolute(maps_dir),
			"the map landed in the run's own maps/ folder rather than beside the log")
	var found := DirAccess.open(maps_dir).get_files()
	t.check(found.has("day01-attempt1.png"),
			"a first attempt is named like every other attempt (got %s)" % found)

	_put_back_the_suite_log()
	_delete_recursive(scratch)

## Every filename that can repeat within a run asks for its attempt's suffix, the first attempt
## included. Driven through a real run's `maps/` folder, where `write_map()` names the picture: a
## question about the attempts counted per day, answered by the files that land.
func _test_the_attempt_suffix_names_every_attempt_including_the_first(t) -> void:
	var map := CityGenerator.generate(4242)
	var scratch := "user://telemetry-test-suffix-%d" % Time.get_ticks_usec()
	_use_a_log_over(scratch)
	_log.begin_run(778812347, false)
	var run_dir := _log.current_log().path.get_base_dir()
	t.check(_log.current_log().path.begins_with(scratch + "/"),
			"the run lands under the folder it was handed, not the player's own (got '%s')"
			% _log.current_log().path)
	_log.begin_day(6, 2, 1, 1, 10.0)
	_log.write_map(map, 6)
	var found := DirAccess.open("%s/maps" % run_dir).get_files()
	t.check(found == PackedStringArray(["day06-attempt1.png"]),
			"a first attempt is named too, so every name has the same shape (got %s)" % found)
	_log.begin_day(6, 2, 1, 1, 10.0)
	_log.write_map(map, 6)
	found = DirAccess.open("%s/maps" % run_dir).get_files()
	t.check(found.has("day06-attempt2.png"),
			"a second attempt at the same day is named (a nerve retries without the day advancing)")
	_log.begin_day(7, 2, 1, 1, 10.0)
	_log.write_map(map, 7)
	found = DirAccess.open("%s/maps" % run_dir).get_files()
	t.check(found.has("day07-attempt1.png"),
			"a different day's first attempt is unaffected by day 6's retry")
	_log.begin_day(6, 2, 1, 1, 10.0)
	_log.write_map(map, 6)
	found = DirAccess.open("%s/maps" % run_dir).get_files()
	t.check(found.has("day06-attempt3.png"),
			"day 6 keeps its own count across whatever happened to other days in between")
	_put_back_the_suite_log()
	_delete_recursive(scratch)

## The run's calendar (`RunCalendar.finish_day()`) retries a lost day by starting it again with the
## same day number — `begin_day()` sees the same day twice — and `write_map()` is called
## once per attempt by `RunSession`. Without the attempt in the name the second call's map would
## overwrite the first's, which is exactly the picture worth keeping: the day that went wrong.
func _test_a_second_attempt_at_a_day_writes_a_second_map_instead_of_overwriting(t) -> void:
	var map := CityGenerator.generate(4242)
	var scratch := "user://telemetry-test-second-%d" % Time.get_ticks_usec()
	_use_a_log_over(scratch)
	_log.begin_run(778812346, false)
	var run_dir := _log.current_log().path.get_base_dir()
	t.check(_log.current_log().path.begins_with(scratch + "/"),
			"the run lands under the folder it was handed, not the player's own (got '%s')"
			% _log.current_log().path)

	_log.begin_day(6, 2, 778812346, 778812346, 10.0)
	_log.write_map(map, 6)
	_log.write_map(map, 6, [], null, [], true)  # dusk, same attempt
	_log.begin_day(6, 2, 778812346, 778812346, 10.0)  # the retry a nerve buys
	_log.write_map(map, 6)
	_log.write_map(map, 6, [], null, [], true)

	var found := DirAccess.open("%s/maps" % run_dir).get_files()
	t.check(found.has("day06-attempt1.png"),
			"the first attempt's dawn map is still there (got %s)" % found)
	t.check(found.has("day06-attempt1-dusk.png"),
			"and its dusk map is too (got %s)" % found)
	t.check(found.has("day06-attempt2.png"),
			"the retry writes a second dawn picture instead of overwriting the first (got %s)"
			% found)
	t.check(found.has("day06-attempt2-dusk.png"),
			"and a second dusk picture (got %s)" % found)

	_put_back_the_suite_log()
	_delete_recursive(scratch)

# -------------------------------------------------------------- the web override ---

## `TelemetryPage.asks_for_telemetry()` is the pure half of the web override, pulled out for
## exactly this: a test process is never a Web export, so there is no real
## `window.location.search` to drive it with.
func _test_the_web_override_flag_parses_the_query(t) -> void:
	t.check(TelemetryPage.asks_for_telemetry("?telemetry=1"),
			"the leading '?' a real address bar gives is not part of the key")
	t.check(TelemetryPage.asks_for_telemetry("telemetry=1"),
			"and it parses just as well without one")
	t.check(TelemetryPage.asks_for_telemetry("?seed=4242&telemetry=1&day=3"),
			"telemetry is found among other query parameters, wherever it sits")
	t.check(not TelemetryPage.asks_for_telemetry("?telemetry=0"),
			"any value but '1' leaves the platform default in place")
	t.check(not TelemetryPage.asks_for_telemetry("?seed=4242"),
			"a query with no telemetry key answers false rather than guessing")
	t.check(not TelemetryPage.asks_for_telemetry(""), "no query at all is also false")

## *(2026-09-06, the player: "I never asked for telemetry on web ... that browser build should be
## dev only the CI build is release.")* the web override's gate is a build type and a
## platform, which a test cannot fake together, so `TelemetryPage.reads_the_url()` makes that promise a truth
## table instead.
func _test_reads_the_url_only_when_debug_and_web(t) -> void:
	t.check(TelemetryPage.reads_the_url(true, true),
			"a debug build on the web reads the query string -- the one case the flag exists for")
	t.check(not TelemetryPage.reads_the_url(false, true),
			"a release build on the web does not -- the published page, and the promise being made")
	t.check(not TelemetryPage.reads_the_url(true, false),
			"a debug build off the web does not -- there is no address bar to ask")
	t.check(not TelemetryPage.reads_the_url(false, false),
			"and neither does a release build off the web")

# --------------------------------------------------------------------- spikes ---
# *(`docs/TODO.md`, "The 24 ms frame, found": the observer already keeps a per-second worst frame
# for the `frame` line; under `--spikes` it also keeps the running mean of that same second's
# frames and names the one frame that ran past twice it, plus what changed since the previous
# frame — no new per-frame hook on a gameplay class, the **telemetry** rule's own "the observer
# reads state".)*

## A frame watch writing into lines of the test's own, as the observer's writes into the run log
## (`TelemetryObserver` hands its `FrameWatch` the log's `note`), and fed a series of frame lengths
## the way the observer hands it each frame's: a frame's length is the one thing a real frame cannot
## be told. Under `--spikes` (`spikes`) the watch asks the scene her tile and the live event count,
## here a street corner with nothing on it.
class Frames:
	var lines: Array[String] = []
	var watch := FrameWatch.new(noted)

	func noted(kind: String, text: String) -> void:
		lines.append("%s %s" % [kind, text])

	func feed(deltas: Array, spikes := true) -> void:
		for delta: float in deltas:
			watch.watch(delta, spikes, scene)

	func scene() -> Array:
		return [Vector2i(12, 30), 0]

	func spikes() -> Array[String]:
		return lines.filter(func(line: String) -> bool: return line.begins_with("spike"))

## `count` copies of `dt`, for building a second's worth of frames without spelling each one out.
func _steady_frames(count: int, dt: float) -> Array:
	var out: Array = []
	for i in count:
		out.append(dt)
	return out

## One frame at five times the mean of the ten steady frames before it, padded out with more
## steady frames so the second's own `frame`/`spike` report actually closes.
func _test_a_frame_past_twice_the_mean_writes_one_spike_line(t) -> void:
	var frames := Frames.new()
	var deltas := _steady_frames(10, 0.02)
	deltas.append(0.1)
	deltas.append_array(_steady_frames(36, 0.02))
	frames.feed(deltas)

	var spikes := frames.spikes()
	t.check(spikes.size() == 1,
			"one frame past twice the mean writes exactly one spike line (got %d)" % spikes.size())
	if not spikes.is_empty():
		t.check(spikes[0].contains("100.0ms"),
				"the spike line carries the frame's own length (got '%s')" % spikes[0])
		t.check(spikes[0].contains("mean 20.0ms"),
				"and the mean it was measured against (got '%s')" % spikes[0])

## No frame in a second of ordinary frames is ever twice the mean of its own neighbours.
func _test_steady_frames_write_no_spike_line(t) -> void:
	var frames := Frames.new()
	frames.feed(_steady_frames(55, 0.02))
	t.check(frames.spikes().is_empty() and frames.lines.size() == 1,
			"a second of ordinary frames writes no spike line")

## Two frames qualify in the same second — a big one, then a smaller one that still clears twice
## the (now higher) mean. The rate limit keeps the worse of the two, not the more recent.
func _test_two_spikes_in_one_second_write_only_the_worse_one(t) -> void:
	var frames := Frames.new()
	var deltas := _steady_frames(10, 0.02)
	deltas.append(0.5)
	deltas.append_array(_steady_frames(5, 0.02))
	deltas.append(0.15)
	deltas.append_array(_steady_frames(5, 0.02))
	frames.feed(deltas)

	var spikes := frames.spikes()
	t.check(spikes.size() == 1,
			"a second rate-limited to at most one spike line, however many frames qualify (got %d)"
			% spikes.size())
	if not spikes.is_empty():
		t.check(spikes[0].contains("500.0ms"),
				"and it names the worse of the two, not the more recent (got '%s')" % spikes[0])

## The same series as the first test, with the flag off: nothing about the frame accounting
## changes, but no spike line is ever written.
func _test_no_spike_line_with_the_flag_off(t) -> void:
	var frames := Frames.new()
	var deltas := _steady_frames(10, 0.02)
	deltas.append(0.1)
	deltas.append_array(_steady_frames(36, 0.02))
	frames.feed(deltas, false)

	t.check(frames.spikes().is_empty() and frames.lines.size() == 1,
			"with --spikes off, no spike line even across a frame far past twice the mean")


## A baked page says which of the two sanctioned moments it was read from disk in, how long the
## read took and how big the page is — the line a reader scans to answer "did anything load in a
## frame somebody was walking in" — and says again, on the release that actually drops it, how
## long it was resident. **Both halves are one line each, per page rather than per call**: a
## second `acquire()` of a resident page reads nothing and a release above the last frees nothing,
## so a line for either would report a load or a drop that did not happen.
## `OUTSIDE` is the fourth value the load line can carry and is deliberately
## not produced here: `AtlasLibrary.acquire()` raises a real engine error on it, and an engine
## error in a suite makes the gate red whether or not a test expected it. What that value means
## is `tests/test_atlas_loading.gd`'s, asked through `moment_for_a_load()` with nothing loaded.
## Asked of a library of the test's own (`AtlasLibrary.new()`), handed the suite's log to write into
## (`trace_note`, as `main` hands the sitting's the boot's trace), so the count this test watches
## starts at nought whatever any other library in the process holds — a `City` left standing by an
## earlier suite holds `events` on its own library, not on this one — and the library is dropped
## with the test, leaving nothing behind for the suite that runs next.
func _test_a_baked_page_says_which_moment_loaded_it(t) -> void:
	var atlas := AtlasLibrary.new()
	atlas.trace_note = _log.note
	var group := EventPictures.ATLAS_GROUP
	_log.begin_run(0)
	atlas.claim_the_loading_moments(AtlasLibrary.MOMENT_STARTUP)
	atlas.hold_for_the_process(group)
	atlas.close_loading_window()
	# The second acquire is a consumer's, on a page already resident: it reads nothing, so it
	# must not write a second line about a load that did not happen — and its release drops no
	# memory, so that must not write one either.
	atlas.acquire(group)
	atlas.release(group)
	atlas.stop_holding(group)
	var loaded: Array[String] = []
	var released: Array[String] = []
	for line: String in _log.current_log().lines:
		if not line.contains("atlas page '%s'" % group):
			continue
		if line.contains("released"):
			released.append(line)
		else:
			loaded.append(line)
	_log.end_run()

	t.check(loaded.size() == 1, "one line per page actually read from disk (got %d)" % loaded.size())
	for line in loaded:
		t.check(line.substr(6, 2) == "  " and line.contains("texture"),
				"the page line is an ordinary texture entry (got '%s')" % line)
		t.check(line.contains("in the startup"),
				"and names the moment it loaded in (got '%s')" % line)
		t.check(line.contains(" ms") and line.contains(" x "),
				"with what the read cost and how big the page is (got '%s')" % line)
	t.check(released.size() == 1,
			"and one line per page actually dropped, not per release (got %d)" % released.size())
	for line in released:
		t.check(line.substr(6, 2) == "  " and line.contains("texture"),
				"the release line is an ordinary texture entry too (got '%s')" % line)
		t.check(line.contains(" s: ") and line.contains(" x "),
				"saying how long the page was resident and how big it was (got '%s')" % line)

# ------------------------------------------------------------------ helpers ---

## A day's own stream, fixed to one city so a picture test is asserting the drawing rather than
## whichever day the generator happened to hand it.
func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [4242, day])
	return rng

## Everything a planned day is, as one comparable string: what was placed, where, and in what
## order. Positions to the pixel, because a shifted RNG moves an event without changing the
## set of events.
func _plan_signature(map: CityMap, day: int, trace: RunTrace = null) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("telemetry:%d:%d" % [map.seed_used, day])
	var consumed: Array[String] = []
	var parts: Array[String] = []
	for plan in EventScheduler.build_day(DaySpec.for_day(day), rng, map, CalmAreas.of(map),
			consumed, [], null, 0,
			PackedVector2Array(), [], [], trace).placements():
		parts.append("%s@%.2f,%.2f" % [plan.def.id, plan.position.x, plan.position.y])
	# The one-shot ledger is part of the answer: a roll that fires on day 3 rather than day 4
	# is exactly the divergence this is looking for.
	parts.append("consumed:" + ",".join(consumed))
	return "|".join(parts)

## Where every block ends up after a whole run of scheduled advances.
func _arc_signature(map: CityMap, trace: RunTrace = null) -> String:
	var state := CityState.new()
	if trace:
		state.trace = trace
	var parts: Array[String] = []
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		state.begin_day(map.block_plans, day)
	var blocks: Array = map.block_plans.keys()
	blocks.sort()
	for block: Vector2i in blocks:
		parts.append("%s=%d:%d" % [RunTrace.tile(block),
				state.purpose_of(map.block_plans, block), CityStateReads.changed_on(state, block)])
	return "|".join(parts)

# --------------------------------------------------------- moved in: the log's own ---

## `--invincible` is noted on the day header the way the seed is, once when the day opens, never as
## a per-frame entry, so a log of a day that could not be lost says so.
func _test_the_day_header_notes_the_invincible_flag_once_per_day(t) -> void:
	_log.begin_run(4242, false)

	_log.configure(RunConfig.parse(PackedStringArray(["--invincible"]), "", true))
	_log.begin_day(1, 1, 4242, 4242, 144.0)
	var on_lines := _log.current_log().lines.duplicate()

	_log.configure(RunConfig.parse(PackedStringArray(), "", true))
	_log.begin_day(2, 1, 4242, 4242, 144.0)
	var off_lines := _log.current_log().lines.duplicate()

	_log.configure(null)
	_log.end_run()

	# The header line is the last one `begin_day` wrote before the next call — noted the same
	# way the seed is, once when the day opens, never as a per-frame entry.
	t.check(on_lines[on_lines.size() - 1].contains("invincible"),
		"the day header notes the flag the way it notes the seed (got '%s')"
		% on_lines[on_lines.size() - 1])
	t.check(not off_lines[off_lines.size() - 1].contains("invincible"),
		"and says nothing on a day played with the flag off (got '%s')"
		% off_lines[off_lines.size() - 1])

## The run log's own burst refuses in a headless run, where its screen draws nothing; the refusal
## starts nothing, so a second request is refused the same way and not as an overlap.
func _test_a_headless_burst_is_refused_without_a_capture_wait(t) -> void:
	_log.begin_run(0, false)
	t.check(not _log.start_burst("headless test"),
			"headless capture refuses without beginning a renderer wait")
	var lines := _log.current_log().lines
	t.check(not _log.start_burst("headless again")
				and lines.filter(func(line: String) -> bool:
					return line.contains("burst refused: no drawable viewport")).size() == 2
				and lines.filter(func(line: String) -> bool:
					return line.contains("another burst is active")).is_empty(),
			"headless refusal leaves no active recorder")
	_log.end_run()

## `end_day()` and `end_run()` each cut the active sequence short, with their own reason. A log over
## a folder of the test's own is handed a recorder on the burst suite's bench (its screen, clock and
## scratch folder, `tests/test_burst_capture.gd`) through `use_bursts()`, the way `main` hands the
## log it makes the game's own, which is on the viewport and draws nothing here.
func _test_a_day_or_a_run_ending_cuts_the_active_burst_short(t) -> void:
	var bench = BurstSuite.Bench.new("day-and-run")
	var scratch := "user://telemetry-test-bursts-%d" % Time.get_ticks_usec()
	_use_a_log_over(scratch)
	_log.use_bursts(bench.recorder)
	_log.begin_run(0, false)
	var day: String = bench.start("cut by the day")
	bench.draw()
	_log.end_day()
	var by_day: Dictionary = bench.manifest(day)
	t.check(by_day.get("status") == "cancelled" and by_day.get("reason") == "day ended"
				and (by_day.get("frames", []) as Array).size() == 1 and not bench.busy(),
			"ending a day cuts its active burst short, keeping the frames drawn")
	var run: String = bench.start("cut by the run")
	bench.draw()
	_log.end_run()
	var by_run: Dictionary = bench.manifest(run)
	t.check(by_run.get("status") == "cancelled" and by_run.get("reason") == "run ended"
				and not bench.busy(),
			"ending the run cuts its active burst short")
	_put_back_the_suite_log()
	_delete_recursive(scratch)
	bench.close()

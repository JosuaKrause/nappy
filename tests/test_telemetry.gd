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
	_test_a_stuck_player_is_logged_once(t)
	_test_a_free_walk_is_never_logged_as_blocked(t)
	_test_idling_with_no_input_is_never_logged_as_blocked(t)
	_test_a_capture_is_never_logged_as_blocked(t)
	_test_the_map_picture_covers_the_city_and_marks_it(t)
	_test_the_map_picture_draws_the_corridor(t)
	_test_the_map_picture_marks_what_the_day_placed(t)
	_test_every_routed_event_is_a_straight_line(t)
	_test_the_map_picture_reads_the_map_and_nothing_else(t)
	_test_a_picture_asked_for_by_hand_is_never_capped(t)
	_test_the_trail_is_sampled_by_distance_not_by_frame(t)
	_test_the_trail_carries_whether_she_was_running(t)
	_test_a_lost_day_restarts_the_trail(t)
	_test_met_means_entering_the_outer_radius_not_merely_being_streamed_in(t)
	_test_the_trail_and_the_met_events_scan_do_not_touch_gameplay(t)
	_test_the_map_picture_draws_the_trail_and_distinguishes_running(t)
	_test_a_runs_files_share_one_folder(t)
	_test_the_attempt_suffix_names_every_attempt_including_the_first(t)
	_test_a_second_attempt_at_a_day_writes_a_second_map_instead_of_overwriting(t)

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

## Without a version a trace cannot be checked against anything, and a dirty tree has to say so
## rather than claim a build that does not describe what ran. Which of the shapes this machine
## gets cannot be asserted — this repo has a tag reachable from `HEAD` (`v0.0.0`), so in practice
## `source_version()` always returns the tag form here, but a shallow checkout with no tags
## reachable is `git describe --always`'s bare-hash fallback, and neither is wrong.
func _test_the_commit_is_recorded_or_honestly_unknown(t) -> void:
	var version := Telemetry.source_version()
	t.check(version != "", "a run always records something about where it came from")
	if version == "unknown":
		# An exported build with no repository to ask. Nothing more to check.
		t.check(true, "no repository here, and the log says so rather than guessing")
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

# --------------------------------------------------------------- being stuck ---
# *(`docs/TODO.md`, "The log says when she is stuck": a `--walk` rig that never left the
# doorstep currently reads as a run, because standing still emits nothing else — no crossing,
# no turn, no contact. `TelemetryObserver._watch_blocked` is the fix, and it is exercised
# directly, the way `test_danger.gd` drives `EventManager._warn_about_the_ground_she_is_on()`
# by hand: it is a per-frame poll with no signal of its own to trigger from outside.)*

## A bare observer with only the one field `_watch_blocked` reads: `_map`, for the tile in the
## sentence. `CityMap.new()` is a real map with nothing generated onto it — `world_to_tile` is
## arithmetic on `Tuning.TILE_SIZE` and asks the generator for nothing.
func _blocked_rig() -> TelemetryObserver:
	var observer := TelemetryObserver.new()
	observer._map = CityMap.new()
	return observer

## Simulates `hold` seconds of a real held key — `Input.action_press`, the same call
## `src/dev/auto_screenshot.gd` uses for `--walk`, so this is the polled state `Stroller` itself
## reads and not a shortcut invented for the test. `here` is fixed throughout, which is the
## rig's stand-in for a wall: displacement is exactly zero rather than merely small.
func _hold_against_a_wall(observer: TelemetryObserver, action: String, here: Vector2,
		hold: float) -> void:
	const STEP := 1.0 / 60.0
	Input.action_press(action)
	var clock := Telemetry.clock()
	var steps := int(round(hold / STEP))
	for i in steps:
		clock += STEP
		Telemetry.set_clock(clock)
		observer._watch_blocked(here)
	Input.action_release(action)

func _blocked_lines(t) -> Array:
	var lines: Array = Telemetry.current_log().lines
	Telemetry.end_run()
	t.check(not Telemetry.is_active(), "and the suite is left dormant again")
	var blocked: Array = []
	for line in lines:
		if line.contains("blocked"):
			blocked.append(line)
	return blocked

## Held for a couple of seconds against a wall that never gives: one line, not one a frame, and
## it is not written until the hold has actually run past `BLOCKED_HOLD_TIME`.
func _test_a_stuck_player_is_logged_once(t) -> void:
	var observer := _blocked_rig()
	Telemetry.begin_memory_log()
	Telemetry.begin_day(1, 1, 1, 1, 180.0)

	_hold_against_a_wall(observer, "move_right", Vector2(100.0, 100.0), 2.0)

	var blocked := _blocked_lines(t)
	t.check(blocked.size() == 1,
			"pressing into a wall for 2s writes exactly one blocked entry (got %d)"
			% blocked.size())
	if not blocked.is_empty():
		t.check(blocked[0].contains("east"),
				"and it names the direction pressed (got '%s')" % blocked[0])
	observer.free()

## The same held key, but she is actually covering ground — `here` advances every step by more
## than `TelemetryObserver.BLOCKED_DRIFT` before the hold ever reaches
## `TelemetryObserver.BLOCKED_HOLD_TIME`. A run this ordinary must never read as stuck.
func _test_a_free_walk_is_never_logged_as_blocked(t) -> void:
	var observer := _blocked_rig()
	Telemetry.begin_memory_log()
	Telemetry.begin_day(1, 1, 1, 1, 180.0)

	const STEP := 1.0 / 60.0
	Input.action_press("move_right")
	var here := Vector2(100.0, 100.0)
	var clock := 0.0
	for i in int(round(3.0 / STEP)):
		clock += STEP
		Telemetry.set_clock(clock)
		here.x += Tuning.WALK_SPEED * STEP
		observer._watch_blocked(here)
	Input.action_release("move_right")

	t.check(_blocked_lines(t).is_empty(), "walking freely for 3s is never logged as blocked")
	observer.free()

## `is_idle()` elsewhere in this file is the legitimate stand-still, and it is a different
## condition from this one on purpose: idling asks nothing about input at all, so a player who
## simply lets go of every key must never be told she is blocked.
func _test_idling_with_no_input_is_never_logged_as_blocked(t) -> void:
	var observer := _blocked_rig()
	Telemetry.begin_memory_log()
	Telemetry.begin_day(1, 1, 1, 1, 180.0)

	const STEP := 1.0 / 60.0
	var here := Vector2(100.0, 100.0)
	var clock := 0.0
	for i in int(round(3.0 / STEP)):
		clock += STEP
		Telemetry.set_clock(clock)
		observer._watch_blocked(here)

	t.check(_blocked_lines(t).is_empty(),
			"standing idle with no direction held is never logged as blocked")
	observer.free()

## M59's own interaction: `chatting_mother` locks input with `Stroller.detain()`, and a captured
## player may well be holding a key the whole way through it — which is exactly what
## `_watch_blocked` reads. Without the gate on `_player.is_detained()` a capture would write
## itself down twice: once as `chat`, by `EventManager`, and once as `blocked`, by this file, for
## the same held key. And the gate has to let go the instant the capture ends, or a real stall
## picked up right after one hides behind a stale anchor.
func _test_a_capture_is_never_logged_as_blocked(t) -> void:
	var observer := _blocked_rig()
	var stroller := Stroller.new()
	observer._player = stroller
	Telemetry.begin_memory_log()
	Telemetry.begin_day(1, 1, 1, 1, 180.0)

	# A conversation running: holding a direction the whole way through it must never surface as
	# a stall, whatever `BLOCKED_HOLD_TIME` says.
	stroller.detain(2.0)
	_hold_against_a_wall(observer, "move_right", Vector2(100.0, 100.0), 2.5)

	# The capture is over — `Stroller._physics_process` would have zeroed this by now — and the
	# same held key against the same wall is a genuine stall again.
	stroller._detained_for = 0.0
	_hold_against_a_wall(observer, "move_right", Vector2(100.0, 100.0), 1.5)

	var blocked := _blocked_lines(t)
	t.check(blocked.size() == 1,
			"the capture writes nothing, and a real stall right after it is still caught (got %d)"
			% blocked.size())
	stroller.free()
	observer.free()

# ------------------------------------------------------------ the trail and the meets ---
# *(`docs/TODO.md`, M66, "the dusk map shows what the player did": a trail belongs in
# `TelemetryObserver`, sampled by distance rather than by frame so it stays bounded and
# framerate-independent, and "met" means she came within an event's own outer radius — the field
# she can actually feel — rather than merely close enough for the plan to have been streamed into
# the world.)*

## A bare observer with only `_player` set, the one field `_watch_the_trail` reads besides the
## position it is handed directly.
func _trail_rig() -> TelemetryObserver:
	var observer := TelemetryObserver.new()
	observer._player = Stroller.new()
	return observer

## Distance sampling, not frame sampling: many small steps inside one tile must leave the trail
## alone, and the first step to cross a tile of distance — however many frames it took — must add
## exactly one point.
func _test_the_trail_is_sampled_by_distance_not_by_frame(t) -> void:
	var observer := _trail_rig()
	var here := Vector2(100.0, 100.0)

	observer._watch_the_trail(here)
	t.check(observer.trail().size() == 1, "the very first sample always leaves a point")

	for i in 20:
		here.x += 1.0
		observer._watch_the_trail(here)
	t.check(observer.trail().size() == 1,
			"twenty one-pixel steps inside a tile leave the trail at one point (got %d)"
			% observer.trail().size())

	here.x += TelemetryObserver.TRAIL_SAMPLE_DISTANCE
	observer._watch_the_trail(here)
	t.check(observer.trail().size() == 2,
			"crossing a tile of distance writes exactly one more point, however many frames it took")

	observer._player.free()
	observer.free()

## The third component of a sample is `Stroller.run_excess_ratio()` at the moment it was taken —
## 0.0 at a walk, above 0.0 the instant she is running faster than a walk — so the dusk map can
## colour a run stretch differently from a walked one without a second trail to keep in step.
func _test_the_trail_carries_whether_she_was_running(t) -> void:
	var observer := _trail_rig()
	observer._player.velocity = Vector2.ZERO
	observer._watch_the_trail(Vector2.ZERO)
	t.check(observer.trail()[0].z == 0.0, "a sample taken at a walk carries no run ratio")

	observer._player.velocity = Vector2(Tuning.RUN_SPEED, 0.0)
	observer._watch_the_trail(Vector2(TelemetryObserver.TRAIL_SAMPLE_DISTANCE, 0.0))
	t.check(observer.trail()[1].z > 0.0,
			"and a sample taken at a sprint carries its run_excess_ratio (got %.2f)"
			% observer.trail()[1].z)

	observer._player.free()
	observer.free()

## `start_day()` resets everything else about yesterday, and the trail is no exception: a rewound
## day was not walked, so the picture of it must start from nothing rather than carrying the
## abandoned attempt's trail into the retry.
func _test_a_lost_day_restarts_the_trail(t) -> void:
	var saved_day := GameState.day
	GameState.day = 1
	var map := CityGenerator.generate(4242)
	var city: City = preload("res://scenes/world/city.tscn").instantiate()
	t.add_child(city)
	city.build(map)
	# Not added to the tree: a bare `Stroller.new()` has no `Camera2D` child, which only the scene
	# it is normally instanced from provides, and `start_day()` reads nothing that needs one.
	var player := Stroller.new()
	player.global_position = city.map.home_world_position()
	player.facing = Vector2.DOWN

	var observer := TelemetryObserver.new()
	observer._city = city
	observer._map = city.map
	observer._player = player

	observer.start_day()
	observer._watch_the_trail(player.global_position + Vector2(200.0, 0.0))
	t.check(not observer.trail().is_empty(), "the trail records a point during the day")

	observer.start_day()
	t.check(observer.trail().is_empty(),
			"a new day's start — including a rewound day's — starts the trail over from nothing")

	GameState.day = saved_day
	observer.free()
	player.free()
	city.free()

## The dusk map's whole reason to exist: `was_live` marks a plan the moment
## `EventManager.stream_around` loads it at `Tuning.EVENT_STREAM_RADIUS` (900px), which is more
## than twice the reach (`def.outer_radius`, typically 150px) of a row that has not telegraphed
## anything yet. "Met" has to be the narrower, honest question — did the field that actually costs
## her something ever reach her — or a day that met eight of forty events would read as forty.
func _test_met_means_entering_the_outer_radius_not_merely_being_streamed_in(t) -> void:
	var map := CityGenerator.generate(4242)
	var city: City = preload("res://scenes/world/city.tscn").instantiate()
	t.add_child(city)
	city.build(map)
	var consumed: Array[String] = []
	city.events.start_day(3, _rng(3), consumed)

	var plan: EventScheduler.Planned = null
	for candidate in city.events.plans():
		if candidate.is_placed() and not candidate.def.city_wide:
			plan = candidate
			break
	t.check(plan != null, "day 3 places something sited and not city-wide to test against")
	if plan == null:
		city.free()
		return

	city.events.stream_around(plan.position)
	t.check(plan.live != null, "streaming in from right on top of it brings it live")

	var observer := TelemetryObserver.new()
	observer._city = city

	# Asserted about `plan` specifically rather than "the dict is empty": `stream_around` from right
	# on top of it may well have streamed in a neighbour too, and a neighbour being met at `far` is
	# not what this test is about.
	var far := plan.live.global_position + Vector2(plan.def.outer_radius + 200.0, 0.0)
	observer._watch_met_events(far)
	t.check(not observer.met_events().has(plan),
			"being streamed in is not being met — she has not come within the outer radius yet")
	t.check(plan.was_live, "the plan is 'was_live' regardless, which answers the looser question")

	var close := plan.live.global_position + Vector2(plan.def.outer_radius - 10.0, 0.0)
	observer._watch_met_events(close)
	t.check(observer.met_events().has(plan),
			"entering the outer radius — the field she can actually feel — is what counts as met")

	observer.free()
	city.free()

## `_test_tracing_a_day_does_not_change_it` is the invariant's own test, and it does not reach
## either of these two: it calls `EventScheduler.build_day` directly and never instantiates an
## observer at all, so it says nothing about `_watch_the_trail` or `_watch_met_events` — the two
## per-frame watchers M66 added, both of which run every frame the observer is alive and both of
## which read live gameplay objects (the player's position; every event instance's
## `global_position`). Neither takes a `RandomNumberGenerator` — there is no `rng` parameter to
## consume from, unlike the hoisted-roll systems the invariant's comment warns about — and neither
## writes anywhere but the observer's own `_trail` and `_met_events`. That is a claim about the
## code, and this is the test that would catch it being wrong: it drives both across four hundred
## frames of a real day, with the log on, and requires the day after to plan exactly as it would
## have if the drive had never happened — the only way that can hold is if nothing either watcher
## did reached `map`, `city.events` or a `day_rng()` stream.
func _test_the_trail_and_the_met_events_scan_do_not_touch_gameplay(t) -> void:
	var map := CityGenerator.generate(4242)
	var city: City = preload("res://scenes/world/city.tscn").instantiate()
	t.add_child(city)
	city.build(map)
	var consumed: Array[String] = []
	city.events.start_day(3, _rng(3), consumed)

	var plan: EventScheduler.Planned = null
	for candidate in city.events.plans():
		if candidate.is_placed() and not candidate.def.city_wide:
			plan = candidate
			break
	t.check(plan != null, "day 3 places something sited and not city-wide to walk near")
	if plan == null:
		city.free()
		return
	city.events.stream_around(plan.position)

	# What day 4 plans, computed before the trail is ever walked.
	var quiet := _plan_signature(map, 4)

	var observer := TelemetryObserver.new()
	observer._city = city
	observer._player = Stroller.new()
	observer._player.global_position = plan.live.global_position \
			+ Vector2(plan.def.outer_radius + 200.0, 0.0)

	Telemetry.begin_memory_log()
	var here: Vector2 = observer._player.global_position
	var towards := (plan.live.global_position - here).normalized()
	for i in 400:
		here += towards * TelemetryObserver.TRAIL_SAMPLE_DISTANCE
		observer._player.global_position = here
		observer._watch_the_trail(here)
		observer._watch_met_events(here)
	Telemetry.end_run()

	t.check(observer.trail().size() > 300,
			"the drive actually sampled the trail, not a vacuous pass (got %d points)"
			% observer.trail().size())
	t.check(not observer.met_events().is_empty(),
			"and walked close enough to mark the plan met, so the scan actually ran")

	var traced := _plan_signature(map, 4)
	t.check(quiet == traced, "four hundred frames of trail sampling and met-events scanning, "
			+ "with the log on, leave what day 4 plans untouched")

	observer._player.free()
	observer.free()
	city.free()

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

## What the day placed, carrying what it is. *(M50, and this is the picture the milestone is
## checked against rather than a decoration on one.)*
##
## The thing being asserted is that the **legend is the drawing**: a picture whose colours have
## drifted from `role_mark` is worse than no picture, because it answers the one question the
## milestone can get badly wrong — *is that wall on the corridor or beside it* — confidently and
## wrongly. Two days rather than one because the vocabulary has four roles and no single day places
## in all of them: day 9 has walls and friction and no one-shot, day 3 is the day the fire engine
## runs.
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
		var plans := EventScheduler.build_day(day, _rng(day), map, consumed, [], [], tree)
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
			t.check(seen.has(TelemetryMap.role_mark(role)),
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
## not `TelemetryObserver._watch_met_events`, which has its own test.
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
		var colour := TelemetryMap.role_mark(plan.role)
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
## walk — the two claims `TelemetryObserver._watch_the_trail` makes about a sample, checked the way
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
		for plan in EventScheduler.build_day(day, _rng(day), map, consumed):
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

# ---------------------------------------------------------------- one folder ---
# *(docs/TODO.md, M70, "all the files of one run live in one folder": the run identity moved from
# a shared filename stem to a folder, `<day>/<minute>/<run>/`, and a day played twice — a nerve
# retries a lost day without the calendar advancing — has to write a second picture rather than
# overwrite the first's.)*

## Deletes a real path this suite wrote, so a test that opens a real run — the only way to check
## a folder actually landed where `begin_run()` says it does — leaves nothing behind for a person
## to find later. Also removes the `<minute>` and `<day>` ancestors once they are empty: nothing in
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
	for ancestor in [path.get_base_dir(), path.get_base_dir().get_base_dir()]:
		var above := DirAccess.open(ancestor)
		if above and above.get_files().is_empty() and above.get_directories().is_empty():
			DirAccess.remove_absolute(ancestor)

## The only way to check a folder actually landed where `begin_run()` says it does is to open a
## real run — `begin_memory_log()` has no path to inspect. `false` (a rig) because this is a
## scripted check rather than a person at the controls, the same reason `check.sh` and `shot.sh`
## write `rig-`.
func _test_a_runs_files_share_one_folder(t) -> void:
	var map := CityGenerator.generate(4242)
	Telemetry.begin_run(778812345, false)
	var log_path := Telemetry.current_log().path
	t.check(log_path != "", "a real run opens a file")
	t.check(log_path.get_file() == "run.log",
			"the log is named plainly — the folder is what says which run it belongs to (got '%s')"
			% log_path.get_file())
	var run_dir := log_path.get_base_dir()
	t.check(run_dir.get_file().begins_with("rig-"),
			"the run folder itself carries the run/rig distinction (got '%s')" % run_dir.get_file())
	t.check(run_dir.get_file().ends_with("-" + Telemetry._file_tag()),
			"and its own name ends with the commit it was played on (got '%s', wanted suffix '-%s')"
			% [run_dir.get_file(), Telemetry._file_tag()])
	var minute_dir := run_dir.get_base_dir().get_file()
	t.check(minute_dir.length() == 4 and minute_dir.is_valid_int(),
			"its parent is the minute folder, HHMM (got '%s')" % minute_dir)

	Telemetry.begin_day(1, 1, 778812345, 778812345, 10.0)
	Telemetry.write_map(map, 1)

	var maps_dir := "%s/maps" % run_dir
	t.check(DirAccess.dir_exists_absolute(maps_dir),
			"the map landed in the run's own maps/ folder rather than beside the log")
	var found := DirAccess.open(maps_dir).get_files()
	t.check(found.has("day01-attempt1.png"),
			"a first attempt is named like every other attempt (got %s)" % found)

	Telemetry.end_run()
	_delete_recursive(run_dir)

## `_attempt_suffix()` is what every filename that can repeat within a run asks for its own name.
## Driven directly against a memory log, so this needs no disk at all — it is a question about
## `_day_attempts`, not about anything written anywhere.
func _test_the_attempt_suffix_names_every_attempt_including_the_first(t) -> void:
	Telemetry.begin_memory_log()
	Telemetry.begin_day(6, 2, 1, 1, 10.0)
	t.check(Telemetry._attempt_suffix() == "-attempt1",
			"a first attempt is named too, so every name has the same shape")
	Telemetry.begin_day(6, 2, 1, 1, 10.0)
	t.check(Telemetry._attempt_suffix() == "-attempt2",
			"a second attempt at the same day is named (a nerve retries without the day advancing)")
	Telemetry.begin_day(7, 2, 1, 1, 10.0)
	t.check(Telemetry._attempt_suffix() == "-attempt1",
			"a different day's first attempt is unaffected by day 6's retry")
	Telemetry.begin_day(6, 2, 1, 1, 10.0)
	t.check(Telemetry._attempt_suffix() == "-attempt3",
			"day 6 keeps its own count across whatever happened to other days in between")
	Telemetry.end_run()

## `GameState.finish_day()` retries a lost day by calling `_start_day()` again with the same
## `GameState.day` — `begin_day()` sees the same day number twice — and `write_map()` is called
## once per attempt from `main.gd`. Without the attempt in the name the second call's map would
## overwrite the first's, which is exactly the picture worth keeping: the day that went wrong.
func _test_a_second_attempt_at_a_day_writes_a_second_map_instead_of_overwriting(t) -> void:
	var map := CityGenerator.generate(4242)
	Telemetry.begin_run(778812346, false)
	var run_dir := Telemetry.current_log().path.get_base_dir()

	Telemetry.begin_day(6, 2, 778812346, 778812346, 10.0)
	Telemetry.write_map(map, 6)
	Telemetry.write_map(map, 6, [], null, [], true)  # dusk, same attempt
	Telemetry.begin_day(6, 2, 778812346, 778812346, 10.0)  # the retry a nerve buys
	Telemetry.write_map(map, 6)
	Telemetry.write_map(map, 6, [], null, [], true)

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

	Telemetry.end_run()
	_delete_recursive(run_dir)

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

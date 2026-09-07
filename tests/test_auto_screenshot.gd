extends RefCounted
## `AutoScreenshot`'s `--walk` parsing: the scripted walk `1s5e` beside the bare direction it
## already understood, and the angled step `3@45@2e` beside `1s5e` — a duration and a bearing
## between a pair of `@`s rather than a duration and a letter, so a script can press a diagonal.
##
## *(`docs/TODO.md`, M66, "A rig that walks a route, because one that holds a key walks into a
## wall": `--walk north|south|east|west` holds one direction for the whole run, so a rig meets the
## first building on that heading and stays there — which is why every dusk map taken with it
## showed a speck where a trail should be. `1s5e` is a script of timed presses instead: one second
## of south then five of east, read left to right.)*
##
## *(`docs/TODO.md`, M87, "No rig can drive a heading that is not an axis": a heading is now an
## arbitrary unit vector, `TouchControls.heading_to()`'s own answer, and `1s5e`'s letters can only
## ever name four of them. `3@45@` presses `move_left`/`move_right` and `move_up`/`move_down`
## through `TouchControls._set_axis()` at the bearing's own fractional strength — the same call
## the real touch scheme presses through — so the vector stays unit length and the rig still
## walks at `Tuning.WALK_SPEED` like every other press. The letters are shorthand for four
## particular bearings now, not a second mechanism.)*
##
## `_ready()` never runs on a script-only instance — the node is never added to a tree here — so
## this calls it and `_process()` by hand, the way `tests/test_main.gd` already reaches past
## `_ready()` for `main.gd`. Every test releases whatever it pressed, since `Input`'s polled state
## is global and outlives the node that set it.

func run(t) -> void:
	_test_a_bare_direction_is_unaffected(t)
	_test_a_script_parses_into_timed_steps(t)
	_test_an_angled_step_parses_its_own_bearing(t)
	_test_letters_are_shorthand_for_four_bearings(t)
	_test_a_malformed_script_parses_to_nothing(t)
	_test_a_script_can_mix_letters_and_angles(t)
	_test_a_script_presses_one_action_at_a_time_in_order(t)
	_test_an_angled_step_presses_both_axes_at_fractional_strength(t)
	_test_an_angled_step_releases_both_axes_when_it_ends(t)
	_test_a_script_lets_go_of_the_last_action_when_it_ends(t)
	_test_a_pursuit_stops_the_script_from_resuming(t)
	_test_a_pursuit_reverses_an_angled_step_too(t)
	_test_a_headless_run_has_nothing_to_photograph(t)

# --------------------------------------------------------------- photographing ---

## The guard that stops `_capture()` awaiting a frame a headless run will never draw. **The hang it
## replaces printed nothing at all**, so the failure read as a slow run rather than as a stuck one,
## and it is reached by any caller of `tools/shot.sh` that has no display to open a window against.
##
## The predicate takes the display server's name rather than reading it, which is what makes this
## testable: the suite is itself headless, so a version that asked `DisplayServer` directly could
## only ever be checked in one of its two states.
func _test_a_headless_run_has_nothing_to_photograph(t) -> void:
	t.check(not AutoScreenshot.can_photograph("headless"),
			"a headless run draws no frame, so there is nothing to save")
	t.check(AutoScreenshot.can_photograph("macos"),
			"a real display server has a frame to photograph")
	t.check(AutoScreenshot.can_photograph("windows") and AutoScreenshot.can_photograph("x11"),
			"and so does every other one — only the null server is refused")
	t.check(not AutoScreenshot.can_photograph(DisplayServer.get_name()),
			"and this suite is itself headless, which is why the name is a parameter")

# ------------------------------------------------------------------- parsing ---

## `1s5e|north` etc. still means exactly what it always meant: held for the whole run, and never
## routed through `_parse_script` at all — `from_command_line` checks `_DIRECTIONS` first.
func _test_a_bare_direction_is_unaffected(t) -> void:
	t.check(AutoScreenshot._DIRECTIONS.has("north"), "a direction word is still in the old table")
	t.check(AutoScreenshot._parse_script("north").is_empty(),
			"and read as a script it is not a run of <seconds><letter> pairs, so it parses to nothing")

## The player's own example, and the one named in `docs/TODO.md`. Asserted on `direction` rather
## than an action name — `docs/TODO.md`'s own words are "the letters become shorthand for four
## particular bearings rather than a separate mechanism" — but the resulting press is bit-for-bit
## what the old `"action"`-keyed shape produced; see `_test_a_script_presses_one_action_at_a_time_in_order`.
func _test_a_script_parses_into_timed_steps(t) -> void:
	var steps := AutoScreenshot._parse_script("1s5e")
	t.check(steps.size() == 2, "1s5e is two steps (got %d)" % steps.size())
	if steps.size() != 2:
		return
	t.check(steps[0]["direction"] == Vector2.DOWN and is_equal_approx(steps[0]["seconds"], 1.0),
			"one second of south (got %s)" % steps[0])
	t.check(steps[1]["direction"] == Vector2.RIGHT and is_equal_approx(steps[1]["seconds"], 5.0),
			"then five of east (got %s)" % steps[1])

## `3@45@2e` is the syntax `docs/TODO.md` asks for: a duration and a bearing in degrees between a
## pair of `@`s, coexisting with `<seconds><letter>` in the same script — the closing `@` is what
## stops a bearing's own digits from swallowing the next step's, the way a letter already ends a
## step's digits without any separator at all.
func _test_an_angled_step_parses_its_own_bearing(t) -> void:
	var steps := AutoScreenshot._parse_script("3@45@2e")
	t.check(steps.size() == 2, "3@45@2e is two steps (got %d)" % steps.size())
	if steps.size() != 2:
		return
	t.check(is_equal_approx(steps[0]["seconds"], 3.0), "three seconds at the angle (got %s)" % steps[0])
	# The convention `TelemetryLog.compass()` reads a bearing back with: +y is south, so 0° is
	# north, 90° is east and a bearing runs clockwise between them.
	var expected := Vector2(sin(deg_to_rad(45.0)), -cos(deg_to_rad(45.0)))
	t.check(steps[0]["direction"].is_equal_approx(expected),
			"45° parses to the same vector TelemetryLog.compass() would read 45° back off (got %s)"
			% steps[0]["direction"])
	t.check(is_equal_approx(steps[0]["direction"].length(), 1.0),
			"and the parsed direction is unit length (got %.6f)" % steps[0]["direction"].length())
	t.check(steps[1]["direction"] == Vector2.RIGHT and is_equal_approx(steps[1]["seconds"], 2.0),
			"then two seconds east — the old vocabulary unaffected by the new step beside it (got %s)"
			% steps[1])

## *(`docs/TODO.md`: "The letters become shorthand for four particular bearings rather than a
## separate mechanism.")* Asserted directly: a lettered step's own direction is exactly the vector
## the matching bearing would parse to, not a value a different code path happens to agree with.
func _test_letters_are_shorthand_for_four_bearings(t) -> void:
	var by_letter := {"n": 0.0, "s": 180.0, "e": 90.0, "w": 270.0}
	for letter: String in by_letter:
		var from_letter: Vector2 = AutoScreenshot._LETTERS[letter]
		var from_bearing: Vector2 = AutoScreenshot._bearing_to_direction(by_letter[letter])
		t.check(from_letter.is_equal_approx(from_bearing),
				"'%s' is shorthand for %.0f° (got %s vs %s)"
				% [letter, by_letter[letter], from_letter, from_bearing])

## Four ways to be malformed, and all of them fail the whole script rather than skipping one step —
## a script that silently drops a bad step walks a different route than the one asked for, which is
## exactly what determinism exists to rule out. The last three are the angled step's own ways.
func _test_a_malformed_script_parses_to_nothing(t) -> void:
	t.check(AutoScreenshot._parse_script("").is_empty(), "the empty string is not a script")
	t.check(AutoScreenshot._parse_script("5").is_empty(),
			"a number with nothing after it has no direction to press")
	t.check(AutoScreenshot._parse_script("5x").is_empty(),
			"an unknown letter is not one of the walk directions")
	t.check(AutoScreenshot._parse_script("0s").is_empty(),
			"a zero-second step presses nothing for no time, which is not a step")
	t.check(AutoScreenshot._parse_script("3@").is_empty(),
			"an '@' with no digits after it has no bearing to read")
	t.check(AutoScreenshot._parse_script("3@45").is_empty(),
			"an '@' with no closing '@' would swallow whatever comes after it as more bearing")
	t.check(AutoScreenshot._parse_script("3@x@").is_empty(),
			"a non-digit between the '@'s is not a bearing either")

## A script can mix the old vocabulary and the new one in the same string, in the same
## left-to-right order — `docs/TODO.md`'s own requirement for where the angled step lands.
func _test_a_script_can_mix_letters_and_angles(t) -> void:
	var steps := AutoScreenshot._parse_script("1s3@45@2e")
	t.check(steps.size() == 3, "one lettered step, one angled step, one lettered step (got %d)"
			% steps.size())
	if steps.size() != 3:
		return
	t.check(steps[0]["direction"] == Vector2.DOWN, "the lettered step first")
	t.check(is_equal_approx(steps[1]["direction"].length(), 1.0)
			and not steps[1]["direction"].is_equal_approx(Vector2.DOWN),
			"the angled step in the middle, its own bearing rather than an axis")
	t.check(steps[2]["direction"] == Vector2.RIGHT, "and the lettered step after it, unaffected")

# -------------------------------------------------------------------- stepping ---

## A fresh rig ready to run a script, never added to a tree — `_seconds_to_wait` is set high
## enough that no test here ever reaches `--after` and calls `_capture()`, which quits the process
## headless rather than photographing it, and would therefore end the suite mid-run.
func _script_rig(script: String) -> AutoScreenshot:
	var node := AutoScreenshot.new()
	node._seconds_to_wait = 60.0
	node._script = AutoScreenshot._parse_script(script)
	return node

## `_ready()` presses the first step's direction immediately, the same as a bare direction would —
## and each step ends by releasing its own press and pressing the next one, never both at once.
func _test_a_script_presses_one_action_at_a_time_in_order(t) -> void:
	var node := _script_rig("1s2e")
	node._ready()
	t.check(Input.is_action_pressed("move_down"), "the first step is pressed as soon as it is ready")
	node._process(0.5)
	t.check(Input.is_action_pressed("move_down"),
			"and still pressed before its second is up (0.5s in)")

	node._process(0.6)
	t.check(not Input.is_action_pressed("move_down"),
			"the first action lets go once its second is up (1.1s in)")
	t.check(Input.is_action_pressed("move_right"), "and the second step's action takes over")

	Input.action_release("move_down")
	Input.action_release("move_right")
	node.free()

## The trap the milestone is named for: an angled step must press *both* axes, at the bearing's
## own fractional strength, not one axis at full strength — a step that pressed a shorter vector
## would reintroduce the slow walk M82 deleted. Read through `Input.get_action_strength()` rather
## than the boolean `is_action_pressed()` the other stepping tests use, since strength is exactly
## what is being asserted here.
func _test_an_angled_step_presses_both_axes_at_fractional_strength(t) -> void:
	var node := _script_rig("3@45@")
	node._ready()
	var right := Input.get_action_strength("move_right")
	var up := Input.get_action_strength("move_up")
	var down := Input.get_action_strength("move_down")
	t.check(is_equal_approx(right, 0.70710678),
			"45° presses move_right at 0.707 (got %.4f)" % right)
	t.check(is_equal_approx(up, 0.70710678),
			"and move_up at 0.707, the other half of the same unit vector (got %.4f)" % up)
	t.check(down == 0.0, "and never the opposite axis (got %.4f)" % down)
	var combined := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	t.check(is_equal_approx(combined.length(), 1.0),
			"the two fractional presses combine back into a unit vector — must never press a "
			+ "vector shorter than one (got %.6f)" % combined.length())

	Input.action_release("move_right")
	Input.action_release("move_up")
	node.free()

## The release path (`_release_direction`) is shared with the lettered steps, so a script ending
## on an angled one has to let go of both axes just as cleanly as
## `_test_a_script_lets_go_of_the_last_action_when_it_ends` checks for a lettered one.
func _test_an_angled_step_releases_both_axes_when_it_ends(t) -> void:
	var node := _script_rig("1@45@")
	node._ready()
	t.check(Input.get_action_strength("move_right") > 0.0, "the angle is pressed once ready")
	node._process(1.1)
	t.check(Input.get_action_strength("move_right") == 0.0
			and Input.get_action_strength("move_up") == 0.0,
			"and both axes let go once the one step's second is up")

	Input.action_release("move_right")
	Input.action_release("move_up")
	node.free()

## The last step releases its own press rather than leaving it held, since nothing after the
## script is meant to keep walking — `_advance_script` calls `_release_direction()` once the
## index runs off the end, and never presses a next step.
func _test_a_script_lets_go_of_the_last_action_when_it_ends(t) -> void:
	var node := _script_rig("1s1e")
	node._ready()
	node._process(1.1)
	t.check(Input.is_action_pressed("move_right"), "the second and last step is pressed (1.1s in)")

	node._process(1.1)
	t.check(not Input.is_action_pressed("move_right"),
			"the script lets go of it once the last step's second is up (2.2s in)")
	t.check(not Input.is_action_pressed("move_down"), "and nothing earlier is still held either")

	Input.action_release("move_down")
	Input.action_release("move_right")
	node.free()

## `_turn_and_run` repurposes `_holding` or `_holding_direction` the instant a pursuit starts, and
## a script resuming underneath it would fight it for the same pressed axes — so once `_fled` is
## true the script must stop advancing, whatever `_elapsed` says.
func _test_a_pursuit_stops_the_script_from_resuming(t) -> void:
	var node := _script_rig("1s1e")
	node._ready()
	node._fled = true

	node._process(5.0)
	t.check(Input.is_action_pressed("move_down"),
			"a fled rig never advances past the step it fled during")
	t.check(not Input.is_action_pressed("move_right"),
			"and never presses a later step's action either")

	Input.action_release("move_down")
	Input.action_release("move_right")
	node.free()

## A bare direction holds through `_holding`, which `_turn_and_run` already knew how to reverse.
## Any script step — lettered or angled — holds through `_holding_direction` instead, so without
## the `elif` in `_turn_and_run` a pursuit starting mid-script would press `run` in whatever
## direction was already held instead of turning round — the wrong answer to the one encounter
## with a right one.
func _test_a_pursuit_reverses_an_angled_step_too(t) -> void:
	var node := _script_rig("5@45@")
	node._ready()
	var before := node._holding_direction
	node._turn_and_run()
	t.check(node._holding_direction.is_equal_approx(-before),
			"turning round negates the diagonal (got %s from %s)" % [node._holding_direction, before])
	t.check(Input.is_action_pressed("run"), "and holds run, the same as a bare-direction flee")

	Input.action_release("move_left")
	Input.action_release("move_down")
	Input.action_release("run")
	node.free()

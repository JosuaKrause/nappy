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
## arbitrary unit vector, as a touch's heading always is, and `1s5e`'s letters can only
## ever name four of them. `3@45@` presses `move_left`/`move_right` and `move_up`/`move_down`
## through `TouchControls.set_axis()` at the bearing's own fractional strength — the same call
## the real touch scheme presses through — so the vector stays unit length and the rig still
## walks at `Tuning.WALK_SPEED` like every other press. The letters are shorthand for four
## particular bearings now, not a second mechanism.)*
##
## The rig is built the way `main` builds it, by `AutoScreenshot.from_config()` from the words a
## player types (`RunConfig.parse()`), and handed a clock the suite moves (`simulation_clock`, the
## one a scene recipe hands its screenshot). It stands in the tree, so its own `_ready()` and
## `_process()` run on real frames, and what a word of the script means is read off what the rig
## presses on `Input` at a time on that clock. Every test releases whatever it pressed, since
## `Input`'s polled state is global and outlives the node that set it.

func run(t: TestRunner) -> void:
	await _test_a_bare_direction_is_held_for_the_whole_run(t)
	await _test_a_script_runs_in_timed_steps(t)
	await _test_an_angled_step_presses_its_own_bearing(t)
	await _test_letters_are_shorthand_for_four_bearings(t)
	await _test_a_malformed_script_presses_nothing(t)
	await _test_a_script_can_mix_letters_and_angles(t)
	await _test_a_decimal_duration_runs_a_fractional_second(t)
	await _test_a_second_decimal_point_is_malformed(t)
	await _test_the_stand_still_letter_presses_nothing(t)
	await _test_an_uppercase_letter_marks_a_running_step(t)
	await _test_a_script_presses_one_action_at_a_time_in_order(t)
	await _test_a_running_step_presses_and_releases_the_run_action(t)
	await _test_a_stand_still_step_presses_nothing_and_releases_nothing(t)
	await _test_an_angled_step_presses_both_axes_at_fractional_strength(t)
	await _test_an_angled_step_releases_both_axes_when_it_ends(t)
	await _test_a_script_lets_go_of_the_last_action_when_it_ends(t)
	await _test_a_pursuit_stops_the_script_from_resuming(t)
	await _test_a_pursuit_reverses_an_angled_step_too(t)
	_test_a_headless_run_has_nothing_to_photograph(t)
	_test_the_scan_finds_a_bare_wait_on_the_render_loop(t)
	_test_only_a_covered_recording_needs_an_on_demand_frame(t)
	_test_no_capture_under_src_waits_on_the_render_loop_alone(t)

const UI := preload("res://tests/ui_screens.gd")

# --------------------------------------------------------------- photographing ---

## The scene a child process runs to be photographed: a rig built the way `main` builds it by
## `AutoScreenshot.from_config()`, asked for a picture at once.
const PROBE := """extends Node
func _ready() -> void:
	var words := PackedStringArray(["--screenshot", OS.get_cmdline_user_args()[0], "--after", "0"])
	add_child(AutoScreenshot.from_config(RunConfig.parse(words, "", true)))
"""

## The guard that stops `_capture()` awaiting a frame a headless run will never draw. **The hang it
## replaces printed nothing at all**, so the failure read as a slow run rather than as a stuck one,
## and it is reached by any caller of `tools/shot.sh` that has no display to open a window against.
##
## Asked of a process of its own, started headless the way a display-less machine starts one: the
## rig refuses with the line that says why, exits non-zero, and writes no picture to its path.
func _test_a_headless_run_has_nothing_to_photograph(t: TestRunner) -> void:
	var stem := "user://auto_screenshot_probe_%d" % OS.get_process_id()
	var script := FileAccess.open(stem + ".gd", FileAccess.WRITE)
	script.store_string(PROBE)
	script.close()
	var scene := FileAccess.open(stem + ".tscn", FileAccess.WRITE)
	scene.store_string("[gd_scene load_steps=2 format=3]\n[ext_resource type=\"Script\" path=\"%s.gd\" id=\"1\"]\n[node name=\"Probe\" type=\"Node\"]\nscript = ExtResource(\"1\")\n" % stem)
	scene.close()
	var picture := ProjectSettings.globalize_path(stem + ".png")
	var output: Array = []
	var status := OS.execute(OS.get_executable_path(), PackedStringArray([
			"--headless", "--path", ProjectSettings.globalize_path("res://"), "--quit-after", "600",
			stem + ".tscn", "--", picture]), output, true)
	var text_output := "\n".join(output)
	t.check(status == 1 and text_output.contains("nothing to photograph"),
			"a headless run draws no frame, so it says there is nothing to save and exits 1: %s" % text_output)
	t.check(not FileAccess.file_exists(stem + ".png"), "and writes no picture")
	DirAccess.remove_absolute(stem + ".tscn")
	DirAccess.remove_absolute(stem + ".gd")
	DirAccess.remove_absolute(stem + ".gd.uid")

# ------------------------------------------------------------------ the rig ---

const _MOVES: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]

## A rig for the words a player types after `--walk` (and `--flee`), built by the game's own
## `from_config()` and standing in the tree on `clock`. `--after 600` keeps it from ever reaching
## its capture, which quits a headless process.
func _rig(t: TestRunner, clock: UI.FakeClock, words: Array[String], flee := false) -> AutoScreenshot:
	var args := ["--screenshot", "scratch_unused.png", "--after", "600", "--walk"] + words
	if flee:
		args.append("--flee")
	var node := AutoScreenshot.from_config(RunConfig.parse(PackedStringArray(args), "", true))
	node.simulation_clock = clock.read
	t.add_child(node)
	return node

## Moves the clock to `seconds` and lets the rig's frames read it.
func _at(t: TestRunner, clock: UI.FakeClock, seconds: float) -> void:
	clock.now = seconds
	await UI.frames(t)

## The strength each move action is pressed at, left, right, up, down.
func _strengths() -> Array[float]:
	var found: Array[float] = []
	for action in _MOVES:
		found.append(Input.get_action_strength(action))
	return found

func _strengths_are(left: float, right: float, up: float, down: float) -> bool:
	var found := _strengths()
	return is_equal_approx(found[0], left) and is_equal_approx(found[1], right) \
			and is_equal_approx(found[2], up) and is_equal_approx(found[3], down)

func _nothing_pressed() -> bool:
	return _strengths_are(0.0, 0.0, 0.0, 0.0)

func _let_go(rig: Node) -> void:
	rig.free()
	for action in _MOVES:
		Input.action_release(action)
	Input.action_release(&"run")

# ------------------------------------------------------------------- parsing ---

## `--walk north` still means exactly what it always meant: held for the whole run, and never
## routed through the script's parsing at all.
func _test_a_bare_direction_is_held_for_the_whole_run(t: TestRunner) -> void:
	var clock := UI.FakeClock.new()
	var rig := _rig(t, clock, ["north"])
	t.check(Input.is_action_pressed("move_up"), "a direction word presses its action at once")
	await _at(t, clock, 59.0)
	t.check(Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_down"),
			"and still holds it a minute in, as one key held down")
	_let_go(rig)

## The player's own example, and the one named in `docs/TODO.md`: one second of south then five of
## east, read left to right. The resulting press is bit-for-bit what the old `"action"`-keyed shape
## produced; see `_test_a_script_presses_one_action_at_a_time_in_order`.
func _test_a_script_runs_in_timed_steps(t: TestRunner) -> void:
	var clock := UI.FakeClock.new()
	var rig := _rig(t, clock, ["1s5e"])
	await _at(t, clock, 0.5)
	t.check(_strengths_are(0.0, 0.0, 0.0, 1.0),
			"one second of south (got %s)" % [_strengths()])
	await _at(t, clock, 3.0)
	t.check(_strengths_are(0.0, 1.0, 0.0, 0.0),
			"then east, at 3s, well within its five (got %s)" % [_strengths()])
	await _at(t, clock, 5.9)
	t.check(Input.is_action_pressed("move_right"), "still east at 5.9s, short of the six it ends at")
	await _at(t, clock, 6.1)
	t.check(_nothing_pressed(), "and nothing pressed once the five seconds of east are up")
	_let_go(rig)

## `3@45@2e` is the syntax `docs/TODO.md` asks for: a duration and a bearing in degrees between a
## pair of `@`s, coexisting with `<seconds><letter>` in the same script — the closing `@` is what
## stops a bearing's own digits from swallowing the next step's, the way a letter already ends a
## step's digits without any separator at all.
func _test_an_angled_step_presses_its_own_bearing(t: TestRunner) -> void:
	var clock := UI.FakeClock.new()
	var rig := _rig(t, clock, ["3@45@2e"])
	await _at(t, clock, 1.0)
	# The convention `RunTrace.compass()` reads a bearing back with: +y is south, so 0° is
	# north, 90° is east and a bearing runs clockwise between them.
	var expected := Vector2(sin(deg_to_rad(45.0)), -cos(deg_to_rad(45.0)))
	var pressed := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	t.check(pressed.is_equal_approx(expected),
			"45° presses the vector RunTrace.compass() would read 45° back off (got %s)" % pressed)
	t.check(is_equal_approx(pressed.length(), 1.0),
			"and the pressed direction is unit length (got %.6f)" % pressed.length())
	await _at(t, clock, 3.5)
	t.check(_strengths_are(0.0, 1.0, 0.0, 0.0),
			"then two seconds east — the old vocabulary unaffected by the new step beside it (got %s)"
			% [_strengths()])
	await _at(t, clock, 5.5)
	t.check(_nothing_pressed(), "and nothing once both steps are over")
	_let_go(rig)

## *(`docs/TODO.md`: "The letters become shorthand for four particular bearings rather than a
## separate mechanism.")* Asserted directly: a lettered step presses exactly what the matching
## bearing presses, not a value a different code path happens to agree with.
func _test_letters_are_shorthand_for_four_bearings(t: TestRunner) -> void:
	var by_letter := {"n": 0.0, "s": 180.0, "e": 90.0, "w": 270.0}
	for letter: String in by_letter:
		var clock := UI.FakeClock.new()
		var rig := _rig(t, clock, ["1" + letter])
		var from_letter := _strengths()
		_let_go(rig)
		rig = _rig(t, clock, ["1@%d@" % int(by_letter[letter])])
		var from_bearing := _strengths()
		_let_go(rig)
		var same := true
		for i in from_letter.size():
			same = same and is_equal_approx(from_letter[i], from_bearing[i])
		t.check(same and from_letter.max() == 1.0,
				"'%s' is shorthand for %.0f° (got %s vs %s)"
				% [letter, by_letter[letter], from_letter, from_bearing])

## Seven ways to be malformed, and all of them fail the whole script rather than skipping one step —
## a script that silently drops a bad step walks a different route than the one asked for, which is
## exactly what determinism exists to rule out. The last three are the angled step's own ways. A
## script that parsed to nothing presses nothing.
func _test_a_malformed_script_presses_nothing(t: TestRunner) -> void:
	var cases := {
		"": "the empty string is not a script",
		"5": "a number with nothing after it has no direction to press",
		"5x": "an unknown letter is not one of the walk directions",
		"0s": "a zero-second step presses nothing for no time, which is not a step",
		"3@": "an '@' with no digits after it has no bearing to read",
		"3@45": "an '@' with no closing '@' would swallow whatever comes after it as more bearing",
		"3@x@": "a non-digit between the '@'s is not a bearing either",
	}
	for word: String in cases:
		var clock := UI.FakeClock.new()
		var rig := _rig(t, clock, [word])
		var at_once := _nothing_pressed()
		await _at(t, clock, 0.5)
		t.check(at_once and _nothing_pressed(), cases[word])
		_let_go(rig)

## A script can mix the old vocabulary and the new one in the same string, in the same
## left-to-right order — `docs/TODO.md`'s own requirement for where the angled step lands.
func _test_a_script_can_mix_letters_and_angles(t: TestRunner) -> void:
	var clock := UI.FakeClock.new()
	var rig := _rig(t, clock, ["1s3@45@2e"])
	await _at(t, clock, 0.5)
	t.check(_strengths_are(0.0, 0.0, 0.0, 1.0), "the lettered step first")
	await _at(t, clock, 2.0)
	var pressed := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	t.check(is_equal_approx(pressed.length(), 1.0) and not pressed.is_equal_approx(Vector2.DOWN)
			and not Input.is_action_pressed("move_down"),
			"the angled step in the middle, its own bearing rather than an axis (got %s)" % pressed)
	await _at(t, clock, 4.5)
	t.check(_strengths_are(0.0, 1.0, 0.0, 0.0),
			"and the lettered step after it, unaffected")
	_let_go(rig)

## The three shapes M204 (the trailer) added to the walk script, so a shot's path can turn on a
## street rather than only on a whole second: a decimal duration, `p` standing still, and an
## uppercase letter running instead of walking.

## `1.7w` — a duration may carry a decimal point, since a whole second is 92px of street and a
## turn wants finer placing than that.
func _test_a_decimal_duration_runs_a_fractional_second(t: TestRunner) -> void:
	var clock := UI.FakeClock.new()
	var rig := _rig(t, clock, ["1.7w"])
	await _at(t, clock, 1.6)
	t.check(_strengths_are(1.0, 0.0, 0.0, 0.0),
			"west at 1.6s, within its 1.7 (got %s)" % [_strengths()])
	await _at(t, clock, 1.8)
	t.check(_nothing_pressed(), "and let go at 1.8s, past them")
	_let_go(rig)

## A second decimal point in the same duration is malformed, the same as every other way a step can
## fail to parse — the whole script refuses rather than guessing which point was meant.
func _test_a_second_decimal_point_is_malformed(t: TestRunner) -> void:
	var clock := UI.FakeClock.new()
	var rig := _rig(t, clock, ["1.5.5s"])
	var at_once := _nothing_pressed()
	await _at(t, clock, 0.5)
	t.check(at_once and _nothing_pressed(), "a duration with two decimal points has no single number to read")
	_let_go(rig)

## `0.6p` — she stops, sees the wrong street for what it is, and turns, with nothing pressed, the
## same as a player letting go.
func _test_the_stand_still_letter_presses_nothing(t: TestRunner) -> void:
	var clock := UI.FakeClock.new()
	var rig := _rig(t, clock, ["0.6p"])
	await _at(t, clock, 0.3)
	t.check(_nothing_pressed(), "0.6 seconds standing still presses nothing")
	_let_go(rig)

## `2S` — that direction at a run, the `run` action held for the step. The lower-case letter beside
## it stays a walk, so the same script can mix the two.
func _test_an_uppercase_letter_marks_a_running_step(t: TestRunner) -> void:
	var clock := UI.FakeClock.new()
	var rig := _rig(t, clock, ["2S3e"])
	await _at(t, clock, 1.0)
	t.check(Input.is_action_pressed("move_down") and Input.is_action_pressed("run"),
			"two seconds south at a run")
	await _at(t, clock, 3.0)
	t.check(Input.is_action_pressed("move_right") and not Input.is_action_pressed("run"),
			"then three seconds east at a walk — the lower-case letter beside it unaffected")
	_let_go(rig)

# -------------------------------------------------------------------- stepping ---

## Each step ends by releasing its own press and pressing the next one, never both at once.
func _test_a_script_presses_one_action_at_a_time_in_order(t: TestRunner) -> void:
	var clock := UI.FakeClock.new()
	var rig := _rig(t, clock, ["1s2e"])
	t.check(Input.is_action_pressed("move_down"), "the first step is pressed as soon as it is ready")
	await _at(t, clock, 0.5)
	t.check(Input.is_action_pressed("move_down"),
			"and still pressed before its second is up (0.5s in)")

	await _at(t, clock, 1.1)
	t.check(not Input.is_action_pressed("move_down"),
			"the first action lets go once its second is up (1.1s in)")
	t.check(Input.is_action_pressed("move_right"), "and the second step's action takes over")
	_let_go(rig)

## An uppercase step (`2S`) holds `run` for its own duration and lets go once a walking step
## follows it — a running step followed by a walking one slows back down rather than running on.
func _test_a_running_step_presses_and_releases_the_run_action(t: TestRunner) -> void:
	var clock := UI.FakeClock.new()
	var rig := _rig(t, clock, ["2S3e"])
	t.check(Input.is_action_pressed("move_down"), "the running step presses its direction")
	t.check(Input.is_action_pressed("run"), "and holds run for its own duration")

	await _at(t, clock, 2.1)
	t.check(Input.is_action_pressed("move_right"), "the walking step after it takes over")
	t.check(not Input.is_action_pressed("run"), "and run lets go, since the next step only walks")
	_let_go(rig)

	clock.now = 0.0
	rig = _rig(t, clock, ["1S"])
	t.check(Input.is_action_pressed("run"), "a running step that is the last one still runs")
	await _at(t, clock, 1.1)
	t.check(not Input.is_action_pressed("run"), "and lets go of run when the script ends")
	_let_go(rig)

## `0.6p` presses no `move_*` action for its duration — it does not skip the step, so the next one
## starts when it is over.
func _test_a_stand_still_step_presses_nothing_and_releases_nothing(t: TestRunner) -> void:
	var clock := UI.FakeClock.new()
	var rig := _rig(t, clock, ["0.6p2e"])
	t.check(_nothing_pressed(), "standing still presses no move_* action at all")

	await _at(t, clock, 0.7)
	t.check(Input.is_action_pressed("move_right"), "the step after it takes over as normal")
	_let_go(rig)

## The trap the milestone is named for: an angled step must press *both* axes, at the bearing's
## own fractional strength, not one axis at full strength — a step that pressed a shorter vector
## would reintroduce the slow walk M82 deleted. Read through `Input.get_action_strength()` rather
## than the boolean `is_action_pressed()` the other stepping tests use, since strength is exactly
## what is being asserted here.
func _test_an_angled_step_presses_both_axes_at_fractional_strength(t: TestRunner) -> void:
	var clock := UI.FakeClock.new()
	var rig := _rig(t, clock, ["3@45@"])
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
	_let_go(rig)

## The release path is shared with the lettered steps, so a script ending on an angled one has to
## let go of both axes just as cleanly as a lettered one.
func _test_an_angled_step_releases_both_axes_when_it_ends(t: TestRunner) -> void:
	var clock := UI.FakeClock.new()
	var rig := _rig(t, clock, ["1@45@"])
	t.check(Input.get_action_strength("move_right") > 0.0, "the angle is pressed once ready")
	await _at(t, clock, 1.1)
	t.check(Input.get_action_strength("move_right") == 0.0
			and Input.get_action_strength("move_up") == 0.0,
			"and both axes let go once the one step's second is up")
	_let_go(rig)

## The last step releases its own press rather than leaving it held, since nothing after the
## script is meant to keep walking.
func _test_a_script_lets_go_of_the_last_action_when_it_ends(t: TestRunner) -> void:
	var clock := UI.FakeClock.new()
	var rig := _rig(t, clock, ["1s1e"])
	await _at(t, clock, 1.1)
	t.check(Input.is_action_pressed("move_right"), "the second and last step is pressed (1.1s in)")

	await _at(t, clock, 2.2)
	t.check(not Input.is_action_pressed("move_right"),
			"the script lets go of it once the last step's second is up (2.2s in)")
	t.check(not Input.is_action_pressed("move_down"), "and nothing earlier is still held either")
	_let_go(rig)

# --------------------------------------------------------------------- a pursuit ---

## A pursuit as the director announces one: an event whose def carries a pursuit, telegraphed on
## the bus the rig listens to.
func _telegraph_a_pursuer() -> void:
	var def := EventDef.new()
	def.id = "test_pursuer"
	def.pursuit = PursuitSpec.new()
	def.telegraph_time = 2.0
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	EventBus.event_telegraphed.emit(instance)
	instance.free()

## A pursuit repurposes the pressed axes the instant it starts (about-turn, hold run), and a script
## resuming underneath it would fight it for the same axes — so once the rig has fled, the script
## stops advancing, whatever the clock says.
func _test_a_pursuit_stops_the_script_from_resuming(t: TestRunner) -> void:
	var clock := UI.FakeClock.new()
	var rig := _rig(t, clock, ["1s1e"], true)
	await _at(t, clock, 0.1)
	_telegraph_a_pursuer()
	await _at(t, clock, 0.2)

	await _at(t, clock, 5.0)
	t.check(Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_down"),
			"a fled rig holds the about-turned step it fled during, and never advances past it")
	t.check(not Input.is_action_pressed("move_right"),
			"and never presses a later step's action either")
	_let_go(rig)

## A bare direction reverses through its one action; any script step — lettered or angled — holds
## two axes, so a pursuit starting mid-script has to negate those too, or the rig would press `run`
## in whatever direction was already held instead of turning round — the wrong answer to the one
## encounter with a right one.
func _test_a_pursuit_reverses_an_angled_step_too(t: TestRunner) -> void:
	var clock := UI.FakeClock.new()
	var rig := _rig(t, clock, ["5@45@"], true)
	var before := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	await _at(t, clock, 0.1)
	_telegraph_a_pursuer()
	await _at(t, clock, 0.2)
	var after := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	t.check(after.is_equal_approx(-before),
			"turning round negates the diagonal (got %s from %s)" % [after, before])
	t.check(Input.is_action_pressed("run"), "and holds run, the same as a bare-direction flee")
	_let_go(rig)

# ------------------------------------------------------------ a hidden window ---

## The line a capture must not wait on by itself: on macOS a window nobody can see is not drawn, so
## this signal never comes and the rig ends on its wall-clock limit with no picture.
## `DrawnFrame.wait()` is the wait that draws the frame on demand instead.
const _BARE_RENDER_LOOP_WAIT := "await RenderingServer.frame_post_draw"

## The lines of `source` that wait on `_BARE_RENDER_LOOP_WAIT`, comments aside. Pure over a string
## so the scan itself is checked against a line that must be found, not only against a tree that
## happens to have none.
static func _bare_render_loop_waits(source: String) -> PackedStringArray:
	var found := PackedStringArray()
	for line in source.split("\n"):
		var code := line.strip_edges()
		if code.begins_with("#"):
			continue
		if code.contains(_BARE_RENDER_LOOP_WAIT):
			found.append(code)
	return found

## Every `.gd` file under `directory`, recursively.
static func _scripts_under(directory: String) -> PackedStringArray:
	var scripts := PackedStringArray()
	var dir := DirAccess.open(directory)
	if dir == null:
		return scripts
	for file in dir.get_files():
		if file.ends_with(".gd"):
			scripts.append(directory.path_join(file))
	for child in dir.get_directories():
		scripts.append_array(_scripts_under(directory.path_join(child)))
	return scripts

func _test_the_scan_finds_a_bare_wait_on_the_render_loop(t: TestRunner) -> void:
	var reintroduced := "func _capture() -> void:\n\tawait RenderingServer.frame_post_draw\n"
	t.check(_bare_render_loop_waits(reintroduced).size() == 1,
		"the scan finds a capture that waits on the render loop's own frame")
	t.check(_bare_render_loop_waits("\t## await RenderingServer.frame_post_draw\n").is_empty(),
		"a doc comment naming the wait is not a wait")

func _test_only_a_covered_recording_needs_an_on_demand_frame(t: TestRunner) -> void:
	t.check(AutoScreenshot.recording_frame_needs_force(true, false),
		"a covered movie-writer window needs a current viewport texture")
	t.check(not AutoScreenshot.recording_frame_needs_force(true, true),
		"a visible recording keeps the engine's ordinary draw path")
	t.check(not AutoScreenshot.recording_frame_needs_force(false, false),
		"covering an ordinary game does not install the movie-writer workaround")

## Every capture under `src/` waits through `DrawnFrame.wait()`, so a hidden rig still photographs.
func _test_no_capture_under_src_waits_on_the_render_loop_alone(t: TestRunner) -> void:
	var scripts := _scripts_under("res://src")
	t.check(scripts.has("res://src/dev/auto_screenshot.gd"),
		"there were scripts to scan (%d), the capture's own among them" % scripts.size())
	t.check(FileAccess.get_file_as_string("res://src/drawn_frame.gd")
			.contains("static func wait("), "the wait a capture uses instead exists")
	for path in scripts:
		var waits := _bare_render_loop_waits(FileAccess.get_file_as_string(path))
		t.check(waits.is_empty(),
			"%s waits on RenderingServer.frame_post_draw alone, which never comes while the " % path
			+ "window is hidden -- await DrawnFrame.wait(get_tree()) instead")

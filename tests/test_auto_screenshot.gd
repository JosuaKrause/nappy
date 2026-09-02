extends RefCounted
## `AutoScreenshot`'s `--walk` parsing, and the scripted walk `1s5e` added beside the bare
## direction it already understood.
##
## *(`docs/TODO.md`, M66, "A rig that walks a route, because one that holds a key walks into a
## wall": `--walk north|south|east|west` holds one direction for the whole run, so a rig meets the
## first building on that heading and stays there — which is why every dusk map taken with it
## showed a speck where a trail should be. `1s5e` is a script of timed presses instead: one second
## of south then five of east, read left to right, pressing the same `move_*` actions a bare
## direction already does.)*
##
## `_ready()` never runs on a script-only instance — the node is never added to a tree here — so
## this calls it and `_process()` by hand, the way `tests/test_main.gd` already reaches past
## `_ready()` for `main.gd`. Every test releases whatever it pressed, since `Input`'s polled state
## is global and outlives the node that set it.

func run(t) -> void:
	_test_a_bare_direction_is_unaffected(t)
	_test_a_script_parses_into_timed_steps(t)
	_test_a_malformed_script_parses_to_nothing(t)
	_test_a_script_presses_one_action_at_a_time_in_order(t)
	_test_a_script_lets_go_of_the_last_action_when_it_ends(t)
	_test_a_pursuit_stops_the_script_from_resuming(t)

# ------------------------------------------------------------------- parsing ---

## `1s5e|north` etc. still means exactly what it always meant: held for the whole run, and never
## routed through `_parse_script` at all — `from_command_line` checks `_DIRECTIONS` first.
func _test_a_bare_direction_is_unaffected(t) -> void:
	t.check(AutoScreenshot._DIRECTIONS.has("north"), "a direction word is still in the old table")
	t.check(AutoScreenshot._parse_script("north").is_empty(),
			"and read as a script it is not a run of <seconds><letter> pairs, so it parses to nothing")

## The player's own example, and the one named in `docs/TODO.md`.
func _test_a_script_parses_into_timed_steps(t) -> void:
	var steps := AutoScreenshot._parse_script("1s5e")
	t.check(steps.size() == 2, "1s5e is two steps (got %d)" % steps.size())
	if steps.size() != 2:
		return
	t.check(steps[0]["action"] == "move_down" and is_equal_approx(steps[0]["seconds"], 1.0),
			"one second of south (got %s)" % steps[0])
	t.check(steps[1]["action"] == "move_right" and is_equal_approx(steps[1]["seconds"], 5.0),
			"then five of east (got %s)" % steps[1])

## Four ways to be malformed, and all of them fail the whole script rather than skipping one step —
## a script that silently drops a bad step walks a different route than the one asked for, which is
## exactly what determinism exists to rule out.
func _test_a_malformed_script_parses_to_nothing(t) -> void:
	t.check(AutoScreenshot._parse_script("").is_empty(), "the empty string is not a script")
	t.check(AutoScreenshot._parse_script("5").is_empty(),
			"a number with nothing after it has no direction to press")
	t.check(AutoScreenshot._parse_script("5x").is_empty(),
			"an unknown letter is not one of the walk directions")
	t.check(AutoScreenshot._parse_script("0s").is_empty(),
			"a zero-second step presses nothing for no time, which is not a step")

# -------------------------------------------------------------------- stepping ---

## A fresh rig ready to run a script, never added to a tree — `_seconds_to_wait` is set high
## enough that no test here ever reaches `--after` and calls `_capture()`, which awaits a real
## frame and would hang the headless suite.
func _script_rig(script: String) -> AutoScreenshot:
	var node := AutoScreenshot.new()
	node._seconds_to_wait = 60.0
	node._script = AutoScreenshot._parse_script(script)
	return node

## `_ready()` presses the first step's action immediately, the same as a bare direction would —
## and each step ends by releasing its own action and pressing the next one, never both at once.
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

## The last step releases its own action rather than leaving it held, since nothing after the
## script is meant to keep walking — `_advance_script` sets `_holding` to `""` once the index
## runs off the end.
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

## `_turn_and_run` repurposes `_holding` the instant a pursuit starts, and a script resuming
## underneath it would fight it for the same held key — so once `_fled` is true the script must
## stop advancing, whatever `_elapsed` says.
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

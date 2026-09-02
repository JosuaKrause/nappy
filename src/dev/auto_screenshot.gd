class_name AutoScreenshot
extends Node
## Dev tool: let the game run for a while, save the viewport to a PNG, quit.
##
## Headless runs never call `_draw()`, so a clean headless boot says nothing about whether
## the game looks right. This gives a windowed run a way to produce a checkable image.
##
##     godot --path . -- --screenshot out.png [--after 4.0] [--walk north|south|east|west|1s5e]
##                                            [--flee [delay]]
##
## `--after` is in SECONDS, not frames. It counted frames at first, which was quietly
## useless for checking anything time-based: a windowed run here draws ~110fps, so waiting
## "240 frames" for a 2.6s telegraph to end still caught it mid-telegraph.
##
## `--walk` holds a direction down for the whole run. The crowd and the events are built around the
## player and the director only puts something in front of her while she is *going somewhere*, so a
## tool that can only photograph a standing player cannot photograph the game: no cat ever crosses
## her path, nothing ever streams in, and nothing at the screen edge is ever closing. It presses the
## real input
## actions rather than writing to the rig, so everything downstream — the gait, the run excess,
## the baby — behaves exactly as it does for a person holding the key.
##
## **A bare direction holds it for the whole run, which walks the rig into the first building on
## that heading and leaves it there** — the doorstep is a notch with one exit, so every direction
## but the one the notch opens onto stops within a body-width. `1s5e` is the other shape: a script
## of timed presses, one second of south then five of east, read left to right and run in order
## before the node lets go of the last one. A number is seconds and a letter is the initial of a
## `--walk` word (`n`/`s`/`e`/`w`) rather than a second vocabulary, and it presses the same
## `move_*` action a bare direction does — nothing downstream can tell a scripted press from a
## held key. It is what makes a rig's trail worth photographing instead of a speck: a route with a
## turn in it, deterministic over the same seed, so the same script is reproducible evidence rather
## than one run that happened to go somewhere.
##
## `--flee` turns round and runs **when something starts chasing her**, and it exists for exactly
## one thing: the game has one encounter with a **right answer**, and a rig that can only hold a
## direction can only ever demonstrate the wrong one. Every trace of the day-3 dog taken with
## `--walk` ends in a hard fail, which is the mechanic working and says nothing about whether the
## answer is affordable. It presses the real actions too, so the run costs what a player's run
## costs.
##
## It waits for the pursuit rather than taking a timestamp, and the first version did take one. That
## is worth writing down, because the failure was not a bad reading, it was a *reversed* one: the
## director sites what it owes in front of the direction she is actually travelling, so a rig that
## started running before the dog was placed had the dog placed in front of the **run** — and then
## sprinted into it at 168px/s. Three traces of a lethal dog "arriving from nowhere" were a rig
## running at it.
##
## An optional delay in seconds is how long she dithers first, which is the axis worth measuring:
## the price of the right answer is what it costs to give it late.
##
## `--press <action> <seconds>` taps one input action once, and it exists for the class of bug
## nothing else here can see. A pause screen can pass a green suite and a screenshot and **never
## open once** — a guard reading `visible` on a `CanvasLayer` is true from the moment the node is
## added — because nothing in either has ever *pressed a key*. This can:
##
##     tools/shot.sh pause.png 4 --press pause 3
##
## It may be given more than once, and it takes a **bare key** as `key:<name>` as well as an input
## action. Both for the same reason as the flag itself: one tap can only ever photograph one screen,
## and the keys a screen's own shortcuts are made of — `q` to quit, `r` to start the run again — are
## keycodes rather than actions, so an action-only `--press` cannot reach the two keys the pause
## screen is mostly made of.
##
##     tools/shot.sh restart.png 6 --press pause 2 --press key:r 3.5

const DEFAULT_SECONDS := 1.5

const _DIRECTIONS := {
	"north": "move_up", "south": "move_down", "east": "move_right", "west": "move_left",
}
## The same four actions, keyed by the single letter a script step ends in — `1s5e`'s `s` and `e`
## rather than `--walk`'s own words, so a script is not a second vocabulary to learn.
const _LETTERS := {
	"n": "move_up", "s": "move_down", "e": "move_right", "w": "move_left",
}
const _OPPOSITE := {
	"move_up": "move_down", "move_down": "move_up",
	"move_left": "move_right", "move_right": "move_left",
}

var _path := ""
var _seconds_to_wait := DEFAULT_SECONDS
var _elapsed := 0.0
var _holding := ""
## A script of timed presses — `[{ "action": String, "seconds": float }]`, in the order `1s5e`
## gave them. Empty for a bare direction, which is still held by `_holding` alone; see
## `_advance_script`.
var _script: Array[Dictionary] = []
var _script_index := 0
## `_elapsed` at the moment the current script step started, so each step is timed against the
## one clock the rest of the node already uses rather than a second one of its own.
var _script_step_started := 0.0
## Whether to answer a pursuit by running, and how long to dither before doing it.
var _flees := false
var _dither := 0.0
## The clock reading at which to turn, once something is chasing. `INF` until it is.
var _flee_at := INF
var _fled := false
## What to tap and when: `[{ "what": String, "at": float, "done": bool }]`, in the order the flags
## were given. See `--press`.
var _presses: Array[Dictionary] = []

## Returns a configured instance, or null if the command line did not ask for a screenshot —
## including every time it is asked from outside a debug build. `--screenshot`, `--after`,
## `--walk`, `--flee` and `--press` are developer furniture like every flag `DevFlags` gates, and
## are gated here rather than moved there because this file already owns their parsing.
static func from_command_line() -> AutoScreenshot:
	if not OS.is_debug_build():
		return null
	var args := OS.get_cmdline_user_args()
	var index := args.find("--screenshot")
	if index == -1 or index + 1 >= args.size():
		return null
	var node := AutoScreenshot.new()
	node._path = args[index + 1]
	var after := args.find("--after")
	if after != -1 and after + 1 < args.size():
		node._seconds_to_wait = float(args[after + 1])
	var walk := args.find("--walk")
	if walk != -1 and walk + 1 < args.size():
		var word: String = args[walk + 1]
		if _DIRECTIONS.has(word):
			node._holding = String(_DIRECTIONS[word])
		else:
			node._script = _parse_script(word)
			if node._script.is_empty():
				push_warning("unknown --walk direction '%s'" % word)
	var flee := args.find("--flee")
	if flee != -1:
		node._flees = true
		# The next argument is a delay only if it is a number; `--flee` on its own is "at once",
		# and `--flee --seed 4242` must not read the flag after it as one.
		if flee + 1 < args.size() and args[flee + 1].is_valid_float():
			node._dither = float(args[flee + 1])
	# Every occurrence, not the first: one tap can only ever demonstrate a screen, and what usually
	# has to be checked is a *sequence* — `--press pause 2 --press key:r 3.5` is Esc and then the
	# key the pause screen offers.
	for i in args.size():
		if args[i] != "--press" or i + 2 >= args.size():
			continue
		var what := args[i + 1]
		if not what.begins_with(KEY_PREFIX) and not InputMap.has_action(what):
			push_warning("unknown --press action '%s'" % what)
			continue
		node._presses.append({"what": what, "at": float(args[i + 2]), "done": false})
	return node

## What marks a `--press` argument as a raw key rather than an input action.
const KEY_PREFIX := "key:"

## `1s5e` into `[{"action": "move_down", "seconds": 1.0}, {"action": "move_right", "seconds": 5.0}]`,
## or an empty array for anything that is not a run of `<seconds><letter>` pairs — which is also
## what a plain typo in a direction word (`"suth"`) parses as, so the caller warns on empty the
## same way it always warned on an unrecognised word.
##
## A number with no letter after it, a letter with no digits before it, an unknown letter or a
## zero-or-negative duration all fail the whole script rather than skipping the one bad step: a
## script that silently drops a step walks a different route than the one asked for, which is the
## exact failure determinism exists to rule out.
static func _parse_script(word: String) -> Array[Dictionary]:
	var steps: Array[Dictionary] = []
	var i := 0
	while i < word.length():
		var digits_start := i
		while i < word.length() and word[i].is_valid_int():
			i += 1
		if i == digits_start or i >= word.length():
			return []
		var seconds := float(word.substr(digits_start, i - digits_start))
		var action: String = _LETTERS.get(word[i], "")
		if action == "" or seconds <= 0.0:
			return []
		i += 1
		steps.append({"action": action, "seconds": seconds})
	return steps

func _ready() -> void:
	if not _script.is_empty():
		_holding = String(_script[0]["action"])
		Input.action_press(_holding)
	elif _holding != "":
		Input.action_press(_holding)
	if _flees:
		EventBus.event_telegraphed.connect(_on_telegraphed)

## Steps the script forward against `_elapsed`, the same clock `--after` and `--flee` already read,
## rather than a timer of its own. `while` and not `if`: a step shorter than one frame's delta must
## still be seen, or a script of short steps silently skips some of them on a slow machine.
##
## Stops advancing once a pursuit has taken over (`_fled`), because `_turn_and_run` has already
## repurposed `_holding` for the one encounter with a right answer — a script resuming underneath
## that would fight it for the same held key.
func _advance_script() -> void:
	if _fled:
		return
	while _script_index < _script.size():
		var step: Dictionary = _script[_script_index]
		if _elapsed - _script_step_started < float(step["seconds"]):
			return
		if _holding != "":
			Input.action_release(_holding)
		_script_step_started += float(step["seconds"])
		_script_index += 1
		if _script_index < _script.size():
			_holding = String(_script[_script_index]["action"])
			Input.action_press(_holding)
		else:
			_holding = ""

func _on_telegraphed(instance: EventInstance) -> void:
	if _fled or _flee_at < INF or not instance.def.pursues:
		return
	_flee_at = _elapsed + _dither

func _process(delta: float) -> void:
	_elapsed += delta
	_advance_script()
	if not _fled and _elapsed >= _flee_at:
		_fled = true
		_turn_and_run()
	for press in _presses:
		if not press["done"] and _elapsed >= float(press["at"]):
			press["done"] = true
			_tap(String(press["what"]))
	if _elapsed < _seconds_to_wait:
		return
	set_process(false)
	if _holding != "":
		Input.action_release(_holding)
	Input.action_release("run")
	_capture()

## Taps an action, or a bare key, so that it **propagates** — which `--walk` does not need and this
## does.
##
## `Input.action_press()` sets the polled state and nothing else, which is all the rig ever wanted
## before: the stroller reads `Input.get_vector` every frame. A key that something answers in
## `_unhandled_input` — the pause, and anything else that is a *moment* rather than a state — needs a
## real event pushed through the tree, and that is `parse_input_event`. The first version of
## `--press` used `action_press` and produced a screenshot of the game carrying on, which looks
## exactly like the bug it was written to check.
##
## **And a bare key is not an action, which is the same lesson one level down.** `Q` quits from the
## pause screen and `R` restarts the run, and neither is in the input map — they are read as
## keycodes, the way a screen's own shortcuts usually are. Without `key:`, a rig can reach no screen
## whose shortcuts are keycodes, which is the pause screen entirely.
func _tap(what: String) -> void:
	for pressed in [true, false]:
		var event: InputEvent
		if what.begins_with(KEY_PREFIX):
			var key := InputEventKey.new()
			key.keycode = OS.find_keycode_from_string(what.trim_prefix(KEY_PREFIX))
			key.pressed = pressed
			event = key
		else:
			var action := InputEventAction.new()
			action.action = what
			action.pressed = pressed
			event = action
		Input.parse_input_event(event)

## The one answer the game asks for: about-turn, and hold shift.
func _turn_and_run() -> void:
	if _holding != "":
		Input.action_release(_holding)
		_holding = String(_OPPOSITE.get(_holding, _holding))
		Input.action_press(_holding)
	Input.action_press("run")

func _capture() -> void:
	# The viewport texture is only valid once the frame has actually been drawn.
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(_path)
	if error != OK:
		printerr("[AutoScreenshot] could not write %s (error %d)" % [_path, error])
	else:
		print("[AutoScreenshot] wrote %s (%dx%d) after %.1fs"
				% [_path, image.get_width(), image.get_height(), _elapsed])
	get_tree().quit()

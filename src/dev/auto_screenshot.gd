class_name AutoScreenshot
extends Node
## Dev tool: let the game run for a while, save the viewport to a PNG, quit.
##
## Headless runs never call `_draw()`, so a clean headless boot says nothing about whether
## the game looks right. This gives a windowed run a way to produce a checkable image.
##
##     godot --path . -- --screenshot out.png [--after 4.0] [--walk north|south|east|west]
##                                            [--flee [delay]]
##
## `--after` is in SECONDS, not frames. It counted frames at first, which was quietly
## useless for checking anything time-based: a windowed run here draws ~110fps, so waiting
## "240 frames" for a 2.6s telegraph to end still caught it mid-telegraph.
##
## `--walk` holds a direction down for the whole run, and M27 is what made it necessary. Since
## the crowd and the events are built around the player and the director only puts something in
## front of her while she is *going somewhere*, a tool that can only photograph a standing
## player had stopped being able to photograph the game: no cat ever crosses her path, nothing
## ever streams in, and nothing at the screen edge is ever closing. It presses the real input
## actions rather than writing to the rig, so everything downstream — the gait, the run excess,
## the baby — behaves exactly as it does for a person holding the key.
##
## `--flee` turns round and runs **when something starts chasing her**, and it exists for exactly
## one thing. *(M35, playtest 08 finding 4.)* Since M33 the game has one encounter with a **right
## answer**, and a rig that can only hold a direction can only ever demonstrate the wrong one: every
## trace of the day-3 dog taken with `--walk` ends in a hard fail, which is the mechanic working and
## says nothing about whether the answer is affordable. It presses the real actions too, so the run
## costs what a player's run costs.
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
## `--press <action> <seconds>` taps one input action once, and it exists because of the bug that
## made it necessary. *(M36, playtest 09: "esc doesn't work".)* The pause screen shipped in M33,
## passed a green suite and a screenshot, and **never opened once** — its guard read `visible` on a
## `CanvasLayer`, which is true from the moment the node is added. Neither the suite nor a
## screenshot could have caught it, because nothing in either of them has ever *pressed a key*. Now
## something can:
##
##     tools/shot.sh pause.png 4 --press pause 3

const DEFAULT_SECONDS := 1.5

const _DIRECTIONS := {
	"north": "move_up", "south": "move_down", "east": "move_right", "west": "move_left",
}
const _OPPOSITE := {
	"move_up": "move_down", "move_down": "move_up",
	"move_left": "move_right", "move_right": "move_left",
}

var _path := ""
var _seconds_to_wait := DEFAULT_SECONDS
var _elapsed := 0.0
var _holding := ""
## Whether to answer a pursuit by running, and how long to dither before doing it.
var _flees := false
var _dither := 0.0
## The clock reading at which to turn, once something is chasing. `INF` until it is.
var _flee_at := INF
var _fled := false
## One action to tap once, and when. See `--press`.
var _press := ""
var _press_at := INF
var _pressed := false

## Returns a configured instance, or null if the command line did not ask for a screenshot.
static func from_command_line() -> AutoScreenshot:
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
		node._holding = String(_DIRECTIONS.get(args[walk + 1], ""))
		if node._holding == "":
			push_warning("unknown --walk direction '%s'" % args[walk + 1])
	var flee := args.find("--flee")
	if flee != -1:
		node._flees = true
		# The next argument is a delay only if it is a number; `--flee` on its own is "at once",
		# and `--flee --seed 4242` must not read the flag after it as one.
		if flee + 1 < args.size() and args[flee + 1].is_valid_float():
			node._dither = float(args[flee + 1])
	var press := args.find("--press")
	if press != -1 and press + 2 < args.size():
		node._press = args[press + 1]
		node._press_at = float(args[press + 2])
		if not InputMap.has_action(node._press):
			push_warning("unknown --press action '%s'" % node._press)
			node._press = ""
	return node

func _ready() -> void:
	if _holding != "":
		Input.action_press(_holding)
	if _flees:
		EventBus.event_telegraphed.connect(_on_telegraphed)

func _on_telegraphed(instance: EventInstance) -> void:
	if _fled or _flee_at < INF or not instance.def.pursues:
		return
	_flee_at = _elapsed + _dither

func _process(delta: float) -> void:
	_elapsed += delta
	if not _fled and _elapsed >= _flee_at:
		_fled = true
		_turn_and_run()
	if not _pressed and _press != "" and _elapsed >= _press_at:
		_pressed = true
		_tap(_press)
	if _elapsed < _seconds_to_wait:
		return
	set_process(false)
	if _holding != "":
		Input.action_release(_holding)
	Input.action_release("run")
	_capture()

## Taps an action so that it **propagates**, which `--walk` does not need and this does.
##
## `Input.action_press()` sets the polled state and nothing else, which is all the rig ever wanted
## before: the stroller reads `Input.get_vector` every frame. A key that something answers in
## `_unhandled_input` — the pause, and anything else that is a *moment* rather than a state — needs a
## real event pushed through the tree, and that is `parse_input_event`. The first version of
## `--press` used `action_press` and produced a screenshot of the game carrying on, which looks
## exactly like the bug it was written to check.
func _tap(action: String) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
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

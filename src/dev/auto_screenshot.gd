class_name AutoScreenshot
extends Node
## Dev tool: let the game run for a while, save the viewport to a PNG, quit.
##
## Headless runs never call `_draw()`, so a clean headless boot says nothing about whether
## the game looks right. This gives a windowed run a way to produce a checkable image.
##
##     godot --path . -- --screenshot out.png [--after 4.0] [--walk north|south|east|west]
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

const DEFAULT_SECONDS := 1.5

const _DIRECTIONS := {
	"north": "move_up", "south": "move_down", "east": "move_right", "west": "move_left",
}

var _path := ""
var _seconds_to_wait := DEFAULT_SECONDS
var _elapsed := 0.0
var _holding := ""

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
	return node

func _ready() -> void:
	if _holding != "":
		Input.action_press(_holding)

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < _seconds_to_wait:
		return
	set_process(false)
	if _holding != "":
		Input.action_release(_holding)
	_capture()

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

class_name AutoScreenshot
extends Node
## Dev tool: render a few frames, save the viewport to a PNG, quit.
##
## Headless runs never call `_draw()`, so a clean headless boot says nothing about whether
## the game looks right. This gives a windowed run a way to produce a checkable image.
##
##     godot --path . -- --screenshot out.png [--after 60]

const DEFAULT_FRAMES := 60

var _path := ""
var _frames_to_wait := DEFAULT_FRAMES
var _frames := 0

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
		node._frames_to_wait = int(args[after + 1])
	return node

func _process(_delta: float) -> void:
	_frames += 1
	if _frames < _frames_to_wait:
		return
	set_process(false)
	_capture()

func _capture() -> void:
	# The viewport texture is only valid once the frame has actually been drawn.
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(_path)
	if error != OK:
		printerr("[AutoScreenshot] could not write %s (error %d)" % [_path, error])
	else:
		print("[AutoScreenshot] wrote %s (%dx%d)" % [_path, image.get_width(), image.get_height()])
	get_tree().quit()

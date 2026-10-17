extends SceneTree
## Composes into one still the warnings this PR adds that no scene recipe can stage, from the game's
## own SVGs placed the way the drawing code places them (`EventInstance`):
##
## - the checkpoint hut's guard, standing and then with his hand raised as she nears the raised
##   boom (`_draw_checkpoint_hut()`: the hut at `_HUT_ANCHOR` (28, 52), the guard beside it at
##   (0, 22) for a south-facing door, `guard_standing.svg` or `guard_alert_front.svg` at
##   `_GUARD_ANCHOR` (11, 44));
## - an alley post's guard, the same two pictures on their own;
## - the masked man at the foot of the escape's stairwell, waiting, warning and running
##   (`masked_pursuer_pictures()`, front view);
## - day 13's task guard, waiting, warning in her view and charging (`robber_pictures()`, front
##   view).
##
## Every other picture stands at its canvas's bottom centre, as `Sprites.draw_standing()` grounds a
## standing sprite. Each panel is on the sidewalk's colour, at `--scale`, standing on one ground line.

const SIDEWALK := Color("8b8478")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var usage := "Usage: godot --headless --path <project> --script warning-stills.gd -- --repo REPO_ROOT --output FRESH.png [--scale N]"
	if args.size() == 1 and args[0] in ["--help", "-h"]:
		print(usage)
		quit()
		return
	var options := {"--scale": "4"}
	var index := 0
	while index < args.size():
		if args[index] in ["--repo", "--output", "--scale"] and index + 1 < args.size():
			options[args[index]] = args[index + 1]
			index += 2
		else:
			push_error(usage)
			quit(2)
			return
	if not options.has("--repo") or not options.has("--output"):
		push_error(usage)
		quit(2)
		return
	if FileAccess.file_exists(options["--output"]):
		push_error("Output must be fresh, a delivered still is never overwritten: " + options["--output"])
		quit(2)
		return
	var repo: String = options["--repo"]
	var scale := float(options["--scale"])
	# Each part: [svg path, its anchor or Vector2.INF for bottom centre, where the anchor stands].
	var hut := ["art/checkpoints/hut_south.svg", Vector2(28, 52), Vector2.ZERO]
	var panels := [
		[hut, ["art/checkpoints/guard_standing.svg", Vector2(11, 44), Vector2(0, 22)]],
		[hut, ["art/checkpoints/guard_alert_front.svg", Vector2(11, 44), Vector2(0, 22)]],
		[["art/checkpoints/guard_standing.svg", Vector2.INF, Vector2.ZERO]],
		[["art/checkpoints/guard_alert_front.svg", Vector2.INF, Vector2.ZERO]],
		[["art/checkpoints/guard_standing_front.svg", Vector2.INF, Vector2.ZERO]],
		[["art/checkpoints/guard_alert_front.svg", Vector2.INF, Vector2.ZERO]],
		[["art/checkpoints/guard_lunging_front.svg", Vector2.INF, Vector2.ZERO]],
		[["art/events/robber_waiting_front.svg", Vector2.INF, Vector2.ZERO]],
		[["art/events/robber_alert_front.svg", Vector2.INF, Vector2.ZERO]],
		[["art/events/robber_lunging_front.svg", Vector2.INF, Vector2.ZERO]],
	]
	var cell := Vector2i(int(64 * scale), int(96 * scale))
	var sheet := Image.create(cell.x * panels.size(), cell.y, false, Image.FORMAT_RGBA8)
	sheet.fill(SIDEWALK)
	for p in panels.size():
		var ground := Vector2(cell.x * p + cell.x * 0.5, cell.y - 26 * scale)
		for part: Array in panels[p]:
			var raster := Image.new()
			var source := FileAccess.get_file_as_string(repo.path_join(part[0]))
			if raster.load_svg_from_string(source, scale) != OK:
				push_error("SVG render failed: " + str(part[0]))
				quit(1)
				return
			raster.convert(Image.FORMAT_RGBA8)
			var anchor: Vector2 = part[1]
			if anchor == Vector2.INF:
				anchor = Vector2(raster.get_width() / scale * 0.5, raster.get_height() / scale)
			var at: Vector2 = ground + (part[2] - anchor) * scale
			sheet.blend_rect(raster, Rect2i(Vector2i.ZERO, raster.get_size()), Vector2i(at.round()))
	if sheet.save_png(options["--output"]) != OK:
		push_error("PNG save failed: " + options["--output"])
		quit(1)
		return
	print("wrote %s %s" % [options["--output"], sheet.get_size()])
	quit()

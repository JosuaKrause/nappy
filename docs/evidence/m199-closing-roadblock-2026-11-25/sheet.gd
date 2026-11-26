extends SceneTree
## Scratch: renders the open and the closing roadblock's pictures side by side through the engine's
## SVG parser, on a road-grey ground, as one sheet. Args: <art_events_dir> <out_png> <scale>

func _render(path: String, scale: float) -> Image:
	var img := Image.new()
	var err := img.load_svg_from_string(FileAccess.get_file_as_string(path), scale)
	if err != OK:
		push_error("svg failed " + path)
	img.convert(Image.FORMAT_RGBA8)
	return img

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var dir: String = args[0]
	var out: String = args[1]
	var s := float(args[2])
	var w := int(460 * s)
	var h := int(170 * s)
	var sheet := Image.create(w, h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#cfcabd"))
	var rows := [["roadblock_segment", "roadblock_segment_vertical", "roadblock_end", "checkpoint_block"],
		["closing_roadblock_segment", "closing_roadblock_segment_vertical", "closing_roadblock_end", "closing_roadblock_block"]]
	for r in 2:
		var names: Array = rows[r]
		var y0 := int((10 + r * 80) * s)
		var seg := _render(dir + "/" + names[0] + ".svg", s)
		var cap := _render(dir + "/" + names[2] + ".svg", s)
		var x := int(10 * s)
		sheet.blend_rect(cap, Rect2i(Vector2i.ZERO, cap.get_size()), Vector2i(x, y0))
		x += cap.get_width()
		for i in 7:
			sheet.blend_rect(seg, Rect2i(Vector2i.ZERO, seg.get_size()), Vector2i(x, y0))
			x += seg.get_width()
		sheet.blend_rect(cap, Rect2i(Vector2i.ZERO, cap.get_size()), Vector2i(x, y0))
		var vert := _render(dir + "/" + names[1] + ".svg", s)
		var vx := int(220 * s)
		for i in 2:
			sheet.blend_rect(vert, Rect2i(Vector2i.ZERO, vert.get_size()), Vector2i(vx, y0 + i * vert.get_height()))
		var icon := _render(dir + "/" + names[3] + ".svg", s * 2.0)
		sheet.blend_rect(icon, Rect2i(Vector2i.ZERO, icon.get_size()), Vector2i(int(270 * s), y0))
		var native := _render(dir + "/" + names[3] + ".svg", 1.0)
		sheet.blend_rect(native, Rect2i(Vector2i.ZERO, native.get_size()), Vector2i(int(340 * s), y0))
		var nseg := _render(dir + "/" + names[0] + ".svg", 1.0)
		for i in 4:
			sheet.blend_rect(nseg, Rect2i(Vector2i.ZERO, nseg.get_size()), Vector2i(int(380 * s) + i * nseg.get_width(), y0))
	sheet.save_png(out)
	quit()

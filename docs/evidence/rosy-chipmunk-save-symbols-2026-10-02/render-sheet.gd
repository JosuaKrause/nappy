extends SceneTree
## Renders the plain and struck save symbols at 48px and 128px over a light and a dark ground.
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var usage := "Usage: godot --headless --path <project> --script render-sheet.gd -- PLAIN_SVG STRUCK_SVG OUTPUT_PNG"
	if a.size() == 1 and a[0] in ["--help", "-h"]:
		print(usage)
		quit()
		return
	if a.size() != 3:
		push_error(usage)
		quit(2)
		return
	var plain := FileAccess.get_file_as_string(a[0])
	var struck := FileAccess.get_file_as_string(a[1])
	var sizes: Array[int] = [48, 128]
	var grounds: Array[Color] = [Color("#d9d4c7"), Color("#2a2733")]
	var pad := 16
	var w := pad + (48 + pad) * 2 + (128 + pad) * 2
	var h := pad + (128 + pad) * 2
	var sheet := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for row in 2:
		sheet.fill_rect(Rect2i(0, row * (h / 2), w, h / 2), grounds[row])
		var x := pad
		for size in sizes:
			for src: String in [plain, struck]:
				var img := Image.new()
				if img.load_svg_from_string(src, size / 128.0) != OK:
					push_error("render failed"); quit(1); return
				img.convert(Image.FORMAT_RGBA8)
				var y := row * (h / 2) + pad + (128 - size) / 2
				sheet.blend_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), Vector2i(x, y))
				x += size + pad
	if sheet.save_png(a[2]) != OK:
		push_error("save failed"); quit(1); return
	quit()

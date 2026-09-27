extends SceneTree
## Crop separated vector spans with the runtime SVG parser and retain their registration.

func _init() -> void:
	var arguments := OS.get_cmdline_user_args()
	assert(arguments.size() == 1, "Pass the split-scenes.py temporary layer description")
	var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(arguments[0]))
	var output := {"sources": payload.sources, "layers": {}}
	for stem: String in payload.layers:
		var entries: Array = []
		for layer: Dictionary in payload.layers[stem]:
			var bounds := Rect2i()
			var canvas := Rect2i()
			for source: String in layer.frames:
				var image := Image.new()
				assert(image.load_svg_from_string(source) == OK)
				canvas = Rect2i(Vector2i.ZERO, image.get_size())
				var used := image.get_used_rect()
				bounds = used if bounds.size == Vector2i.ZERO else bounds.merge(used)
			assert(bounds.has_area(), "Every authored span paints something")
			# A transparent texel protects the edge coverage of subpixel vector strokes from
			# the SVG rasterizer's viewport clip; original canvas edges remain clipped as authored.
			bounds = bounds.grow(1).intersection(canvas)
			for frame in layer.frames.size():
				var source: String = layer.frames[frame]
				for attribute: String in ["width", "height", "viewBox"]:
					var regex := RegEx.new()
					assert(regex.compile(' ' + attribute + '="[^"]*"') == OK)
					var value := str(bounds.size.x if attribute == "width" else bounds.size.y)
					if attribute == "viewBox":
						value = "%d %d %d %d" % [bounds.position.x, bounds.position.y,
								bounds.size.x, bounds.size.y]
					source = regex.sub(source, ' ' + attribute + '="' + value + '"', false)
				var path := "res://art/events/%s%s.svg" % [layer.name, "_b" if frame else ""]
				var file := FileAccess.open(path, FileAccess.WRITE)
				assert(file != null)
				file.store_string("<!-- Registered crop from %s, painter-order span. -->\n" % stem
						+ source + "\n")
				file.close()
			entries.append([layer.name, bounds.position.x, bounds.position.y,
					bounds.size.x, bounds.size.y, layer.moving])
		output.layers[stem] = entries
	var file := FileAccess.open("res://docs/evidence/m159-scenery-animation-2026-09-26/layers.json",
			FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "  ") + "\n")
	file.close()
	quit()

extends RefCounted
## Raster parity evidence for the authored whole scenes and their registered layer compositions.

func run(t) -> void:
	var output := OS.get_environment("SCENERY_COMPARISON_OUTPUT")
	if not output.is_empty():
		DirAccess.make_dir_recursive_absolute(output)
	var results := {}
	for stem: String in EventSceneryParts.LAYERS:
		var preview: Image
		var entries: Array = EventSceneryParts.LAYERS[stem]
		for frame in 2:
			var original := _svg("events/" + stem + ("_b" if frame else ""))
			var composite := Image.create_empty(original.get_width(), original.get_height(),
					false, Image.FORMAT_RGBA8)
			for entry: Array in entries:
				var picture := "events/" + str(entry[0]) + ("_b" if frame and entry[5] else "")
				var part := _svg(picture)
				composite.blend_rect(part, Rect2i(Vector2i.ZERO, part.get_size()),
						Vector2i(entry[1], entry[2]))
			var error := _difference(original, composite)
			results[stem + ("_b" if frame else "")] = error
			t.check(error.alpha_max <= 2.0 / 255.0 + 0.000001
					and error.premultiplied_max <= 3.0 / 255.0 + 0.000001,
					"%s frame %d composes within raster rounding: %s" % [stem, frame, error])
			if preview == null:
				preview = Image.create_empty(original.get_width() * 2, original.get_height() * 2,
						false, Image.FORMAT_RGBA8)
			preview.blit_rect(original, Rect2i(Vector2i.ZERO, original.get_size()),
					Vector2i(0, frame * original.get_height()))
			preview.blit_rect(composite, Rect2i(Vector2i.ZERO, composite.get_size()),
					Vector2i(original.get_width(), frame * original.get_height()))
		preview.resize(preview.get_width() * 3, preview.get_height() * 3, Image.INTERPOLATE_NEAREST)
		if not output.is_empty():
			t.check(preview.save_png(output.path_join(stem + "-parity.png")) == OK,
					"save the parity preview")
	if not output.is_empty():
		var file := FileAccess.open(output.path_join("raster-parity.json"), FileAccess.WRITE)
		t.check(file != null, "open the explicit comparison output")
		if file != null:
			file.store_string(JSON.stringify(results, "  ") + "\n")
			file.close()

func _svg(picture: String) -> Image:
	var result := Image.new()
	assert(result.load_svg_from_string(FileAccess.get_file_as_string("res://art/" + picture + ".svg")) == OK)
	return result

func _difference(a: Image, b: Image) -> Dictionary:
	var alpha_max := 0.0
	var color_max := 0.0
	var changed := 0
	var alpha_at := Vector2i.ZERO
	for y in a.get_height():
		for x in a.get_width():
			var left := a.get_pixel(x, y)
			var right := b.get_pixel(x, y)
			if absf(left.a - right.a) > alpha_max:
				alpha_max = absf(left.a - right.a)
				alpha_at = Vector2i(x, y)
			for channel in 3:
				color_max = maxf(color_max, absf(left[channel] * left.a - right[channel] * right.a))
			if left != right:
				changed += 1
	return {"alpha_max": alpha_max, "alpha_at": [alpha_at.x, alpha_at.y],
			"premultiplied_max": color_max, "changed_pixels": changed}

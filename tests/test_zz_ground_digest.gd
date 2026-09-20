extends RefCounted
## Throwaway: writes a per-tile digest of the ground TileSet `GroundLayers.build_tile_set()`
## produces, so the same digest taken before and after the compositor moves to the baked page can
## be diffed. Deleted before committing.
##
## `--svg` on the run picks the SVG side. On `origin/main` that is `TextureResolver`'s mode; on the
## new compositor the mode is the bake's, so the SVG side is taken after `tools/bake-atlases.sh
## --svg` instead and this flag only labels the file.

const AUTHORED_GROUND: TileSet = preload("res://assets/ground_tileset.tres")

func run(t) -> void:
	var svg := DevFlags.svg_requested()
	TextureResolver.reset_for_tests(svg)
	DirAccess.make_dir_recursive_absolute("/tmp/m171-ground")
	var out := "/tmp/m171-ground/digest-%s.txt" % ("svg" if svg else "png")
	var lines: Array[String] = []
	var built := GroundLayers.build_tile_set(AUTHORED_GROUND)
	lines.append("sources %d" % built.get_source_count())
	var shared: Texture2D = null
	for index in built.get_source_count():
		var id := built.get_source_id(index)
		var source := built.get_source(id) as TileSetAtlasSource
		if source == null or source.texture == null:
			lines.append("%d MISSING" % id)
			continue
		if shared == null:
			shared = source.texture
		lines.append("%d region_size=%s separation=%s tiles=%d shared=%s" % [id,
				source.texture_region_size, source.separation, source.get_tiles_count(),
				"yes" if source.texture == shared else "NO"])
		var sheet := source.texture.get_image()
		for tile in source.get_tiles_count():
			var coords := source.get_tile_id(tile)
			var cell := sheet.get_region(source.get_tile_texture_region(coords))
			lines.append("  %d %s %s" % [id, coords, _digest(cell.get_data())])
	if shared != null:
		var whole := shared.get_image()
		lines.append("sheet %s %s" % [whole.get_size(), _digest(whole.get_data())])
	var file := FileAccess.open(out, FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	print("DIGEST written to ", out, " (", lines.size(), " lines)")
	t.check(true, "digest written")

func _digest(data: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(data)
	return context.finish().hex_encode()

class_name CrowdAtlas
extends RefCounted
## Packs `CrowdAgent`'s per-view texture tables — the walker's body and trim in both gait frames
## across five views, and the crowd car's body and trim across five views — into one shared
## texture, so a walker's body, its trim and the next walker's body stop being three separate
## textures for the compatibility renderer's batcher to break on. *(Playtest 72: "I can see lag
## only if the crowd is being drawn though.")*
##
## Built once, lazily, on first use rather than at parse time — the atlas has to be packed
## **after** the presentation mode is known, and `TextureResolver`'s own first call is what fixes
## that mode, so packing at load time could pack the wrong half of the SVG/PNG choice. Every
## source texture is resolved through `TextureResolver.resolve()` before it is blitted, so a PNG
## transfer is what gets packed by default and `--svg`/`?svg=1` packs the SVG rasters instead; the
## picture on screen cannot change by a pixel either way, since the atlas only relocates whichever
## raster the resolver already chose.
##
## `pack()` builds from whatever `sources` its first caller supplies and **ignores the argument on
## every later call** until `reset_for_tests()` clears it — the same "read once" shape
## `TextureResolver._svg_requested` already has, and for the same reason: every caller in the
## running game passes the same six tables, so re-reading the argument on every call would be
## silly work for an answer that cannot change. A test that packs a different set of textures
## across cases has to call `reset_for_tests()` between them or it is reading the first case's
## atlas.

## The safe upper bound for one canvas texture's side on a phone.
const MAX_ATLAS_SIDE := 2048
## The margin kept between two packed images, and between the atlas edge and its first shelf, so
## bilinear filtering at a region's own edge never samples a neighbour's pixel.
const PADDING := 1

static var _built := false
static var _atlas_texture: ImageTexture
static var _result: Dictionary = {}

## Packs every dictionary in `sources` (an arbitrary group name -> {view name: Texture2D}) into
## one shared atlas the first time it is called, and returns a Dictionary keyed the same way whose
## values are dictionaries of the same shape as the inputs but with `AtlasTexture` values over the
## shared atlas. See the class doc for why a later call's own `sources` argument is ignored.
static func pack(sources: Dictionary) -> Dictionary:
	if not _built:
		_build(sources)
	return _result

## Clears the packed atlas so the next `pack()` call rebuilds from whatever `TextureResolver` mode
## is current — paired with `TextureResolver.reset_for_tests()` in every test that forces a
## presentation mode, since a suite that toggles `--svg` mid-run otherwise keeps drawing through
## whichever mode's atlas was built first.
static func reset_for_tests() -> void:
	_built = false
	_atlas_texture = null
	_result = {}

static func _build(sources: Dictionary) -> void:
	# One flat list of [group, view, Image] so the shelf layout below does not have to know the
	# dictionary-of-dictionaries shape at all; tallest first, so a shelf's own height is set by the
	# first image placed on it and never grows once later, shorter images are added beside it.
	var placements: Array = []
	for group: String in sources.keys():
		var views: Dictionary = sources[group]
		for view in views.keys():
			var texture: Texture2D = TextureResolver.resolve(views[view])
			var image := texture.get_image()
			image = image.duplicate()
			if image.get_format() != Image.FORMAT_RGBA8:
				image.convert(Image.FORMAT_RGBA8)
			placements.append([group, view, image])
	placements.sort_custom(func(a, b): return a[2].get_height() > b[2].get_height())

	var regions: Array[Rect2i] = []
	var shelf_x := PADDING
	var shelf_y := PADDING
	var shelf_height := 0
	var atlas_width := 0
	for placement in placements:
		var image: Image = placement[2]
		var w := image.get_width()
		var h := image.get_height()
		if shelf_x + w + PADDING > MAX_ATLAS_SIDE:
			shelf_y += shelf_height + PADDING
			shelf_x = PADDING
			shelf_height = 0
		regions.append(Rect2i(shelf_x, shelf_y, w, h))
		atlas_width = maxi(atlas_width, shelf_x + w)
		shelf_x += w + PADDING
		shelf_height = maxi(shelf_height, h)
	var atlas_height := shelf_y + shelf_height + PADDING
	atlas_width += PADDING

	assert(atlas_width <= MAX_ATLAS_SIDE and atlas_height <= MAX_ATLAS_SIDE,
			"crowd atlas is %dx%d, over the %dpx phone-safe canvas side"
			% [atlas_width, atlas_height, MAX_ATLAS_SIDE])

	var atlas_image := Image.create(atlas_width, atlas_height, false, Image.FORMAT_RGBA8)
	for i in placements.size():
		var image: Image = placements[i][2]
		atlas_image.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), regions[i].position)
	_atlas_texture = ImageTexture.create_from_image(atlas_image)

	_result = {}
	for i in placements.size():
		var group: String = placements[i][0]
		var view = placements[i][1]
		if not _result.has(group):
			_result[group] = {}
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = _atlas_texture
		atlas_texture.region = Rect2(regions[i])
		# So a neighbour's pixel is never sampled across a region's own edge under bilinear
		# filtering — see `PADDING`.
		atlas_texture.filter_clip = true
		_result[group][view] = atlas_texture
	_built = true

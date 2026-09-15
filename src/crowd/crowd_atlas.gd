class_name CrowdAtlas
extends RefCounted
## Packs `CrowdAgent`'s per-view texture tables — the walker's body and trim in both gait frames
## across five views, and the crowd car's body and trim across five views — into one shared
## texture, so a walker's body, its trim and the next walker's body stop being three separate
## textures for the compatibility renderer's batcher to break on. *(Playtest 72: "I can see lag
## only if the crowd is being drawn though.")*
##
## The packing itself is `TextureAtlas`'s, under the group name `ATLAS_NAME`; what lives here is
## the crowd's own shape on top of it — a dictionary of dictionaries in, the same dictionary of
## dictionaries out with `AtlasTexture` values, which is what `CrowdAgent._draw_body()` indexes
## by group and view.
##
## Built once, lazily, on first use rather than at parse time — the atlas has to be packed
## **after** the presentation mode is known, and `TextureResolver`'s own first call is what fixes
## that mode, so packing at load time could pack the wrong half of the SVG/PNG choice. Every
## source texture is resolved through `TextureResolver.resolve()` before it is blitted, so a PNG
## transfer is what gets packed by default and `--svg`/`?svg=1` packs the SVG rasters instead; the
## picture on screen cannot change by a pixel either way, since the atlas only relocates whichever
## raster the resolver already chose.
##
## **This one waits for its own blit rather than falling back to the sources while it runs**,
## which is the one thing it does differently from every other `TextureAtlas` user: `pack()`'s
## contract is that its caller can index the result straight away, and `CrowdAgent` asks for it
## from inside `_draw_body()`, where there is no earlier moment at which to have asked.
##
## `pack()` builds from whatever `sources` its first caller supplies and **ignores the argument on
## every later call** until `reset_for_tests()` clears it — the same "read once" shape
## `TextureResolver._svg_requested` already has, and for the same reason: every caller in the
## running game passes the same six tables, so re-reading the argument on every call would be
## silly work for an answer that cannot change. A test that packs a different set of textures
## across cases has to call `reset_for_tests()` between them or it is reading the first case's
## atlas.

## The group name the crowd's pictures are packed under in `TextureAtlas`.
const ATLAS_NAME := "crowd"
## The safe upper bound for one canvas texture's side on a phone.
const MAX_ATLAS_SIDE := TextureAtlas.MAX_ATLAS_SIDE
## The margin kept between two packed images, and between the atlas edge and its first shelf, so
## bilinear filtering at a region's own edge never samples a neighbour's pixel.
const PADDING := TextureAtlas.PADDING

static var _result: Dictionary = {}

## Packs every dictionary in `sources` (an arbitrary group name -> {view name: Texture2D}) into
## one shared atlas the first time it is called, and returns a Dictionary keyed the same way whose
## values are dictionaries of the same shape as the inputs but with `AtlasTexture` values over the
## shared atlas. See the class doc for why a later call's own `sources` argument is ignored.
static func pack(sources: Dictionary) -> Dictionary:
	if _result.is_empty():
		_build(sources)
	return _result

## Clears the packed atlas so the next `pack()` call rebuilds from whatever `TextureResolver` mode
## is current — paired with `TextureResolver.reset_for_tests()` in every test that forces a
## presentation mode, since a suite that toggles `--svg` mid-run otherwise keeps drawing through
## whichever mode's atlas was built first.
static func reset_for_tests() -> void:
	TextureAtlas.release(ATLAS_NAME)
	_result = {}

## The one flat key a group/view pair is packed under. `TextureAtlas` indexes by whatever its
## caller hands it and the crowd's index is a pair, so the pair is spelled out here rather than
## the packer being taught about nesting it has no other user for.
static func _key(group: String, view: Variant) -> String:
	return "%s|%s" % [group, view]

static func _build(sources: Dictionary) -> void:
	var flat: Dictionary = {}
	for group: String in sources.keys():
		var views: Dictionary = sources[group]
		for view in views.keys():
			flat[_key(group, view)] = views[view]
	TextureAtlas.request(ATLAS_NAME, flat)
	TextureAtlas.collect(ATLAS_NAME, true)
	_result = {}
	for group: String in sources.keys():
		var views: Dictionary = sources[group]
		var packed: Dictionary = {}
		for view in views.keys():
			packed[view] = TextureAtlas.texture_for(ATLAS_NAME, _key(group, view), views[view])
		_result[group] = packed

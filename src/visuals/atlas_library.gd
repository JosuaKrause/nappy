class_name AtlasLibrary
extends RefCounted
## The baked atlases, handed out by region name, one page per group.
##
## `tools/bake-atlases.sh` writes a page PNG per group and one region table into
## `BAKED_ROOT` before the engine imports anything; this reads that table and answers
## `region()` with an `AtlasTexture` over the page. **The page is the only texture a group
## costs**: it is loaded on the first `acquire()` and dropped on the last `release()`, and
## nothing here ever loads a constituent picture.
##
## **A region is valid only while its group is acquired.** `region()` on an unacquired group
## is a programming error rather than a fallback — it says so with `push_error` and answers
## `null`, because the alternative, quietly loading the page, is exactly the second copy in
## memory the atlases exist to prevent. Ask `native_size()` or `has_region()` instead when the
## question is about geometry: both are answered from the region table with no texture loaded
## at all, which is what a layout pass or a shadow's footprint needs.
##
## **The region table is loaded once and never dropped.** It is a few hundred rectangles, it is
## needed to answer `native_size()` with nothing acquired, and re-reading it per group would
## make the cheap questions cost a file read.
##
## The bake shares this file's `region_name_for()`, `illustrated_path_for()` and `plan()`, so
## the name a picture is baked under, the PNG that stands in for it and the shelf it lands on
## are decided in one place rather than agreed between two.

## Where the bake writes. Gitignored: a page is a build output, rebuilt from the sources on
## demand, and never committed.
const BAKED_ROOT := "res://assets/atlases/baked/"
## Region name -> group, rect and native size. Written by the bake, read here, and listed in
## the Web preset's `include_filter` because a `.json` is not a resource and would otherwise
## not be exported at all.
const REGIONS_PATH := BAKED_ROOT + "regions.json"
## Which group every picture belongs to, its lifetime and its padding kind. Checked in, and the
## one file a new consumer edits.
const MEMBERSHIP_PATH := "res://assets/atlases/membership.json"
## Where a PNG transfer stands in for an authored SVG, the same mapping `TextureResolver` uses.
const ILLUSTRATED_ROOT := "res://assets/illustrated/svg-transfer/"

## The safe upper bound for one canvas texture's side on a phone.
const MAX_ATLAS_SIDE := 2048
## The border every region owns, so bilinear filtering at a region's own edge never samples a
## neighbour. An opaque family's border holds its own edge pixels (extruded); a sprite's stays
## transparent.
const PADDING := 1
## What `plan()` leaves between two neighbours and around the page. Two rather than one, so the
## `PADDING` border belongs to a single region: at one pixel of separation the gap column
## between two neighbours would be both regions' border at once and whichever was written last
## would win, which makes "extruded" false for the other one.
const SEPARATION := 2 * PADDING

static var _regions: Dictionary = {}
static var _pages: Dictionary = {}
static var _mode := ""
static var _table_loaded := false

## Group name -> the loaded page `Texture2D`, its reference count and its size.
class Page extends RefCounted:
	var texture: Texture2D = null
	var count := 0
	var size := Vector2i.ZERO
	var padding := "transparent"
	## Region name -> the `AtlasTexture` handed out for it, dropped with the page.
	var textures: Dictionary = {}

# ------------------------------------------------------------------ the names ---

## The region name a source path is baked under: its repository path without the `assets/`
## prefix and without its extension, so `res://assets/events/cat_running_side.svg` is
## `events/cat_running_side`.
##
## **The rule is the path and nothing else**, so a name is stable under everything but a rename
## of the picture itself, a consumer can write it as a literal, and the bake and the test derive
## the same string from the membership file without a table between them. Takes either a
## `res://` path or a repository-relative one.
static func region_name_for(source_path: String) -> StringName:
	var path := source_path.trim_prefix("res://").trim_prefix("assets/")
	var extension := path.get_extension()
	if not extension.is_empty():
		path = path.left(path.length() - extension.length() - 1)
	return StringName(path)

## The illustrated PNG that stands in for an authored SVG, or "" for anything else — the same
## mapping `TextureResolver.resolve()` applies at runtime, so a baked picture is the picture the
## game draws today. Existence and size are the caller's to check.
static func illustrated_path_for(source_path: String) -> String:
	var path := source_path
	if not path.begins_with("res://"):
		path = "res://" + path
	if not path.begins_with("res://assets/") or not path.ends_with(".svg"):
		return ""
	return ILLUSTRATED_ROOT + path.trim_prefix("res://assets/").trim_suffix(".svg") + ".png"

# ----------------------------------------------------------------- the layout ---

## The shelf layout, as a pure function of the sizes it is asked to place: tallest first, so a
## shelf's height is set by the first image on it and never grows once shorter images are added
## beside it. `regions[i]` is where `sizes[i]` goes, in the caller's own order.
##
## Shared with the bake rather than owned by it, because the test that checks a page for
## overlaps and the tool that writes the page have to mean the same thing by "fits".
static func plan(sizes: Array[Vector2i]) -> Dictionary:
	var order: Array[int] = []
	for index in sizes.size():
		order.append(index)
	order.sort_custom(func(a: int, b: int) -> bool: return sizes[a].y > sizes[b].y)
	var regions: Array[Rect2i] = []
	regions.resize(sizes.size())
	var shelf_x := SEPARATION
	var shelf_y := SEPARATION
	var shelf_height := 0
	var width := 0
	for index in order:
		var size: Vector2i = sizes[index]
		if shelf_x + size.x + SEPARATION > MAX_ATLAS_SIDE:
			shelf_y += shelf_height + SEPARATION
			shelf_x = SEPARATION
			shelf_height = 0
		regions[index] = Rect2i(shelf_x, shelf_y, size.x, size.y)
		width = maxi(width, shelf_x + size.x)
		shelf_x += size.x + SEPARATION
		shelf_height = maxi(shelf_height, size.y)
	var page_size := Vector2i(width + SEPARATION, shelf_y + shelf_height + SEPARATION)
	return {
		"regions": regions,
		"size": page_size,
		"fits": page_size.x <= MAX_ATLAS_SIDE and page_size.y <= MAX_ATLAS_SIDE,
	}

# ------------------------------------------------------------------ the table ---

## Reads the region table if it has not been read yet. Every public question calls this; a
## missing table says so once and leaves every lookup answering its empty default, so a tree
## whose atlases were never baked fails with one legible error rather than a hundred.
static func _load_table() -> void:
	if _table_loaded:
		return
	_table_loaded = true
	if not FileAccess.file_exists(REGIONS_PATH):
		push_error("No baked atlases at %s — run tools/bake-atlases.sh" % REGIONS_PATH)
		return
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(REGIONS_PATH)) != OK:
		push_error("Unreadable region table: %s" % REGIONS_PATH)
		return
	var data: Variant = parser.data
	if not data is Dictionary or int((data as Dictionary).get("version", 0)) != 1:
		push_error("Region table is not version 1: %s" % REGIONS_PATH)
		return
	var table: Dictionary = data
	_mode = str(table.get("mode", ""))
	var pages: Dictionary = table.get("pages", {})
	for group: String in pages.keys():
		var record: Dictionary = pages[group]
		var page := Page.new()
		var size: Array = record.get("size", [0, 0])
		page.size = Vector2i(int(size[0]), int(size[1]))
		page.padding = str(record.get("padding", "transparent"))
		_pages[StringName(group)] = page
	_regions = table.get("regions", {})

## Which bake the tree carries, `"png"` or `"svg"`. The release is always `"png"`; a local
## `tools/bake-atlases.sh --svg` is what produces the other.
static func bake_mode() -> String:
	_load_table()
	return _mode

## Every group the bake wrote a page for, sorted.
static func groups() -> Array[StringName]:
	_load_table()
	var names: Array[StringName] = []
	for group: StringName in _pages.keys():
		names.append(group)
	names.sort()
	return names

## Every region name in the table, sorted. The sweep a test walks.
static func region_names() -> Array[StringName]:
	_load_table()
	var names: Array[StringName] = []
	for name: String in _regions.keys():
		names.append(StringName(name))
	names.sort()
	return names

## Whether the bake knows this name, answered without loading anything.
static func has_region(name: StringName) -> bool:
	_load_table()
	return _regions.has(String(name))

## The picture's own size in pixels, answered from the table with no group acquired and no
## texture loaded — what a layout, a shadow's footprint or an anchor needs. `Vector2i.ZERO` for
## a name the bake does not know.
static func native_size(name: StringName) -> Vector2i:
	_load_table()
	var record: Dictionary = _regions.get(String(name), {})
	if record.is_empty():
		return Vector2i.ZERO
	var size: Array = record["size"]
	return Vector2i(int(size[0]), int(size[1]))

## Which group a region belongs to, or `&""` for a name the bake does not know.
static func group_of(name: StringName) -> StringName:
	_load_table()
	var record: Dictionary = _regions.get(String(name), {})
	return StringName(str(record.get("group", ""))) if not record.is_empty() else &""

## The page's own size in pixels, from the table.
static func page_size(group: StringName) -> Vector2i:
	_load_table()
	var page: Page = _pages.get(group)
	return page.size if page != null else Vector2i.ZERO

## The rect a region occupies on its page, from the table.
static func region_rect(name: StringName) -> Rect2i:
	_load_table()
	var record: Dictionary = _regions.get(String(name), {})
	if record.is_empty():
		return Rect2i()
	var rect: Array = record["rect"]
	return Rect2i(int(rect[0]), int(rect[1]), int(rect[2]), int(rect[3]))

# --------------------------------------------------------------- the lifetime ---

## Takes a reference on `group`, loading its page on the first one.
static func acquire(group: StringName) -> void:
	_load_table()
	var page: Page = _pages.get(group)
	if page == null:
		push_error("No baked atlas group '%s'" % group)
		return
	page.count += 1
	if page.count > 1:
		return
	var path := BAKED_ROOT + String(group) + ".png"
	var texture: Texture2D = load(path)
	if texture == null:
		push_error("Baked atlas page missing: %s" % path)
		page.count = 0
		return
	page.texture = texture

## Drops a reference on `group`, freeing its page and every region handed out over it on the
## last one. A `release()` with nothing acquired is a programming error and says so.
static func release(group: StringName) -> void:
	_load_table()
	var page: Page = _pages.get(group)
	if page == null:
		push_error("No baked atlas group '%s'" % group)
		return
	if page.count == 0:
		push_error("Released atlas group '%s' that was not acquired" % group)
		return
	page.count -= 1
	if page.count > 0:
		return
	page.textures.clear()
	page.texture = null

## Whether `group` currently holds its page.
static func is_acquired(group: StringName) -> bool:
	_load_table()
	var page: Page = _pages.get(group)
	return page != null and page.count > 0

## How many references `group` is holding, which is what a test asserts the counting on.
static func reference_count(group: StringName) -> int:
	_load_table()
	var page: Page = _pages.get(group)
	return page.count if page != null else 0

# ---------------------------------------------------------------- the regions ---

## The picture to draw, as an `AtlasTexture` over its group's page: its region's own size is
## what `get_size()` answers, so scale, offsets, mirroring, anchors and y-sort read exactly the
## number they read from a single-picture texture.
##
## **Null when the group is not acquired**, with an error naming the region — see the class
## note. The `AtlasTexture` is cached per name and dropped with the page, so a draw call costs a
## dictionary lookup and a released group leaves nothing behind.
static func region(name: StringName) -> AtlasTexture:
	_load_table()
	var key := String(name)
	var record: Dictionary = _regions.get(key, {})
	if record.is_empty():
		push_error("No baked region '%s'" % key)
		return null
	var group := StringName(str(record["group"]))
	var page: Page = _pages.get(group)
	if page == null or page.texture == null:
		push_error("Region '%s' asked for while its group '%s' is not acquired" % [key, group])
		return null
	if page.textures.has(key):
		return page.textures[key]
	var rect: Array = record["rect"]
	var texture := AtlasTexture.new()
	texture.atlas = page.texture
	texture.region = Rect2(int(rect[0]), int(rect[1]), int(rect[2]), int(rect[3]))
	# So a neighbour's pixel is never sampled across a region's own edge — see `PADDING`.
	texture.filter_clip = true
	page.textures[key] = texture
	return texture

## The whole page as a CPU image, for the ground compositor, which composes its TileSet out of
## the page's pixels rather than drawing regions. Loaded on demand and **not cached**: it is a
## megabyte-scale image wanted once per day repaint and holding it would be the second resident
## copy this class exists to avoid. Answers null for an unknown group.
static func page_image(group: StringName) -> Image:
	_load_table()
	var page: Page = _pages.get(group)
	if page == null:
		push_error("No baked atlas group '%s'" % group)
		return null
	var texture: Texture2D = page.texture
	if texture == null:
		texture = load(BAKED_ROOT + String(group) + ".png")
	if texture == null:
		push_error("Baked atlas page missing for group '%s'" % group)
		return null
	var image: Image = texture.get_image()
	if image == null:
		return null
	if image.is_compressed() and image.decompress() != OK:
		return null
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	return image

## Drops every page and re-reads the table, so a suite that bakes or swaps one starts clean.
static func reset_for_tests() -> void:
	_regions = {}
	_pages = {}
	_mode = ""
	_table_loaded = false

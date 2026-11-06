class_name AtlasTable
extends RefCounted
## The baked atlases' region table (`PATH`), read from disk once and never
## written after: which group every region belongs to, where it sits on its page, its native size,
## each page's size and padding, and which bake the tree carries.
##
## **Geometry, with no texture anywhere.** Every answer here comes from a few hundred rectangles, so
## a layout pass, a shadow's footprint, a planner keeping a tree's reach clear or a placement
## measuring a warning picture asks this rather than an `AtlasLibrary`, and holds no page to do it.
## The pages, and which of them are held, are the library's (`AtlasLibrary`), which is built over a
## table.
##
## **One per process, read by the first ask** (`baked()`). The table is a build output that nothing
## the game does can change, so every reader is answered the same rectangles whichever asked first:
## a pure memo of the baked file, not state a caller leaves behind. The planners and the events'
## footprints read sizes off it ahead of any city or library existing, which is why it is asked here
## rather than handed through every one of them. A missing or unreadable table says so once and
## leaves every lookup answering its empty default, so a tree whose atlases were never baked fails
## with one legible error rather than a hundred.

## Region name -> group, rect and native size, beside the pages in `AtlasLibrary.BAKED_ROOT`.
## Written by the bake, read here, and listed in the Web preset's `include_filter` because a
## `.json` is not a resource and would otherwise not be exported at all. A literal rather than
## built from the library's constant: the bake compiles both files in a `--script` run with no
## class-name cache, so neither names the other's `class_name`.
const PATH := "res://assets/atlases/baked/regions.json"

## Region name -> `{"group", "rect", "size"}`, as the bake wrote it.
var _regions: Dictionary = {}
## Group -> `{"size": Vector2i, "padding": String}`.
var _pages: Dictionary = {}
var _mode := ""

static var _baked: AtlasTable = null

## The table the bake wrote, read on the first call and the same object on every call after.
static func baked() -> AtlasTable:
	if _baked == null:
		# `new()` rather than the class name: the bake compiles this file with no class-name cache.
		_baked = new()
		_baked._read(PATH)
	return _baked

func _read(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("No baked atlases at %s — run tools/bake-atlases.sh" % path)
		return
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		push_error("Unreadable region table: %s" % path)
		return
	var data: Variant = parser.data
	if not data is Dictionary or int((data as Dictionary).get("version", 0)) != 1:
		push_error("Region table is not version 1: %s" % path)
		return
	var table: Dictionary = data
	_mode = str(table.get("mode", ""))
	var pages: Dictionary = table.get("pages", {})
	for group: String in pages.keys():
		var record: Dictionary = pages[group]
		var size: Array = record.get("size", [0, 0])
		_pages[StringName(group)] = {
			"size": Vector2i(int(size[0]), int(size[1])),
			"padding": str(record.get("padding", "transparent")),
		}
	_regions = table.get("regions", {})

## Which bake the tree carries, `"png"` or `"svg"`. The release is always `"png"`; a local
## `tools/bake-atlases.sh --svg` is what produces the other.
func bake_mode() -> String:
	return _mode

## Every group the bake wrote a page for, sorted.
func groups() -> Array[StringName]:
	var names: Array[StringName] = []
	for group: StringName in _pages.keys():
		names.append(group)
	names.sort()
	return names

## Whether the bake wrote a page for `group`.
func has_group(group: StringName) -> bool:
	return _pages.has(group)

## Whether the bake knows this name.
func has_region(name: StringName) -> bool:
	return _regions.has(String(name))

## The picture's own size in pixels — what a layout, a shadow's footprint or an anchor needs.
## `Vector2i.ZERO` for a name the bake does not know.
func native_size(name: StringName) -> Vector2i:
	var record: Dictionary = _regions.get(String(name), {})
	if record.is_empty():
		return Vector2i.ZERO
	var size: Array = record["size"]
	return Vector2i(int(size[0]), int(size[1]))

## Which group a region belongs to, or `&""` for a name the bake does not know.
func group_of(name: StringName) -> StringName:
	var record: Dictionary = _regions.get(String(name), {})
	return StringName(str(record.get("group", ""))) if not record.is_empty() else &""

## The page's own size in pixels, or `Vector2i.ZERO` for a group the bake did not write.
func page_size(group: StringName) -> Vector2i:
	var page: Dictionary = _pages.get(group, {})
	var size: Vector2i = page.get("size", Vector2i.ZERO)
	return size

## The page's padding kind, `"transparent"` or `"extruded"` (see `AtlasLibrary.PADDING`).
func page_padding(group: StringName) -> String:
	var page: Dictionary = _pages.get(group, {})
	var padding: String = page.get("padding", "transparent")
	return padding

## The rect a region occupies on its page, or an empty rect for a name the bake does not know.
func region_rect(name: StringName) -> Rect2i:
	var record: Dictionary = _regions.get(String(name), {})
	if record.is_empty():
		return Rect2i()
	var rect: Array = record["rect"]
	return Rect2i(int(rect[0]), int(rect[1]), int(rect[2]), int(rect[3]))

extends RefCounted
## **Every region name the bake wrote**, read off the region table on disk (`AtlasTable.PATH`), for
## the suites that sweep the pages. A helper, not a suite: the runner loads only `test_*.gd`.
##
## The game never lists the table: it asks it about one name at a time (`AtlasTable.has_region()`,
## `group_of()`, `region_rect()`), so a listing is a question only the tests ask, and it lives with
## them rather than on the table (curly-rabbit #1095). It reads the bake's own output, the file
## `AtlasTable.baked()` is read from, so a sweep walks exactly what the pages carry.

## Every region name in the table, sorted, or none if the table cannot be read (which the atlas
## suites' guards that a sweep was not vacuous then report).
static func names() -> Array[StringName]:
	var found: Array[StringName] = []
	if not FileAccess.file_exists(AtlasTable.PATH):
		return found
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(AtlasTable.PATH)) != OK:
		return found
	var data: Variant = parser.data
	if not data is Dictionary:
		return found
	var regions: Variant = (data as Dictionary).get("regions", {})
	if not regions is Dictionary:
		return found
	for name: String in (regions as Dictionary).keys():
		found.append(StringName(name))
	found.sort()
	return found

## Every region name on `group`'s page, sorted.
static func on(group: StringName) -> Array[StringName]:
	var found: Array[StringName] = []
	for name in names():
		if AtlasTable.baked().group_of(name) == group:
			found.append(name)
	return found

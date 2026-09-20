extends RefCounted
## The baked atlases' own contract: that the pages on disk were baked from the tree the suite is
## running against, that every picture the membership file names has a region, that no two
## regions overlap on a page, that a group's page arrives on the first `acquire()` and is gone
## after the last `release()`, and that geometry can be asked for with nothing acquired at all.
##
## **The parity test is transitional and says so here so nobody defends it later.** It reads each
## baked region back and compares it, pixel for pixel, against the picture the running game draws
## today — `TextureResolver.resolve(load(source))`, the illustrated PNG where one exists and the
## SVG's own raster where none does. That comparison is only possible while the constituent
## sources are still in the imported tree, and the last pull request of this milestone moves them
## out; **it goes with them.** Until then it is the one check that says the bake changed no
## picture, which is the whole claim the consumer moves rest on.
##
## A tolerance is not this suite's to invent. Both sides go through the same rasterizer at the
## same scale, so the comparison is exact; a family that ever stops matching is a finding to
## report by name and by how far, not a comparison to loosen.

const MEMBERSHIP_PATH := "res://assets/atlases/membership.json"
const MANIFEST_PATH := "res://assets/atlases/baked/bake_manifest.json"

## A page is a few hundred pictures. Well under what the tree actually holds, and far enough
## above nought that a table that failed to load cannot pass this suite by sweeping nothing.
const FEWEST_CREDIBLE_REGIONS := 400

func run(t) -> void:
	AtlasLibrary.reset_for_tests()
	var membership := _read_json(MEMBERSHIP_PATH)
	t.check(not membership.is_empty(), "the membership file parses")
	_test_the_bake_is_not_stale(t)
	_test_every_member_has_a_region(t, membership)
	_test_regions_do_not_overlap(t)
	_test_geometry_needs_nothing_acquired(t)
	_test_a_page_arrives_and_leaves_with_its_references(t)
	_test_baked_pixels_are_todays_pictures(t, membership)
	_test_pages_meet_a_fill_floor(t)
	_test_pages_meet_an_aspect_ceiling(t)
	AtlasLibrary.reset_for_tests()

# ------------------------------------------------------------------ the bake ---

## The pages were baked from these sources, at these bytes. Every tool that runs the suite bakes
## first, so a failure here means either that something wrote into the tree mid-run or that the
## suite was started by hand around the wrapper — and in both cases every other check below is
## asking about a page that no longer stands for the tree it is being compared with.
func _test_the_bake_is_not_stale(t) -> void:
	var manifest := _read_json(MANIFEST_PATH)
	t.check(not manifest.is_empty(), "the bake manifest parses")
	if manifest.is_empty():
		return
	var inputs: Dictionary = manifest.get("inputs", {})
	t.check(inputs.size() >= FEWEST_CREDIBLE_REGIONS,
			"the bake manifest records every input it read (%d)" % inputs.size())
	var changed: Array[String] = []
	for path: String in inputs.keys():
		if FileAccess.get_sha256("res://" + path) != str(inputs[path]):
			changed.append(path)
	t.check(changed.is_empty(), "no baked source has changed since the bake: %s"
			% ", ".join(changed.slice(0, 5)))
	t.check(str(manifest.get("mode", "")) == AtlasLibrary.bake_mode(),
			"the region table and the bake manifest agree on the mode")

## Every picture the membership file lists is in the page its group names, and nothing else is.
func _test_every_member_has_a_region(t, membership: Dictionary) -> void:
	var groups: Dictionary = membership.get("groups", {})
	t.check(not groups.is_empty(), "the membership file lists groups")
	var expected := 0
	for group: String in groups.keys():
		var members: Array = (groups[group] as Dictionary).get("members", [])
		expected += members.size()
		var missing: Array[String] = []
		var misfiled: Array[String] = []
		for member: String in members:
			var name := AtlasLibrary.region_name_for(member)
			if not AtlasLibrary.has_region(name):
				missing.append(member)
			elif AtlasLibrary.group_of(name) != StringName(group):
				misfiled.append(member)
		t.check(missing.is_empty(), "%s: every member is baked (missing %s)"
				% [group, ", ".join(missing.slice(0, 5))])
		t.check(misfiled.is_empty(), "%s: every member is on its own group's page (%s)"
				% [group, ", ".join(misfiled.slice(0, 5))])
	t.check(AtlasLibrary.region_names().size() == expected,
			"the region table holds exactly the membership (%d regions, %d members)"
			% [AtlasLibrary.region_names().size(), expected])
	t.check(expected >= FEWEST_CREDIBLE_REGIONS,
			"there were regions to ask about (%d)" % expected)

## A region lies inside its page, and the one-pixel border every region owns is its own: two
## regions grown by `PADDING` never touch. That is what makes an extruded border true for both
## of a pair of neighbours rather than for whichever was written last.
func _test_regions_do_not_overlap(t) -> void:
	var by_group: Dictionary = {}
	for name: StringName in AtlasLibrary.region_names():
		var group := AtlasLibrary.group_of(name)
		if not by_group.has(group):
			by_group[group] = []
		(by_group[group] as Array).append(name)
	for group: StringName in by_group.keys():
		var page := Rect2i(Vector2i.ZERO, AtlasLibrary.page_size(group))
		var padded: Array[Rect2i] = []
		var outside: Array[String] = []
		var names: Array = by_group[group]
		for name: StringName in names:
			var rect := AtlasLibrary.region_rect(name)
			if not page.encloses(rect.grow(AtlasLibrary.PADDING)):
				outside.append(String(name))
			if AtlasLibrary.native_size(name) != rect.size:
				outside.append(String(name) + " (size disagrees with its rect)")
			padded.append(rect.grow(AtlasLibrary.PADDING))
		t.check(outside.is_empty(), "%s: every region and its padding is on the page (%s)"
				% [group, ", ".join(outside.slice(0, 5))])
		var overlaps := 0
		for i in padded.size():
			for j in range(i + 1, padded.size()):
				if padded[i].intersects(padded[j]):
					overlaps += 1
		t.check(overlaps == 0, "%s: no two padded regions overlap (%d pairs do)"
				% [group, overlaps])

# -------------------------------------------------------------- the lifetime ---

## The questions a layout pass asks — how big is this picture, do we have one — are answered
## from the table, with no page loaded. A consumer that had to acquire a group to measure a
## shadow would hold a megabyte of texture to read two integers.
func _test_geometry_needs_nothing_acquired(t) -> void:
	AtlasLibrary.reset_for_tests()
	var name := AtlasLibrary.region_name_for("assets/ui/pause.svg")
	t.check(AtlasLibrary.has_region(name), "the table knows a region with nothing acquired")
	t.check(AtlasLibrary.native_size(name) != Vector2i.ZERO,
			"a native size is answered with nothing acquired")
	t.check(not AtlasLibrary.is_acquired(&"ui"), "asking geometry acquired nothing")
	t.check(AtlasLibrary.native_size(&"no/such/picture") == Vector2i.ZERO,
			"an unknown region has no size")
	t.check(not AtlasLibrary.has_region(&"no/such/picture"), "an unknown region is not known")

## The page arrives on the first reference and is *gone* on the last — checked through a
## `WeakRef` to the texture itself rather than through the library's own bookkeeping, since a
## counter that reaches nought while the texture stays resident is exactly the bug this file
## exists to prevent.
func _test_a_page_arrives_and_leaves_with_its_references(t) -> void:
	AtlasLibrary.reset_for_tests()
	var name := AtlasLibrary.region_name_for("assets/ui/pause.svg")
	AtlasLibrary.acquire(&"ui")
	t.check(AtlasLibrary.reference_count(&"ui") == 1, "the first acquire counts one")
	var region := AtlasLibrary.region(name)
	t.check(region != null, "an acquired group answers its region")
	if region == null:
		return
	t.check(region.filter_clip, "a region clips its own filtering")
	t.check(region.get_size() == Vector2(AtlasLibrary.native_size(name)),
			"a region reports the picture's own size, not the page's")
	t.check(AtlasLibrary.region(name) == region, "a region is handed out once and cached")
	AtlasLibrary.acquire(&"ui")
	t.check(AtlasLibrary.reference_count(&"ui") == 2, "a second acquire counts two")
	var page: WeakRef = weakref(region.atlas)
	AtlasLibrary.release(&"ui")
	t.check(page.get_ref() != null, "the page survives while a reference is left")
	t.check(AtlasLibrary.region(name) != null, "and its regions still answer")
	region = null
	AtlasLibrary.release(&"ui")
	t.check(AtlasLibrary.reference_count(&"ui") == 0, "the last release counts nought")
	t.check(page.get_ref() == null, "the page texture is gone once nothing holds it")
	t.check(not AtlasLibrary.is_acquired(&"ui"), "and the group holds nothing")
	# What a released group answers `region()` — null, with a `push_error` naming the region —
	# is deliberately not exercised here. The error would be a real engine error in the run's
	# output, and an engine error in a suite makes the gate red whether or not a test expected
	# it; the state above is the same claim without the noise.
	t.check(AtlasLibrary.native_size(name) != Vector2i.ZERO,
			"and its geometry is still answerable afterwards")

# ---------------------------------------------------------------- the parity ---

## Every baked region is the picture the game draws today, exactly. See the class note: this is
## the transitional check that the bake relocated pictures and changed none of them, and it is
## deleted with the sources it compares against.
##
## Resolution is forced to the mode the pages were actually baked in rather than to the run's
## own `--svg` flag, so the suite asks the same question whichever bake the tree carries.
func _test_baked_pixels_are_todays_pictures(t, membership: Dictionary) -> void:
	AtlasLibrary.reset_for_tests()
	var svg_bake := AtlasLibrary.bake_mode() == "svg"
	TextureResolver.reset_for_tests(svg_bake)
	var groups: Dictionary = membership.get("groups", {})
	var compared := 0
	for group: String in groups.keys():
		var page := AtlasLibrary.page_image(StringName(group))
		if page == null:
			t.check(false, "%s: the page image reads back" % group)
			continue
		var differing: Array[String] = []
		var worst := ""
		var worst_pixels := 0
		for member: String in (groups[group] as Dictionary).get("members", []):
			var name := AtlasLibrary.region_name_for(member)
			var rect := AtlasLibrary.region_rect(name)
			var source := _todays_picture("res://" + member)
			if source == null:
				differing.append(member + " (unreadable today)")
				continue
			if source.get_size() != rect.size:
				differing.append("%s (%s baked, %s today)" % [member, rect.size, source.get_size()])
				continue
			compared += 1
			var baked := page.get_region(rect)
			if baked.get_data() == source.get_data():
				continue
			var pixels := _differing_pixels(baked, source)
			differing.append("%s (%d px)" % [member, pixels])
			if pixels > worst_pixels:
				worst_pixels = pixels
				worst = member
		t.check(differing.is_empty(),
				"%s: every baked region is today's picture (%d differ: %s; worst %s)"
				% [group, differing.size(), ", ".join(differing.slice(0, 5)), worst])
	t.check(compared >= FEWEST_CREDIBLE_REGIONS,
			"there were pictures to compare (%d)" % compared)
	TextureResolver.reset_for_tests(DevFlags.svg_requested())

## The picture the running game would draw for a source path today: the imported texture, put
## through the resolver's own PNG-transfer choice, as an RGBA8 image.
func _todays_picture(source_path: String) -> Image:
	var texture: Texture2D = load(source_path)
	if texture == null:
		return null
	var resolved := TextureResolver.resolve(texture)
	if resolved == null:
		return null
	var image: Image = resolved.get_image()
	if image == null:
		return null
	if image.is_compressed() and image.decompress() != OK:
		return null
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	return image

func _differing_pixels(a: Image, b: Image) -> int:
	var count := 0
	for y in a.get_height():
		for x in a.get_width():
			if a.get_pixel(x, y) != b.get_pixel(x, y):
				count += 1
	return count

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var data: Variant = parser.data
	return data if data is Dictionary else {}

# ------------------------------------------------------------------ the fit ---

## One group's own geometry, read from the region table rather than from the membership file, so
## a group that gains or loses members — or a group that does not exist yet, the way `stroller`
## is about to split into three and `head_indicators` is about to fold into `ui` — is measured as
## it actually is rather than by a name this suite happens to know today.
class _GroupShape:
	var count := 0
	## Every member's own area plus the one-pixel border `AtlasLibrary.PADDING` gives it on every
	## side — what a member actually costs the page, since its border is never shared with a
	## neighbour (`AtlasLibrary.SEPARATION`, twice `PADDING`, is what keeps it that way).
	var bordered_area := 0
	var widest := 0
	var tallest := 0

static func _group_shapes() -> Dictionary:
	var shapes: Dictionary = {}
	for name: StringName in AtlasLibrary.region_names():
		var group := AtlasLibrary.group_of(name)
		if not shapes.has(group):
			shapes[group] = _GroupShape.new()
		var shape: _GroupShape = shapes[group]
		var size := AtlasLibrary.native_size(name)
		shape.count += 1
		var bordered := size + Vector2i.ONE * (2 * AtlasLibrary.PADDING)
		shape.bordered_area += bordered.x * bordered.y
		shape.widest = maxi(shape.widest, size.x)
		shape.tallest = maxi(shape.tallest, size.y)
	return shapes

## The fill floor a page's member area (each member's own picture plus its one-pixel border, see
## `_GroupShape`) must clear over the page's own area. **Loosens for a small group** —
## `35 + 8·ln(member count)`, clamped to `[35, 85]` — because a greedy packer only ever plugs a
## gap with a member it has not placed yet: a page of a few hundred pictures has hundreds of
## chances to fill the room beside and under a tall one, and a page of five or six has only that
## many. The curve rises fastest where the difference between "a handful" and "a dozen" is
## largest and flattens once a group is big enough that the packer's own choices, not its member
## count, decide how tight the page is. Calibrated so every page the bake currently writes clears
## it and so the same rule, run against a page this test's own suite temporarily rebuilt with the
## shelf packer this milestone replaced, did not.
static func _fill_floor_percent(member_count: int) -> float:
	return clampf(35.0 + 8.0 * log(float(member_count)), 35.0, 85.0)

## The aspect ceiling a page's longer side over its shorter side must stay under. **Loosens with
## how much of an ideally square page a single member already demands** — `max(widest, tallest)`
## over the square root of the group's own bordered member area, the same measure `plan()` uses
## for its square-root target width — since a page cannot be more square than its own most
## dominant member's shape forces: a member that alone needs most of one side leaves nothing for
## the packer's choices to make up. `1.8` is the flat floor under that term for a group with no
## single dominant member, loose enough that a well-packed roughly-square page never trips it and
## tight enough that a single shelf-packed row, at four times that or worse, always does.
static func _aspect_ceiling(shape: _GroupShape) -> float:
	var ideal_side := sqrt(float(shape.bordered_area))
	var dominance := float(maxi(shape.widest, shape.tallest)) / ideal_side if ideal_side > 0.0 else 0.0
	return maxf(1.8, 1.0 + dominance)

## Every page's fill clears `_fill_floor_percent()`. Run once against the shelf packer this
## milestone replaced (`tools/bake_atlases.gd` reverted, one forced bake, this suite alone): it
## failed on `street_kit`, `interior`, `events` and `buildings`, the four PLAYTEST-109 measured as
## worst, and passed on every other group, which is why the floor is not simply raised until
## everything passes — a floor a shelf-packed page can still clear is not a floor.
func _test_pages_meet_a_fill_floor(t) -> void:
	var shapes := _group_shapes()
	for group: StringName in shapes.keys():
		var shape: _GroupShape = shapes[group]
		var page := AtlasLibrary.page_size(group)
		var fill := 100.0 * float(shape.bordered_area) / float(page.x * page.y)
		var floor_percent := _fill_floor_percent(shape.count)
		t.check(fill >= floor_percent,
				"%s: fill %.1f%% clears its floor %.1f%% for %d members (page %dx%d)"
				% [group, fill, floor_percent, shape.count, page.x, page.y])

## Every page's aspect ratio stays under `_aspect_ceiling()`. The same reverted-packer run that
## proves the fill floor also proves this one: every shelf-packed page is a single strip, tens of
## times wider than it is tall, which is exactly the shape this check exists to catch.
func _test_pages_meet_an_aspect_ceiling(t) -> void:
	var shapes := _group_shapes()
	for group: StringName in shapes.keys():
		var shape: _GroupShape = shapes[group]
		var page := AtlasLibrary.page_size(group)
		var aspect := float(maxi(page.x, page.y)) / float(mini(page.x, page.y))
		var ceiling := _aspect_ceiling(shape)
		t.check(aspect <= ceiling,
				"%s: aspect %.3f stays under its ceiling %.3f (page %dx%d)"
				% [group, aspect, ceiling, page.x, page.y])

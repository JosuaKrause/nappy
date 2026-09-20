extends SceneTree
## Bakes every atlas page the game draws from, using the engine's own rasterizer.
##
##     godot --headless --path . --script tools/bake_atlases.gd -- [--svg]
##
## `tools/bake-atlases.sh` is the entry point anybody should use; it decides whether this needs
## to run at all. Run it directly and it always bakes.
##
## **The presentation mode is the bake's, and there is no other.** By default a member with an
## illustrated PNG beside it is baked from that PNG and everything else from its SVG's raster;
## `--svg` bakes the SVG rasters alone and is the custom local build, never the release. Nothing
## in the running game chooses between them — the pixels on the page are the ones the build
## chose.
##
## **And a mode bakes what it draws.** A group's `members` are the pictures both modes carry;
## `members_png` and `members_svg` are the ones only that mode draws, and only that mode reads or
## hashes them. The `ground` group is why: a default bake composes 46 of its 58 TileSet sources
## out of layers, so the whole authored tiles of those 46 are on an `--svg` bake's page alone,
## which composes nothing and carries no layer in return.
##
## **Every picture goes through `Image.load_svg_from_buffer()` at scale 1.0 and
## `fix_alpha_edges()`**, which is what the import pass does to the same file — `svg/scale=1.0`
## and `process/fix_alpha_border=true` in every `.svg.import` sidecar in the tree. That is what
## makes a baked pixel the pixel the game draws today, and `tests/test_atlas_library.gd` holds
## it to that for every region while the constituent sources still exist.
##
## **Nothing here is repaired quietly.** An unreadable member, an illustrated PNG whose size
## disagrees with its SVG, two members claiming one region name, or a page over
## `AtlasLibrary.MAX_ATLAS_SIDE` exits non-zero and names the member. A bake that half-worked
## would be a build that half-draws, and the failure would land in a screenshot rather than in a
## log.
##
## This script may not use an autoload: `--script` starts no scene tree of the project's own, so
## `Telemetry`, `Tuning` and `Palette` do not exist here. It shares `AtlasLibrary`'s naming,
## illustrated-path and packing rules instead, which is the whole of what the loader and the
## bake have to agree on.

const Library := preload("res://src/visuals/atlas_library.gd")

## Bumped whenever this script changes what it writes for unchanged inputs, so a human reading
## `bake_manifest.json` can tell two bakes of the same tree apart. **The wrapper does not compare
## it** — `tools/bake-atlases.sh` already hashes this file and `atlas_library.gd` as inputs (see
## `_hash_input()` below), so any change to either, this bump included, already makes every
## checkout's recorded hash disagree with the tree and forces a rebake without a second constant
## kept in step with this one in the wrapper's own Python.
const TOOL_VERSION := 2

const MEMBERSHIP_PATH := "res://assets/atlases/membership.json"
## Every key a group record may carry. Checked rather than ignored, because a typo in one of the
## two mode lists — `members_svgs`, `members_png2` — would otherwise bake a group silently short
## of what a mode draws, and the missing region only shows up as a tile drawing nothing.
const MEMBERSHIP_KEYS := ["lifetime", "padding", "consumers", "members", "members_png",
		"members_svg"]
const BAKED_DIR := "res://assets/atlases/baked"
const REGIONS_PATH := BAKED_DIR + "/regions.json"
const MANIFEST_PATH := BAKED_DIR + "/bake_manifest.json"

## The import settings the pages are written with, since a `.import` sidecar inside a gitignored
## folder cannot be committed and a fresh clone would otherwise take the project defaults.
##
## `process/fix_alpha_border=false` is the one that matters: the bake has already run
## `fix_alpha_edges()` on each picture separately, and letting the importer run it again over
## the assembled page would bleed one region's colour into its neighbour's transparent pixels
## across the padding. `compress/mode=0` keeps the page lossless, `mipmaps/generate=false` keeps
## it sharp at the one scale it is drawn at, and `detect_3d/compress_to=0` stops the engine
## silently re-importing it VRAM-compressed if it is ever sampled in 3D.
const IMPORT_SIDECAR := """[remap]

importer="texture"
type="CompressedTexture2D"

[deps]

source_file="%s"

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_alpha_border=false
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=0
"""

var _svg_mode := false
var _inputs: Dictionary = {}
var _failures: Array[String] = []

func _init() -> void:
	var started := Time.get_ticks_msec()
	if not _parse_arguments():
		quit(2)
		return
	var membership := _read_membership()
	if membership.is_empty():
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(BAKED_DIR) != OK:
		printerr("bake_atlases: cannot create %s" % BAKED_DIR)
		quit(1)
		return
	var regions: Dictionary = {}
	var pages: Dictionary = {}
	var outputs: Array[String] = []
	var group_names: Array = membership.keys()
	group_names.sort()
	for group: String in group_names:
		var record: Dictionary = membership[group]
		var page_size := _bake_group(group, record, regions, pages)
		if page_size == Vector2i.ZERO:
			break
		outputs.append("assets/atlases/baked/%s.png" % group)
	if not _failures.is_empty():
		for failure in _failures:
			printerr("bake_atlases: " + failure)
		quit(1)
		return
	_remove_orphan_pages(group_names)
	outputs.append("assets/atlases/baked/regions.json")
	outputs.append("assets/atlases/baked/bake_manifest.json")
	_hash_input("assets/atlases/membership.json")
	_hash_input("tools/bake_atlases.gd")
	_hash_input("src/visuals/atlas_library.gd")
	# The region table is read by the running game and travels in the Web export, so it is
	# written compact; the bake manifest is read by the wrapper alone and is indented to be
	# readable when somebody is asking why a tree came out stale.
	_write_json(REGIONS_PATH, {
		"version": 1,
		"mode": "svg" if _svg_mode else "png",
		"pages": pages,
		"regions": regions,
	}, "")
	_write_json(MANIFEST_PATH, {
		"version": 1,
		"mode": "svg" if _svg_mode else "png",
		"tool_version": TOOL_VERSION,
		"outputs": outputs,
		"inputs": _inputs,
	})
	print("bake_atlases: %d regions over %d pages in %s mode, %d ms" % [regions.size(),
			pages.size(), "svg" if _svg_mode else "png", Time.get_ticks_msec() - started])
	quit(0)

# --------------------------------------------------------------- the argument ---

func _parse_arguments() -> bool:
	for argument in OS.get_cmdline_user_args():
		match argument:
			"--svg":
				_svg_mode = true
			"--help", "-h":
				print("usage: godot --headless --path . --script tools/bake_atlases.gd -- [--svg]")
				print("  --svg   bake the authored SVG rasters alone, never the illustrated PNGs")
				return false
			_:
				printerr("bake_atlases: unknown argument '%s'" % argument)
				return false
	return true

# ---------------------------------------------------------------- the reading ---

func _read_membership() -> Dictionary:
	if not FileAccess.file_exists(MEMBERSHIP_PATH):
		printerr("bake_atlases: no membership file at %s" % MEMBERSHIP_PATH)
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(MEMBERSHIP_PATH)) != OK:
		printerr("bake_atlases: %s is not valid JSON: %s (line %d)"
				% [MEMBERSHIP_PATH, parser.get_error_message(), parser.get_error_line()])
		return {}
	var data: Variant = parser.data
	if not data is Dictionary or int((data as Dictionary).get("version", 0)) != 1:
		printerr("bake_atlases: %s is not a version 1 membership file" % MEMBERSHIP_PATH)
		return {}
	var groups: Dictionary = (data as Dictionary).get("groups", {})
	if groups.is_empty():
		printerr("bake_atlases: %s lists no groups" % MEMBERSHIP_PATH)
	return groups

## What this bake's mode draws from `group`: the members both modes carry plus the ones only this
## mode does. Empty — with a failure recorded — for a group that would bake nothing, or one that
## lists a picture twice in the mode being baked, which would be two members claiming one region
## name and is a mistake in the file rather than a duplicate to drop.
##
## **The other mode's list is not read and not hashed**, which is what makes a change to a
## picture only an `--svg` bake draws leave a default tree up to date: `_rasterize()` is the only
## thing that hashes an input, and it is never called on a member this does not return.
func _members_for_this_mode(group: String, record: Dictionary) -> Array[String]:
	var members: Array[String] = []
	var seen: Dictionary = {}
	var lists: Array = [record.get("members", []),
			record.get("members_svg" if _svg_mode else "members_png", [])]
	for list: Array in lists:
		for member: String in list:
			if seen.has(member):
				_failures.append("group %s lists %s twice in the %s bake"
						% [group, member, "svg" if _svg_mode else "png"])
				return []
			seen[member] = true
			members.append(member)
	if members.is_empty():
		_failures.append("group %s has no members in the %s bake"
				% [group, "svg" if _svg_mode else "png"])
	return members

## The picture a member is baked from: its illustrated PNG in the default mode where one exists
## and agrees on size, its SVG's raster otherwise. Returns null and records a failure for
## anything unreadable or mis-sized, because either is a defect in the tree rather than a
## picture to skip.
func _member_image(member: String) -> Image:
	var source_path := "res://" + member
	if not FileAccess.file_exists(source_path):
		_failures.append("member does not exist: %s" % member)
		return null
	var authored := _rasterize(source_path)
	if authored == null:
		return null
	if _svg_mode or not member.ends_with(".svg"):
		return authored
	var illustrated := Library.illustrated_path_for(member)
	if illustrated.is_empty() or not FileAccess.file_exists(illustrated):
		return authored
	var transfer := _rasterize(illustrated)
	if transfer == null:
		return null
	if transfer.get_size() != authored.get_size():
		# A mis-sized transfer is a committed mistake rather than a picture to skip: the game
		# has no second copy to fall back to, so a page baked around the wrong canvas would
		# move an anchor in every frame that draws it. Failing is what gets it looked at.
		_failures.append("illustrated transfer is %s and its source %s is %s: %s"
				% [transfer.get_size(), member, authored.get_size(), illustrated])
		return null
	return transfer

## One picture, rasterized the way the import pass rasterizes it: SVG at scale 1.0 or PNG as it
## is, RGBA8, and `fix_alpha_edges()` for the importer's own `process/fix_alpha_border`.
func _rasterize(path: String) -> Image:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		_failures.append("unreadable or empty: %s" % path)
		return null
	var image := Image.new()
	var status := ERR_FILE_UNRECOGNIZED
	if path.ends_with(".svg"):
		status = image.load_svg_from_buffer(bytes, 1.0)
	elif path.ends_with(".png"):
		status = image.load_png_from_buffer(bytes)
	else:
		_failures.append("not an svg or a png: %s" % path)
		return null
	if status != OK:
		_failures.append("could not decode %s (error %d)" % [path, status])
		return null
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	image.fix_alpha_edges()
	_hash_input(path.trim_prefix("res://"))
	return image

func _hash_input(repository_path: String) -> void:
	if _inputs.has(repository_path):
		return
	var digest := FileAccess.get_sha256("res://" + repository_path)
	if digest.is_empty():
		_failures.append("cannot hash %s" % repository_path)
		return
	_inputs[repository_path] = digest

# ---------------------------------------------------------------- the packing ---

## Bakes one group's page and fills in its regions. Returns the page size, or `Vector2i.ZERO`
## when something failed — the caller stops there, since a second failure on a broken tree only
## buries the first.
func _bake_group(group: String, record: Dictionary, regions: Dictionary,
		pages: Dictionary) -> Vector2i:
	var padding := str(record.get("padding", "transparent"))
	if padding != "transparent" and padding != "extrude":
		_failures.append("group %s asks for unknown padding '%s'" % [group, padding])
		return Vector2i.ZERO
	for key: String in record.keys():
		if not (key in MEMBERSHIP_KEYS):
			_failures.append("group %s carries the unknown key '%s'" % [group, key])
			return Vector2i.ZERO
	var members := _members_for_this_mode(group, record)
	if members.is_empty():
		return Vector2i.ZERO
	members.sort()
	var images: Array[Image] = []
	var names: Array[StringName] = []
	var sizes: Array[Vector2i] = []
	for member: String in members:
		var image := _member_image(member)
		if image == null:
			return Vector2i.ZERO
		var name := Library.region_name_for(member)
		if regions.has(String(name)):
			_failures.append("two members share the region name '%s': %s" % [name, member])
			return Vector2i.ZERO
		names.append(name)
		images.append(image)
		sizes.append(image.get_size())
	var layout := Library.plan(sizes)
	if not layout["fits"]:
		var overflow: int = layout.get("overflow", -1)
		if overflow >= 0:
			_failures.append(
					"member %s is %dx%d including its own border, over the %dpx phone-safe canvas side"
					% [members[overflow], sizes[overflow].x, sizes[overflow].y, Library.MAX_ATLAS_SIDE])
		else:
			_failures.append("group %s packs to %s, over the %dpx phone-safe canvas side"
					% [group, layout["size"], Library.MAX_ATLAS_SIDE])
		return Vector2i.ZERO
	var placements: Array = layout["regions"]
	var page_size: Vector2i = layout["size"]
	var page := Image.create(page_size.x, page_size.y, false, Image.FORMAT_RGBA8)
	var member_area := 0
	for index in images.size():
		var image: Image = images[index]
		var rect: Rect2i = placements[index]
		page.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), rect.position)
		if padding == "extrude":
			_extrude(page, image, rect)
		regions[String(names[index])] = {
			"group": group,
			"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
			"size": [image.get_width(), image.get_height()],
		}
		var bordered := image.get_size() + Vector2i.ONE * (2 * Library.PADDING)
		member_area += bordered.x * bordered.y
	var png_path := "%s/%s.png" % [BAKED_DIR, group]
	if page.save_png(png_path) != OK:
		_failures.append("could not write %s" % png_path)
		return Vector2i.ZERO
	_write_import_sidecar(png_path)
	pages[group] = {
		"size": [page_size.x, page_size.y],
		"padding": padding,
		"members": images.size(),
	}
	# The fill the player reads off this line, printed for every page rather than measured
	# separately, is each member's own area including the one-pixel border every region owns
	# (`Library.PADDING`, not the larger `SEPARATION` gap to a neighbour) over the page's own
	# area — the same ratio PLAYTEST-109 measured from `regions.json` by hand.
	var fill := 100.0 * float(member_area) / float(page_size.x * page_size.y)
	print("bake_atlases: %-16s %4d members  %dx%d  %s padding  %.0f%% fill"
			% [group, images.size(), page_size.x, page_size.y, padding, fill])
	return page_size

## Copies a picture's own edge pixels into the one-pixel border `AtlasLibrary.PADDING` reserves
## around its region, so a filtered sample at the edge of an opaque tile reads the tile rather
## than the transparent gap beside it. `AtlasLibrary.SEPARATION` is two, so this border belongs
## to this region alone and no neighbour overwrites it.
func _extrude(page: Image, image: Image, rect: Rect2i) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var at := rect.position
	page.blit_rect(image, Rect2i(0, 0, width, 1), at + Vector2i(0, -1))
	page.blit_rect(image, Rect2i(0, height - 1, width, 1), at + Vector2i(0, height))
	page.blit_rect(image, Rect2i(0, 0, 1, height), at + Vector2i(-1, 0))
	page.blit_rect(image, Rect2i(width - 1, 0, 1, height), at + Vector2i(width, 0))
	page.blit_rect(image, Rect2i(0, 0, 1, 1), at + Vector2i(-1, -1))
	page.blit_rect(image, Rect2i(width - 1, 0, 1, 1), at + Vector2i(width, -1))
	page.blit_rect(image, Rect2i(0, height - 1, 1, 1), at + Vector2i(-1, height))
	page.blit_rect(image, Rect2i(width - 1, height - 1, 1, 1), at + Vector2i(width, height))

# ---------------------------------------------------------------- the writing ---

## Deletes every page in `BAKED_DIR` that no current group names, and its `.import` sidecar with
## it. A group that is folded into another — `head_indicators` into `ui` — leaves its page on
## disk otherwise: nothing loads it, `regions.json` does not mention it, and the wrapper's hash
## check calls the tree current, but `assets/atlases/baked/` **is** an imported folder, so the
## engine imports that page and exports it into the pack. A picture nothing draws, shipped.
##
## **The direction is what makes deleting safe here**: this only ever removes, only inside a
## gitignored folder the bake itself writes every file of, and only files that are not a page of
## a group in the membership the bake has just read. It cannot take a page a group names, and it
## cannot take anything a human put there, because nothing else belongs there. Called after every
## group has baked successfully, so a failed bake — which stops above this — never removes a page
## it was about to rewrite.
func _remove_orphan_pages(group_names: Array) -> void:
	var wanted: Dictionary = {}
	for group: String in group_names:
		wanted["%s.png" % group] = true
		wanted["%s.png.import" % group] = true
	var dir := DirAccess.open(BAKED_DIR)
	if dir == null:
		return
	var removed: Array[String] = []
	for entry in dir.get_files():
		if not entry.ends_with(".png") and not entry.ends_with(".png.import"):
			continue
		if wanted.has(entry):
			continue
		if dir.remove(entry) != OK:
			_failures.append("could not remove the orphan page %s/%s" % [BAKED_DIR, entry])
			continue
		removed.append(entry)
	if not removed.is_empty():
		removed.sort()
		print("bake_atlases: removed %d page(s) no group names: %s"
				% [removed.size(), ", ".join(removed)])

## Writes a page's import settings beside it, once. **Only when it is absent**: the import pass
## fills in the `uid` and the imported copy's path on first import, and rewriting the sidecar on
## every bake would hand the page a new identity each time and re-import the whole project.
func _write_import_sidecar(png_path: String) -> void:
	var sidecar_path := png_path + ".import"
	if FileAccess.file_exists(sidecar_path):
		return
	var file := FileAccess.open(sidecar_path, FileAccess.WRITE)
	if file == null:
		_failures.append("could not write %s" % sidecar_path)
		return
	file.store_string(IMPORT_SIDECAR % png_path)
	file.close()

func _write_json(path: String, data: Dictionary, indent := "  ") -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("could not write %s" % path)
		return
	# Sorted keys and a fixed indent, so the same inputs write the same bytes.
	file.store_string(JSON.stringify(data, indent, true) + "\n")
	file.close()

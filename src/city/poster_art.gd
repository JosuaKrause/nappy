class_name PosterArt
extends RefCounted
## The poster pictures a building front draws: the intact sheets, and every kind torn three ways.
##
## Every sheet is a 32×32 picture registered on a wall cell (`docs/GRAPHICS.md`, "Posters"), baked
## on the `buildings` page because `Building` is what draws them. **A torn sheet is not a file**:
## it is an intact kind with one of three tear masks applied — the poster's alpha multiplied by the
## mask's, then the tear's overlay drawn over it — which is the recipe the art was accepted with.
## The fifteen results are composed once, from the baked page's own pixels, by `prepare()`; a
## drawing call only ever looks one up.
##
## **Why the pixels and not a shader.** A mask on a canvas item needs either a material on the
## whole building (which would mask its walls too) or a node per torn sheet, and a composed
## `ImageTexture` is fifteen 32×32 pictures made once at a loading moment, then drawn exactly like
## the intact sheets are.

## The four kinds of poster, in the order the run brings them to the walls. `WANTED` is the one-X
## copy: the two-X copy (`poster_wanted_crossed.svg`) waits on the neighbor of M181's day 10, which
## no run can fail yet, so it is not drawn.
enum Kind { LEADER, RULES, CURFEW, UNIFORM, WANTED }

const SHEETS := {
	Kind.LEADER: &"events/posters/poster_leader",
	Kind.RULES: &"events/posters/poster_rules",
	Kind.CURFEW: &"events/posters/poster_curfew",
	Kind.UNIFORM: &"events/posters/poster_uniform",
	Kind.WANTED: &"events/posters/poster_wanted",
}
## The three tears, each a mask of the paper that stays and an overlay of the tear's fringe, bare
## wall, glue and crumbs. Index 0 is tear A, 1 is B (the hanging flap), 2 is C.
const TEAR_MASKS: Array[StringName] = [
	&"events/posters/poster_tear_a_mask",
	&"events/posters/poster_tear_b_mask",
	&"events/posters/poster_tear_c_mask",
]
const TEAR_OVERLAYS: Array[StringName] = [
	&"events/posters/poster_tear_a_overlay",
	&"events/posters/poster_tear_b_overlay",
	&"events/posters/poster_tear_c_overlay",
]
const TEARS := 3
## The page every picture above is baked on — see `assets/atlases/membership.json`.
const ATLAS_GROUP := &"buildings"

## Where a pair of sheets stands on its cell when a newer one was pasted over an older one with an
## offset (`PosterState`'s `under`): the older one shifted `-side` and up, the newer one `+side`.
## Eight pixels apart across, two up and down, which shows two fifths of the older 20px sheet — more
## than a sliver, so it reads as pasted over rather than as a drawing glitch (PLAYTEST-123,
## statement 31) — and keeps both inside their 32px cell with a gap on every side: the older sheet
## spans x 2–22 and y 1–23, the newer x 10–30 and y 3–25, clear of the plinth from y 26. Stated for
## `side` +1; `Building._draw_posters()` multiplies the x by the cell's own side.
const UNDER_OFFSET := Vector2(-4.0, -2.0)
const OVER_OFFSET := Vector2(4.0, 0.0)

## `kind * TEARS + tear` -> the composed `ImageTexture`. Built once for the process by `prepare()`.
static var _torn: Dictionary = {}

## Every region name this class draws, for the bake check in `tests/test_atlas_leaf_consumers.gd`.
static func region_names() -> Array[StringName]:
	var names: Array[StringName] = []
	for kind: int in SHEETS:
		names.append(SHEETS[kind])
	names.append_array(TEAR_MASKS)
	names.append_array(TEAR_OVERLAYS)
	return names

## The intact sheet for `kind`, a region on the held `buildings` page.
static func sheet(kind: int) -> Texture2D:
	return AtlasLibrary.region(SHEETS[kind])

## `kind` torn the `tear`th way, or the intact sheet if `prepare()` could not compose it — a torn
## sheet drawn whole is a wrong picture, never a missing one.
static func torn(kind: int, tear: int) -> Texture2D:
	var composed: Texture2D = _torn.get(kind * TEARS + tear)
	return composed if composed else sheet(kind)

## Composes every torn sheet from the baked page, once for the process. Called by `City.build()`,
## which is a loading moment: the page image is a CPU copy of a whole page, which is nothing to
## want in the frame a tear happens.
static func prepare() -> void:
	if not _torn.is_empty():
		return
	var page := AtlasLibrary.page_image(ATLAS_GROUP)
	if page == null:
		push_error("PosterArt: no '%s' page to compose the torn posters from" % ATLAS_GROUP)
		return
	for kind: int in SHEETS:
		var poster := _cut(page, SHEETS[kind])
		for tear in TEARS:
			var mask := _cut(page, TEAR_MASKS[tear])
			var overlay := _cut(page, TEAR_OVERLAYS[tear])
			if poster == null or mask == null or overlay == null:
				continue
			_torn[kind * TEARS + tear] = ImageTexture.create_from_image(
					compose(poster, mask, overlay))

## The picture for a sheet as `PosterState` holds it: intact, or torn the `tear`th way.
static func texture_for(kind: int, tear: int) -> Texture2D:
	return sheet(kind) if tear == PosterState.INTACT else torn(kind, tear)

## The recipe, per pixel: the poster's colour with its alpha multiplied by the mask's, then the
## overlay drawn over the result with ordinary source-over blending. All three images are the same
## size and registration. Pure, so a test can hold it without a page.
static func compose(poster: Image, mask: Image, overlay: Image) -> Image:
	var result := Image.create(poster.get_width(), poster.get_height(), false, Image.FORMAT_RGBA8)
	for y in poster.get_height():
		for x in poster.get_width():
			var colour := poster.get_pixel(x, y)
			colour.a *= mask.get_pixel(x, y).a
			result.set_pixel(x, y, colour)
	result.blend_rect(overlay, Rect2i(Vector2i.ZERO, overlay.get_size()), Vector2i.ZERO)
	return result

static func _cut(page: Image, name: StringName) -> Image:
	var rect := AtlasLibrary.region_rect(name)
	if rect.size == Vector2i.ZERO:
		push_error("PosterArt: no baked region '%s'" % name)
		return null
	return page.get_region(rect)

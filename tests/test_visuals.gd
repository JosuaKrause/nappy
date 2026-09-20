extends RefCounted
## What the artwork owes the game, asked of the pixels the game actually draws.
##
## **The pixels come off the baked page, because there is nowhere else to get them.** The authoring
## sources live under `art/`, which the engine ignores, so nothing here loads a picture: each
## region is read out of `AtlasLibrary.page_image()` with `Image.get_region()`, which is the same
## rectangle `AtlasLibrary.region()` hands a draw call.
##
## Every sweep below is over `AtlasLibrary.region_names()` and carries a count with it, because a
## sweep that silently finds nothing is the way this file has failed before: its predecessor walked
## `event_instance.gd`'s constants for `Texture2D`s, and passed vacuously on an empty map the day
## those constants became region names.
##
## **Three of the rules are the illustrated transfer's own, and are asked of the default bake
## alone.** A redrawn picture owes its source the same registration — the same anchor, the same
## centre, real alpha where the source had it — and that is what `_transfer_rules` below gates. An
## SVG bake carries the thing being transferred *from*, where the same three are deliberately not
## true: an authored `tiles/layers/*.svg` is a whole opaque tile, because an SVG bake composes
## nothing (`GroundLayers._layer_recipe()` returns `{}` for one); the authored `props/garbage_sack`
## leaves a pixel under its own feet; and the authored `rig/pram_side` is drawn two pixels left of
## its canvas centre. The authored vectors are judged by eye under the **svg-art** skill. Every
## release and every CI run is a default bake, so the gated half is asked on every tree that
## matters and the suite says out loud when it is not.
##
## The rest are about *placement and coverage* and hold for either bake.

## How far a picture's visible centre may sit from the anchor its caller draws it on.
const ANCHOR_TOLERANCE := 1.5
## The ground components' own canvas — `GroundLayers.TILE_SIZE`, restated as the number this file
## asserts rather than read from it, since a component that stopped being tile-sized would make
## the compositor's own arithmetic wrong in a way reading its constant back could not catch.
const LAYER_CANVAS := Vector2i(32, 32)

## **How many whole ground tiles there are to ask about is the bake's.** An `--svg` bake carries
## all 58; a default bake carries the twelve whose source the compositor composes nothing for, and
## the other 46 are composed from layers rather than drawn. This is the smaller of the two, so the
## sweep below stays a guard against having found nothing rather than a second copy of the
## per-mode membership `tests/test_atlas_ground.gd` already pins exactly.
const FEWEST_WHOLE_GROUND_TILES := 12
## And how many layer components there are: 31 in a default bake, none at all in an `--svg` one,
## which composes nothing and carries no layer in return.
const FEWEST_GROUND_COMPONENTS := 25

## The props whose placement is a contract their caller relies on, by region name. Each is drawn
## by `Prop`, `Litter` or `CityDecals` on a point — a ground decal on its own centre, a standing
## object on its feet — so a picture that drifts inside its canvas moves in the world without
## anything in the code changing.
const CENTRED_PROPS: Array[StringName] = [&"props/bollard", &"props/litter_apple",
		&"props/litter_bag", &"props/litter_can", &"props/litter_cup", &"props/litter_newspaper"]
const STANDING_PROPS: Array[StringName] = [&"props/garbage_sack", &"props/garbage_sacks_pile",
		&"props/tree_a", &"props/tree_b"]
## The one prop that is ground rather than an object on it: the pit a street tree stands in, drawn
## flat under the tree, so a transparent pixel in it would show the paving through the soil.
const OPAQUE_PROP := &"props/tree_pit"

## Whether this tree carries the default bake, which is the only one the transfer rules are about.
var _transfer_rules := false

func run(t) -> void:
	_transfer_rules = AtlasLibrary.bake_mode() == "png"
	if not _transfer_rules:
		print("test_visuals: %s bake — the transfer registration rules are not asked of the "
				% AtlasLibrary.bake_mode() + "authored vectors; see this file's own note")
	_test_the_rig_stands_on_its_canvas_bottom(t)
	_test_ground_tiles_cover_their_cell(t)
	_test_ground_components_keep_their_canvas(t)
	_test_props_keep_the_placement_their_callers_draw_on(t)

# ------------------------------------------------------------------- the rig ---

## Every mother, father and pram view is an upright figure the game draws feet-down on a point
## (`Sprites.draw_standing()`), so its artwork has to reach the bottom of its own canvas and sit
## centred across it — otherwise she floats or walks beside herself when she turns. Each also has
## to carry real transparency *inside* its own bounds: the gaps between an arm and a body, and
## between a pram's wheels, are what stop a figure reading as a filled block.
func _test_the_rig_stands_on_its_canvas_bottom(t) -> void:
	var checked := 0
	for name: StringName in AtlasLibrary.region_names():
		if not String(name).begins_with("rig/"):
			continue
		var image := _region_image(name)
		if image == null:
			t.check(false, "%s reads back off its page" % name)
			continue
		checked += 1
		var bounds := _visible_bounds(image)
		t.check(bounds.has_area(), "%s has visible artwork" % name)
		if not bounds.has_area():
			continue
		t.check(bounds.end.y == image.get_height(),
				"%s keeps its canvas-bottom ground anchor" % name)
		t.check(_has_a_clear_pixel_inside(image, bounds),
				"%s keeps real transparency within its own artwork bounds" % name)
		if _transfer_rules:
			var visible_centre := float(bounds.position.x) + float(bounds.size.x) / 2.0
			t.check(absf(visible_centre - float(image.get_width()) / 2.0) <= ANCHOR_TOLERANCE,
					"%s stays centred on its ground anchor" % name)
	t.check(checked >= 60, "there were rig views to ask about (%d)" % checked)

# ---------------------------------------------------------------- the ground ---

## A ground picture is the floor of a cell, so every pixel of it is opaque: the TileSet draws one
## per cell with nothing behind it, and a hole shows the void. The layer components below are the
## exception and are excluded here by name — those are drawn *over* a base and are supposed to be
## mostly transparent.
##
## **How many whole tiles there are to ask about is the bake's** — see
## `FEWEST_WHOLE_GROUND_TILES`.
func _test_ground_tiles_cover_their_cell(t) -> void:
	var checked := 0
	var holed: Array[String] = []
	for name: StringName in AtlasLibrary.region_names():
		var text := String(name)
		if not text.begins_with("tiles/") or text.begins_with("tiles/layers/"):
			continue
		var image := _region_image(name)
		if image == null:
			t.check(false, "%s reads back off its page" % name)
			continue
		checked += 1
		if not _is_opaque(image):
			holed.append(text)
	t.check(holed.is_empty(), "every ground tile covers its full opaque canvas (%s)"
			% ", ".join(holed.slice(0, 5)))
	t.check(checked >= FEWEST_WHOLE_GROUND_TILES,
			"there were whole ground tiles to ask about (%d)" % checked)

## A curb, a marking, a crack or a grass clump is blended over a shared base at build time
## (`GroundLayers._layered_image()`), so each component owes the tile's own canvas — the blend
## lands off-register otherwise — and, as a transfer, genuine transparency, or it paints out the
## base it was meant to sit on.
##
## **The four `*_base` components are the bases themselves, not overlays**, and owe the opposite:
## the paving, asphalt, alley and grass materials every other component is blended *onto* are what
## the composed tile's opacity comes from, so a transparent pixel in one of those is a hole in
## every tile built on it.
##
## **An `--svg` bake has no components at all to ask about**, since it composes nothing and its
## page carries no layer: there the sweep asserts that absence rather than a count, which is the
## same claim from the other side.
func _test_ground_components_keep_their_canvas(t) -> void:
	var checked := 0
	var bases := 0
	for name: StringName in AtlasLibrary.region_names():
		var text := String(name)
		if not text.begins_with("tiles/layers/"):
			continue
		var image := _region_image(name)
		if image == null:
			t.check(false, "%s reads back off its page" % name)
			continue
		checked += 1
		t.check(image.get_size() == LAYER_CANVAS,
				"%s keeps the tile's native %dpx component canvas (got %s)"
				% [name, LAYER_CANVAS.x, image.get_size()])
		if text.ends_with("_base"):
			bases += 1
			t.check(_is_opaque(image),
					"%s is a shared base and covers its full opaque canvas" % name)
			continue
		if _transfer_rules:
			t.check(_has_opaque_and_clear(image),
					"%s has visible detail and genuine transparency" % name)
	if AtlasLibrary.bake_mode() == "svg":
		t.check(checked == 0,
				"an svg bake's page carries no ground component, since it composes nothing (%d)"
				% checked)
		return
	t.check(checked >= FEWEST_GROUND_COMPONENTS,
			"there were ground components to ask about (%d)" % checked)
	t.check(bases >= 4, "and the shared bases were among them (%d)" % bases)

# ----------------------------------------------------------------- the props ---

## The props whose caller draws them on a point rather than on a rectangle. A ground decal is
## placed by its canvas centre and a standing object by its canvas bottom, so where the artwork
## sits inside its canvas *is* where the object sits in the world.
func _test_props_keep_the_placement_their_callers_draw_on(t) -> void:
	for name in CENTRED_PROPS:
		var image := _region_image(name)
		t.check(image != null, "%s is a baked region" % name)
		if image == null:
			continue
		var bounds := _visible_bounds(image)
		t.check(bounds.has_area(), "%s has visible artwork" % name)
		if not bounds.has_area():
			continue
		var centre := Vector2(bounds.position) + Vector2(bounds.size) / 2.0
		t.check(centre.distance_to(Vector2(image.get_size()) / 2.0) <= ANCHOR_TOLERANCE,
				"%s stays centred on the decal anchor it is drawn from" % name)
	for name in STANDING_PROPS:
		var image := _region_image(name)
		t.check(image != null, "%s is a baked region" % name)
		if image == null:
			continue
		var bounds := _visible_bounds(image)
		t.check(bounds.has_area(), "%s has visible artwork" % name)
		if not bounds.has_area():
			continue
		t.check(_has_opaque_and_clear(image),
				"%s has opaque art and genuine transparency around it" % name)
		if _transfer_rules:
			t.check(bounds.end.y == image.get_height(),
					"%s keeps its canvas-bottom ground anchor" % name)
	var pit := _region_image(OPAQUE_PROP)
	t.check(pit != null, "%s is a baked region" % OPAQUE_PROP)
	if pit != null:
		t.check(_is_opaque(pit), "%s covers its full opaque canvas, since it is ground" % OPAQUE_PROP)

# ----------------------------------------------------------------- the pixels ---

## One region's own pixels, read out of its group's page. The page is loaded for the read and
## dropped again, so this suite leaves nothing acquired behind it — and it is read per region
## rather than cached, since `page_image()` deliberately does not cache a megabyte-scale image.
func _region_image(name: StringName) -> Image:
	if not AtlasLibrary.has_region(name):
		return null
	var page := AtlasLibrary.page_image(AtlasLibrary.group_of(name))
	if page == null:
		return null
	return page.get_region(AtlasLibrary.region_rect(name))

func _is_opaque(image: Image) -> bool:
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < 0.99:
				return false
	return true

func _has_opaque_and_clear(image: Image) -> bool:
	var opaque := false
	var clear := false
	for y in image.get_height():
		for x in image.get_width():
			var alpha := image.get_pixel(x, y).a
			opaque = opaque or alpha >= 0.95
			clear = clear or alpha <= 0.01
	return opaque and clear

func _has_a_clear_pixel_inside(image: Image, bounds: Rect2i) -> bool:
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			if image.get_pixel(x, y).a <= 0.01:
				return true
	return false

func _visible_bounds(image: Image) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.01:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < 0:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

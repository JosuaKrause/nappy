extends RefCounted
## The "decoration" `AtlasLibrary` group — props, litter and city decals. `tests/test_atlas_library.gd`
## already covers the atlas contract every group shares (every member baked, no two regions
## overlap, geometry answered with nothing acquired, a page arriving and leaving with its
## references); this suite covers what is specific to this family: a prop's shadow reads its size
## from the region table rather than from a loaded texture, and the clearance the street trees'
## planner keeps round a pit (`TreePictures.widest_reach()`) covers every picture a street tree's prop
## may be drawn as. The group's lifetime while a `City`
## stands (read once, released when the city is freed) is a fact about `City` and is
## `tests/test_city_atlas_holds.gd`'s.

func run(t: TestRunner) -> void:
	_test_shadow_sizes_read_the_region_table(t)
	_test_the_street_tree_footprint_covers_every_picture(t)

## A prop's shadow (`Prop.shadow_outlines()`, what it draws and the debug view traces) is sized from
## `AtlasTable.baked().native_size()`, not from `get_size()` on a loaded texture — the change
## `docs/TODO.md`'s M171 decoration item asks for by name: a point prop's oval reaches its radius to
## either side, and the swing frame's two ovals stand under its two A-frames. Built off the scene
## tree, one `Prop` at a time, in the order `City` itself builds one: `Prop.new()`, then the
## exports, then `add_child()` — which is what fires `_ready()` and computes its ground shape.
func _test_shadow_sizes_read_the_region_table(t: TestRunner) -> void:
	var point_cases := [
		[Prop.Kind.BOLLARD, Prop.BOLLARD, 0.4],
		[Prop.Kind.SACK, Prop.SACK, 0.35],
		[Prop.Kind.SACK_PILE, Prop.SACK_PILE, 0.3],
	]
	for case: Array in point_cases:
		var kind: Prop.Kind = case[0]
		var region: StringName = case[1]
		var fraction: float = case[2]
		var prop := Prop.new()
		prop.dress(null, kind)
		t.add_child(prop)
		var expected: float = float(AtlasTable.baked().native_size(region).x) * fraction
		var radius := _shadow_half_width(prop)
		t.check(is_equal_approx(radius, expected),
				"Prop.Kind %d's shadow radius is off the region table's own size (%.2f against %.2f)"
				% [kind, radius, expected])
		prop.free()

	var tree := Prop.new()
	tree.dress(null, Prop.Kind.TREE, 0, 1.3)
	t.add_child(tree)
	var expected_tree := TreePictures.shape(0, 1.3).reach()
	var tree_radius := _shadow_half_width(tree)
	t.check(is_equal_approx(tree_radius, expected_tree),
			"a tree's shadow radius follows scale_factor() off the region table's own size (%.2f against %.2f)"
			% [tree_radius, expected_tree])
	var own_size_tree := Prop.new()
	own_size_tree.dress(null, Prop.Kind.TREE, 0)
	t.add_child(own_size_tree)
	var own_reach := _shadow_half_width(own_size_tree)
	t.check(own_reach > 0.0 and is_equal_approx(tree_radius, own_reach * 1.3),
			"a tree dressed 1.3 times its picture's size reaches 1.3 times as far as one at its own size (%.2f against %.2f)"
			% [tree_radius, own_reach])
	own_size_tree.free()
	tree.free()

	var frame := Prop.new()
	frame.dress(null, Prop.Kind.PLAYGROUND_FRAME)
	t.add_child(frame)
	var frame_size := Vector2(AtlasTable.baked().native_size(Prop.SWING_FRAME))
	var a_frame := frame_size.x * 0.5 * Prop.SWING_A_FRAME_SHARE
	var centres: Array[Vector2] = []
	for outline in frame.shadow_outlines(Vector2.ZERO):
		var bounds := _bounds(outline)
		centres.append(bounds.get_center())
	centres.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	t.check(centres.size() == 2
			and centres[0].distance_to(Vector2(-a_frame, 0.0)) < 0.01
			and centres[1].distance_to(Vector2(a_frame, 0.0)) < 0.01,
			"the swing frame's shadow is an oval under each A-frame, %.2fpx either side of its middle (%s)"
			% [a_frame, str(centres)])
	frame.free()

## `TreePictures.widest_reach()` is the reach `StreetTrees.footprint_tiles()` keeps the day's events
## out of round every pit, ahead of any `City` existing, and a pit's prop picks its picture from its
## own variant where it is built. So a street tree drawn as any picture reaches no further than that,
## or an event could stand under a canopy; and the widest reaches exactly that, or the planners refuse
## ground no tree takes. Each is built the way `City` builds a street tree: `Prop.new()`, dressed with
## no scale, then `add_child()`.
func _test_the_street_tree_footprint_covers_every_picture(t: TestRunner) -> void:
	var widest := 0.0
	for variant in TreePictures.REGIONS.size():
		var tree := Prop.new()
		tree.dress(null, Prop.Kind.STREET_TREE, variant)
		t.add_child(tree)
		var reach := _shadow_half_width(tree)
		t.check(reach <= TreePictures.widest_reach() + 0.001,
				"a street tree drawn as %s reaches %.2fpx, within the %.2fpx the planners keep clear"
				% [TreePictures.region(variant), reach, TreePictures.widest_reach()])
		widest = maxf(widest, reach)
		tree.free()
		# A street tree dressed with any scale is still grounded at its picture's own size.
		var scaled := Prop.new()
		scaled.dress(null, Prop.Kind.STREET_TREE, variant, 2.0)
		t.add_child(scaled)
		var scaled_reach := _shadow_half_width(scaled)
		t.check(is_equal_approx(scaled_reach, reach),
				"a street tree of %s dressed with a scale reaches the same (%.2f against %.2f)"
				% [TreePictures.region(variant), scaled_reach, reach])
		scaled.free()
	t.check(is_equal_approx(widest, TreePictures.widest_reach()),
			"and the widest street tree reaches exactly the planners' clearance (%.2f against %.2f)"
			% [widest, TreePictures.widest_reach()])

## How far a prop's shadow reaches to either side of where it stands, `INF` for one that casts
## none: for a point prop, its ground shape's radius.
func _shadow_half_width(prop: Prop) -> float:
	var outlines := prop.shadow_outlines(Vector2.ZERO)
	if outlines.is_empty():
		return INF
	var widest := 0.0
	for outline in outlines:
		for point in outline:
			widest = maxf(widest, absf(point.x))
	return widest

## The box round `outline`.
func _bounds(outline: PackedVector2Array) -> Rect2:
	var box := Rect2(outline[0], Vector2.ZERO)
	for point in outline:
		box = box.expand(point)
	return box

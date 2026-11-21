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

## A prop's shadow radius (and the swing frame's capsule) come from `AtlasTable.baked().native_size()`,
## not from `get_size()` on a loaded texture — the change `docs/TODO.md`'s M171 decoration item
## asks for by name. Built off the scene tree, one `Prop` at a time, in the order `City` itself
## builds one: `Prop.new()`, then the exports, then `add_child()` — which is what fires `_ready()`
## and computes `shape`.
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
		t.check(prop.shape() != null and is_equal_approx(prop.shape().radius, expected),
				"Prop.Kind %d's shadow radius is off the region table's own size (%.2f against %.2f)"
				% [kind, prop.shape().radius if prop.shape() else -1.0, expected])
		prop.free()

	var tree := Prop.new()
	tree.dress(null, Prop.Kind.TREE, 0, 1.3)
	t.add_child(tree)
	var tree_name := TreePictures.region(0)
	var expected_tree: float = float(AtlasTable.baked().native_size(tree_name).x) * 1.3 * 0.28
	t.check(tree.shape() != null and is_equal_approx(tree.shape().radius, expected_tree),
			"a tree's shadow radius follows scale_factor() off the region table's own size (%.2f against %.2f)"
			% [tree.shape().radius if tree.shape() else -1.0, expected_tree])
	tree.free()

	var frame := Prop.new()
	frame.dress(null, Prop.Kind.PLAYGROUND_FRAME)
	t.add_child(frame)
	var frame_size := Vector2(AtlasTable.baked().native_size(Prop.SWING_FRAME))
	var expected_radius := frame_size.y * 0.5
	var expected_half_length := frame_size.x * 0.5 - expected_radius
	t.check(frame.shape() != null and is_equal_approx(frame.shape().radius, expected_radius)
			and is_equal_approx(frame.shape().half_length, expected_half_length),
			"the swing frame's capsule is sized off the region table (radius %.2f, half-length %.2f)"
			% [frame.shape().radius if frame.shape() else -1.0,
					frame.shape().half_length if frame.shape() else -1.0])
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
		var reach := tree.shape().reach() if tree.shape() else INF
		t.check(reach <= TreePictures.widest_reach() + 0.001,
				"a street tree drawn as %s reaches %.2fpx, within the %.2fpx the planners keep clear"
				% [TreePictures.region(variant), reach, TreePictures.widest_reach()])
		widest = maxf(widest, reach)
		tree.free()
		# A street tree dressed with a park tree's scale is still grounded at its picture's own size.
		var scaled := Prop.new()
		scaled.dress(null, Prop.Kind.STREET_TREE, variant, 1.25)
		t.add_child(scaled)
		var scaled_reach := scaled.shape().reach() if scaled.shape() else INF
		t.check(is_equal_approx(scaled_reach, reach),
				"a street tree of %s dressed with a scale reaches the same (%.2f against %.2f)"
				% [TreePictures.region(variant), scaled_reach, reach])
		scaled.free()
	t.check(is_equal_approx(widest, TreePictures.widest_reach()),
			"and the widest street tree reaches exactly the planners' clearance (%.2f against %.2f)"
			% [widest, TreePictures.widest_reach()])

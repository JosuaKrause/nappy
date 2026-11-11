@warning_ignore_start("untyped_declaration")
extends RefCounted
## The "decoration" `AtlasLibrary` group — props, litter and city decals. `tests/test_atlas_library.gd`
## already covers the atlas contract every group shares (every member baked, no two regions
## overlap, geometry answered with nothing acquired, a page arriving and leaving with its
## references); this suite covers what is specific to this family: a prop's shadow reads its size
## from the region table rather than from a loaded texture, and `StreetTrees.footprint_radius()` plans
## clearance off the same table its planted trees are drawn from. The group's lifetime while a `City`
## stands (read once, released when the city is freed) is a fact about `City` and is
## `tests/test_city_atlas_holds.gd`'s.

func run(t: TestRunner) -> void:
	_test_shadow_sizes_read_the_region_table(t)
	_test_street_tree_footprint_matches_the_region_table(t)

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
	for case in point_cases:
		var kind: Prop.Kind = case[0]
		var region: StringName = case[1]
		var fraction: float = case[2]
		var prop := Prop.new()
		prop.kind = kind
		t.add_child(prop)
		var expected: float = float(AtlasTable.baked().native_size(region).x) * fraction
		t.check(prop.shape != null and is_equal_approx(prop.shape.radius, expected),
				"Prop.Kind %d's shadow radius is off the region table's own size (%.2f against %.2f)"
				% [kind, prop.shape.radius if prop.shape else -1.0, expected])
		prop.free()

	var tree := Prop.new()
	tree.kind = Prop.Kind.TREE
	tree.variant = 0
	tree.scale_factor = 1.3
	t.add_child(tree)
	var tree_name: StringName = Prop.TREES[0]
	var expected_tree: float = float(AtlasTable.baked().native_size(tree_name).x) * 1.3 * 0.28
	t.check(tree.shape != null and is_equal_approx(tree.shape.radius, expected_tree),
			"a tree's shadow radius follows scale_factor off the region table's own size (%.2f against %.2f)"
			% [tree.shape.radius if tree.shape else -1.0, expected_tree])
	tree.free()

	var frame := Prop.new()
	frame.kind = Prop.Kind.PLAYGROUND_FRAME
	t.add_child(frame)
	var frame_size := Vector2(AtlasTable.baked().native_size(Prop.SWING_FRAME))
	var expected_radius := frame_size.y * 0.5
	var expected_half_length := frame_size.x * 0.5 - expected_radius
	t.check(frame.shape != null and is_equal_approx(frame.shape.radius, expected_radius)
			and is_equal_approx(frame.shape.half_length, expected_half_length),
			"the swing frame's capsule is sized off the region table (radius %.2f, half-length %.2f)"
			% [frame.shape.radius if frame.shape else -1.0,
					frame.shape.half_length if frame.shape else -1.0])
	frame.free()

## `StreetTrees.footprint_radius()` (`src/city/street_trees.gd`) plans tree clearance for the
## closure and event planners off `AtlasTable.baked().native_size()` now, ahead of any `City` existing —
## the same table `Prop`'s own shadow reads, rather than a second source of the same number.
## `tests/test_atlas_library.gd`'s `_test_baked_pixels_are_todays_pictures` already establishes
## that `native_size()` is bit-identical to the SVG import this used to read (see the docstring on
## `footprint_radius()` itself), so this only pins the planner and the region table together.
func _test_street_tree_footprint_matches_the_region_table(t: TestRunner) -> void:
	var widest := 0.0
	for name: StringName in Prop.TREES:
		widest = maxf(widest, float(AtlasTable.baked().native_size(name).x) * 0.28)
	t.check(is_equal_approx(StreetTrees.footprint_radius(), widest),
			"StreetTrees.footprint_radius() (%.2f) is the widest street tree's region size times 0.28 (%.2f)"
			% [StreetTrees.footprint_radius(), widest])

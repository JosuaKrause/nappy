extends RefCounted
## The "decoration" `AtlasLibrary` group — props, litter and city decals — moved off individually
## preloaded textures and off the runtime packer `TextureAtlas`. `tests/test_atlas_library.gd`
## already covers the atlas contract every group shares (every member baked, no two regions
## overlap, geometry answered with nothing acquired, a page arriving and leaving with its
## references); this suite covers what is specific to this family: a prop's shadow reads its size
## from the region table rather than from a loaded texture, the "decoration" group has exactly one
## acquire while a `City` stands, and `City._exit_tree()`'s `release()` actually balances
## `build()`'s `acquire()`.
##
## `tests/test_blocks.gd`'s own street-tree footprint check already builds a real `City` off
## `CITY_SCENE` and frees it; the acquire/release checks here do the same rather than reaching for
## a lighter double, since the group's lifetime is a fact about `City` and not about `AtlasLibrary`
## on its own.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242

func run(t) -> void:
	_test_shadow_sizes_read_the_region_table(t)
	_test_the_city_is_the_groups_only_acquire(t)
	_test_the_group_is_released_when_the_city_is_freed(t)

## A prop's shadow radius (and the swing frame's capsule) come from `AtlasLibrary.native_size()`,
## not from `get_size()` on a loaded texture — the change `docs/TODO.md`'s M171 decoration item
## asks for by name. Built off the scene tree, one `Prop` at a time, in the order `City` itself
## builds one: `Prop.new()`, then the exports, then `add_child()` — which is what fires `_ready()`
## and computes `shape`.
func _test_shadow_sizes_read_the_region_table(t) -> void:
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
		var expected: float = float(AtlasLibrary.native_size(region).x) * fraction
		t.check(prop.shape != null and is_equal_approx(prop.shape.radius, expected),
				"Prop.Kind %d's shadow radius is off the region table's own size (%.2f against %.2f)"
				% [kind, prop.shape.radius if prop.shape else -1.0, expected])
		prop.free()

	var tree := Prop.new()
	tree.kind = Prop.Kind.TREE
	tree.variant = 0
	tree.scale_factor = 1.3
	t.add_child(tree)
	var tree_name := AtlasLibrary.region_name_for(Prop.TREES[0].resource_path)
	var expected_tree: float = float(AtlasLibrary.native_size(tree_name).x) * 1.3 * 0.28
	t.check(tree.shape != null and is_equal_approx(tree.shape.radius, expected_tree),
			"a tree's shadow radius follows scale_factor off the region table's own size (%.2f against %.2f)"
			% [tree.shape.radius if tree.shape else -1.0, expected_tree])
	tree.free()

	var frame := Prop.new()
	frame.kind = Prop.Kind.PLAYGROUND_FRAME
	t.add_child(frame)
	var frame_size := Vector2(AtlasLibrary.native_size(Prop.SWING_FRAME))
	var expected_radius := frame_size.y * 0.5
	var expected_half_length := frame_size.x * 0.5 - expected_radius
	t.check(frame.shape != null and is_equal_approx(frame.shape.radius, expected_radius)
			and is_equal_approx(frame.shape.half_length, expected_half_length),
			"the swing frame's capsule is sized off the region table (radius %.2f, half-length %.2f)"
			% [frame.shape.radius if frame.shape else -1.0,
					frame.shape.half_length if frame.shape else -1.0])
	frame.free()

## The "decoration" group has exactly one acquire while a `City` is alive — `City.build()`'s own —
## so nothing in `Prop` or `CityDecals` could ever be asked to draw a region before the group
## backing it exists: a second, independent acquire from either of them would read as a reference
## count of two rather than one, and a draw from an unacquired group would mean the city itself
## never actually acquired it, which the check below on `is_acquired()` after `build()` refuses.
##
## `AtlasLibrary.region()` on an unacquired group is deliberately not called here to provoke the
## failure directly — see `tests/test_atlas_library.gd`'s own note beside the same choice: the
## `push_error` it raises is a real engine error, and an engine error fails the whole run
## (`docs/DECISIONS.md`, M164), which would be a worse silence than the state checks below.
func _test_the_city_is_the_groups_only_acquire(t) -> void:
	AtlasLibrary.reset_for_tests()
	t.check(not AtlasLibrary.is_acquired(CityDecals.DECORATION_ATLAS),
			"nothing holds the decoration group before any city exists")
	var map := CityGenerator.generate(SEED)
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(map)
	t.check(AtlasLibrary.is_acquired(CityDecals.DECORATION_ATLAS),
			"City.build() acquires the decoration group")
	t.check(AtlasLibrary.reference_count(CityDecals.DECORATION_ATLAS) == 1,
			"build() is the group's only acquire (count %d)"
			% AtlasLibrary.reference_count(CityDecals.DECORATION_ATLAS))
	# A region a real draw depends on actually resolves while the city stands.
	var door := AtlasLibrary.region(City.DOOR_TEXTURE)
	t.check(door != null and door.get_size() == Vector2(AtlasLibrary.native_size(City.DOOR_TEXTURE)),
			"the door's region resolves to its own size while the city holds the group")
	city.free()
	AtlasLibrary.reset_for_tests()

## `City._exit_tree()` owes `build()`'s `acquire()` a matching `release()` — a city freed without
## one would leave the page counted, and resident, for a city that no longer exists.
func _test_the_group_is_released_when_the_city_is_freed(t) -> void:
	AtlasLibrary.reset_for_tests()
	var map := CityGenerator.generate(SEED)
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(map)
	t.check(AtlasLibrary.is_acquired(CityDecals.DECORATION_ATLAS),
			"the group is acquired while the city stands")
	city.free()
	t.check(not AtlasLibrary.is_acquired(CityDecals.DECORATION_ATLAS),
			"the group is released once the city that acquired it is freed")
	t.check(AtlasLibrary.reference_count(CityDecals.DECORATION_ATLAS) == 0,
			"and its reference count returns to nought (got %d)"
			% AtlasLibrary.reference_count(CityDecals.DECORATION_ATLAS))
	AtlasLibrary.reset_for_tests()

class_name TreePictures
extends RefCounted
## The pictures a tree is drawn as, and the ground its trunk takes for each: the one place that
## says both, so the prop that draws a tree (`Prop`) and the planner that keeps the day's events off
## a street tree's ground (`StreetTrees.footprint_tiles()`) read one answer rather than each working
## it out.
##
## **Data, with no scene.** Every answer is read off the baked region table
## (`AtlasTable.native_size()`), which answers with nothing acquired, so a headless planner asks it
## ahead of any `City` existing. The regions sit in the "decoration" atlas group, which the city
## holds on its library while it stands, so a prop drawing one always finds it.

## Region names of the trees, in the order a prop's variant picks them (`region()`).
const REGIONS: Array[StringName] = [&"props/tree_a", &"props/tree_b"]

## The fraction of a tree picture's own width its ground shape reaches from the trunk: the point
## the shadow is drawn from and the footprint an event is kept out of.
const _REACH_FRACTION := 0.28

## The picture a tree of `variant` is drawn as.
static func region(variant: int) -> StringName:
	return REGIONS[absi(variant) % REGIONS.size()]

## A tree's ground shape: a point reaching `_REACH_FRACTION` of its picture's width, drawn
## `scaled` times its picture's own size.
static func shape(variant: int, scaled: float) -> GroundShape:
	return _ground_of(drawn_size(variant, scaled))

## The size a tree of `variant` is drawn at when it is `scaled` times its picture's own size, in px:
## the one place that multiplies the two, which the prop's drawing and `shape()` both ask.
static func drawn_size(variant: int, scaled: float) -> Vector2:
	return Vector2(AtlasTable.baked().native_size(region(variant))) * scaled

## The size a street tree of `variant` is drawn at: its picture's own, the one place that says so,
## which `Prop` draws `Kind.STREET_TREE` at and `street_tree_shape()` grounds it by.
static func street_tree_size(variant: int) -> Vector2:
	return drawn_size(variant, 1.0)

## A street tree's ground shape, at `street_tree_size()`, which `Prop` takes for
## `Kind.STREET_TREE` and `widest_reach()` keeps clear.
static func street_tree_shape(variant: int) -> GroundShape:
	return _ground_of(street_tree_size(variant))

## The ground shape of a tree drawn `size` large: the one place that says how much of its width it
## reaches.
static func _ground_of(size: Vector2) -> GroundShape:
	return GroundShape.point(size.x * _REACH_FRACTION)

## The widest tree picture's width at its own size, in px: what a park tree's spacing is worked out
## from (`City._min_tree_spacing()`), at the largest scale a park tree is rolled.
static func widest_canopy() -> float:
	var widest := 0.0
	for variant in REGIONS.size():
		widest = maxf(widest, drawn_size(variant, 1.0).x)
	return widest

## How far the widest tree's ground shape reaches at its picture's own size, the size a street tree
## is drawn at, in px: which picture a pit gets is decided where its prop is built, so a planner
## keeps clear the widest. The planners' determinism rests on this number, and the region table's
## size is the source picture's own: `tests/test_atlas_library.gd`'s
## `_test_baked_pixels_are_todays_pictures` compares every baked region, the trees included, against
## the imported picture pixel for pixel, size included.
static func widest_reach() -> float:
	var widest := 0.0
	for variant in REGIONS.size():
		widest = maxf(widest, street_tree_shape(variant).reach())
	return widest

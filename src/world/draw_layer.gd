class_name DrawLayer
extends RefCounted
## **The one list of the order the world's pictures are drawn in**, shared by the city and the
## building, and the one place a `z_index` is written. A world hosts each layer it draws on as a
## node of its own (`WorldLayers`) and adds what it is handed through `add_entity(node, layer)`
## (`WorldContext`); whatever is not one of a world's own nodes — the halo, the debug view, a
## figure raised for its warning — asks for its layer here (`draw_on()`). Nothing else in `src/`
## writes a `z_index` or a `z_as_relative`; `tests/test_draw_layers.gd` reads the tree for one.
##
## **Within a layer, depth is the feet.** A layer that holds things standing on the ground is
## y-sorted, so each sorts at its own origin, its feet; a thing longer than a tile, whose ground
## runs away from the camera, cannot sort at one point, so it is drawn as slices standing at their
## own feet (`slice_feet()`, `add_slices()`), each sorting against her on its own.
##
## The layers, from the bottom:
## - `BACKDROP`: the building's stairwell walls, drawn behind its own floor.
## - `GROUND`: the ground, its decals, the buildings' shadows and anything lying flat on the floor,
##   at the engine's default `z_index` of 0, which a world's own ground nodes already draw at.
## - `BUILDINGS`: the city's buildings and the building's walls. Nothing can stand behind a
##   building, since no lot tile is walkable and its drawing stays in its lot, so nothing on the
##   ground sorts against one (docs/CITY.md, "Rendering").
## - `DOORS`: the building's doors and thresholds, always under her *(minty-lemur #789: "the escape
##   doors should be in a way that the graphics is always under her")*.
## - `GROUND_MARKS`: a mark on the ground she reads standing on it, the resistance's chalk, under
##   everything that stands there, her included.
## - `HALO`: the glow of what is charging the meter, a picture of the ground under everything
##   standing on it (`ExcitementHalo`).
## - `ENTITIES`: her, the crowd, every event and everything else that stands on the ground,
##   y-sorted.
## - `WARNING`: a figure whose warning must not be hidden while he gives it, drawn over the
##   street's other figures (the warning roadblock guard, `EventInstance`).
## - `OVERHEAD`: what is drawn over everything standing in the street, the dark inside the tunnel
##   that lands on a car as it drives in.
## - `DEBUG`: the debug view's overlays, over everything in the world, since a box drawn under what
##   it outlines cannot be read.

## The layers, in draw order: a layer later in the list is drawn over every earlier one.
enum Layer { BACKDROP, GROUND, BUILDINGS, DOORS, GROUND_MARKS, HALO, ENTITIES, WARNING, OVERHEAD,
		DEBUG }

## The `z_index` a layer draws at: its place in the list, counted from `GROUND` at 0. Every layer
## draws at an absolute z, never one relative to its parent, so a layer means the same depth
## wherever its node stands in the tree — under a world, or under `main` beside it.
##
## `layer` is an `int` rather than a `Layer` here and in every function below, because an enum
## named from another script does not match its own type as a parameter (the **godot** skill, "a
## cross-script enum is not the same type as itself").
static func z_of(layer: int) -> int:
	return layer - Layer.GROUND

## Draws `item` on `layer`, wherever it stands in the tree. Written only when it changes, so asking
## every frame costs no canvas update.
static func draw_on(item: CanvasItem, layer: int) -> void:
	var z := z_of(layer)
	if item.z_as_relative or item.z_index != z:
		item.z_as_relative = false
		item.z_index = z

## The layer `item` is drawn on: its own, or the nearest one above it in the tree that was set
## (`draw_on()`). `GROUND` for anything no layer was asked for, which draws at the default z.
static func layer_of(item: CanvasItem) -> int:
	var z := 0
	var node: Node = item
	while node is CanvasItem:
		var canvas_item := node as CanvasItem
		z += canvas_item.z_index
		if not canvas_item.z_as_relative:
			break
		node = node.get_parent()
	return clampi(z + Layer.GROUND, Layer.BACKDROP, Layer.DEBUG)

## Makes `node` a world's node for `layer` (`WorldLayers`): drawn on the layer, and y-sorted when
## what it holds stands on the ground and sorts at its feet.
static func adopt(node: Node2D, layer: int, y_sorted := false) -> void:
	draw_on(node, layer)
	node.y_sort_enabled = y_sorted

# ------------------------------------------------------------------- slices ---

## Where slice `index` of `count` equal slices of a run from `from` to `to` stands its feet, on the
## run's own axis.
##
## **Broadside, at the middle of its slice; end-on, at the near end of it.** A picture stands up
## from its feet (`Sprites.draw_standing()`). Broadside the run lies across the picture, so the
## middle centres a slice on its ground. End-on the run goes up the picture: a slice drawn its own
## length tall with its feet at its middle would stand half a slice up the screen from its ground,
## and the whole column with it, overhanging the far end and falling short of the near end where
## she walks up to it. With the feet at the near end each slice covers its own ground, and the run
## covers exactly the ground its body closes.
static func slice_along(from: float, to: float, count: int, index: int, end_on: bool) -> float:
	return from + (to - from) / count * (index + (1.0 if end_on else 0.5))

## The feet of `count` equal slices of the run from `from` to `to` on the ground, in draw order: the
## far end first. A run that goes down the screen more than across it is end-on, and its feet stand
## at each slice's near end (`slice_along()`); **the last is the near end itself, exactly**, so a
## piece standing at that end (a fence's post) shares its feet with the slice and sorts by the order
## the two were added, not by a fraction of a pixel two sums of the same length disagree by.
static func slice_feet(from: Vector2, to: Vector2, count: int) -> PackedVector2Array:
	var far := from
	var near := to
	if far.y > near.y:
		far = to
		near = from
	var end_on := absf(near.y - far.y) > absf(near.x - far.x)
	var feet := PackedVector2Array()
	for i in count:
		if end_on and i == count - 1:
			feet.append(near)
		else:
			feet.append(Vector2(slice_along(far.x, near.x, count, i, end_on),
					slice_along(far.y, near.y, count, i, end_on)))
	return feet

## The run a long footprint covers on the ground with its origin at `at`: the two ends of its
## longest piece along its length, far end first (`Footprint.Piece.span()`). Empty for a footprint
## with no piece.
static func run_of(footprint: Footprint, at: Vector2) -> PackedVector2Array:
	var longest: Footprint.Piece = null
	for piece in footprint.pieces:
		if longest == null or piece.half_length() > longest.half_length():
			longest = piece
	if longest == null:
		return PackedVector2Array()
	return longest.span(at)

## **Adds a long footprint's slices to `world`**: each node in `slices` stands at its own feet
## (`feet`, index for index, as `slice_feet()` gives them) on `layer`, so each sorts against
## whatever stands beside it on its own. With `before`, a node already on the layer, each slice is
## placed ahead of it in the tree, so at a tie of feet `before` draws over the slices: an event
## whose caret must stay on top of its own picture.
static func add_slices(world: WorldContext, slices: Array[Node2D], feet: PackedVector2Array,
		layer: int = Layer.ENTITIES, before: Node = null) -> void:
	for i in slices.size():
		var slice := slices[i]
		slice.position = feet[i]
		world.add_entity(slice, layer)
		_put_ahead_of(slice, before)

## The same, beside `before` in its own parent rather than in a world: a figure stood by a test rig
## under a bare node, with no world handed to it.
static func add_slices_beside(before: Node2D, slices: Array[Node2D],
		feet: PackedVector2Array) -> void:
	var parent := before.get_parent()
	for i in slices.size():
		var slice := slices[i]
		slice.position = feet[i]
		parent.add_child(slice)
		_put_ahead_of(slice, before)

static func _put_ahead_of(slice: Node, before: Node) -> void:
	if before == null or slice.get_parent() != before.get_parent():
		return
	slice.get_parent().move_child(slice, before.get_index())

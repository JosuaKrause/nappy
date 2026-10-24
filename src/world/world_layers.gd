class_name WorldLayers
extends RefCounted
## **The nodes one world draws its layers in** (`DrawLayer.Layer`), so adding a node to a world on a
## layer is one call however the world is built (`WorldContext.add_entity()`). A world hands over
## the nodes its scene already holds for a layer (`hold()`); any other layer gets a node of its own
## the first time something is added to it, under the world, drawn on that layer, and y-sorted if it
## is `ENTITIES`, where everything sorts at its feet.

var _world: Node2D
## The node for each layer, by `DrawLayer.Layer`.
var _nodes := {}

func _init(world: Node2D) -> void:
	_world = world

## Makes `node`, one of the world's own children or a new one added under it here, the world's node
## for `layer` (`layer` an `int` for the reason `DrawLayer.z_of()` gives).
func hold(layer: int, node: Node2D, y_sorted := false) -> Node2D:
	DrawLayer.adopt(node, layer, y_sorted)
	if node.get_parent() == null:
		_world.add_child(node)
	_nodes[layer] = node
	return node

## The world's node for `layer`, made the first time it is asked for.
func node(layer: int) -> Node2D:
	var found: Node2D = _nodes.get(layer)
	if found != null:
		return found
	var made := Node2D.new()
	made.name = String(DrawLayer.Layer.keys()[layer]).to_pascal_case() + "Layer"
	return hold(layer, made, layer == DrawLayer.Layer.ENTITIES)

## Every node the world has for a layer so far.
func nodes() -> Array[Node2D]:
	var found: Array[Node2D] = []
	for layer: int in _nodes:
		found.append(_nodes[layer])
	return found

## Whether the world has a node for `layer` yet.
func has(layer: int) -> bool:
	return _nodes.has(layer)

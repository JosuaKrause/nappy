class_name Prop
extends Node2D
## Small scenery. Feet-anchored like everything else, so it y-sorts against the player:
## she passes behind a tree's canopy and in front of its trunk.

enum Kind { TREE, PLAYGROUND_FRAME, BOLLARD }

const TREES: Array[Texture2D] = [
	preload("res://assets/props/tree_a.svg"),
	preload("res://assets/props/tree_b.svg"),
]
const SWING_FRAME := preload("res://assets/props/swing_frame.svg")
const BOLLARD := preload("res://assets/props/bollard.svg")

@export var kind := Kind.TREE
## Deterministic per-prop variation, so a park does not shimmer between frames.
@export var variant := 0
@export var scale_factor := 1.0

func _draw() -> void:
	match kind:
		Kind.TREE:
			_draw_tree()
		Kind.PLAYGROUND_FRAME:
			_playground_frame_shape().draw_shadow(self, Vector2.ZERO)
			Sprites.draw_standing(self, SWING_FRAME, Vector2.ZERO)
		Kind.BOLLARD:
			var size := BOLLARD.get_size()
			Sprites.draw_shadow(self, Vector2.ZERO, size.x * 0.4)
			Sprites.draw_standing(self, BOLLARD, Vector2.ZERO)

## The swing frame's own shadow shape — a capsule along its width, read off its own texture the
## same way `CrowdAgent`'s car reads its two: `radius` from the frame's depth (its texture height),
## `half_length` from what is left of half its width once the rounded ends are accounted for.
static func _playground_frame_shape() -> GroundShape:
	var size := SWING_FRAME.get_size()
	var radius := size.y * 0.5
	return GroundShape.segment(size.x * 0.5 - radius, radius)

## Two tree shapes and a mirror, so ten trees in a park are not one silhouette repeated.
func _draw_tree() -> void:
	var texture: Texture2D = TREES[absi(variant) % TREES.size()]
	var size := texture.get_size() * scale_factor
	Sprites.draw_shadow(self, Vector2.ZERO, size.x * 0.28)
	Sprites.draw_standing(self, texture, Vector2.ZERO, size, absi(variant) % 4 < 2)

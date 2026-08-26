class_name Prop
extends Node2D
## Small procedurally drawn scenery. Feet-anchored like everything else, so it y-sorts
## against the player: she passes behind a tree's canopy and in front of its trunk.

enum Kind { TREE, PLAYGROUND_FRAME }

@export var kind := Kind.TREE
## Deterministic per-prop variation, so a park does not shimmer between frames.
@export var variant := 0
@export var scale_factor := 1.0

func _draw() -> void:
	match kind:
		Kind.TREE:
			_draw_tree()
		Kind.PLAYGROUND_FRAME:
			_draw_playground_frame()

func _draw_shadow(radius: float) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, radius, Palette.SHADOW)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_tree() -> void:
	var lean := float((variant * 37) % 7 - 3) * 0.6
	var canopy := 15.0 * scale_factor
	var trunk_height := 15.0 * scale_factor

	_draw_shadow(canopy * 0.75)
	draw_line(Vector2.ZERO, Vector2(lean, -trunk_height), Palette.TREE_TRUNK, 4.5 * scale_factor)
	var crown := Vector2(lean, -trunk_height - canopy * 0.6)
	draw_circle(crown, canopy, Palette.TREE_CANOPY)
	draw_circle(crown + Vector2(-canopy * 0.3, -canopy * 0.3), canopy * 0.55, Palette.TREE_HIGHLIGHT)

func _draw_playground_frame() -> void:
	# A swing frame: two A-legs and a crossbar.
	var width := 34.0
	var height := 30.0
	_draw_shadow(width * 0.55)
	for side in [-1.0, 1.0]:
		var foot := Vector2(side * width * 0.5, 0.0)
		draw_line(foot, Vector2(side * 6.0, -height), Palette.PLAYGROUND_FRAME, 3.0)
		draw_line(foot + Vector2(side * -10.0, 0.0), Vector2(side * 6.0, -height),
				Palette.PLAYGROUND_FRAME, 3.0)
	draw_line(Vector2(-6.0, -height), Vector2(6.0, -height), Palette.PLAYGROUND_FRAME, 3.0)
	for x in [-3.0, 3.0]:
		draw_line(Vector2(x, -height), Vector2(x, -height * 0.45), Palette.OUTLINE, 1.5)

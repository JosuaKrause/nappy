class_name DebugNoiseSource
extends Node2D
## A stand-in for M4's EventInstance: a fixed point that emits excitement with the falloff
## from docs/MECHANICS.md, drawn so the danger geometry is visible while tuning.

@export var intensity := 8.0
@export var inner_radius := 40.0
@export var outer_radius := 150.0
@export var label := "noise"

func contribution_at(world_position: Vector2) -> float:
	var distance := global_position.distance_to(world_position)
	return Tuning.falloff(distance, intensity, inner_radius, outer_radius)

func _draw() -> void:
	draw_circle(Vector2.ZERO, outer_radius, Color(0.9, 0.35, 0.25, 0.06))
	draw_arc(Vector2.ZERO, outer_radius, 0.0, TAU, 48, Color(0.9, 0.35, 0.25, 0.35), 1.5)
	draw_circle(Vector2.ZERO, inner_radius, Color(0.9, 0.35, 0.25, 0.14))
	draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, 32, Color(0.9, 0.35, 0.25, 0.5), 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(-18.0, 4.0), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.7))

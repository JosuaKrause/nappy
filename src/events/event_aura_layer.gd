class_name EventAuraLayer
extends Node2D
## Draws the excitement field of every active event.
##
## Separate from the instances themselves because the fields belong *under* the buildings
## and props: an aura painted over a roof would read as something floating above the city.
## This node sits between the ground and the y-sorted entity layer.

## The field is the player's only warning, so it has to read at a glance from across a
## street. A first pass at a fifth of these values was invisible in play.
const _INNER_ALPHA := 0.30
const _OUTER_ALPHA := 0.11
const _RING_ALPHA := 0.85
const _RING_WIDTH := 3.0
## A second ring at the inner radius, where the event stops fading and simply hurts.
const _INNER_RING_ALPHA := 0.55

var _instances: Array[EventInstance] = []

func track(instances: Array[EventInstance]) -> void:
	_instances = instances

func _process(_delta: float) -> void:
	# Auras pulse and move with their events, so this is one of the few things that has to
	# redraw every frame. It is a handful of circles.
	queue_redraw()

func _draw() -> void:
	for instance in _instances:
		if instance.is_finished:
			continue
		_draw_field(instance)

func _draw_field(instance: EventInstance) -> void:
	var at := to_local(instance.global_position)
	var telegraphing := instance.is_telegraphing()
	var colour := Palette.AURA_LETHAL if instance.def.hard_fail else (
			Palette.AURA_TELEGRAPH if telegraphing else Palette.AURA_ACTIVE)

	# Strength tracks what the event is actually emitting, so a pulsing event visibly
	# breathes and the player can time a pass through it.
	var strength := 1.0
	if instance.def.intensity > 0.0:
		strength = clampf(instance.current_intensity() / instance.def.intensity, 0.0, 1.0)
	if telegraphing:
		# Damped emission would make the warning almost invisible, which defeats it.
		strength = 0.55 + 0.45 * sin(instance.age * 7.0)

	draw_circle(at, instance.def.outer_radius, _with_alpha(colour, _OUTER_ALPHA * strength))
	draw_circle(at, instance.def.inner_radius, _with_alpha(colour, _INNER_ALPHA * strength))
	draw_arc(at, instance.def.outer_radius, 0.0, TAU, 64,
			_with_alpha(colour, _RING_ALPHA * strength), _RING_WIDTH)
	draw_arc(at, instance.def.inner_radius, 0.0, TAU, 48,
			_with_alpha(colour, _INNER_RING_ALPHA * strength), _RING_WIDTH * 0.7)

func _with_alpha(colour: Color, alpha: float) -> Color:
	return Color(colour.r, colour.g, colour.b, alpha)

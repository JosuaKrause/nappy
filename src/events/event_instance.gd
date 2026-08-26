class_name EventInstance
extends Node2D
## One live event in the world: its lifetime, its telegraph phase, its excitement field and
## its drawing.
##
## The excitement model is entirely a *query* — `contribution_at()`. Nothing pushes a value
## at the baby, so there is no ordering to get wrong, events compose by simple addition, and
## the whole thing is testable without a scene.

signal finished(instance: EventInstance)

var def: EventDef
## Waypoints for a mobile event, in world space. Empty for a stationary one.
var path: PackedVector2Array = PackedVector2Array()

var age := 0.0
var is_finished := false

var _path_travelled := 0.0
var _telegraph_announced := false
var _activation_announced := false

func setup(definition: EventDef, at: Vector2, route: PackedVector2Array = PackedVector2Array()) -> void:
	def = definition
	path = route
	position = route[0] if route.size() > 0 else at

func _ready() -> void:
	EventBus.event_telegraphed.emit(self)
	_telegraph_announced = true
	if def.obstructs_radius > 0.0:
		_build_obstruction()

## Some events are physically in the way. The body is a child so it travels with a mobile
## event and disappears with the instance.
func _build_obstruction() -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = def.obstructs_radius
	shape.shape = circle
	body.add_child(shape)
	add_child(body)

func _process(delta: float) -> void:
	if is_finished:
		return
	age += delta

	if not _activation_announced and not is_telegraphing():
		_activation_announced = true
		EventBus.event_activated.emit(self)

	if def.mobile and path.size() > 1:
		_advance_along_path(delta)

	if _has_expired():
		_finish()
	queue_redraw()

func _advance_along_path(delta: float) -> void:
	# Movement starts when the telegraph does, so an approaching siren is audible and
	# visible while it is still far away — which is what makes the warning usable.
	_path_travelled += def.speed * delta
	var remaining := _path_travelled
	for i in range(1, path.size()):
		var segment := path[i] - path[i - 1]
		var length := segment.length()
		if remaining <= length:
			position = path[i - 1] + segment.normalized() * remaining
			return
		remaining -= length
	position = path[path.size() - 1]
	# A mobile event that has driven off the end of its route is done, whatever its
	# nominal duration says.
	_finish()

func _has_expired() -> bool:
	return def.duration > 0.0 and age >= def.telegraph_time + def.duration

func _finish() -> void:
	if is_finished:
		return
	is_finished = true
	EventBus.event_finished.emit(self)
	finished.emit(self)

# ------------------------------------------------------------------ emission ---

## True while the event is visible but has not yet reached full strength.
func is_telegraphing() -> bool:
	return age < def.telegraph_time

## Current peak intensity at the centre, after the telegraph damping and the pulse envelope.
func current_intensity() -> float:
	if is_finished:
		return 0.0
	var value := def.intensity
	if def.pulse_period > 0.0:
		# 0.25..1.0, so a pulsing event is never entirely silent between beats.
		var phase := TAU * age / def.pulse_period
		value *= 0.25 + 0.75 * (0.5 - 0.5 * cos(phase))
	if is_telegraphing():
		value *= Tuning.TELEGRAPH_INTENSITY_FRACTION
	return value

## Excitement per second this event contributes at a point.
func contribution_at(world_position: Vector2) -> float:
	if is_finished:
		return 0.0
	return Tuning.falloff(global_position.distance_to(world_position),
			current_intensity(), def.inner_radius, def.outer_radius)

## True when a point is inside the radius that ends the day, for a hard-fail event that is
## no longer merely telegraphing.
func is_lethal_at(world_position: Vector2) -> bool:
	if is_finished or not def.hard_fail or is_telegraphing():
		return false
	return global_position.distance_to(world_position) <= def.inner_radius

# ------------------------------------------------------------------ drawing ---

func _draw() -> void:
	if is_finished:
		return
	_draw_body()

func _draw_body() -> void:
	match def.look:
		EventDef.Look.FIRE:
			_draw_fire()
		EventDef.Look.ANIMAL:
			_draw_animal()
		EventDef.Look.PERSON:
			_draw_person()
		EventDef.Look.VEHICLE:
			_draw_vehicle()
		EventDef.Look.OBJECT:
			_draw_object()
		EventDef.Look.NONE:
			pass

func _draw_shadow(radius: float) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, radius, Palette.SHADOW)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_animal() -> void:
	_draw_shadow(7.0)
	# Crouched while telegraphing, stretched out once it bolts.
	var stretch := 1.0 if is_telegraphing() else 1.6
	draw_rect(Rect2(-8.0 * stretch, -9.0, 16.0 * stretch, 7.0), Palette.CAT_FUR)
	draw_circle(Vector2(-8.0 * stretch, -11.0), 4.5, Palette.CAT_FUR)
	draw_line(Vector2(8.0 * stretch, -9.0), Vector2(12.0 * stretch, -16.0), Palette.CAT_FUR, 2.5)

func _draw_person() -> void:
	_draw_shadow(8.0)
	draw_line(Vector2(-3.0, -13.0), Vector2(-3.0, 0.0), Palette.TROUSERS, 4.0)
	draw_line(Vector2(3.0, -13.0), Vector2(3.0, 0.0), Palette.TROUSERS, 4.0)
	draw_rect(Rect2(-7.0, -30.0, 14.0, 18.0), Palette.NPC_COAT)
	draw_circle(Vector2(0.0, -35.0), 6.0, Palette.SKIN)

func _draw_vehicle() -> void:
	_draw_shadow(20.0)
	draw_rect(Rect2(-22.0, -26.0, 44.0, 24.0), Palette.NPC_COAT)
	draw_rect(Rect2(-22.0, -12.0, 44.0, 4.0), Palette.OUTLINE)
	draw_circle(Vector2(-14.0, -3.0), 4.5, Palette.PRAM_WHEEL)
	draw_circle(Vector2(14.0, -3.0), 4.5, Palette.PRAM_WHEEL)

## Flames scaled by what the event is currently emitting, so a fire visibly roars.
func _draw_fire() -> void:
	var strength := 1.0
	if def.intensity > 0.0:
		strength = clampf(current_intensity() / def.intensity, 0.2, 1.0)
	_draw_shadow(22.0)
	for i in 5:
		var offset := (i - 2.0) * 11.0
		var flicker := 1.0 + 0.25 * sin(age * 9.0 + i * 1.7)
		var height := (34.0 + i % 2 * 14.0) * strength * flicker
		draw_colored_polygon(PackedVector2Array([
			Vector2(offset - 9.0, 0.0),
			Vector2(offset + 9.0, 0.0),
			Vector2(offset, -height),
		]), Palette.FIRE_OUTER)
		draw_colored_polygon(PackedVector2Array([
			Vector2(offset - 4.5, 0.0),
			Vector2(offset + 4.5, 0.0),
			Vector2(offset, -height * 0.6),
		]), Palette.FIRE_INNER)

func _draw_object() -> void:
	_draw_shadow(10.0)
	var half := maxf(11.0, def.obstructs_radius)
	draw_rect(Rect2(-half, -20.0, half * 2.0, 20.0), Palette.NPC_COAT)
	draw_rect(Rect2(-half, -20.0, half * 2.0, 20.0), Palette.OUTLINE, false, 1.5)

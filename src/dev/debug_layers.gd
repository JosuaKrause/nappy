class_name DebugLayers
extends Node2D
## Three world-space overlays over the live game state — fields, shadows and bounding boxes — each
## toggleable by its own number key. See docs/TODO.md, M104, "the debug view".
##
## **Drawn from queries of the live objects, never a change to their own drawing.** The excitement
## halo already has this shape — a duplicate drawing over the source, see `ExcitementHalo` and
## `EntityHalo` — and this node goes the other way: outlines rather than glows, geometry rather
## than a picture. `EventInstance`, `CrowdAgent`, `Building`, `Prop` and `Stroller` are read, never
## written, and the handful of private fields this needed (a flock's own bird offsets, a car's
## travel axis, a jolt's own radii, `City`'s building and prop lists) each got the smallest
## read-only getter rather than a second copy of the geometry kept here.
##
## **One node, three booleans, not three nodes.** Godot skips `_draw()` on an invisible `CanvasItem`
## entirely, so a plain `visible` flag per section already buys "no work happens while a layer is
## off" without a second node per layer to manage — `main.gd` owns the fourth layer (the developer
## readout) on its own pre-existing `CanvasLayer`, which is not a `CanvasItem` this class could
## parent anyway.
##
## **Every field is the real level set**, not a circle standing in for it —
## `GroundShape.field_outline()` and `field_outline_at()`, the same effective-distance arithmetic
## `Tuning.falloff()` prices, so this layer cannot disagree with what the meter does: a capsule
## about a stationary body's own spine, an ellipse (the emitter at one focus) about a moving one.
## `_draw_fields()` is where the shape-per-emitter decision is made.

## The falloff's own outline colour for a merely costly field — `Palette.MARK_COSTLY`, the same
## amber the caret already uses for "worth going round", so this view speaks the vocabulary the
## game already has rather than inventing a third pair of danger colours.
const FIELD_COSTLY := Palette.MARK_COSTLY
## And the same deep red `Palette.MARK_LETHAL` for a `hard_fail` event's field and a car's strike
## box — "lethal != noise ... lethal is when you get hit by a car" (the player, 2026-09-10): a
## car's ordinary noise field is never this colour, only the box that can end the day.
const FIELD_LETHAL := Palette.MARK_LETHAL
## Debug-only: neither colour is used anywhere else, so a shadow outline cannot be mistaken for a
## danger cue.
const SHADOW_COLOUR := Color(0.32, 0.78, 0.95, 0.85)
const BODY_COLOUR := Color(0.55, 1.0, 0.55, 0.9)

const LINE_WIDTH := 1.5
const _CIRCLE_SEGMENTS := 40

var fields_on := false
var shadows_on := false
var bodies_on := false

var _events: EventManager
var _crowd: Crowd
var _city: City
var _player: Stroller

func setup(events: EventManager, crowd: Crowd, city: City, player: Stroller) -> void:
	_events = events
	_crowd = crowd
	_city = city
	_player = player

## Sets which layers start on — `1` fields, `2` shadows, `3` bounding boxes — from
## `DevFlags.layers_override()`. Pulled out from `main._add_debug_layers()` so a test can drive it
## directly without a real command line to read: see `DevFlags.parse_layers()` for the same split.
func apply_initial_state(indices: Array[int]) -> void:
	fields_on = 1 in indices
	shadows_on = 2 in indices
	bodies_on = 3 in indices

## `1` fields, `2` shadows, `3` bounding boxes — a number key's own numbering once `main.gd`
## wires one to each; `4` (the readout) lives on its own pre-existing layer and never reaches here.
func set_layer(index: int, on: bool) -> void:
	match index:
		1: fields_on = on
		2: shadows_on = on
		3: bodies_on = on

func layer_on(index: int) -> bool:
	match index:
		1: return fields_on
		2: return shadows_on
		3: return bodies_on
		_: return false

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not _events or not _crowd or not _player:
		return
	if fields_on:
		_draw_fields()
	if shadows_on:
		_draw_shadows()
	if bodies_on:
		_draw_bodies()

# ------------------------------------------------------------------ fields ---

## Every emitter's actual falloff boundary — `GroundShape.field_outline()`, the same effective-
## distance arithmetic `Tuning.falloff()` prices, so this layer cannot disagree with what the
## meter does: a capsule about a stationary body's own spine, an ellipse (focus at the emitter)
## about a moving one, and a plain circle at zero speed, exactly as it always drew. **Skips
## `city_wide`** — it has no position to stand a boundary on, the same exemption
## `ExcitementHalo.select_sources()` already makes. A flock draws one pair per bird, at its own
## position and its own `heading * speed`, and `flock_outer_radius()` rather than `outer_radius` —
## the same radius `_flock_contribution_at()` sums over, so drawing the flat number instead would
## show a field wider than what the birds actually emit.
func _draw_fields() -> void:
	for instance in _events.instances():
		if instance.is_finished or instance.def.city_wide:
			continue
		var colour := FIELD_LETHAL if instance.def.hard_fail else FIELD_COSTLY
		var offsets := instance.flock_offsets()
		if offsets.is_empty():
			var axis := instance.solid_axis()
			var velocity := instance.travel_velocity()
			_draw_field_boundary(instance.def.shape, instance.global_position, axis, velocity,
					instance.def.inner_radius, colour)
			_draw_field_boundary(instance.def.shape, instance.global_position, axis, velocity,
					instance.def.outer_radius, colour)
			continue
		var outer := instance.flock_outer_radius()
		var velocities := instance.flock_velocities()
		for i in offsets.size():
			var at := instance.global_position + offsets[i]
			_draw_field_boundary(null, at, Vector2.RIGHT, velocities[i], instance.def.inner_radius,
					colour)
			_draw_field_boundary(null, at, Vector2.RIGHT, velocities[i], outer, colour)
	for agent in _crowd.agents():
		var is_car := agent.kind == CrowdAgent.Kind.CAR
		var inner := Tuning.CAR_INNER_RADIUS if is_car else Tuning.PEDESTRIAN_INNER_RADIUS
		var outer := Tuning.CAR_OUTER_RADIUS if is_car else Tuning.PEDESTRIAN_OUTER_RADIUS
		# Noise, never lethal — a car's strike box is drawn in the bounding-box layer instead, in
		# the same lethal colour, because being hit is a body question and this is a field one. A
		# crowd body is always a point in field terms (see `CrowdAgent.contribution_at()`'s own
		# doc), so `shape` is null here whatever the agent's own shadow shape says.
		var velocity := agent.velocity()
		_draw_field_boundary(null, agent.global_position, Vector2.RIGHT, velocity, inner, FIELD_COSTLY)
		_draw_field_boundary(null, agent.global_position, Vector2.RIGHT, velocity, outer, FIELD_COSTLY)
		if agent.is_startled():
			var jolt := agent.jolt_radii()
			_draw_field_boundary(null, agent.global_position, Vector2.RIGHT, velocity, jolt.x,
					FIELD_COSTLY)
			_draw_field_boundary(null, agent.global_position, Vector2.RIGHT, velocity, jolt.y,
					FIELD_COSTLY)

## One level of one field's boundary — `shape.field_outline()` when there is a shape to offset,
## `GroundShape.field_outline_at()`'s plain-point form otherwise (a crowd agent or one bird of a
## flock, neither of which owns a body in field terms).
func _draw_field_boundary(shape: GroundShape, at: Vector2, axis: Vector2, velocity: Vector2,
		level: float, colour: Color) -> void:
	var points := shape.field_outline(at, axis, velocity, level) if shape != null \
			else GroundShape.field_outline_at(at, velocity, level)
	_draw_closed_polyline(points, colour)

# ----------------------------------------------------------------- shadows ---

## The ground extent every `GroundShape` shadow is drawn over today — events, crowd agents, props,
## her and the pram. **Buildings draw no shadow** (`Building.shape`'s own doc: "Buildings draw no
## shadow, so this is read for its body alone today"), so none is drawn here for one either; its
## `shape` still appears in the bounding-box layer below.
func _draw_shadows() -> void:
	for instance in _events.instances():
		if instance.is_finished:
			continue
		_draw_shadow_outline(instance.def.shape, instance.global_position, instance.solid_axis())
	for agent in _crowd.agents():
		var axis := agent.travel_axis() if agent.kind == CrowdAgent.Kind.CAR else Vector2.RIGHT
		_draw_shadow_outline(agent.shape, agent.global_position, axis)
	for prop in _city.props():
		if prop is Prop:
			_draw_shadow_outline((prop as Prop).shape, prop.global_position, Vector2.RIGHT)
	_draw_shadow_outline(_player.shape, _player.global_position, Vector2.RIGHT)
	_draw_shadow_outline(_player.pram_shape, _pram_position(), Vector2.RIGHT)

func _draw_shadow_outline(shape: GroundShape, at: Vector2, axis: Vector2) -> void:
	_draw_closed_polyline(shape.shadow_outline(at, axis), SHADOW_COLOUR)

## `Stroller._draw()`'s own `pram_offset` formula, read here rather than duplicated as a private
## field: `facing`, `PRAM_DISTANCE` and `OBLIQUE_Y` are already public on `Stroller`, so this is the
## same one line `_draw()` computes rather than a second copy of it kept as state.
func _pram_position() -> Vector2:
	return _player.global_position + Vector2(
			_player.facing.x, _player.facing.y * Stroller.OBLIQUE_Y) * Stroller.PRAM_DISTANCE

# ------------------------------------------------------------- bounding boxes ---

## Every collision body's own outline — an event's obstruction, a building's footprint, her own
## circle — plus a moving car's strike box, drawn in the field layer's own lethal colour because it
## is not a body (`CrowdAgent._car_shadow_shape()`'s own doc: "no body for a car") but is exactly
## what `will_be_lethal()` tests against. **Walkers and cars have no body; nothing is invented for
## them.** The pram has no collision of its own either, and draws nothing here.
func _draw_bodies() -> void:
	for instance in _events.instances():
		if not instance.is_solid():
			continue
		var shape := instance.def.shape
		var axis := instance.solid_axis() if shape.half_length > 0.0 else Vector2.RIGHT
		_draw_shape_outline(shape, instance.global_position, axis, BODY_COLOUR)
	for building in _city.buildings():
		# The lot's own centre, not the building's south-edge origin — `Building._rebuild()`'s own
		# `_collision.position`, restated here so the outline and the real body cannot disagree.
		var offset := Vector2(0.0, -building.shape.half_extents.y)
		_draw_shape_outline(building.shape, building.global_position + offset, Vector2.RIGHT,
				BODY_COLOUR)
	draw_arc(_player.global_position, Tuning.PLAYER_BODY_RADIUS, 0.0, TAU, _CIRCLE_SEGMENTS,
			BODY_COLOUR, LINE_WIDTH, true)
	for agent in _crowd.agents():
		if agent.kind != CrowdAgent.Kind.CAR or agent.speed() < Tuning.CAR_STRIKE_MIN_SPEED:
			continue
		_draw_closed_polyline(_rect_corners(agent.global_position, agent.heading(),
				Vector2(Tuning.CAR_STRIKE_HALF_LENGTH, Tuning.CAR_STRIKE_HALF_WIDTH)), FIELD_LETHAL)

func _draw_shape_outline(shape: GroundShape, at: Vector2, axis: Vector2, colour: Color) -> void:
	match shape.kind:
		GroundShape.Kind.POINT:
			draw_arc(at, shape.radius, 0.0, TAU, _CIRCLE_SEGMENTS, colour, LINE_WIDTH, true)
		GroundShape.Kind.RECT:
			_draw_closed_polyline(_rect_corners(at, axis, shape.half_extents), colour)
		_:
			_draw_closed_polyline(_capsule_outline(at, axis, shape.half_length, shape.radius),
					colour)

# ------------------------------------------------------------------ geometry ---
# Unsquashed — a bounding body and a field are both stated in the plain 2D plane the physics and
# `Tuning.falloff()` already use; only a shadow (`GroundShape.shadow_outline()`) carries the
# oblique view's own foreshortening.

func _rect_corners(at: Vector2, axis: Vector2, half_extents: Vector2) -> PackedVector2Array:
	var along := axis.normalized()
	var across := Vector2(-along.y, along.x)
	var corners: Array[Vector2] = [
		Vector2(-half_extents.x, -half_extents.y), Vector2(half_extents.x, -half_extents.y),
		Vector2(half_extents.x, half_extents.y), Vector2(-half_extents.x, half_extents.y),
	]
	var points := PackedVector2Array()
	for corner in corners:
		points.append(at + along * corner.x + across * corner.y)
	return points

## A stadium: a half-turn of arc at each end of the spine, joined by the two straight sides the
## polyline draws between them on its own. Wound the same direction both halves, so the second
## cap's start meets the first cap's end and the loop closes on the *other* straight side too.
func _capsule_outline(at: Vector2, axis: Vector2, half_length: float, radius: float
		) -> PackedVector2Array:
	var along := axis.normalized()
	var base := along.angle()
	var lead := at + along * half_length
	var trail := at - along * half_length
	var segments := _CIRCLE_SEGMENTS / 2
	var points := PackedVector2Array()
	for i in segments + 1:
		var a := base - PI * 0.5 + PI * float(i) / float(segments)
		points.append(lead + Vector2(cos(a), sin(a)) * radius)
	for i in segments + 1:
		var a := base + PI * 0.5 + PI * float(i) / float(segments)
		points.append(trail + Vector2(cos(a), sin(a)) * radius)
	return points

func _draw_closed_polyline(points: PackedVector2Array, colour: Color) -> void:
	if points.size() < 2:
		return
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, colour, LINE_WIDTH, true)

class_name EventInstance
extends Node2D
## One live event in the world: its lifetime, its telegraph phase, its excitement field and
## its drawing.
##
## The excitement model is entirely a *query* — `contribution_at()`. Nothing pushes a value
## at the baby, so there is no ordering to get wrong, events compose by simple addition, and
## the whole thing is testable without a scene.

signal finished(instance: EventInstance)

const CAT_CROUCHED := preload("res://assets/events/cat_crouched.svg")
const CAT_RUNNING := preload("res://assets/events/cat_running.svg")
const PERSON := preload("res://assets/events/person.svg")
const VEHICLE := preload("res://assets/events/vehicle.svg")
const FLAME := preload("res://assets/events/flame.svg")
const BARRIER_SEGMENT := preload("res://assets/events/barrier_segment.svg")
const BARRIER_END := preload("res://assets/events/barrier_end.svg")
const CAFE_TABLE := preload("res://assets/events/cafe_table.svg")
const DOG := preload("res://assets/events/dog.svg")

var def: EventDef
## Waypoints for a mobile event, in world space. Empty for a stationary one.
var path: PackedVector2Array = PackedVector2Array()

var age := 0.0
var is_finished := false

## Facing, for art with a front and a back. Only a mobile event ever changes it.
var _heading := Vector2.RIGHT
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

	if def.mobile and path.size() > 1 and not (def.still_while_telegraphing and is_telegraphing()):
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
			_heading = segment.normalized()
			position = path[i - 1] + _heading * remaining
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
	if not is_equal_approx(def.intensity_ramp, 1.0) and def.duration > 0.0:
		var through := clampf((age - def.telegraph_time) / def.duration, 0.0, 1.0)
		value *= lerpf(1.0, def.intensity_ramp, through)
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
	# A city-wide source has no falloff: there is nowhere in the city it does not reach.
	if def.city_wide:
		return current_intensity()
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
	_draw_mark()

# ------------------------------------------------------------------ the mark ---
# M22, playtest 02 finding 8 and playtest 04 finding 2. The aura rings are gone: a ring
# communicates a falloff radius, which is a number, and a number is not a threat. What replaces
# it over an entity is a small mark, and it earns its place by three rules.

## How far above the entity the mark floats, and how big it is at full strength.
const MARK_HEIGHT := 44.0
const MARK_WIDTH := 15.0
const MARK_FLASHES_PER_SECOND := 3.0

## Whether this event is worth a mark at all.
##
## **The mark is for danger that changes over time, and for nothing else.** That is the whole
## rule, and it is the answer to the half of finding 8 that says a ring marked a notice board
## exactly as hard as it marked an abduction and therefore explained nothing:
##
## - **It is about to start.** The telegraph is the promise the fairness contract makes, and a
##   promise nobody can see is not one.
## - **It ends the day.** Nothing else in the game is a different kind of thing from everything
##   else in the game, and that deserves its own mark whether or not the silhouette carries it.
## - **It comes and goes.** A pulsing or swelling event has to be *timed*, and timing is the one
##   thing the ring genuinely did well. See `mark_swell()`.
##
## Everything steady is left to its own silhouette, which is the standing decision in
## `CLAUDE.md` — a barricade, a boarded shopfront and a burnt-out shell are large, distinct and
## visibly what they are, and pointing at them adds nothing but noise. A first pass used
## "louder than the walking decay" instead and marked all three of those, which is the ring's
## own mistake in a new shape.
func wants_a_mark() -> bool:
	if is_finished or def.city_wide:
		# A floor under the whole city has nothing to stand over. That is the HUD's job.
		return false
	if def.kind == GameEnums.EventKind.AMBIENT:
		# A permanent feature of a fixed map never appears, so there is no moment to mark and
		# nothing to time. The same reason the fairness contract exempts it.
		return false
	if def.hard_fail or is_telegraphing():
		return true
	return def.pulse_period > 0.0 or not is_equal_approx(def.intensity_ramp, 1.0)

## How hard the mark is breathing, 0..1, from what the event is emitting right now.
##
## **This is the one thing the ring did that a symbol does not get for free**, and it is
## load-bearing: a pulsing event can be timed and slipped past between beats, and a mark that
## sat there at a constant size would turn the pulse envelope from something to play against
## into something random.
func mark_swell() -> float:
	if def.intensity <= 0.0:
		return 1.0
	return clampf(current_intensity() / def.intensity, 0.0, 1.0)

func mark_colour() -> Color:
	if def.hard_fail:
		return Palette.MARK_LETHAL
	return Palette.MARK_TELEGRAPH if is_telegraphing() else Palette.MARK_ACTIVE

## A caret over anything worth looking at, breathing with what it is currently emitting.
##
## What is deliberately *not* here: any drawing of where the danger reaches. That is the ring,
## and its absence is the milestone.
func _draw_mark() -> void:
	if not wants_a_mark():
		return
	# Flashing while telegraphing, which is the phase that means *this has not happened yet*.
	# A steady mark for something already happening: it has stopped being a warning.
	var telegraphing := is_telegraphing()
	if telegraphing and fmod(age * MARK_FLASHES_PER_SECOND, 1.0) > 0.55:
		return

	var swell := mark_swell()
	# Never all the way to nothing: between beats the mark shrinks, it does not vanish, or a
	# pulsing event would read as flickering in and out of existence.
	var scale := 0.55 + 0.45 * swell
	var at := Vector2(0.0, -(MARK_HEIGHT + 10.0 * swell))
	Sprites.draw_caret(self, at, MARK_WIDTH * scale, mark_colour())
	if def.hard_fail:
		# Doubled, so lethal reads at a glance and never has to be told apart by hue.
		Sprites.draw_caret(self, at - Vector2(0.0, MARK_WIDTH * scale * 0.85),
				MARK_WIDTH * scale, mark_colour())

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
			_draw_spread(BARRIER_SEGMENT, BARRIER_END)
		EventDef.Look.TABLES:
			_draw_spread(CAFE_TABLE)
		EventDef.Look.DOG_WALKER:
			_draw_dog_walker()
		EventDef.Look.NONE:
			pass

func _draw_animal() -> void:
	# Crouched while telegraphing, stretched out once it bolts. The crouch *is* the
	# telegraph, so the two silhouettes have to differ at a glance, not by a scale factor.
	var texture := CAT_CROUCHED if is_telegraphing() else CAT_RUNNING
	Sprites.draw_shadow(self, Vector2.ZERO, 7.0)
	Sprites.draw_standing(self, texture, Vector2.ZERO, Vector2.ZERO, _heading_is_west())

func _draw_person() -> void:
	Sprites.draw_shadow(self, Vector2.ZERO, 8.0)
	Sprites.draw_standing(self, PERSON, Vector2.ZERO, Vector2.ZERO, _heading_is_west())

func _draw_vehicle() -> void:
	Sprites.draw_shadow(self, Vector2.ZERO, 20.0)
	Sprites.draw_standing(self, VEHICLE, Vector2.ZERO, Vector2.ZERO, _heading_is_west())

## Flames scaled by what the event is currently emitting, so a fire visibly roars.
func _draw_fire() -> void:
	var strength := 1.0
	if def.intensity > 0.0:
		strength = clampf(current_intensity() / def.intensity, 0.2, 1.0)
	Sprites.draw_shadow(self, Vector2.ZERO, 22.0)
	for i in 5:
		var offset := (i - 2.0) * 11.0
		var flicker := 1.0 + 0.25 * sin(age * 9.0 + i * 1.7)
		var height := (34.0 + i % 2 * 14.0) * strength * flicker
		Sprites.draw_standing(self, FLAME, Vector2(offset, 0.0), Vector2(18.0, height))

## A blocking object is drawn at exactly the width it obstructs, by repeating a segment
## across it. Anything else would be a lie about where the player can walk.
func _draw_spread(segment_texture: Texture2D, cap: Texture2D = null) -> void:
	var half := maxf(11.0, def.obstructs_radius)
	Sprites.draw_shadow(self, Vector2.ZERO, half * 0.9)
	var segment := segment_texture.get_size()
	var segments := maxi(1, ceili(half * 2.0 / segment.x))
	var width := half * 2.0 / segments
	for i in segments:
		Sprites.draw_standing(self, segment_texture,
				Vector2(-half + width * (i + 0.5), 0.0), Vector2(width, segment.y))
	if not cap:
		return
	for side in [-1.0, 1.0]:
		Sprites.draw_standing(self, cap, Vector2(side * half, 0.0))

## The person, the dog, and the lead between them.
##
## The lead is drawn because it is the mechanic: what makes a dog walker worth crossing the
## street for is the span it owns, and a span you cannot see is a span you walk into. The dog
## leads on the side the walker is heading, so the pair reads as being dragged along.
func _draw_dog_walker() -> void:
	var reach := def.inner_radius * 0.8
	var to_the_dog := Vector2(-reach if _heading_is_west() else reach, 0.0)
	Sprites.draw_shadow(self, Vector2.ZERO, 8.0)
	Sprites.draw_shadow(self, to_the_dog, 9.0)
	# Slack in the middle, so it reads as a lead rather than as a bar.
	draw_line(Vector2(0.0, -26.0), to_the_dog + Vector2(0.0, -6.0), Palette.OUTLINE, 2.0)
	Sprites.draw_standing(self, PERSON, Vector2.ZERO, Vector2.ZERO, _heading_is_west())
	Sprites.draw_standing(self, DOG, to_the_dog, Vector2.ZERO, _heading_is_west())

## Which way a mobile event is travelling, for art that has a front and a back. A
## stationary event never flips.
func _heading_is_west() -> bool:
	return _heading.x < 0.0

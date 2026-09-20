class_name ContactPoint
extends Node2D
## A place in the city where touching completes a step of the resistance subquest.
##
## Deliberately quiet: no quest marker, no arrow. A pickup is a chalk mark on the ground,
## found by walking past it, which is the only way anything in this game is found. A
## perform's contact rides on the `EventInstance` its task is built around and draws
## nothing of its own — it must look exactly like the ordinary version of the same row, or
## "several candidates to test before finding the correct one" is not actually true.

signal completed(step: int)

## How close the player must be for a touch to complete the step.
const REACH := 36.0

## The chalk decal's two baked pictures, in the "decoration" `AtlasLibrary` group — acquired for
## the whole run by `City.build()` (see `city_decals.gd`'s own doc), so nothing here has to hold a
## reference of its own. `_MARK` is what a pickup shows while it waits; `_MARK_TOUCHED` is what it
## switches to the instant the step completes (M177), the ground half of "a completed step is
## acknowledged where she is looking."
const _MARK := &"props/chalk_mark"
const _MARK_TOUCHED := &"props/chalk_mark_touched"

## Drawn larger than the baked 32×32 picture (M177, playtest 116: "they need to be a little bit
## more obviously visible") — still a chalk mark, not a marker or a glow: the **cues** skill's
## vocabulary stays a silhouette drawn once, not a ring or a pulse. A scale change rather than a
## bigger canvas, so the stroke geometry `art/props/chalk_mark.svg` authors stays the one source
## for both the native preview and the drawn size.
const _MARK_SCALE := 1.35

var step: ResistanceSteps.Step
var is_done := false

var _player: Stroller
var _pulse := 0.0
## Set only for a perform step: the instance this contact rides on, and the fixed offset
## from it — drawn once, in a direction the day's own RNG chose, so a contact that has to
## clear an obstruction sits at a learnable spot rather than a re-rolled one.
var _rider: EventInstance
var _rider_offset := Vector2.ZERO

## A pickup: a bare chalk mark at a fixed point.
func setup(which: ResistanceSteps.Step, at: Vector2) -> void:
	step = which
	position = at
	# A mark on the ground belongs under everything that stands on it, including the
	# player who is standing on it to read it.
	z_index = -1

## A perform: the contact follows `instance`, offset so a solid body between them never
## makes it unreachable.
func ride(which: ResistanceSteps.Step, instance: EventInstance, offset: Vector2) -> void:
	step = which
	_rider = instance
	_rider_offset = offset
	position = instance.global_position + offset
	z_index = -1

## Whether the thing this rides on is still there to be touched.
func rider_alive() -> bool:
	return not _rider or (is_instance_valid(_rider) and not _rider.is_finished)

func _physics_process(delta: float) -> void:
	if is_done:
		return
	_pulse += delta
	if _rider:
		if not rider_alive():
			return
		global_position = _rider.global_position + _rider_offset
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as Stroller
		if not _player:
			return
	if global_position.distance_to(_player.global_position) <= REACH:
		_complete()
	queue_redraw()

func _complete() -> void:
	is_done = true
	completed.emit(step.index)
	queue_redraw()

# ------------------------------------------------------------------ drawing ---

func _draw() -> void:
	# A perform's contact is invisible — it has to look exactly like the ordinary row it
	# rides on, or approaching it would already answer "is this the one".
	if _rider:
		return
	var texture := AtlasLibrary.region(_MARK_TOUCHED if is_done else _MARK)
	if not texture:
		return
	# The untouched mark still flickers — the same "sort of mark you would walk past a hundred
	# times" this used to draw by hand — but with a higher floor than before (0.85, was 0.75), the
	# contrast half of the same M177 visibility bump the scale above answers: still a breathing
	# mark, just never faint enough to read as chalk that has mostly worn off. The touched picture
	# holds still: `_physics_process()` already stops calling `queue_redraw()` once `is_done`, so
	# this alpha is only ever asked for on the one frame `_complete()` redraws it.
	var tint := Color.WHITE
	if not is_done:
		tint.a = 0.85 + 0.15 * sin(_pulse * 2.0)
	var size := texture.get_size() * _MARK_SCALE
	draw_texture_rect(texture, Rect2(-size * 0.5, size), false, tint)

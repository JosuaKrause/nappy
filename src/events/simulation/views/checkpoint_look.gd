class_name CheckpointLook
extends EventLook
## The checkpoint kit at a region door: the hut with its guard, the boom gate and the alley post.
## `docs/GRAPHICS.md` binds each row to the file it draws; `RegionPlanner` says where the bodies
## stand and `CheckpointController` holds her at them.

## Overrides EventLook._draw_figure.
func _draw_figure(canvas: CanvasItem) -> void:
	match _look.picture():
		EventDef.Look.CHECKPOINT_HUT:
			_draw_checkpoint_hut(canvas)
		EventDef.Look.CHECKPOINT_GATE:
			_draw_checkpoint_gate(canvas)
		EventDef.Look.CHECKPOINT_POST:
			# The guard's own picture is person-scale, but his shape is the checkpoint's own —
			# one body covers the whole 64px alley mouth, same as `checkpoint_hut`'s hut. See
			# `EventCatalogue._checkpoint_post`.
			_draw_body_shadow(canvas)
			_draw_at_anchor(canvas,
					EventPictures.GUARD_ALERT_BY_VIEW["front"] if event.is_its_guard_warning() \
							else EventPictures.GUARD_STANDING,
					EventPictures.GUARD_ANCHOR)

## The hut's own doorway direction (`EventFootprints.hut_doorway()`), facing the carriageway.
func _hut_doorway() -> Vector2i:
	return EventFootprints.hut_doorway(event.world_map(), event.global_position)

func _hut_texture(doorway: Vector2i) -> String:
	if doorway == Vector2i.UP:
		return EventPictures.HUT_NORTH
	if doorway == Vector2i.LEFT:
		return EventPictures.HUT_WEST
	if doorway == Vector2i.RIGHT:
		return EventPictures.HUT_EAST
	return EventPictures.HUT_SOUTH

## The hut, doorway facing the carriageway, with a guard posted beside it on the pavement rather
## than in the doorway itself, where `EventInstance.its_guards_feet()` says he stands
## (`EventFootprints.hut_guard_beside()`), so the two never overlap whichever of the four the
## doorway turns out to be.
##
## **The guard is the only part of it that goes inside for a hold.** The hut is a building: it
## stays exactly where it is, casting the same shadow, so the two seconds read as her having gone
## in rather than as the checkpoint having vanished.
func _draw_checkpoint_hut(canvas: CanvasItem) -> void:
	var doorway := _hut_doorway()
	_draw_body_shadow(canvas)
	_draw_at_anchor(canvas, _hut_texture(doorway), EventPictures.HUT_ANCHOR)
	if event.is_its_guard_inside():
		return
	var beside := event.its_guards_feet() - event.global_position
	# The guard's own shadow, not the row's shape — a per-part point beside the hut, same as the
	# dog beside a dog walker.
	_draw_shadow(canvas, beside, 8.0)
	_draw_at_anchor(canvas,
			EventPictures.GUARD_ALERT_BY_VIEW["front"] if event.is_its_guard_warning() \
					else EventPictures.GUARD_STANDING,
			EventPictures.GUARD_ANCHOR, beside)

## The boom, raised or lowered (`is_raised()`, which reads as lowered before `Crowd` has ever touched
## it, the safe default), over whichever axis of road `facing_now()` says this door's street
## runs — `EventInstance.facing_now()` is the street's own along-axis here, not a direction this
## stationary body ever turns to face, see `facing_now()`'s own doc.
func _draw_checkpoint_gate(canvas: CanvasItem) -> void:
	var raised := event.is_raised()
	var runs_north_south := EventPictures.gate_runs_north_south(event.facing_now())
	var picture: String
	var anchor: Vector2
	if runs_north_south:
		picture = EventPictures.BOOM_GATE_NS_RAISED if raised \
				else EventPictures.BOOM_GATE_NS_LOWERED
		anchor = EventPictures.BOOM_NS_ANCHOR
	else:
		picture = EventPictures.BOOM_GATE_EW_RAISED if raised \
				else EventPictures.BOOM_GATE_EW_LOWERED
		anchor = EventPictures.BOOM_EW_ANCHOR
	_draw_body_shadow(canvas)
	_draw_at_anchor(canvas, picture, anchor)

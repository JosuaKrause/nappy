class_name PursuerLook
extends EventLook
## A man on foot who comes after her: the robbers, the policeman, the masked man and the guards who
## give chase, each drawn by the stage he is in (waiting, warning with a hand raised, running).

func _draw_figure(canvas: CanvasItem) -> void:
	match event.def.look:
		EventDef.Look.ROBBER, EventDef.Look.ROBBER_GIVING_CHASE:
			_draw_robber(canvas)
		EventDef.Look.MASKED_PURSUER, EventDef.Look.DOOR_GUARD, \
				EventDef.Look.VAN_GUARD_GIVING_CHASE, \
				EventDef.Look.GUARDSMAN_GIVING_CHASE:
			_draw_masked_pursuer(canvas)
		EventDef.Look.POLICEMAN_GIVING_CHASE:
			_draw_policeman(canvas)

## Hood up and hands in the coat while he is only somewhere; both hands out of the coat, walking at
## her, through his notice; leaning out over a forward leg once he lunges.
##
## The same rule as the cat above, at the one row where reading it wrong ends the run: the postures
## are the states `EventDef.notice` invented, and `is_waiting()` and `is_telegraphing()` are
## exactly the lines between them. What the player has to be able to see from an alley mouth is not
## "there is a man there" but *which of the three men that is* — so the change of posture happens on
## the frame he notices her, and again on the frame he lunges *(velvet-marten, #699: "warning (when
## the player gets close; needs to be visually distinct), and then the actual charging")*.
func _draw_robber(canvas: CanvasItem) -> void:
	_draw_body_shadow(canvas)
	var waiting := event.is_waiting()
	var by_view := robber_pictures()
	# Once he has noticed her, `EventPursuit` already keeps `EventInstance.facing_now()` pointed at
	# her for every frame of the telegraph and the lunge alike — `draw_body()`'s ordinary reading,
	# `EventInstance.facing_now()`. Before that he has nothing of his own to face except the alley
	# he was sited in, and a man only watching the street is worth nothing next to a man watching
	# *her* — see `_robber_waiting_heading()`.
	var heading := _robber_waiting_heading() if waiting else event.facing_now()
	var view := _select_view(heading)
	Sprites.draw_standing(canvas, EventPictures.drawn(by_view[view]), Vector2.ZERO, Vector2.ZERO,
			EightDirection.is_mirrored(_view_sector))

## The robber's picture for this frame: waiting, his two-frame alert walk through his notice
## (`is_telegraphing()`, which the sent robber, arriving already chasing, never is), and the lunge
## with its stride frame once he goes. The waiting posture holds still by construction — he has
## nothing to stride toward yet. The one place the choice is read, so the draw, its halo and a test
## ask the same question.
func robber_pictures() -> Dictionary:
	if event.is_waiting():
		return EventPictures.ROBBER_WAITING_BY_VIEW
	if event.is_telegraphing():
		return EventPictures.ROBBER_ALERT_BY_VIEW_B if _gait_stepping() \
				else EventPictures.ROBBER_ALERT_BY_VIEW
	return EventPictures.ROBBER_LUNGING_BY_VIEW_B if _gait_stepping() \
			else EventPictures.ROBBER_LUNGING_BY_VIEW

## **The policeman on foot, drawn as the robber is.** He faces her while he is after her
## (`EventPursuit` keeps `EventInstance.facing_now()` on her) and his vehicle's door as he walks
## back (`EventOfficer.walk_back()`); which picture is `policeman_pictures()`.
func _draw_policeman(canvas: CanvasItem) -> void:
	_draw_body_shadow(canvas)
	var by_view := policeman_pictures()
	var view := _select_view(event.facing_now())
	Sprites.draw_standing(canvas, EventPictures.drawn(by_view[view]), Vector2.ZERO, Vector2.ZERO,
			EightDirection.is_mirrored(_view_sector))

## The policeman's picture for this frame: his alert, hand raised, for the second the man out of an
## investigating vehicle stands beside her before he charges (`is_standing_for_its_notice()`); his
## waiting posture while he stands with her through a stop (`has_stopped_her()`, through
## `_stands_still_now()`); his lunge, with its stride, once he gives chase and as he walks back to
## his vehicle. The one a torn poster sends arrives charging and is only ever drawn coming. The one
## place the choice is read, so the draw, its halo and a test ask the same question.
func policeman_pictures() -> Dictionary:
	if event.is_standing_for_its_notice():
		return EventPictures.POLICEMAN_ALERT_BY_VIEW
	if _stands_still_now():
		return EventPictures.POLICEMAN_WAITING_BY_VIEW
	return EventPictures.POLICEMAN_LUNGING_BY_VIEW_B if _gait_stepping() \
			else EventPictures.POLICEMAN_LUNGING_BY_VIEW

## Whether a man on foot is drawn standing rather than lunging: while he waits for her to come
## near (`is_waiting()`, which `is_telegraphing()` is false for, the masked man at the foot of the
## shaft being the one who does), through his notice, and through a stop he has made of his catch
## (`has_stopped_her()`) until he turns to walk back.
func _stands_still_now() -> bool:
	return event.is_waiting() or event.is_telegraphing() or (event.has_stopped_her()
			and not event.is_leaving)

## A masked man coming up a stairwell, or a door's guard coming after her once she has walked under
## its boom — the same man, and the guardsman a torn poster sends or a vehicle lets out:
## the `guard_standing_*` family while he waits for her and through a stop (`_stands_still_now()`),
## `guard_alert_*` for any notice he gives (`masked_pursuer_pictures()`), as a heated roadblock's
## guard does at his post, and `guard_lunging_*` once he is actually on her line. Read from his own
## travel heading through `_draw_eight_view()`, the same helper every other moving family uses, so
## he turns to face where he is going on every step of the shaft rather than only mirroring
## east/west. No `side_faces_west` override: `guard_lunging_side.svg`'s own comment says the family
## is east-authored, the same as every person/animal family. Its own body shadow — `def.shape`, a
## 9px point, at local origin — is exactly what `_draw_eight_view()` draws by default.
func _draw_masked_pursuer(canvas: CanvasItem) -> void:
	_draw_eight_view(masked_pursuer_pictures(), event.facing_now(), canvas)

## The guard-drawn pursuer's picture for this frame. **The alert, hand raised, is every notice one
## of them gives**: the guardsman a vehicle lets out, standing for his notice
## (`is_standing_for_its_notice()`, read off `PursuitSpec.stands`), and the masked man standing at
## the foot of the shaft through his notice (`is_telegraphing()` after his wait, which his row's
## `EventDef.notice` gives him and no other guard-drawn row has). *(Inbox #764 in minty-lemur, the
## player: an event that does not spawn already charging always needs a warning.)* The van's guard a
## task sends and the guardsman a torn poster sends arrive charging and never give one, nor does the
## door guard, whose warning was the hut's or the post's guard's from her crossing
## (`PursuitSpec.Start.CHARGES_AT_ONCE`). Otherwise `guard_standing_*` while `_stands_still_now()` —
## the masked man's wait, a stop — and `guard_lunging_*` after.
func masked_pursuer_pictures() -> Dictionary:
	if event.is_standing_for_its_notice() or (event.def.notice_within() > 0.0
			and event.is_telegraphing()):
		return EventPictures.GUARD_ALERT_BY_VIEW
	return EventPictures.GUARD_STANDING_BY_VIEW if _stands_still_now() \
			else EventPictures.GUARD_LUNGING_BY_VIEW

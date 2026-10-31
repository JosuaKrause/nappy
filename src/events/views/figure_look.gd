class_name FigureLook
extends EventLook
## A row drawn as one figure: the people and animals who walk, stand or sit by themselves (the
## mouse, the cat, the yeller, the neighbor, the dog walker, the loose dog, the leaf blower, the
## cyclist, the charging dog, the chatting mother, the busker, the poster crews), and the single
## pictures that stand on a spot (a skip, a vent's steam, a crater, a loudspeaker mast).

func _draw_figure(canvas: CanvasItem) -> void:
	match event.def.look:
		EventDef.Look.CAT:
			_draw_cat(canvas)
		EventDef.Look.MOUSE:
			_draw_eight_view(EventPictures.MOUSE_BY_VIEW, event.facing_now(), canvas, false,
					EventPictures.MOUSE_BY_VIEW_B)
		EventDef.Look.YELLER:
			_draw_eight_view(EventPictures.YELLER_BY_VIEW, event.facing_now(), canvas, false,
					EventPictures.YELLER_BY_VIEW_B)
		EventDef.Look.NEIGHBOR:
			_draw_eight_view(EventPictures.NEIGHBOR_BY_VIEW, event.facing_now(), canvas, false,
					EventPictures.NEIGHBOR_BY_VIEW_B)
		EventDef.Look.DOG_WALKER:
			_draw_dog_walker(canvas)
		EventDef.Look.BUSKER:
			_draw_busker(canvas)
		EventDef.Look.LOOSE_DOG:
			_draw_loose_dog(canvas)
		EventDef.Look.LEAF_BLOWER:
			_draw_eight_view(EventPictures.LEAF_BLOWER_BY_VIEW, event.facing_now(), canvas, false,
					EventPictures.LEAF_BLOWER_BY_VIEW_B)
		EventDef.Look.CYCLIST:
			var rider := rider_pictures()
			_draw_eight_view(rider[0], event.facing_now(), canvas, false, rider[1])
		EventDef.Look.CHARGING_DOG:
			var dog := charging_dog_pictures()
			_draw_eight_view(dog[0], event.facing_now(), canvas, false, dog[1])
		EventDef.Look.CHATTING_MOTHER:
			_draw_chatting_mother(canvas)
		EventDef.Look.POSTER_CREW:
			var crew := EventPictures.POSTER_CREW_BY_VIEW_B \
					if _idle_stepping(EventPictures.POSTER_CREW_PASTE_PERIOD) \
					else EventPictures.POSTER_CREW_BY_VIEW
			_draw_eight_view(crew, event.facing_now(), canvas)
		EventDef.Look.POSTER_CREW_SQUARE:
			# Sited with no pavement side to turn it, so `_build_placement` leaves its facing at
			# due east and the row draws its `side` view unmirrored, every time — the same dead
			# branch `reversing_lorry` has above. The other four views exist so the family is
			# whole if anything ever does turn one.
			_draw_eight_view(EventPictures.POSTER_CREW_SQUARE_BY_VIEW, event.facing_now(), canvas)
		EventDef.Look.SKIP:
			_draw_simple(EventPictures.SKIP, canvas)
		EventDef.Look.IMPACT_CRATER:
			_draw_crater(canvas)
		EventDef.Look.STEAM:
			_draw_simple(EventPictures.STEAM_B
					if _idle_stepping(EventPictures.STEAM_BILLOW_PERIOD) \
							else EventPictures.STEAM, canvas)
		EventDef.Look.LOUDSPEAKER_MAST:
			_draw_mast(canvas)

## The two pedal frames a cyclist draws, `[by_view, by_view_b]`: the pelican's when `is_pelican`
## is set, the kid's otherwise. The one place the choice is read, so the draw and a test ask the
## same question.
func rider_pictures() -> Array[Dictionary]:
	if event.is_pelican:
		return [EventPictures.PELICAN_BY_VIEW, EventPictures.PELICAN_BY_VIEW_B]
	return [EventPictures.CYCLIST_BY_VIEW, EventPictures.CYCLIST_BY_VIEW_B]

## The charging dog's two frames for this stage, `[by_view, by_view_b]`, `by_view_b` empty for a
## still pose: sitting while it waits (`is_waiting()`), its alert while it stands for its notice
## (`is_standing_for_its_notice()`), and the gallop otherwise — the charge, the day-3 dog's
## approach, and the trot away when it gives up. The one place the choice is read, so the draw, its
## halo and a test ask the same question.
func charging_dog_pictures() -> Array[Dictionary]:
	if event.is_waiting():
		return [EventPictures.CHARGING_DOG_RESTING_BY_VIEW, {}]
	if event.is_standing_for_its_notice():
		return [EventPictures.CHARGING_DOG_ALERT_BY_VIEW, {}]
	return [EventPictures.CHARGING_DOG_BY_VIEW, EventPictures.CHARGING_DOG_BY_VIEW_B]

## The dog, and the lead it is no longer on.
##
## Read against `_draw_dog_walker()`, which draws the lead *taut between two bodies*: that is
## the span it owns and the reason to cross the street. Here the same lead trails on the ground
## behind one body, and the difference between the two pictures is the whole event.
func _draw_loose_dog(canvas: CanvasItem) -> void:
	var behind := Vector2(EventFootprints.LOOSE_LEAD_REACH if _heading_is_west()
			else -EventFootprints.LOOSE_LEAD_REACH, 0.0)
	_draw_body_shadow(canvas)
	# On the ground and slack, not held up at hip height. Nobody is holding it. The lead's own
	# offset stays a plain east/west span — a composite the picture underneath it does not own,
	# same as `_draw_dog_walker`'s taut one.
	canvas.draw_line(Vector2(0.0, -8.0), behind + Vector2(0.0, -2.0), Palette.OUTLINE, 2.0)
	var view := _select_view(event.facing_now())
	var dog := EventPictures.dog_picture(view, _gait_stepping(), _gait_second_half())
	Sprites.draw_standing(canvas, EventPictures.drawn(dog), Vector2.ZERO, Vector2.ZERO,
			EightDirection.is_mirrored(_view_sector))

func _draw_cat(canvas: CanvasItem) -> void:
	# Crouched while telegraphing, stretched out once it bolts. The crouch *is* the
	# telegraph, so the two silhouettes have to differ at a glance, not by a scale factor.
	var telegraphing := event.is_telegraphing()
	var by_view := EventPictures.CAT_CROUCHED_BY_VIEW if telegraphing \
			else EventPictures.CAT_RUNNING_BY_VIEW
	# The crouch holds still by construction (`still_while_telegraphing`), so only the dash gets a
	# second frame — a crouching cat has nothing to stride into yet.
	if not telegraphing and _gait_stepping():
		by_view = EventPictures.CAT_RUNNING_BY_VIEW_B
	_draw_body_shadow(canvas)
	var view := _select_view(event.facing_now())
	Sprites.draw_standing(canvas, EventPictures.drawn(by_view[view]), Vector2.ZERO, Vector2.ZERO,
			EightDirection.is_mirrored(_view_sector))

## The tables, and the people at them.
##
## The hole an off-screen burst left in the road. **Flat, centred and unshadowed**, which is all
## three of the ways it is unlike every other body an event is drawn as: the picture is ground
## rather than an object standing on ground, so it registers on its own middle
## (`EventPictures.CRATER_ANCHOR`) instead of on its feet, and a drop shadow under a hole would read
## as a mound. What makes it solid anyway is `def.shape` — `EventInstance._build_obstruction()`
## reads that and nothing here — so the circle she cannot walk into is exactly half of the picture
## she can see.
func _draw_crater(canvas: CanvasItem) -> void:
	_draw_at_anchor(canvas, EventPictures.IMPACT_CRATER, EventPictures.CRATER_ANCHOR)

## The busker's own site facing and idle strum — he never moves, so this reads `_idle_stepping()`
## rather than `_gait_stepping()`, the same timer the café sitters use above at a faster tempo
## (`EventPictures.BUSKER_STRUM_PERIOD`). Kept as its own function rather than routed through
## `_draw_eight_view()` because that helper's own `by_view_b` parameter is keyed to the gait, not
## the idle timer.
func _draw_busker(canvas: CanvasItem) -> void:
	_draw_body_shadow(canvas)
	var view := _select_view(event.facing_now())
	var mirror := EightDirection.is_mirrored(_view_sector)
	var by_view := EventPictures.BUSKER_BY_VIEW_B \
			if _idle_stepping(EventPictures.BUSKER_STRUM_PERIOD) else EventPictures.BUSKER_BY_VIEW
	Sprites.draw_standing(canvas, EventPictures.drawn(by_view[view]), Vector2.ZERO, Vector2.ZERO,
			mirror)

## The pole and horns stand whether the mast is live or silenced — a mast never leaves. On top of
## it, the lamp and the arcs say what the pole alone cannot: amber and dark during the telegraph
## ("it has not started yet" — the same sentence the flash carries everywhere else in the
## vocabulary, docs/EVENTS.md, "The visual vocabulary"), green with the arcs rising while it
## speaks, and neither once `silenced` — *(2026-09-23, the player: "there should be a visible
## indicator about when a mast is active / has a broadcast")*.
func _draw_mast(canvas: CanvasItem) -> void:
	_draw_simple(EventPictures.MAST, canvas)
	if event.silenced:
		return
	if _mast_is_telegraphing_now():
		Sprites.draw_standing(canvas, EventPictures.drawn(EventPictures.MAST_LAMP),
				EventPictures.MAST_LAMP_AT, Vector2.ZERO, false,
				Palette.SIGNAL_AMBER)
		return
	Sprites.draw_standing(canvas, EventPictures.drawn(EventPictures.MAST_LAMP),
			EventPictures.MAST_LAMP_AT, Vector2.ZERO, false,
			Palette.SIGNAL_GREEN)
	Sprites.draw_standing(canvas, EventPictures.drawn(EventPictures.SOUND_PULSE),
			EventPictures.MAST_PULSE_AT, Vector2.ZERO, false)

## The person, the dog, and the lead between them.
##
## The lead is drawn because it is the mechanic: what makes a dog walker worth crossing the
## street for is the span it owns, and a span you cannot see is a span you walk into. The dog
## leads on the side the walker is heading, so the pair reads as being dragged along.
func _draw_dog_walker(canvas: CanvasItem) -> void:
	var reach := event.def.inner_radius * 0.8
	# The lead's own span stays a plain east/west offset — a composite the walker's own picture
	# does not own, unaffected by which of the eight views that picture now is.
	var to_the_dog := Vector2(-reach if _heading_is_west() else reach, 0.0)
	_draw_body_shadow(canvas)
	# The dog's own shadow, not the row's shape — a two-body composite has no single shape to be
	# either of its bodies, so this one is a per-part point like the abduction's victim.
	_draw_shadow(canvas, to_the_dog, 9.0)
	# Slack in the middle, so it reads as a lead rather than as a bar.
	canvas.draw_line(Vector2(0.0, -26.0), to_the_dog + Vector2(0.0, -6.0), Palette.OUTLINE, 2.0)
	# The dog faces the walker's own travel — the same heading, the same view, the same mirror —
	# since it is being led rather than watching anything of its own.
	var view := _select_view(event.facing_now())
	var mirror := EightDirection.is_mirrored(_view_sector)
	# One phase for the pair, so the walker's own legs and the dog's never disagree about which of
	# them is mid-stride: the dog steps while he does and rests while he does.
	var stepping := _gait_stepping()
	var person_by_view := EventPictures.PERSON_BY_VIEW_B if stepping \
			else EventPictures.PERSON_BY_VIEW
	var dog := EventPictures.dog_picture(view, stepping, _gait_second_half())
	Sprites.draw_standing(canvas, EventPictures.drawn(person_by_view[view]), Vector2.ZERO,
			Vector2.ZERO, mirror)
	Sprites.draw_standing(canvas, EventPictures.drawn(dog), to_the_dog, Vector2.ZERO, mirror)

## Another mother with a pram — one picture, two postures. Strolling is what she looks like for the
## whole of her beat; talking is what she looks like for exactly the `detain_seconds` of a
## conversation, and it is the only telegraph that mechanic gets — there is no exclamation mark,
## because she is a cost rather than a threat and that mark is spoken for. See
## `docs/EVENTS.md`, "The visual vocabulary".
func _draw_chatting_mother(canvas: CanvasItem) -> void:
	_draw_body_shadow(canvas)
	var chatting := event.is_chatting()
	var by_view := EventPictures.CHATTING_MOTHER_TALKING_BY_VIEW if chatting \
			else EventPictures.CHATTING_MOTHER_WALKING_BY_VIEW
	# Talking holds still by construction — the event's tick freezes her pacing the instant a
	# conversation starts — so only the walking posture gets a second frame.
	if not chatting and _gait_stepping():
		by_view = EventPictures.CHATTING_MOTHER_WALKING_BY_VIEW_B
	var view := _select_view(event.facing_now())
	Sprites.draw_standing(canvas, EventPictures.drawn(by_view[view]), Vector2.ZERO, Vector2.ZERO,
			EightDirection.is_mirrored(_view_sector))

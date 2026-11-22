class_name DangerEdge
extends Control
## What is coming, drawn at the edge of the screen while it is still off it.
##
## **Anything drawn in the world can only warn her once it is on screen**, and that is not soon
## enough for the rows designed around a long telegraph she is meant to spend getting off the
## street: `fire_truck` (190px/s, 340px radius) and `military_convoy` both arrive with most of
## their warning already spent. The fairness contract is met by the geometry and missed by the
## player.
##
## `MARGIN`, `CHEVRON` and `ICON` (and `BadgeModel.SCREEN_MARGIN`, which decides where a badge is raised) are all screen px, and that is only fair because
## the window is letterboxed: `window/stretch/aspect="keep"` in `project.godot` holds the viewport
## at a fixed 1280×720 for every monitor, camera included, so a badge measured in screen px warns
## the same distance out on a 21:9 monitor as on a 4:3 one. Under `"expand"` the same margin would
## buy a wide screen more world before the badge fires — more warning for a bigger monitor, on
## nothing the player did.
##
## Two rules it is built to, both from the danger vocabulary:
##
## - **It says what is coming, not that something is.** The event's own silhouette rides in the
##   chevron. "A fire engine is about to come down this street" is a route decision; "something
##   is over there" is an anxiety.
## - **It is not a field.** Nothing here draws a radius, a distance ring or a falloff. The
##   distance is written as a number of metres, the way the home arrow already does it, because
##   a number that has to be a number should be one.
##
## Not in the HUD, deliberately: the HUD listens to `EventBus` and holds no reference to the
## world, and this needs to ask the world where things are every frame. `main` owns it.
##
## **What it reads is the day's events, not a day.** It asks the `EventManager` it is handed for
## `instances()`, which the manager answers in the city and in the building alike — so the masked
## man coming up a stairwell is announced exactly the way a fire engine coming down a street is.
## See `setup()`.
##
## **And a warning can be up before its thing exists.** The manager's `pending_warnings()` are
## things on their way that are not in the world yet: a cyclist, the day-3 dog, the fire engine, day 13's
## column, the resistance's own robber and guard. Each gets its badge from the moment its warning goes
## up, pointing at the place it will come from, which moves only with her, for the at most one second
## the warning runs (`PendingWarning`). *(PLAYTEST-145: "the warning appears by itself with a
## reasonable position and when the time is right the object is spawned in at that location just
## offscreen"; calm-kestrel, inbox #559: "place the object immediately off screen so it will
## immediately start coming on the screen turning off the warning".)* Nothing about it is measured:
## the warning is the claim that it is coming. Then the thing exists just out of sight and keeps the
## badge (`EventInstance.was_warned_of()`) until she can see it, which is as soon as it moves.

## How far in from each screen edge the chevrons sit, as left/top/right/bottom. Asymmetric
## because the screen is: the clock and the run header are along the top, and the two meters and
## the state line take the bottom left. The first version used one margin for all four and put a
## warning behind the excitement bar, which is a good way to hide the thing you are warning
## about behind the consequence of ignoring it.
const MARGIN := Vector4(104.0, 116.0, 104.0, 148.0)
const CHEVRON := 19.0
const ICON := 34.0
## Whether `main` has decided a portrait touch window is presenting rotated, handed in by
## `use_rotated()` — see `TouchControls.rotated`'s own doc. This control is pinned to
## `ScreenOrientation.DESIGN_SIZE` regardless of rotation (see `main._add_danger_edge()`), so a raw
## canvas-space position has to come back through `ScreenOrientation.to_design_space()` before it is
## drawn here. What is in sight needs no such turn: `VisibleView` asks it of the world box the
## camera shows, the same whichever way the window presents it.
var _rotated := false
## Where this charges its time to the frame record, handed in by `main` (`use_frame_timing()`); the
## null sink until then.
var _timing := FrameTiming.new()
## The baked atlas pages a badge's picture comes from (`AtlasLibrary`): the one `main` holds every
## page a day draws on, handed by `use_atlas()` before the edge is added. A badge only reads a
## region, so it holds no group of its own. Public while `tests/test_atlas_boot.gd` finds every node
## holding a library by the field's name: the badge acquires nothing, and reads a region only while
## a badge is up, so the library it holds is the one thing that shows which it was handed.
var atlas: AtlasLibrary

## The day's events — see `setup()`.
var _events: EventManager
var _player: Node2D
## Which dangers get a badge, and when: handed this frame's inputs by `_measure()`, which is all
## this control does of it.
var _model := BadgeModel.new()

## Hands the edge the baked atlas pages its badges draw from: `main` hands the sitting's library,
## before the edge is added.
func use_atlas(library: AtlasLibrary) -> void:
	atlas = library

## Hands the edge where it charges its time to the frame record: `main` hands the sitting's kept
## frame timing.
func use_frame_timing(timing: FrameTiming) -> void:
	_timing = timing

## Hands the edge whether the window presents rotated: `main` hands its answer at boot and again
## whenever the window turns.
func use_rotated(rotate: bool) -> void:
	_rotated = rotate

## Counted by the frame record under `FrameTiming.Draw.BADGES`, which the recorder reads off this meta
## since it may not name the view.
func _init() -> void:
	set_meta(FrameTiming.DRAW_KIND_META, FrameTiming.Draw.BADGES)

## `events` is the `EventManager` whose instances and warnings the badges are for: the city's on a
## day and in the escape's city, the building's in the escape's building. **Called
## again when the escape walks out of the service door**, with the city's source in place of the
## building's, so one badge serves both sections; an id the new source no longer carries simply
## drops out of `_model._watch` on the next `_measure()`.
func setup(events: EventManager, player: Node2D) -> void:
	_events = events
	_player = player

## What she can see this frame: the day's own view (`EventManager.visible_view()`), so the badge
## and everything else that asks agree on it frame for frame.
func _view() -> VisibleView:
	return _events.visible_view()

## Whether something at `world_position` is in sight (`VisibleView.sees()`), counting `margin`
## screen px past the edge as in sight as well — the one test the badge asks.
func _sees(world_position: Vector2, margin := 0.0) -> bool:
	return _view().sees(world_position, margin * world_per_screen_px())

## Whether she can see any of `instance`: the point it stands at, or any of what it draws
## (`EventInstance.drawn_box()`). Coming into sight is the badge's job done by the thing itself, so the
## badge goes off the moment the first of it shows, not only once its feet do.
func _shows(instance: EventInstance) -> bool:
	if _sees(instance.global_position):
		return true
	var box := instance.drawn_box()
	return box.has_area() and _view().sees_any(Rect2(instance.global_position + box.position, box.size))

## World px per design-space screen px at the camera's zoom: the world the view shows across the
## design box's width.
static func world_per_screen_px() -> float:
	return Tuning.VIEW_HALF_EXTENT.x * 2.0 / ScreenOrientation.DESIGN_SIZE.x

func _process(delta: float) -> void:
	if _timing.is_on():
		var outer := _timing.enter(FrameTiming.CUES)
		_watch_the_edge(delta)
		_timing.leave(outer)
	else:
		_watch_the_edge(delta)

## The badges' measurement, timed under `FrameTiming.CUES`, and their redraw; answers whether it
## asked for one.
##
## The camera moves under the badges every frame, so while any is up the edge redraws every frame —
## a handful of chevrons — and a badge is drawn on the frame `_measure()` first puts it up. With none
## up this frame and none drawn the frame before, there is nothing on the edge to change, so it does
## not redraw at all.
func _watch_the_edge(delta: float) -> bool:
	_measure(delta)
	var badges := _model.has_badges()
	var asked := badges or _drew_badges
	_drew_badges = badges
	if asked:
		queue_redraw()
	return asked

## Whether the last redraw put any badge on the edge, so the frame after the last one comes down
## redraws once to take it off.
var _drew_badges := false

## Hands the model this frame's inputs, once per frame.
##
## Deliberately not in `_draw()`: this is a measurement over time and `_draw` is a function that may
## be called for reasons that have nothing to do with a frame elapsing. Everything below the line is
## drawing.
func _measure(delta: float) -> void:
	_model.clear_badges()
	if not _events or not _player or delta <= 0.0:
		return
	var subjects: Array = []
	for instance in _events.instances():
		if not instance.is_gone():
			subjects.append(_subject_of(instance))
	for warning in _events.pending_warnings():
		if warning.points_at() != Vector2.INF:
			subjects.append(_subject_of_warning(warning))
	_model.step(delta, _player.global_position, subjects, _sees)

## The facts the model reads about a live instance.
func _subject_of(instance: EventInstance) -> BadgeModel.Subject:
	var subject := subject_for_def(instance.row())
	subject.key = instance.get_instance_id()
	subject.position = instance.global_position
	subject.finished = instance.is_gone()
	subject.warned = instance.was_warned_of()
	subject.charging = instance.has_charged()
	subject.shown = _shows(instance)
	subject.logged_name = instance.logged_name()
	return subject

## The facts the model reads about a warning with nothing in the world yet.
func _subject_of_warning(warning: PendingWarning) -> BadgeModel.Subject:
	var subject := subject_for_def(warning.row())
	subject.pending = true
	subject.position = warning.points_at()
	subject.left = warning.seconds_left()
	subject.logged_name = warning.logged_name()
	return subject

## The facts the model reads about a row, live or warned of: whether its coming is worth an arrow
## (`EventDef.announces_its_coming()` at her walk), how fast it comes at her and where its field's
## edge is.
static func subject_for_def(def: EventDef) -> BadgeModel.Subject:
	var subject := BadgeModel.Subject.new()
	subject.payload = def
	subject.announces = def.announces_its_coming(Tuning.WALK_SPEED)
	subject.approach_speed = def.approach_speed()
	subject.heard_within = def.heard_within()
	return subject

## The badges this edge has up (`EdgeBadges.announcing()`: what each is called, how far it is and how
## fast it closes, nearest arrival first): its `BadgeModel`, held as the read-only `EdgeBadges`, the one object for
## the edge's life, which the escape's re-pointing (`setup()`) keeps. For the run log, which has to
## be able to say what she was warned about and whether she then did anything about it, which
## nothing else in the log can say: `main` hands it to the run log's session (`RunSession.watch()`),
## which may not name this view. A badge's `logged_name()` is the name the log calls the thing by
## (`EventInstance.logged_name()`): the row's id, or `pelican` for the pelican, from its warning on.
func badges() -> EdgeBadges:
	return _model

func _draw() -> void:
	if not _events or not _player:
		return
	var transform := get_viewport().get_canvas_transform()
	# Exactly the badges the model announces (`_model.drawn()` are the objects `badges()` hands the
	# run log), farthest arrival first so the soonest lies on top where two overlap.
	var badges := _model.drawn()
	for i in range(badges.size() - 1, -1, -1):
		_draw_arrow(badges[i].row(), badges[i].points_at(), badges[i].distance(), transform)

func _draw_arrow(def: EventDef, world_position: Vector2, distance: float,
		transform: Transform2D) -> void:
	var centre := size * 0.5
	var at_design := ScreenOrientation.to_design_space(transform * world_position, _rotated)
	var offset: Vector2 = at_design - centre
	if offset.length() < 1.0:
		return
	var bounds := Rect2(MARGIN.x, MARGIN.y,
			size.x - MARGIN.x - MARGIN.z, size.y - MARGIN.y - MARGIN.w)
	var direction := offset.normalized()
	var at := centre + direction * _distance_to_edge(bounds, centre, direction)

	# The same two colours the caret over the entity uses, meaning the same two things.
	# A badge and a caret that disagreed about what red meant would be two vocabularies.
	var colour := Palette.MARK_LETHAL if def.ends_the_day() else Palette.MARK_COSTLY
	# A disc under the whole thing, so the icon and the number read over a pale pavement and a
	# dark carriageway alike. The one place in the game a filled circle is still allowed —
	# it is a badge on the screen, not a field drawn in the world.
	draw_circle(at, ICON * 0.72, Color(Palette.OUTLINE.r, Palette.OUTLINE.g, Palette.OUTLINE.b,
			0.72))
	draw_arc(at, ICON * 0.72, 0.0, TAU, 28, colour, 2.0)
	_draw_chevron(at + direction * ICON * 0.95, direction.angle(), colour)

	# The thing itself, so the arrow says *what* rather than *something*. Scaled to fit the
	# badge with its aspect kept: these are authored at world scale and a square box squashes a
	# fire engine into something unrecognisable, which defeats the whole cue. Every row the badge
	# draws has a picture, and every picture has a silhouette: the catalogue suite fails the build
	# on one that does not. (A warned creation is raised by `BadgeModel` without asking
	# `announces_its_coming()`; every warned row announces, so the two paths draw the same rows.)
	# The size comes from the region table rather than from the texture, so the badge's own fit is
	# arithmetic that needs nothing loaded; the region itself is the one thing here that does, and
	# the `events` page is held for the whole process from either boot's own loading window
	# (`main.RESIDENT_GROUPS`), so it is there in the building as in the city.
	var name := StringName(EventPictures.icon_for(def.picture()))
	var art := Vector2(AtlasTable.baked().native_size(name))
	var fit := ICON / maxf(art.x, art.y)
	var drawn := art * fit
	var rect := Rect2(at - drawn * 0.5, drawn)
	draw_texture_rect(atlas.region(name), rect, false)
	# A vehicle's wheels are a picture of their own on the same canvas, so they fit the same
	# rectangle and go over the body the way the street draws them.
	var wheels := EventPictures.icon_wheels_for(def.picture())
	if not wheels.is_empty():
		draw_texture_rect(atlas.region(StringName(wheels)), rect, false)

	var label := Texts.DISTANCE_METRES % roundi(distance / Tuning.TILE_SIZE * 1.5)
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var text_at := at + Vector2(-width * 0.5, ICON * 0.72 + 16.0)
	draw_string(font, text_at + Vector2.ONE, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
			Palette.OUTLINE)
	draw_string(font, text_at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, colour)

func _draw_chevron(at: Vector2, angle: float, colour: Color) -> void:
	var points := PackedVector2Array([
		Vector2(CHEVRON, 0.0), Vector2(-CHEVRON * 0.7, CHEVRON * 0.8),
		Vector2(-CHEVRON * 0.25, 0.0), Vector2(-CHEVRON * 0.7, -CHEVRON * 0.8),
	])
	for i in points.size():
		points[i] = at + points[i].rotated(angle)
	draw_colored_polygon(points, colour)
	draw_polyline(points + PackedVector2Array([points[0]]), Palette.OUTLINE, 1.5)

## Distance from `centre` to where a ray leaves `bounds`. The same arithmetic `HomeArrow` does,
## and kept separate on purpose: one points at somewhere she wants to go and the other at
## something she wants to avoid, and merging them would put those two behaviours in one file.
func _distance_to_edge(bounds: Rect2, centre: Vector2, direction: Vector2) -> float:
	var best := INF
	if not is_zero_approx(direction.x):
		var edge_x: float = bounds.end.x if direction.x > 0.0 else bounds.position.x
		best = minf(best, (edge_x - centre.x) / direction.x)
	if not is_zero_approx(direction.y):
		var edge_y: float = bounds.end.y if direction.y > 0.0 else bounds.position.y
		best = minf(best, (edge_y - centre.y) / direction.y)
	return maxf(best, 0.0)

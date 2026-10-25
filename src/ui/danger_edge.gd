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
## `MARGIN`, `CHEVRON`, `ICON` and `SCREEN_MARGIN` are all screen px, and that is only fair because
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
## **What it reads is an event source, not a day.** The one thing asked of `_events` is
## `instances() -> Array[EventInstance]`, which `EventManager` answers in the city and in the
## building alike — so the masked man coming up a stairwell is
## announced exactly the way a fire engine coming down a street is. See `setup()`.
##
## **And a warning can be up before its thing exists.** A source that also answers
## `pending_warnings() -> Array[PendingWarning]` — `EventManager` does — has things on their way
## that are not in the world yet: a cyclist, the day-3 dog, the fire engine, day 13's
## column, the resistance's own robber and guard. Each gets its badge from the moment its warning goes
## up, pointing at the place it will come from, which moves only with her, for the at most one second
## the warning runs (`PendingWarning`). *(PLAYTEST-145: "the warning appears by itself with a
## reasonable position and when the time is right the object is spawned in at that location just
## offscreen"; calm-kestrel, inbox #559: "place the object immediately off screen so it will
## immediately start coming on the screen turning off the warning".)* Nothing about it is measured:
## the warning is the claim that it is coming. Then the thing exists just out of sight and keeps the
## badge (`EventInstance.came_under_a_warning`) until she can see it, which is as soon as it moves.

## How far in from each screen edge the chevrons sit, as left/top/right/bottom. Asymmetric
## because the screen is: the clock and the run header are along the top, and the two meters and
## the state line take the bottom left. The first version used one margin for all four and put a
## warning behind the excitement bar, which is a good way to hide the thing you are warning
## about behind the consequence of ignoring it.
const MARGIN := Vector4(104.0, 116.0, 104.0, 148.0)
const CHEVRON := 19.0
const ICON := 34.0
## At most this many at once. Three arrows is a warning; eight is wallpaper, and the day the
## edge of the screen becomes wallpaper is the day it stops being read.
const MOST_AT_ONCE := BadgeModel.MOST_AT_ONCE

## The thresholds are `BadgeModel`'s, which decides which dangers get a badge (see there for what
## each means); they stay reachable here for the callers that name them.
const CLOSING_SPEED := BadgeModel.CLOSING_SPEED
const HOLD := BadgeModel.HOLD
const SMOOTHING := BadgeModel.SMOOTHING
const SCREEN_MARGIN := BadgeModel.SCREEN_MARGIN

## Whether `main` has decided a portrait touch window is presenting rotated. Set from outside —
## see `TouchControls.rotated`'s own doc. This control is pinned to `ScreenOrientation.DESIGN_SIZE`
## regardless of rotation (see `main._add_danger_edge()`), so a raw canvas-space position has to
## come back through `ScreenOrientation.to_design_space()` before it is drawn here. What is in
## sight needs no such turn: `VisibleView` asks it of the world box the camera shows, the same
## whichever way the window presents it.
var rotated := false

## The event source — see `setup()`.
var _events: Node
var _player: Node2D
## What she can see, when the event source does not keep the day's own (`EventManager.
## visible_view()`): a stand-in source a test hands over. Looked through once a frame from her
## camera.
var _own_view := VisibleView.new()
## Which dangers get a badge, and when: handed this frame's inputs by `_measure()`, which is all
## this control does of it.
var model := BadgeModel.new()
## What `_draw` puts on the edge this frame, and the model's per-instance state: the model's own,
## read through here.
var _coming: Array:
	get:
		return model.coming
var _watch: Dictionary:
	get:
		return model.watch

## `events` is anything that answers `instances() -> Array[EventInstance]`: an `EventManager`, the
## city's on a day and in the escape's city, the building's in the escape's building. **Called
## again when the escape walks out of the service door**, with the city's source in place of the
## building's, so one badge serves both sections; an id the new source no longer carries simply
## drops out of `_watch` on the next `_measure()`.
func setup(events: Node, player: Node2D) -> void:
	_events = events
	_player = player

## The live instances, typed — the event source is duck-typed (see `setup()`), so its answer is
## read through here rather than at every loop, which is what keeps each loop variable an
## `EventInstance` to the analyser.
func _live() -> Array[EventInstance]:
	return _events.instances()

## What she can see this frame: the day's own view where the event source keeps one
## (`EventManager.visible_view()`), so the badge and everything else that asks agree on it frame for
## frame, and otherwise this edge's own, looked through from her camera.
func view() -> VisibleView:
	if _events and _events.has_method("visible_view"):
		return _events.visible_view()
	return _own_view

## Whether something at `world_position` is in sight (`VisibleView.sees()`), counting `margin`
## screen px past the edge as in sight as well — the one test the badge asks.
func sees(world_position: Vector2, margin := 0.0) -> bool:
	return view().sees(world_position, margin * world_per_screen_px())

## Whether she can see any of `instance`: the point it stands at, or any of what it draws
## (`EventInstance.drawn_box()`). Coming into sight is the badge's job done by the thing itself, so the
## badge goes off the moment the first of it shows, not only once its feet do.
func _shows(instance: EventInstance) -> bool:
	if sees(instance.global_position):
		return true
	var box := instance.drawn_box()
	return box.has_area() and view().sees_any(Rect2(instance.global_position + box.position, box.size))

## World px per design-space screen px at the camera's zoom: the world the view shows across the
## design box's width.
static func world_per_screen_px() -> float:
	return Tuning.VIEW_HALF_EXTENT.x * 2.0 / ScreenOrientation.DESIGN_SIZE.x

## The warnings that are up for something not in the world yet, or none for a source that has no
## such thing (a test's stand-in).
func _warnings() -> Array[PendingWarning]:
	if not _events.has_method("pending_warnings"):
		return []
	return _events.pending_warnings()

func _process(delta: float) -> void:
	if FrameRecord.on:
		var outer := FrameRecord.enter(FrameRecord.CUES)
		_watch_the_edge(delta)
		FrameRecord.leave(outer)
	else:
		_watch_the_edge(delta)

## The badges' measurement, timed under `FrameRecord.CUES`, and their redraw; answers whether it
## asked for one.
##
## The camera moves under the badges every frame, so while any is up the edge redraws every frame —
## a handful of chevrons — and a badge is drawn on the frame `_measure()` first puts it up. With none
## up this frame and none drawn the frame before, there is nothing on the edge to change, so it does
## not redraw at all.
func _watch_the_edge(delta: float) -> bool:
	_measure(delta)
	var badges := not _coming.is_empty()
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
	model.coming.clear()
	if not _events or not _player or delta <= 0.0:
		return
	if not (_events.has_method("visible_view")):
		_own_view.look_through(_player)
	var subjects: Array = []
	for instance in _live():
		if not instance.is_finished:
			subjects.append(_subject_of(instance))
	for warning in _warnings():
		if warning.place != Vector2.INF:
			subjects.append(_subject_of_warning(warning))
	model.step(delta, _player.global_position, subjects, sees, Tuning.WALK_SPEED)

## The facts the model reads about a live instance.
func _subject_of(instance: EventInstance) -> BadgeModel.Subject:
	var subject := _subject_for_def(instance.def)
	subject.key = instance.get_instance_id()
	subject.position = instance.global_position
	subject.finished = instance.is_finished
	subject.warned = instance.came_under_a_warning
	subject.charging = instance.has_charged()
	subject.shown = _shows(instance)
	subject.logged_name = instance.logged_name()
	return subject

## The facts the model reads about a warning with nothing in the world yet.
func _subject_of_warning(warning: PendingWarning) -> BadgeModel.Subject:
	var subject := _subject_for_def(warning.def)
	subject.pending = true
	subject.position = warning.place
	subject.left = warning.left
	subject.logged_name = warning.logged_name()
	return subject

func _subject_for_def(def: EventDef) -> BadgeModel.Subject:
	var subject := BadgeModel.Subject.new()
	subject.payload = def
	subject.speed = def.speed
	subject.outer_radius = def.outer_radius
	subject.chase_speed = def.chase_speed() if def.pursuit != null else def.speed
	subject.telegraphs = def.telegraphs
	subject.has_icon = not _icon_for(def.look).is_empty()
	subject.ahead_of_player = def.spawn_mode == EventDef.SpawnMode.AHEAD_OF_PLAYER
	subject.pursues = def.pursuit != null
	subject.hard_fail = def.hard_fail
	subject.mobile = def.mobile
	return subject

## How fast something at `was`, now at `now`, is closing on a player standing at `player`
## (`BadgeModel.approach_speed()`).
static func approach_speed(was: Vector2, now: Vector2, player: Vector2, delta: float) -> float:
	return BadgeModel.approach_speed(was, now, player, delta)

## Whether something closing at `approach` px/s with `gap` px of clear ground left is worth
## announcing (`BadgeModel.announces()`).
static func announces(approach: float, gap: float) -> bool:
	return BadgeModel.announces(approach, gap)

## What is on the edge of the screen right now: `{id, distance, approach}` per badge, nearest
## arrival first. For the telemetry observer, which has to be able to say what she was warned
## about and whether she then did anything about it, which nothing else in the log can say. `id`
## is the name the log calls the thing by (`EventInstance.logged_name()`): the row's id, or
## `pelican` for the pelican, from its warning on.
func announcing() -> Array[Dictionary]:
	return model.announcing()

func _draw() -> void:
	if FrameRecord.on:
		FrameRecord.drew(FrameLedger.DRAWS_BADGES)
	if not _events or not _player:
		return
	var transform := get_viewport().get_canvas_transform()
	for i in mini(MOST_AT_ONCE, _coming.size()):
		_draw_arrow(_coming[i][2] as EventDef, _coming[i][3] as Vector2, float(_coming[i][1]),
				transform)

## Whether something off-screen deserves an arrow (`BadgeModel.Subject.worth_an_arrow()`).
func _is_worth_an_arrow(instance: EventInstance) -> bool:
	return _is_worth_an_arrow_for(instance.def)

## `_is_worth_an_arrow()` asked of a row rather than of a live instance.
func _is_worth_an_arrow_for(def: EventDef) -> bool:
	return _subject_for_def(def).worth_an_arrow(Tuning.WALK_SPEED)

func _draw_arrow(def: EventDef, world_position: Vector2, distance: float,
		transform: Transform2D) -> void:
	var centre := size * 0.5
	var at_design := ScreenOrientation.to_design_space(transform * world_position, rotated)
	var offset: Vector2 = at_design - centre
	if offset.length() < 1.0:
		return
	var bounds := Rect2(MARGIN.x, MARGIN.y,
			size.x - MARGIN.x - MARGIN.z, size.y - MARGIN.y - MARGIN.w)
	var direction := offset.normalized()
	var at := centre + direction * _distance_to_edge(bounds, centre, direction)

	# The same two colours the caret over the entity uses, meaning the same two things.
	# A badge and a caret that disagreed about what red meant would be two vocabularies.
	var colour := Palette.MARK_LETHAL if def.hard_fail else Palette.MARK_COSTLY
	# A disc under the whole thing, so the icon and the number read over a pale pavement and a
	# dark carriageway alike. The one place in the game a filled circle is still allowed —
	# it is a badge on the screen, not a field drawn in the world.
	draw_circle(at, ICON * 0.72, Color(Palette.OUTLINE.r, Palette.OUTLINE.g, Palette.OUTLINE.b,
			0.72))
	draw_arc(at, ICON * 0.72, 0.0, TAU, 28, colour, 2.0)
	_draw_chevron(at + direction * ICON * 0.95, direction.angle(), colour)

	# The thing itself, so the arrow says *what* rather than *something*. Scaled to fit the
	# badge with its aspect kept: these are authored at world scale and a square box squashes a
	# fire engine into something unrecognisable, which defeats the whole cue.
	var picture := _icon_for(def.look)
	if not picture.is_empty():
		# The size comes from the region table rather than from the texture, so the badge's own
		# fit is arithmetic that needs nothing loaded; the region itself is the one thing here
		# that does, and the `events` page is held for the whole process from either boot's own
		# loading window (`main.RESIDENT_GROUPS`), so it is there in the building as in the city.
		var name := StringName(picture)
		var art := Vector2(AtlasLibrary.native_size(name))
		var fit := ICON / maxf(art.x, art.y)
		var drawn := art * fit
		var rect := Rect2(at - drawn * 0.5, drawn)
		draw_texture_rect(AtlasLibrary.region(name), rect, false)
		# A vehicle's wheels are a picture of their own on the same canvas, so they fit the same
		# rectangle and go over the body the way the street draws them.
		var wheels := EventInstance.icon_wheels_for(def.look)
		if not wheels.is_empty():
			draw_texture_rect(AtlasLibrary.region(StringName(wheels)), rect, false)

	var label := Texts.DISTANCE_METRES % roundi(distance / Tuning.TILE_SIZE * 1.5)
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var text_at := at + Vector2(-width * 0.5, ICON * 0.72 + 16.0)
	draw_string(font, text_at + Vector2.ONE, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
			Palette.OUTLINE)
	draw_string(font, text_at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, colour)

## The silhouette that stands for a kind of event at icon size, as the picture's own repository
## path — `""` for a look with nothing to draw. The badge reads it as a region of the same baked
## `events` page the entity itself draws from, so the thing at the screen edge and the thing in the
## street are the same pixels rather than two loads of one file.
##
## **The table lives on `EventInstance`, not here.** A `match` of its own is one table too many for
## a rule that says *the entity carries its own picture*, and it goes wrong the way a second copy
## does: a category row returns the generic van, so the badge for a fire engine, an army truck and
## the unmarked van that takes the baby is a picture of a delivery van. An arrow that says the wrong
## thing is worse than an arrow that can only say "something".
func _icon_for(look: EventDef.Look) -> String:
	return EventInstance.icon_for(look)

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

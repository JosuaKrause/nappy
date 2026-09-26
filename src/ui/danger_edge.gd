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
## `instances() -> Array[EventInstance]`, which `EventManager` answers in the city and
## `InteriorEvents` answers in the building — so the masked man coming up a stairwell is
## announced exactly the way a fire engine coming down a street is. See `setup()`.
##
## **And a warning can be up before its thing exists.** A source that also answers
## `pending_warnings() -> Array[PendingWarning]` — `EventManager` does — has things on their way
## that are not in the world yet: a cyclist, a loose dog, the fire engine, day 13's column. Each
## gets its badge from the moment its warning goes up, pointing at the place it will come from, for
## as long as the warning runs (`PendingWarning`). *(PLAYTEST-145: "the warning appears by itself
## with a reasonable position and when the time is right the object is spawned in at that location
## just offscreen.")* Nothing about it is measured: the warning is the claim that it is coming.

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
const MOST_AT_ONCE := 3

## How fast something has to be closing before it is worth an arrow, in px/s — **its own
## approach, with the player held still.** Anything slower she can simply walk away from, which
## is the same line `required_telegraph_time()` draws.
##
## **Not the rate the *gap* is shrinking.** That is her speed plus its speed, and she walks at 92
## against a threshold of 20 — so walking towards anything lethal raises its badge whether or not
## the thing is coming, and *"they show events far away"*, *"they disappear when you walk towards
## them"* and *"they flicker"* all fall out of that one line. Her own velocity is hers to control
## and does not need announcing at the edge of the screen.
const CLOSING_SPEED := 20.0
## The range cap, stated as time rather than as pixels: something is announced once it would
## reach her within this many seconds at its current approach.
##
## A distance would have to be wrong for something — a badge at 900px is scenery with a number
## on it for a dog, and is exactly what the cue exists for when it is a fire engine. Stated as a
## window it scales itself: at `fire_truck`'s 190px/s this is most of the stream radius, at a
## cyclist's pace about half of it, and a 60px/s mover has to be within 300px. It is the same
## quantity the fairness contract is written in — how long she has to get out of the way.
const LEAD_TIME := 5.0
## Once raised, a badge stays up this long after its condition lapses. The test is a derivative
## against a threshold, and anything hovering near the threshold toggles every frame without a
## hysteresis.
const HOLD := 0.8
## How fast the measured approach follows the raw frame-to-frame one, per second. A single
## frame's difference is mostly noise at these distances; this is the same smoothing the badge
## would otherwise need three of.
const SMOOTHING := 6.0
## How far outside the view something has to be before it is worth a badge, in screen px. A
## thing sitting on the boundary would otherwise trade places with its own badge every frame:
## off screen, badge up, badge draws it back into mind, on screen, badge gone. Once one is up it
## is kept until the thing is properly in view, which is the same hysteresis `HOLD` gives the
## closing test and for the same reason.
const SCREEN_MARGIN := 130.0

## Whether `main` has decided a portrait touch window is presenting rotated. Set from outside —
## see `TouchControls.rotated`'s own doc. This control is pinned to `ScreenOrientation.DESIGN_SIZE`
## regardless of rotation (see `main._add_danger_edge()`), so a raw canvas-space position has to
## come back through `ScreenOrientation.to_design_space()` before it is usable as a local
## coordinate here.
var rotated := false

## The event source — see `setup()`.
var _events: Node
var _player: Node2D
## Per live instance: where it was last frame, its smoothed approach speed, how long its badge is
## still owed, and the generation it was last touched on. Keyed by instance id and mutated in
## place — see `_measure()` — so an event that streams out drops out of this the frame after it
## stops appearing in `_events.instances()`, rather than every entry being torn down and rebuilt
## fresh regardless of whether anything about it changed.
var _watch := {}
## Bumped once per `_measure()` call, so a stale entry (an id `_events.instances()` no longer
## carries) can be told apart from one just touched this frame without a second Dictionary built
## purely to remember who was seen.
var _watch_generation := 0
## What `_draw` should put on the edge this frame, soonest arrival first:
## `[time_to_reach, distance, def, world position, approach]`.
var _coming: Array = []

## `events` is anything that answers `instances() -> Array[EventInstance]`: `EventManager` on a
## day and in the escape's city, `InteriorEvents` in the escape's building. **Called again when the
## escape walks out of the service door**, with the city's source in place of the building's, so
## one badge serves both sections; an id the new source no longer carries simply drops out of
## `_watch` on the next `_measure()`.
func setup(events: Node, player: Node2D) -> void:
	_events = events
	_player = player

## The live instances, typed — the event source is duck-typed (see `setup()`), so its answer is
## read through here rather than at every loop, which is what keeps each loop variable an
## `EventInstance` to the analyser.
func _live() -> Array[EventInstance]:
	return _events.instances()

## The warnings that are up for something not in the world yet, or none for a source that has no
## such thing (`InteriorEvents`).
func _warnings() -> Array[PendingWarning]:
	if not _events.has_method("pending_warnings"):
		return []
	return _events.pending_warnings()

func _process(delta: float) -> void:
	_measure(delta)
	# The camera moves under it every frame, so it redraws every frame — a handful of chevrons.
	queue_redraw()

## Works out what is actually coming at her, once per frame.
##
## Deliberately not in `_draw()`, where it used to be: this is a measurement over time and
## `_draw` is a function that may be called for reasons that have nothing to do with a frame
## elapsing. Everything below the line is drawing.
func _measure(delta: float) -> void:
	_coming.clear()
	if not _events or not _player or delta <= 0.0:
		return
	var here := _player.global_position
	_watch_generation += 1

	for instance in _live():
		if instance.is_finished:
			continue
		var id := instance.get_instance_id()
		var at := instance.global_position
		var state: Dictionary
		if _watch.has(id):
			state = _watch[id]
		else:
			# **A thing that arrives under its own warning keeps the badge it already had.** It is
			# created just off screen by its notice, inside `SCREEN_MARGIN`, where a fresh thing
			# would not raise one; and it starts with no measured approach. Without this its badge
			# would go down the frame it exists and stay down until it came into view — the one
			# stretch of its approach the warning was for. So it starts closing at its own speed,
			# already raised, and the margin waits until it has been seen once.
			var warned := instance.came_under_a_warning
			state = {"was": at, "approach": instance.def.speed if warned else 0.0,
					"hold": HOLD if warned else 0.0, "seen": not warned}
			_watch[id] = state
		# The event's own approach: how much closer *it* got to where she is standing now. Both
		# distances are measured to the same point, so her own walking cancels out of it.
		var raw := approach_speed(state["was"], at, here, delta)
		var approach: float = lerpf(state["approach"], raw, clampf(delta * SMOOTHING, 0.0, 1.0))
		var distance := at.distance_to(here)
		# The gap to its *field*, not to its centre: an event reaches her when its outer radius
		# does, and for a fire engine that is a third of a block earlier.
		var gap := maxf(0.0, distance - instance.def.outer_radius)
		var hold: float = state["hold"]
		# The margin is hysteresis on the *screen edge*, and it is the other half of the flicker:
		# without it a thing hovering on the boundary trades places with its own badge every
		# frame. It has to be well outside the view to raise one, and keeps it until it is
		# properly in view.
		if is_on_screen(at):
			state["seen"] = true
		var margin: float = SCREEN_MARGIN if state["seen"] else 0.0
		if _is_worth_an_arrow(instance) and announces(approach, gap) \
				and not is_on_screen(at, margin):
			hold = HOLD
		else:
			hold = maxf(0.0, hold - delta)
		# Mutated in place rather than replaced — `state` is the same `Dictionary` `_watch[id]`
		# already holds, so this is the only write this entry needs this frame.
		state["was"] = at
		state["approach"] = approach
		state["hold"] = hold
		state["generation"] = _watch_generation
		# Coming on screen is not a lapse in the condition to be held through — it is the badge's
		# job being done by the thing itself — so it is filtered here, after the hold and not
		# inside it.
		if hold > 0.0 and not is_on_screen(at):
			# Sorted by *when it arrives* rather than by how near it is, because that is what
			# `MOST_AT_ONCE` is choosing between: three badges is a warning and the one worth
			# keeping is the one that gets here first, which a slow thing standing closer is not.
			_coming.append([gap / maxf(approach, 1.0), distance, instance.def, at, approach])
	# A warning with nothing in the world yet is announced for the whole of its warning, on screen
	# or off: it points at where the thing will come from, and there is nothing there to see yet.
	# Sorted by when the thing will exist, which is the soonest it can arrive.
	for warning in _warnings():
		if warning.place == Vector2.INF or not _is_worth_an_arrow_for(warning.def):
			continue
		_coming.append([maxf(warning.left, 0.0), warning.place.distance_to(here), warning.def,
				warning.place, warning.def.speed])
	# Only the instances alive this frame carry state forward. An id the event source no
	# longer carries was never touched above, so its `generation` still reads an earlier one and
	# is erased here — which is also what keeps a freshly streamed event from flashing an arrow on
	# the frame it appears: it has no `was` but its own, the same as when `_watch` used to be
	# rebuilt whole every frame.
	for id in _watch.keys():
		if _watch[id]["generation"] != _watch_generation:
			_watch.erase(id)
	_coming.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])

## How fast something at `was`, now at `now`, is closing on a player standing at `player`.
##
## Static and takes one player position on purpose: passing the same point for both distances is
## what "with the player held still" *means*, and it is the whole of the rule above.
static func approach_speed(was: Vector2, now: Vector2, player: Vector2, delta: float) -> float:
	if delta <= 0.0:
		return 0.0
	return (was.distance_to(player) - now.distance_to(player)) / delta

## Whether something closing at `approach` px/s with `gap` px of clear ground left is worth
## announcing. Pulled out so a test can ask the question without a viewport.
static func announces(approach: float, gap: float) -> bool:
	return approach >= CLOSING_SPEED and gap <= approach * LEAD_TIME

## Whether something is in view, optionally counting a band `margin` px beyond the edge as in
## view as well. In screen pixels, because that is the question — the world is drawn scaled.
##
## Public because it is the one rotation-aware "is this world point on screen" test the game
## has: `ResistanceDirector.set_sight()` is wired to it from `main` rather than growing a
## second one, since a chalk mark asks exactly this question of itself every frame it is
## unseen.
func is_on_screen(world_position: Vector2, margin: float = 0.0) -> bool:
	var at := ScreenOrientation.to_design_space(
			get_viewport().get_canvas_transform() * world_position, rotated)
	return Rect2(Vector2.ZERO, size).grow(margin).has_point(at)

## What is on the edge of the screen right now: `{id, distance, approach}` per badge, nearest
## arrival first. For the telemetry observer, which has to be able to say what she was warned
## about and whether she then did anything about it, which nothing else in the log can say.
func announcing() -> Array[Dictionary]:
	var badges: Array[Dictionary] = []
	for i in mini(MOST_AT_ONCE, _coming.size()):
		badges.append({
			"id": (_coming[i][2] as EventDef).id,
			"distance": float(_coming[i][1]),
			"approach": float(_coming[i][4]),
		})
	return badges

func _draw() -> void:
	if not _events or not _player:
		return
	var transform := get_viewport().get_canvas_transform()
	for i in mini(MOST_AT_ONCE, _coming.size()):
		_draw_arrow(_coming[i][2] as EventDef, _coming[i][3] as Vector2, float(_coming[i][1]),
				transform)

## Whether something off-screen deserves an arrow.
##
## Lethal always, and otherwise only what she cannot outwalk: an event slower than a walk is one
## she can turn round and leave, and it does not need to be announced from three streets away.
## This is the same line the telegraph contract draws when it decides whether the escape
## distance is the falloff band or the whole radius.
func _is_worth_an_arrow(instance: EventInstance) -> bool:
	return _is_worth_an_arrow_for(instance.def)

## `_is_worth_an_arrow()` asked of a row rather than of a live instance, which is all it reads —
## and all a warning with nothing in the world yet has to ask it about.
func _is_worth_an_arrow_for(def: EventDef) -> bool:
	# If there is no silhouette to put in the badge there is nothing to *say*, and an arrow that
	# only says "something" is an anxiety rather than a warning. Nothing lethal or fast is
	# currently in that position, and this is here so that adding one is a decision.
	if _icon_for(def.look).is_empty():
		return false
	# An `AHEAD_OF_PLAYER` crossing is sited across her line by the director, a fixed lead ahead of
	# her, and its entire content is *the moment it happens to you* — three seconds of cat is not
	# a place. Announcing it from the edge of the screen before it arrives gives a badge that
	# appears and vanishes in the same second as the thing walks into view — and takes away the
	# moment, which is the whole row. Its fairness is paid in geometry.
	#
	# **A pursuer is the exception, because it is no longer a moment once it is sited off screen.**
	# `charging_dog` carries `spawn_mode == AHEAD_OF_PLAYER` for the same siting the director gives
	# every other crossing row, but `EventDirector` now sites it outside the view and lets it close
	# in — so for as long as it is off screen it is exactly the thing this function exists to
	# announce, and the moment it crosses into view the ordinary "no badge for what is already
	# visible" filter in `_measure()` takes over. A row sited close and gone in three seconds still
	# has nothing to announce; a row sited off screen and coming does.
	#
	# **`TOWARD_PLAYER` is the opposite case and falls through on purpose.** It is a road, not an
	# ambush — she is meant to see it coming and choose a side or a turn before it arrives — so the
	# badge is exactly the warning the row is designed around rather than a spoiler of it.
	if def.spawn_mode == EventDef.SpawnMode.AHEAD_OF_PLAYER and not def.pursues:
		return false
	if def.hard_fail:
		return true
	return def.mobile and def.speed > Tuning.WALK_SPEED

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

	var label := "%d m" % roundi(distance / Tuning.TILE_SIZE * 1.5)
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

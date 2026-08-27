class_name DangerEdge
extends Control
## What is coming, drawn at the edge of the screen while it is still off it.
##
## M22, and playtest 02's finding 8 is only half of why it exists. The other half is a gap the
## rings never covered and could not: `fire_truck` (190px/s, 340px radius) and `military_convoy`
## are both *designed* around a long telegraph that the player spends getting off that street —
## and a ring is only useful once it is on screen, which at 190px/s is most of the warning gone.
## The fairness contract was being met by the geometry and missed by the player.
##
## Two rules it is built to, both from the standing decision in `CLAUDE.md`:
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

## How fast something has to be closing before it is worth an arrow, in px/s. Anything slower
## she can simply walk away from, which is the same line `required_telegraph_time()` draws.
const CLOSING_SPEED := 20.0

var _events: EventManager
var _player: Node2D
## Distance to each instance last frame, so "closing" is measured rather than guessed at from a
## heading. An event on a path that curves away is not closing, whatever it is pointing at.
var _was := {}

func setup(events: EventManager, player: Node2D) -> void:
	_events = events
	_player = player

func _process(_delta: float) -> void:
	# The camera moves under it every frame, so it redraws every frame — a handful of chevrons.
	queue_redraw()

func _draw() -> void:
	if not _events or not _player:
		return
	var transform := get_viewport().get_canvas_transform()
	var on_screen := Rect2(Vector2.ZERO, size)
	var here := _player.global_position

	var coming: Array = []
	var seen := {}
	for instance in _events.instances():
		if instance.is_finished or instance.def.city_wide:
			continue
		var distance := instance.global_position.distance_to(here)
		var previous: float = _was.get(instance.get_instance_id(), distance)
		seen[instance.get_instance_id()] = distance
		if not _is_worth_an_arrow(instance):
			continue
		if on_screen.has_point(transform * instance.global_position):
			continue
		# Closing, measured. A siren going the other way is not this cue's business.
		var delta_frame := get_process_delta_time()
		if delta_frame <= 0.0 or (previous - distance) / delta_frame < CLOSING_SPEED:
			continue
		coming.append([distance, instance])
	# Only the ones that have been alive long enough to have a previous distance survive the
	# check above, which is what keeps a freshly streamed event from flashing an arrow on the
	# frame it appears.
	_was = seen

	coming.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for i in mini(MOST_AT_ONCE, coming.size()):
		_draw_arrow(coming[i][1] as EventInstance, float(coming[i][0]), transform)

## Whether something off-screen deserves an arrow.
##
## Lethal always, and otherwise only what she cannot outwalk: an event slower than a walk is one
## she can turn round and leave, and it does not need to be announced from three streets away.
## This is the same line the telegraph contract draws when it decides whether the escape
## distance is the falloff band or the whole radius.
func _is_worth_an_arrow(instance: EventInstance) -> bool:
	# If there is no silhouette to put in the badge there is nothing to *say*, and an arrow that
	# only says "something" is an anxiety rather than a warning. Nothing lethal or fast is
	# currently in that position, and this is here so that adding one is a decision.
	if _icon_for(instance.def.look) == null:
		return false
	if instance.def.hard_fail:
		return true
	return instance.def.mobile and instance.def.speed > Tuning.WALK_SPEED

func _draw_arrow(instance: EventInstance, distance: float, transform: Transform2D) -> void:
	var centre := size * 0.5
	var offset: Vector2 = transform * instance.global_position - centre
	if offset.length() < 1.0:
		return
	var bounds := Rect2(MARGIN.x, MARGIN.y,
			size.x - MARGIN.x - MARGIN.z, size.y - MARGIN.y - MARGIN.w)
	var direction := offset.normalized()
	var at := centre + direction * _distance_to_edge(bounds, centre, direction)

	var colour := Palette.MARK_LETHAL if instance.def.hard_fail else Palette.MARK_ACTIVE
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
	var texture := _icon_for(instance.def.look)
	if texture:
		var art := texture.get_size()
		var fit := ICON / maxf(art.x, art.y)
		var drawn := art * fit
		draw_texture_rect(texture, Rect2(at - drawn * 0.5, drawn), false)

	var label := "%d m" % roundi(distance / Tuning.TILE_SIZE * 1.5)
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var text_at := at + Vector2(-width * 0.5, ICON * 0.72 + 16.0)
	draw_string(font, text_at + Vector2.ONE, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
			Palette.OUTLINE)
	draw_string(font, text_at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, colour)

## The silhouette that stands for a kind of event at icon size. `NONE` and `TABLES` never reach
## here — neither is mobile and neither is lethal — but the fallback keeps the arrow drawable if
## one ever becomes so.
func _icon_for(look: EventDef.Look) -> Texture2D:
	match look:
		EventDef.Look.VEHICLE:
			return EventInstance.VEHICLE
		EventDef.Look.ANIMAL:
			return EventInstance.CAT_RUNNING
		EventDef.Look.FIRE:
			return EventInstance.FLAME
		EventDef.Look.PERSON, EventDef.Look.DOG_WALKER:
			return EventInstance.PERSON
		# M31. Every one of these is here because it is lethal or faster than a walk, which is
		# the only reason a look ever needs a badge — and without an entry the badge silently
		# refuses to draw, which is the rule two lines up working as intended and would have
		# left act I's first lethal event announcing nothing.
		EventDef.Look.CYCLIST:
			return EventInstance.CYCLIST
		EventDef.Look.LOOSE_DOG:
			return EventInstance.DOG
		EventDef.Look.LORRY:
			return EventInstance.LORRY
		EventDef.Look.ICE_CREAM_VAN:
			return EventInstance.ICE_CREAM_VAN
		_:
			return null

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

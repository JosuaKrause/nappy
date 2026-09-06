class_name MeterBar
extends Control
## One labelled 0-100 bar with optional threshold markers.

const BAR_TOP := 18.0
const BAR_HEIGHT := 17.0

@export var label := "METER":
	set(value):
		label = value
		queue_redraw()
@export var fill_colour := Color("6f8fd0"):
	set(value):
		fill_colour = value
		queue_redraw()
## Colour the fill lerps toward as the bar approaches full. Leave equal to `fill_colour`
## for a bar whose colour should not change.
@export var full_colour := Color("6f8fd0"):
	set(value):
		full_colour = value
		queue_redraw()
## Threshold positions in meter units (0-100) drawn as ticks across the bar.
@export var markers: Array[float] = []:
	set(value):
		markers = value
		queue_redraw()

var value := 0.0:
	set(new_value):
		var clamped := clampf(new_value, 0.0, Tuning.METER_MAX)
		if is_equal_approx(clamped, value):
			return
		value = clamped
		queue_redraw()

const _BACKGROUND := Color(0.03, 0.07, 0.1, 0.72)
const _BORDER := Color(0.95, 0.91, 0.84, 0.34)
const _MARKER := Color(0.95, 0.91, 0.84, 0.65)
const _TEXT := Color(0.95, 0.91, 0.84, 0.92)
const _TRACK_EDGE := Color(0.95, 0.91, 0.84, 0.12)

func _draw() -> void:
	var width := size.x
	var bar := Rect2(0.0, BAR_TOP, width, BAR_HEIGHT)
	var fraction := value / Tuning.METER_MAX

	# Two inset strokes make the track read as a designed instrument without competing with the
	# world. The outer edge remains square so the meter stays legible at the fixed viewport scale.
	draw_rect(bar, _BACKGROUND)
	draw_rect(Rect2(bar.position + Vector2(2.0, 2.0), Vector2(maxf(0.0, width - 4.0), 2.0)),
			_TRACK_EDGE)
	draw_rect(Rect2(bar.position + Vector2(2.0, 3.0),
			Vector2(maxf(0.0, (width - 4.0) * fraction), BAR_HEIGHT - 6.0)),
			fill_colour.lerp(full_colour, fraction))

	for marker in markers:
		var x := width * (marker / Tuning.METER_MAX)
		draw_line(Vector2(x, BAR_TOP - 2.0), Vector2(x, BAR_TOP + BAR_HEIGHT + 2.0), _MARKER, 1.5)

	draw_rect(bar, _BORDER, false, 1.0)

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(2.0, 12.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, _TEXT)
	draw_string(font, Vector2(width - 34.0, 12.0), "%3.0f" % value,
			HORIZONTAL_ALIGNMENT_RIGHT, 32, 11, _TEXT)

class_name MeterBar
extends Control
## One labelled 0-100 bar with optional threshold markers.

const BAR_TOP := 15.0
const BAR_HEIGHT := 16.0

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

const _BACKGROUND := Color(0.06, 0.06, 0.09, 0.72)
const _BORDER := Color(1, 1, 1, 0.28)
const _MARKER := Color(1, 1, 1, 0.55)
const _TEXT := Color(1, 1, 1, 0.85)

func _draw() -> void:
	var width := size.x
	var bar := Rect2(0.0, BAR_TOP, width, BAR_HEIGHT)
	var fraction := value / Tuning.METER_MAX

	draw_rect(bar, _BACKGROUND)
	draw_rect(Rect2(bar.position, Vector2(width * fraction, BAR_HEIGHT)),
			fill_colour.lerp(full_colour, fraction))

	for marker in markers:
		var x := width * (marker / Tuning.METER_MAX)
		draw_line(Vector2(x, BAR_TOP - 2.0), Vector2(x, BAR_TOP + BAR_HEIGHT + 2.0), _MARKER, 1.5)

	draw_rect(bar, _BORDER, false, 1.0)

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(1.0, 11.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, _TEXT)
	draw_string(font, Vector2(width - 32.0, 11.0), "%3.0f" % value,
			HORIZONTAL_ALIGNMENT_RIGHT, 30, 11, _TEXT)

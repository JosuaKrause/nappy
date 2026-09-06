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

## The most the bar may look full before `value` genuinely is: at 99.7 the fill was drawn 99.7% of
## the width, a sliver no eye can tell from solid, so a bar could *look* done on a day that was
## still live. Capped rather than reworked, the same floor the printed number gets below — the bar
## and the number now agree that "looks/reads full" and "is full" are the same claim.
const _MAX_FILL_BEFORE_FULL := 0.99

## The number this bar actually prints. Floored, not rounded: `"%3.0f" % value` rounds to nearest,
## so 99.5 and everything above it already read `100` while the day was still live — the day ends
## only at exactly `max_value`, never at "close enough". Pulled out to a pure function because
## nothing in this project screenshots a meter and reads the number back, so this is the part a
## test can hold instead of the drawing nothing here can see.
static func displayed_value(value: float) -> int:
	return int(floorf(value))

## The fraction of the bar's width the fill may draw, held at `_MAX_FILL_BEFORE_FULL` until `value`
## genuinely reaches `max_value` — see that constant's own doc for why a bar that merely looks full
## is the same lie the printed number told, just quieter.
static func displayed_fraction(value: float, max_value: float) -> float:
	var fraction := value / max_value
	if value < max_value:
		fraction = minf(fraction, _MAX_FILL_BEFORE_FULL)
	return fraction

func _draw() -> void:
	var width := size.x
	var bar := Rect2(0.0, BAR_TOP, width, BAR_HEIGHT)
	var fraction := displayed_fraction(value, Tuning.METER_MAX)

	draw_rect(bar, _BACKGROUND)
	draw_rect(Rect2(bar.position, Vector2(width * fraction, BAR_HEIGHT)),
			fill_colour.lerp(full_colour, fraction))

	for marker in markers:
		var x := width * (marker / Tuning.METER_MAX)
		draw_line(Vector2(x, BAR_TOP - 2.0), Vector2(x, BAR_TOP + BAR_HEIGHT + 2.0), _MARKER, 1.5)

	draw_rect(bar, _BORDER, false, 1.0)

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(1.0, 11.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, _TEXT)
	draw_string(font, Vector2(width - 32.0, 11.0), "%3.0f" % displayed_value(value),
			HORIZONTAL_ALIGNMENT_RIGHT, 30, 11, _TEXT)

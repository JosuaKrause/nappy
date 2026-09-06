class_name ScreenArt
extends Control
## Quiet architectural marks that make each screen feel like part of the same city.
##
## This is deliberately not a replacement city. The title and pause layers leave the live street
## visible; this control supplies a paper rule, window rhythm and a small stroller-shaped motif so
## the typography has an authored edge without pretending to be the world renderer.

enum Variant { TITLE, PAUSE, SUMMARY, ENDING_GOOD, ENDING_NEUTRAL, ENDING_BAD }

@export var variant := Variant.TITLE
@export var animated := true

var _age := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(animated)
	queue_redraw()

func _process(delta: float) -> void:
	_age += delta
	queue_redraw()

func _draw() -> void:
	var size := get_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		return
	match variant:
		Variant.TITLE:
			_draw_title(size)
		Variant.PAUSE:
			_draw_pause(size)
		Variant.SUMMARY:
			_draw_summary(size, PresentationTheme.OCHRE)
		Variant.ENDING_GOOD:
			_draw_summary(size, Color("82a58b"))
		Variant.ENDING_NEUTRAL:
			_draw_summary(size, Color("9aa7aa"))
		Variant.ENDING_BAD:
			_draw_summary(size, PresentationTheme.RUST)

func _draw_title(size: Vector2) -> void:
	var left := size.x * 0.075
	var right := size.x * 0.68
	var top := size.y * 0.12
	_draw_rule(Vector2(left, top), Vector2(right, top), PresentationTheme.RUST_LIGHT, 2.0)
	_draw_rule(Vector2(left, top + 14.0), Vector2(left + 96.0, top + 14.0), PresentationTheme.PAPER, 1.0)
	_draw_windows(Rect2(size.x * 0.73, size.y * 0.12, size.x * 0.2, size.y * 0.36), 5, 3,
			Color(0.94, 0.85, 0.67, 0.17))
	_draw_stroller(Vector2(size.x * 0.81, size.y * 0.69), 1.12, PresentationTheme.RUST_LIGHT)
	_draw_rule(Vector2(size.x * 0.72, size.y * 0.88), Vector2(size.x * 0.93, size.y * 0.88),
			PresentationTheme.PAPER, 1.0)

func _draw_pause(size: Vector2) -> void:
	var x := size.x * 0.56
	_draw_rule(Vector2(x, size.y * 0.16), Vector2(size.x * 0.92, size.y * 0.16), PresentationTheme.RUST_LIGHT, 2.0)
	_draw_rule(Vector2(x, size.y * 0.84), Vector2(size.x * 0.92, size.y * 0.84), PresentationTheme.PAPER, 1.0)
	_draw_windows(Rect2(size.x * 0.06, size.y * 0.19, size.x * 0.35, size.y * 0.5), 4, 5,
			Color(0.94, 0.85, 0.67, 0.1))
	_draw_stroller(Vector2(size.x * 0.23, size.y * 0.78), 0.76, Color(0.82, 0.76, 0.66, 0.38))

func _draw_summary(size: Vector2, accent: Color) -> void:
	var left := size.x * 0.075
	var bottom := size.y * 0.86
	_draw_rule(Vector2(left, size.y * 0.12), Vector2(left + 180.0, size.y * 0.12), accent, 3.0)
	_draw_rule(Vector2(left, bottom), Vector2(size.x * 0.92, bottom), PresentationTheme.PAPER, 1.0)
	_draw_windows(Rect2(size.x * 0.72, size.y * 0.2, size.x * 0.2, size.y * 0.45), 4, 4,
			Color(accent, 0.16))
	_draw_stroller(Vector2(size.x * 0.82, size.y * 0.75), 0.92, Color(accent, 0.78))

func _draw_rule(from: Vector2, to: Vector2, colour: Color, width: float) -> void:
	draw_line(from, to, colour, width, true)

func _draw_windows(rect: Rect2, columns: int, rows: int, colour: Color) -> void:
	var gap := 10.0
	var cell := Vector2((rect.size.x - gap * float(columns - 1)) / float(columns),
			(rect.size.y - gap * float(rows - 1)) / float(rows))
	for row in rows:
		for column in columns:
			var at := rect.position + Vector2(float(column) * (cell.x + gap), float(row) * (cell.y + gap))
			var shimmer := 0.92 + sin(_age * 0.7 + float(row * columns + column)) * 0.08
			draw_rect(Rect2(at, cell), Color(colour, colour.a * shimmer), false, 1.0)

func _draw_stroller(at: Vector2, scale_factor: float, colour: Color) -> void:
	var sway := sin(_age * 0.8) * 1.5 if animated else 0.0
	var body := Rect2(at + Vector2(-29.0, -24.0) * scale_factor, Vector2(54.0, 17.0) * scale_factor)
	draw_arc(at + Vector2(-2.0, -8.0) * scale_factor, 28.0 * scale_factor, PI, TAU, 18, colour, 3.0 * scale_factor, true)
	draw_line(at + Vector2(26.0, -17.0) * scale_factor, at + Vector2(41.0, -45.0 + sway) * scale_factor,
			colour, 3.0 * scale_factor, true)
	draw_rect(body, colour, false, 2.0 * scale_factor)
	for wheel_x in [-18.0, 20.0]:
		draw_circle(at + Vector2(wheel_x, 1.0) * scale_factor, 7.0 * scale_factor, colour, false, 2.0 * scale_factor)

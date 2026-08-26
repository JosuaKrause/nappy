class_name HomeArrow
extends Control
## Points the way home while the baby is asleep.
##
## Only ever shown during the return phase. The rest of the game is about knowing the city;
## this is about not losing a won day to a wrong turn while carrying a sleeping baby, which
## is a different and much less interesting kind of failure.

## How far in from the screen edge the arrow sits when home is off-screen.
const MARGIN := 74.0
const SIZE := 15.0

var target := Vector2.INF
var active := false

func show_toward(world_position: Vector2) -> void:
	target = world_position
	active = true

func hide_arrow() -> void:
	active = false
	queue_redraw()

func _process(_delta: float) -> void:
	if active:
		# The camera moves under it every frame, so the arrow has to be redrawn every frame.
		queue_redraw()

func _draw() -> void:
	if not active or target == Vector2.INF:
		return

	var on_screen: Vector2 = get_viewport().get_canvas_transform() * target
	var centre := size * 0.5
	var offset := on_screen - centre
	if offset.length() < 1.0:
		return

	var bounds := Rect2(Vector2.ONE * MARGIN, size - Vector2.ONE * MARGIN * 2.0)
	var at := on_screen
	var pointing := bounds.has_point(on_screen)
	if not pointing:
		# Off-screen: pin the arrow to the edge of the safe area, still pointing at home.
		at = centre + offset.normalized() * _distance_to_edge(bounds, centre, offset.normalized())

	var angle := offset.angle()
	_draw_chevron(at, angle)
	var label := "home" if pointing else "%d m" % roundi(_metres_to_home())
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(font, at + Vector2(-width * 0.5, SIZE + 15.0), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.HOME_ARROW)

func _draw_chevron(at: Vector2, angle: float) -> void:
	var points := PackedVector2Array([
		Vector2(SIZE, 0.0), Vector2(-SIZE * 0.7, SIZE * 0.8),
		Vector2(-SIZE * 0.25, 0.0), Vector2(-SIZE * 0.7, -SIZE * 0.8),
	])
	for i in points.size():
		points[i] = at + points[i].rotated(angle)
	draw_colored_polygon(points, Palette.HOME_ARROW)
	draw_polyline(points + PackedVector2Array([points[0]]), Palette.OUTLINE, 1.5)

## Distance from `centre` to where a ray leaves `bounds`.
func _distance_to_edge(bounds: Rect2, centre: Vector2, direction: Vector2) -> float:
	var best := INF
	if not is_zero_approx(direction.x):
		var edge_x: float = bounds.end.x if direction.x > 0.0 else bounds.position.x
		best = minf(best, (edge_x - centre.x) / direction.x)
	if not is_zero_approx(direction.y):
		var edge_y: float = bounds.end.y if direction.y > 0.0 else bounds.position.y
		best = minf(best, (edge_y - centre.y) / direction.y)
	return maxf(best, 0.0)

func _metres_to_home() -> float:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return 0.0
	# One tile reads as about a metre and a half of pavement.
	return player.global_position.distance_to(target) / Tuning.TILE_SIZE * 1.5

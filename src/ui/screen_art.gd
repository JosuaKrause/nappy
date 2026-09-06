class_name ScreenArt
extends Control
## Quiet illustrated linework that gives the screen furniture a shared sense of place.
##
## This is deliberately decorative: it never names a danger, points to a destination or carries
## input. The city and the pram remain the game's readable pictures; this keeps menus from becoming
## generic dark rectangles while leaving the player's route decisions untouched.

@export_enum("title", "pause", "summary") var style := "title"

const INK := Color("172735")
const INK_LIGHT := Color("294052")
const PAPER := Color("f3e8d4")
const TERRACOTTA := Color("c56b54")
const OCHRE := Color("d7a15d")
const SLATE := Color("718697")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	if style == "title":
		_draw_title_city()
	else:
		_draw_card_motif()

func _draw_title_city() -> void:
	var horizon := size.y * 0.72
	# A quiet sun and a thin horizon keep the open side of the title from reading as empty black.
	draw_circle(Vector2(size.x * 0.79, size.y * 0.24), 76.0,
		Color(OCHRE.r, OCHRE.g, OCHRE.b, 0.12))
	draw_circle(Vector2(size.x * 0.79, size.y * 0.24), 58.0,
		Color(OCHRE.r, OCHRE.g, OCHRE.b, 0.10))
	draw_line(Vector2(size.x * 0.57, horizon), Vector2(size.x * 0.96, horizon),
		Color(PAPER, 0.22), 1.0)
	var buildings: Array[Rect2] = [
		Rect2(760.0, horizon - 210.0, 96.0, 210.0),
		Rect2(856.0, horizon - 146.0, 126.0, 146.0),
		Rect2(982.0, horizon - 252.0, 114.0, 252.0),
		Rect2(1096.0, horizon - 178.0, 92.0, 178.0),
	]
	for building: Rect2 in buildings:
		draw_rect(building, Color(INK_LIGHT.r, INK_LIGHT.g, INK_LIGHT.b, 0.54))
		draw_line(building.position, building.position + Vector2(building.size.x, 0.0),
			Color(PAPER.r, PAPER.g, PAPER.b, 0.18), 2.0)
		for row in range(2, int(building.size.y / 34.0)):
			var y := building.position.y + row * 34.0
			for column in range(1, int(building.size.x / 30.0)):
				var x := building.position.x + column * 30.0
				draw_rect(Rect2(x, y, 7.0, 10.0), Color(OCHRE.r, OCHRE.g, OCHRE.b, 0.16))
	# A line-drawn stroller is a visual signature, not a control or a second logo.
	var pram := Vector2(858.0, horizon - 34.0)
	draw_arc(pram + Vector2(-25.0, -20.0), 32.0, PI, TAU, 20,
		Color(PAPER.r, PAPER.g, PAPER.b, 0.42), 3.0)
	draw_line(pram + Vector2(-57.0, -20.0), pram + Vector2(34.0, -20.0),
		Color(PAPER.r, PAPER.g, PAPER.b, 0.42), 4.0)
	draw_line(pram + Vector2(34.0, -20.0), pram + Vector2(58.0, -67.0),
		Color(PAPER.r, PAPER.g, PAPER.b, 0.42), 4.0)
	draw_circle(pram + Vector2(-40.0, 3.0), 9.0,
		Color(TERRACOTTA.r, TERRACOTTA.g, TERRACOTTA.b, 0.9))
	draw_circle(pram + Vector2(20.0, 3.0), 9.0,
		Color(TERRACOTTA.r, TERRACOTTA.g, TERRACOTTA.b, 0.9))
	draw_line(pram + Vector2(-40.0, -5.0), pram + Vector2(20.0, -5.0),
		Color(PAPER.r, PAPER.g, PAPER.b, 0.42), 3.0)

func _draw_card_motif() -> void:
	var centre := Vector2(size.x * 0.5, 92.0)
	var colour := TERRACOTTA if style == "pause" else OCHRE
	draw_line(centre + Vector2(-88.0, 0.0), centre + Vector2(-20.0, 0.0),
		Color(colour.r, colour.g, colour.b, 0.74), 2.0)
	draw_line(centre + Vector2(20.0, 0.0), centre + Vector2(88.0, 0.0),
		Color(colour.r, colour.g, colour.b, 0.74), 2.0)
	draw_circle(centre, 5.0, Color(colour.r, colour.g, colour.b, 0.9))
	if style == "summary":
		for i in range(3):
			var x := centre.x - 30.0 + i * 30.0
			draw_line(Vector2(x, centre.y - 24.0), Vector2(x, centre.y + 24.0),
				Color(SLATE.r, SLATE.g, SLATE.b, 0.5), 2.0)
			draw_line(Vector2(centre.x - 42.0, centre.y + 24.0),
				Vector2(centre.x + 42.0, centre.y + 24.0),
				Color(SLATE.r, SLATE.g, SLATE.b, 0.5), 2.0)

extends Node2D
## Static registration sheet for the current illustrated actor compositors.
##
## This scene deliberately owns no gameplay actor, movement or random state. Each compositor is
## reset once at a known ground point; the legacy SVGs are drawn beside it at the fixed comparison
## offset used by the live illustrated presentation.

const DIRECTIONS: PackedStringArray = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
var headings: Array[Vector2] = [
	Vector2.UP, Vector2(1.0, -1.0).normalized(), Vector2.RIGHT, Vector2(1.0, 1.0).normalized(),
	Vector2.DOWN, Vector2(-1.0, 1.0).normalized(), Vector2.LEFT, Vector2(-1.0, -1.0).normalized(),
]
const COLUMN_X := 70.0
const COLUMN_STEP := 155.0
const MOTHER_Y := 170.0
const MUSTARD_Y := 370.0
const RUST_Y := 570.0
const COMPARISON_OFFSET := ModularPerson.COMPARISON_OFFSET

const LEGACY_MOTHER_FRONT: Array[Texture2D] = [
	preload("res://assets/rig/mother_front_a.svg"), preload("res://assets/rig/mother_front_b.svg")]
const LEGACY_MOTHER_BACK: Array[Texture2D] = [
	preload("res://assets/rig/mother_back_a.svg"), preload("res://assets/rig/mother_back_b.svg")]
const LEGACY_MOTHER_SIDE: Array[Texture2D] = [
	preload("res://assets/rig/mother_side_a.svg"), preload("res://assets/rig/mother_side_b.svg")]
const LEGACY_PRAM_SIDE: Texture2D = preload("res://assets/rig/pram_side.svg")
const LEGACY_PRAM_FRONT: Texture2D = preload("res://assets/rig/pram_front.svg")
const LEGACY_PRAM_BACK: Texture2D = preload("res://assets/rig/pram_back.svg")
const LEGACY_WALKER_BODY: Array[Texture2D] = [
	preload("res://assets/crowd/walker_front_body.svg"), preload("res://assets/crowd/walker_back_body.svg"), preload("res://assets/crowd/walker_side_body.svg")]
const LEGACY_WALKER_TRIM: Array[Texture2D] = [
	preload("res://assets/crowd/walker_front_trim.svg"), preload("res://assets/crowd/walker_back_trim.svg"), preload("res://assets/crowd/walker_side_trim.svg")]

func _ready() -> void:
	_build_sheet()
	var screenshot: AutoScreenshot = AutoScreenshot.from_command_line()
	if screenshot != null:
		add_child(screenshot)

func _build_sheet() -> void:
	for index: int in DIRECTIONS.size():
		var x := COLUMN_X + float(index) * COLUMN_STEP
		_add_label(DIRECTIONS[index], Vector2(x - 30.0, 76.0), 18)
		_add_label("MOTHER + PRAM", Vector2(x - 55.0, MOTHER_Y + 62.0), 11)
		_add_label("MUSTARD WALKER", Vector2(x - 63.0, MUSTARD_Y + 44.0), 10)
		_add_label("RUST WALKER", Vector2(x - 50.0, RUST_Y + 44.0), 10)
		var heading: Vector2 = headings[index]
		var mother := ModularPerson.new()
		mother.name = "Mother_%s" % DIRECTIONS[index]
		mother.position = Vector2(x, MOTHER_Y)
		add_child(mother)
		mother.reset_at(Vector2.ZERO, heading)
		var mustard := ModularWalker.new()
		mustard.name = "Mustard_%s" % DIRECTIONS[index]
		mustard.position = Vector2(x, MUSTARD_Y)
		add_child(mustard)
		mustard.reset_at(Vector2.ZERO, heading)
		var rust := ModularWalker.new()
		rust.name = "Rust_%s" % DIRECTIONS[index]
		rust.set_variant("rust_curls")
		rust.position = Vector2(x, RUST_Y)
		add_child(rust)
		rust.reset_at(Vector2.ZERO, heading)
	queue_redraw()

func _add_label(value: String, at: Vector2, size: int) -> void:
	var label := Label.new()
	label.position = at
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#f3e4c2"))
	label.add_theme_color_override("font_shadow_color", Color(0.03, 0.02, 0.02, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 700.0), Color("#171522"))
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 34.0), "ILLUSTRATED ACTOR REGISTRATION · STATIC EIGHT-FACING REVIEW", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color("#ffe8b5"))
	draw_string(ThemeDB.fallback_font, Vector2(36.0, 58.0), "CURRENT PNG COMPOSITOR  |  LEGACY SVG AT +96 WORLD PX  |  LOGICAL SCALE 1×", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#cfc1a2"))
	for y: float in [MOTHER_Y, MUSTARD_Y, RUST_Y]:
		for index: int in DIRECTIONS.size():
			var x := COLUMN_X + float(index) * COLUMN_STEP
			draw_line(Vector2(x - 60.0, y), Vector2(x + 130.0, y), Color("#806d54"), 1.0)
			draw_line(Vector2(x - 60.0, y + 1.0), Vector2(x + 130.0, y + 1.0), Color(0.35, 0.29, 0.22, 0.35), 1.0)
			draw_string(ThemeDB.fallback_font, Vector2(x - 58.0, y + 18.0), "ground", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, Color("#a99678"))
	for index: int in DIRECTIONS.size():
		var x: float = COLUMN_X + float(index) * COLUMN_STEP
		_draw_legacy_mother(Vector2(x + COMPARISON_OFFSET, MOTHER_Y), headings[index])
		_draw_legacy_walker(Vector2(x + COMPARISON_OFFSET, MUSTARD_Y), headings[index])
		_draw_legacy_walker(Vector2(x + COMPARISON_OFFSET, RUST_Y), headings[index])

func _draw_legacy_mother(at: Vector2, heading: Vector2) -> void:
	var side := absf(heading.x) > absf(heading.y) * 1.15
	var flip: bool = absf(heading.x) > absf(heading.y) * 1.15 and heading.x < 0.0
	var body: Texture2D = LEGACY_MOTHER_SIDE[0] if side else (LEGACY_MOTHER_FRONT[0] if heading.y > 0.0 else LEGACY_MOTHER_BACK[0])
	var pram: Texture2D = LEGACY_PRAM_SIDE if side else (LEGACY_PRAM_FRONT if heading.y > 0.0 else LEGACY_PRAM_BACK)
	Sprites.draw_shadow(self, at, 9.0)
	var pram_at: Vector2 = at + Vector2(heading.x, heading.y * Stroller.OBLIQUE_Y) * Stroller.PRAM_DISTANCE
	if heading.y < 0.0:
		Sprites.draw_standing(self, pram, pram_at, Vector2.ZERO, flip)
		Sprites.draw_standing(self, body, at, Vector2.ZERO, flip)
	else:
		Sprites.draw_standing(self, body, at, Vector2.ZERO, flip)
		Sprites.draw_standing(self, pram, pram_at, Vector2.ZERO, flip)

func _draw_legacy_walker(at: Vector2, heading: Vector2) -> void:
	var side := absf(heading.x) > absf(heading.y) * 1.15
	var frame := 2 if side else (0 if heading.y > 0.0 else 1)
	var flip := side and heading.x < 0.0
	Sprites.draw_shadow(self, at, 7.0)
	Sprites.draw_standing(self, LEGACY_WALKER_BODY[frame], at, Vector2.ZERO, flip)
	Sprites.draw_standing(self, LEGACY_WALKER_TRIM[frame], at, Vector2.ZERO, flip)

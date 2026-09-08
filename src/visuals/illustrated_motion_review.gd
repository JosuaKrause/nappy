extends Node2D
## Reproducible contact sheet for painted limb motion and ground contact.
##
## Each cell owns a compositor whose virtual owner stays at Vector2.ZERO. The compositor is
## advanced only with explicit applied displacement; the cell's Node2D supplies presentation
## placement and never becomes a second movement simulation.

const DIRECTIONS: PackedStringArray = ["S", "SE", "E", "NE", "N", "NW", "W", "SW"]
var headings: Array[Vector2] = [
	Vector2.DOWN, Vector2(1.0, 1.0).normalized(), Vector2.RIGHT,
	Vector2(1.0, -1.0).normalized(), Vector2.UP, Vector2(-1.0, -1.0).normalized(),
	Vector2.LEFT, Vector2(-1.0, 1.0).normalized(),
]
const SAMPLES: PackedStringArray = [
	"IDLE", "INITIAL\nSTRIDE", "MID SWING\nLEFT", "MID SWING\nRIGHT",
	"SUSTAINED\nWALK", "RUN\nHIGH Δ", "BLOCKED /\nSTOP", "REVERSE /\nTURN", "RECYCLE /\nRESET",
]
const CELL_ORIGIN := Vector2(76.0, 112.0)
const CELL_STEP := 132.0
const ROW_Y: Array[float] = [188.0, 374.0, 560.0]
const CELL_WIDTH := 124.0
const SHEET_SIZE := Vector2(1280.0, 720.0)

var _markers: Array[Dictionary] = []
var _virtual_positions: Dictionary = {}

func _ready() -> void:
	_build_sheet()
	queue_redraw()
	var screenshot: AutoScreenshot = AutoScreenshot.from_command_line()
	if screenshot != null:
		add_child(screenshot)

func _build_sheet() -> void:
	for row: int in 3:
		for column: int in SAMPLES.size():
			var actor: Node2D
			var pose: Dictionary
			var heading: Vector2 = headings[column % headings.size()]
			if row == 0:
				var person := ModularPerson.new()
				person.name = "MotionMother_%d_%d" % [row, column]
				actor = person
				pose = _person_sample(person, column, heading)
			else:
				var walker := ModularWalker.new()
				walker.name = "MotionWalker_%d_%d" % [row, column]
				if row == 2:
					walker.set_variant("rust_curls")
				actor = walker
				pose = _walker_sample(walker, column, heading)
			actor.position = _cell_position(row, column)
			add_child(actor)
			_markers.append({"position": actor.position, "pose": pose, "row": row, "column": column})

func _person_sample(actor: ModularPerson, sample: int, heading: Vector2) -> Dictionary:
	actor.reset_at(Vector2.ZERO, heading)
	_virtual_positions[actor] = Vector2.ZERO
	match sample:
		0:
			return actor.last_pose
		1:
			return _advance_person(actor, heading * 8.0, heading)
		2:
			return _find_person_swing(actor, heading, 0)
		3:
			return _find_person_swing(actor, heading, 1)
		4:
			var pose: Dictionary = actor.last_pose
			for _step: int in 16:
				pose = _advance_person(actor, heading * 4.0, heading)
			return pose
		5:
			var run_pose: Dictionary = actor.last_pose
			for _step: int in 14:
				run_pose = _advance_person(actor, heading * 16.0, heading)
			return run_pose
		6:
			_advance_person(actor, heading * 18.0, heading)
			return actor.apply_displacement(Vector2.ZERO, Vector2.ZERO, 0.0, heading)
		7:
			_advance_person(actor, heading * 12.0, heading)
			return _advance_person(actor, -heading * 8.0, -heading)
		8:
			_advance_person(actor, heading * 18.0, heading)
			actor.reset_at(Vector2.ZERO, heading)
			_virtual_positions[actor] = Vector2.ZERO
			return actor.last_pose
	return actor.last_pose

func _walker_sample(actor: ModularWalker, sample: int, heading: Vector2) -> Dictionary:
	actor.reset_at(Vector2.ZERO, heading)
	_virtual_positions[actor] = Vector2.ZERO
	match sample:
		0:
			return actor.last_pose
		1:
			return _advance_walker(actor, heading * 8.0, heading)
		2:
			return _find_walker_swing(actor, heading, 0)
		3:
			return _find_walker_swing(actor, heading, 1)
		4:
			var pose: Dictionary = actor.last_pose
			for _step: int in 16:
				pose = _advance_walker(actor, heading * 4.0, heading)
			return pose
		5:
			var run_pose: Dictionary = actor.last_pose
			for _step: int in 14:
				run_pose = _advance_walker(actor, heading * 16.0, heading)
			return run_pose
		6:
			_advance_walker(actor, heading * 18.0, heading)
			return actor.apply_displacement(Vector2.ZERO, Vector2.ZERO, 0.0, heading)
		7:
			_advance_walker(actor, heading * 12.0, heading)
			return _advance_walker(actor, -heading * 8.0, -heading)
		8:
			_advance_walker(actor, heading * 18.0, heading)
			actor.reset_at(Vector2.ZERO, heading)
			_virtual_positions[actor] = Vector2.ZERO
			return actor.last_pose
	return actor.last_pose

func _find_person_swing(actor: ModularPerson, heading: Vector2, wanted: int) -> Dictionary:
	for _step: int in 80:
		var pose: Dictionary = _advance_person(actor, heading * 2.5, heading)
		if int(pose["swing_foot"]) == wanted and float(pose["step_progress"]) > 0.35 and float(pose["step_progress"]) < 0.65:
			return pose
	push_error("motion review could not find genuine mother swing foot %d" % wanted)
	return actor.last_pose

func _find_walker_swing(actor: ModularWalker, heading: Vector2, wanted: int) -> Dictionary:
	for _step: int in 80:
		var pose: Dictionary = _advance_walker(actor, heading * 2.5, heading)
		if int(pose["swing_foot"]) == wanted and float(pose["step_progress"]) > 0.35 and float(pose["step_progress"]) < 0.65:
			return pose
	push_error("motion review could not find walker swing foot %d" % wanted)
	return actor.last_pose

func _advance_person(actor: ModularPerson, displacement: Vector2, heading: Vector2) -> Dictionary:
	var body_position: Vector2 = _virtual_positions.get(actor, Vector2.ZERO) + displacement
	_virtual_positions[actor] = body_position
	return actor.apply_displacement(displacement, body_position, 0.1, heading)

func _advance_walker(actor: ModularWalker, displacement: Vector2, heading: Vector2) -> Dictionary:
	var body_position: Vector2 = _virtual_positions.get(actor, Vector2.ZERO) + displacement
	_virtual_positions[actor] = body_position
	return actor.apply_displacement(displacement, body_position, 0.1, heading)

func _cell_position(row: int, column: int) -> Vector2:
	return Vector2(CELL_ORIGIN.x + float(column) * CELL_STEP, ROW_Y[row])

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SHEET_SIZE), Color("#171522"))
	draw_string(ThemeDB.fallback_font, Vector2(26.0, 30.0), "ILLUSTRATED LIMB MOTION · APPLIED DISPLACEMENT CONTACT SHEET", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 21, Color("#ffe8b5"))
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 52.0), "Each cell keeps its virtual owner at (0, 0); ticks are solved foot anchors. Swing cells require live gait state.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("#cfc1a2"))
	for column: int in SAMPLES.size():
		var x: float = CELL_ORIGIN.x + float(column) * CELL_STEP
		_add_header(SAMPLES[column], Vector2(x - 50.0, 78.0))
		_add_header(DIRECTIONS[column % DIRECTIONS.size()], Vector2(x - 9.0, 104.0), 11)
	for row: int in 3:
		var row_name := "MOTHER + PRAM" if row == 0 else ("MUSTARD WALKER" if row == 1 else "RUST WALKER")
		draw_string(ThemeDB.fallback_font, Vector2(8.0, ROW_Y[row] - 68.0), row_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color("#e4cda1"))
	for marker: Dictionary in _markers:
		var at: Vector2 = marker["position"]
		var pose: Dictionary = marker["pose"]
		var left: Vector2 = at + pose["left_foot"]
		var right: Vector2 = at + pose["right_foot"]
		var ground_y: float = maxf(left.y, right.y)
		draw_line(Vector2(at.x - CELL_WIDTH * 0.45, at.y + ground_y), Vector2(at.x + CELL_WIDTH * 0.45, at.y + ground_y), Color("#806d54"), 1.0)
		_draw_contact_tick(left, Color("#f2c879"))
		_draw_contact_tick(right, Color("#a8d6c2"))

func _draw_contact_tick(at: Vector2, color: Color) -> void:
	draw_line(at + Vector2(-5.0, 0.0), at + Vector2(5.0, 0.0), color, 2.0)
	draw_line(at + Vector2(0.0, -4.0), at + Vector2(0.0, 4.0), color, 1.0)

func _add_header(value: String, at: Vector2, size: int = 9) -> void:
	draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_CENTER, 100.0, size, Color("#d8c8aa"))

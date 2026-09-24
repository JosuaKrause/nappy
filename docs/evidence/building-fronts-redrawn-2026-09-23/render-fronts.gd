extends Node
## Renders whole residential fronts through the game's own `Building` node: the same exports
## `City._spawn_buildings()` sets, the same `_ready()` rolls, the same `_draw()` from the baked
## `buildings` atlas. Nothing about a front is overridden; each one is found by walking lot
## positions until `Building`'s own `front:` roll gives the fire escape the sheet wants, so every
## escape here is one the game would place on that lot.
##
## Run as a scene rather than with `--script`, which skips the autoloads `Building` calls into
## (`Tuning`). Needs a window, since only a drawn frame can be saved: run it without `--headless`,
## after `tools/check.sh` has baked and imported the worktree. `--no-save` is accepted and changes
## nothing here, since nothing in this scene touches the save; it is what an agent's run carries.

const USAGE := "usage: godot --path . res://docs/evidence/building-fronts-redrawn-2026-09-23/render-fronts.tscn -- --output OUT.png [--set fire-escape|fronts] [--zoom N] [--no-save]"
const TILE := 32.0
const MARGIN := 24.0
const LABEL_HEIGHT := 16.0
const BACKGROUND := Color("5b5750")
const LABEL_COLOUR := Color("f2efe8")

const R := GameEnums.BlockPurpose.RESIDENTIAL
const C := GameEnums.BlockPurpose.COMMERCIAL
const I := GameEnums.BlockPurpose.INDUSTRIAL
const V := GameEnums.BlockPurpose.CIVIC
const LIVED := Building.Condition.LIVED_IN
const BOARDED := Building.Condition.BOARDED
const BURNT := Building.Condition.BURNT

## One front on a sheet: a title, columns, wall rows, roof rows, lot variant (the district
## colour), district, condition, whether it is her own building, and which fire escape the front
## must carry: "a", "b", "any" (the first lot tried, whatever it rolled), or "dropped" — a front
## whose own `front:` stream rolled an escape (replayed here the way `tests/test_ground_floor.gd`
## replays it) and which carries none, because it is too short for one.
const SETS := {
	## The player's diagram, a five-story front, and the short cases below it.
	"fire-escape": [
		["five stories, escape a", 8, 5, 2, 0, R, LIVED, false, "a"],
		["five stories, escape b", 8, 5, 2, 3, R, LIVED, false, "b"],
		["four stories, escape b", 6, 4, 2, 5, R, LIVED, false, "b"],
		["three stories, escape a", 6, 3, 2, 1, R, LIVED, false, "a"],
		["three stories, escape b", 5, 3, 2, 4, R, LIVED, false, "b"],
		["two stories: rolled one, carries none", 5, 2, 2, 2, R, LIVED, false, "dropped"],
	],
	## Whole fronts of every kind, at the heights the city builds them.
	"fronts": [
		["residential, escape a", 6, 3, 2, 0, R, LIVED, false, "a"],
		["residential, escape b", 5, 3, 2, 3, R, LIVED, false, "b"],
		["residential, two stories", 5, 2, 2, 5, R, LIVED, false, "any"],
		["industrial", 6, 2, 2, 4, I, LIVED, false, "any"],
		["commercial", 6, 3, 2, 1, C, LIVED, false, "any"],
		["civic", 5, 3, 2, 5, V, LIVED, false, "any"],
		["her own building", 5, 3, 2, 2, R, LIVED, true, "any"],
		["boarded commercial", 6, 3, 2, 1, C, BOARDED, false, "any"],
		["burnt residential, escape a", 5, 3, 2, 4, R, BURNT, false, "a"],
	],
}
const PER_ROW := 3

var _output := ""
var _set := "fire-escape"
var _zoom := 2.0
var _frames := 0
## The sheet is drawn into a viewport of its own size, since a window is clamped to the screen.
var _viewport: SubViewport

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var index := 0
	while index < args.size():
		var arg := args[index]
		if arg in ["--help", "-h"]:
			print(USAGE)
			get_tree().quit()
			return
		if arg == "--no-save":
			index += 1
			continue
		if arg == "--output" and index + 1 < args.size():
			_output = args[index + 1]
		elif arg == "--set" and index + 1 < args.size() and SETS.has(args[index + 1]):
			_set = args[index + 1]
		elif arg == "--zoom" and index + 1 < args.size() and args[index + 1].is_valid_float():
			_zoom = float(args[index + 1])
		else:
			push_error(USAGE)
			get_tree().quit(2)
			return
		index += 2
	if _output.is_empty() or _zoom <= 0.0:
		push_error(USAGE)
		get_tree().quit(2)
		return
	_build_sheet()

func _build_sheet() -> void:
	var fronts: Array = SETS[_set]
	var cell_w := 0.0
	var cell_h := 0.0
	for front: Array in fronts:
		cell_w = maxf(cell_w, int(front[1]) * TILE)
		cell_h = maxf(cell_h, (int(front[2]) + int(front[3])) * TILE)
	cell_w += MARGIN * 2.0
	cell_h += MARGIN + LABEL_HEIGHT + 8.0
	var rows := ceili(fronts.size() / float(PER_ROW))
	var size := Vector2(cell_w * PER_ROW, cell_h * rows + MARGIN)
	RenderingServer.set_default_clear_color(BACKGROUND)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(size * _zoom)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	var sheet := CanvasLayer.new()
	sheet.name = "Sheet"
	sheet.transform = Transform2D.IDENTITY.scaled(Vector2(_zoom, _zoom))
	_viewport.add_child(sheet)
	for i in fronts.size():
		var front: Array = fronts[i]
		var origin := Vector2((i % PER_ROW) * cell_w + MARGIN, (i / PER_ROW) * cell_h + MARGIN)
		var lot_rows := int(front[2]) + int(front[3])
		var ground := origin + Vector2(int(front[1]) * TILE * 0.5, LABEL_HEIGHT + lot_rows * TILE)
		var building := _find_front(front, ground)
		if building == null:
			return
		var label := Label.new()
		label.text = "%s (%d x %d)" % [front[0], building.columns(), building.wall_tiles()]
		label.position = origin
		label.add_theme_color_override("font_color", LABEL_COLOUR)
		label.add_theme_font_size_override("font_size", 8)
		sheet.add_child(label)
	get_tree().process_frame.connect(_on_frame)

## Tries lot positions a tile apart until the front's own roll gives the escape asked for. The
## roll is keyed on the building's global position, so each attempt stands at a fresh position on
## a `CanvasLayer` of its own whose transform carries it back to the sheet's `ground`: what is
## drawn is exactly what that position rolled.
func _find_front(front: Array, ground: Vector2) -> Building:
	var want: String = front[8]
	for attempt in 4000:
		var at := Vector2(4096.0 + attempt * TILE, 2048.0 + (attempt % 7) * TILE)
		var layer := CanvasLayer.new()
		layer.transform = Transform2D.IDENTITY.translated(ground - at).scaled(Vector2(_zoom, _zoom))
		_viewport.add_child(layer)
		var building := Building.new()
		building.district = int(front[5])
		building.condition = int(front[6]) as Building.Condition
		building.is_home_building = bool(front[7])
		building.variant = int(front[4])
		building.footprint = Vector2(int(front[1]) * TILE, (int(front[2]) + int(front[3])) * TILE)
		building.height = int(front[2]) * TILE
		building.position = at
		layer.add_child(building)
		var got := "none"
		if building._fire_escape_col >= 0:
			got = "b" if building._fire_escape_variant_b else "a"
		elif _rolled_an_escape(building):
			got = "dropped"
		if got == want or want == "any":
			return building
		layer.free()
	push_error("no lot rolled the escape '%s' for %s" % [want, front[0]])
	get_tree().quit(1)
	return null

static func _rolled_an_escape(building: Building) -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("front:%d:%d:%d" % [building.variant, int(building.global_position.x),
			int(building.global_position.y)])
	return rng.randf() < Building.FIRE_ESCAPE_SHARE

func _on_frame() -> void:
	_frames += 1
	if _frames < 4:
		return
	var image := _viewport.get_texture().get_image()
	if image == null or image.save_png(_output) != OK:
		push_error("could not save " + _output)
		get_tree().quit(1)
		return
	print("saved %s (%d x %d)" % [_output, image.get_width(), image.get_height()])
	get_tree().quit()

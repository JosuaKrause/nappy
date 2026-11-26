class_name ThoughtBubble
extends Node2D
## **The bubble over her head holding one hint's picture, no words** (`HintWatch` decides what it
## shows, and owns it). A child of her while the watch has her, in the column the exclamation mark
## stands in; the mark wins the column and the bubble waits (`HintWatch`). The frame, the icon and
## the arrow are baked pictures of the `ui` atlas page (`docs/GRAPHICS.md`): the frame is a
## paper-white cloud, unlike the danger vocabulary in shape and colour, so it never reads as danger
## (**cues**). The arrow is drawn pointing east and turned toward the way to go, which is layout.
## Every picture is laid through the drawer it is handed (`SceneryDrawer`), so a test hands one
## that records what it is told to lay.

const FRAME := &"ui/thought_bubble"
const ARROW := &"ui/hint_arrow"
const ATLAS := &"ui"
## From her origin to the frame's bottom-centre anchor, the trailing dot's foot.
const FOOT_HEIGHT := 50.0
## The frame is 56x46 with its anchor at (28, 46); these are the icon box's centres in it, relative
## to the anchor: alone, and beside the arrow when the hint points.
const ICON_ALONE := Vector2(0.0, -28.5)
const ICON_BESIDE_ARROW := Vector2(-7.0, -28.5)
const ARROW_CENTRE := Vector2(13.0, -28.5)

var _atlas: AtlasLibrary = null
var _drawer: SceneryDrawer = null
var _kind := HintKind.Kind.WAY_TO_PARK
var _direction := Vector2.ZERO
var _up := false

## Hands the bubble the baked pages it draws from, before it enters the tree.
func use_atlas(atlas: AtlasLibrary) -> void:
	_atlas = atlas

## Hands the bubble what its pictures are laid through, before it enters the tree.
func draw_through(drawer: SceneryDrawer) -> void:
	_drawer = drawer

func _enter_tree() -> void:
	if _atlas == null:
		_atlas = AtlasLibrary.new()
	if _drawer == null:
		_drawer = SceneryDrawer.new()
	_atlas.acquire(ATLAS)
	set_meta(FrameTiming.DRAW_KIND_META, FrameTiming.Draw.OTHER)

func _exit_tree() -> void:
	_atlas.release(ATLAS)

## Puts `kind` up, its arrow turned toward `direction` (a unit vector, zero for none).
func put_up(kind: HintKind.Kind, direction: Vector2) -> void:
	if _up and kind == _kind and direction == _direction:
		return
	_up = true
	_kind = kind
	_direction = direction
	queue_redraw()

## Takes the bubble down.
func take_down() -> void:
	if _up:
		_up = false
		queue_redraw()

func _draw() -> void:
	if not _up:
		return
	var foot := Vector2(0.0, -FOOT_HEIGHT)
	var frame := _atlas.region(FRAME)
	var frame_size := frame.get_size()
	_drawer.draw(self, frame, Rect2(foot - Vector2(frame_size.x * 0.5, frame_size.y), frame_size),
			Rect2())
	var points := HintKind.points(_kind) and _direction != Vector2.ZERO
	var icon := _atlas.region(HintKind.region_of(_kind))
	var at := foot + (ICON_BESIDE_ARROW if points else ICON_ALONE)
	_drawer.draw(self, icon, Rect2(at - icon.get_size() * 0.5, icon.get_size()), Rect2())
	if points:
		var arrow := _atlas.region(ARROW)
		draw_set_transform(foot + ARROW_CENTRE, _direction.angle())
		_drawer.draw(self, arrow, Rect2(-arrow.get_size() * 0.5, arrow.get_size()), Rect2())
		draw_set_transform(Vector2.ZERO)

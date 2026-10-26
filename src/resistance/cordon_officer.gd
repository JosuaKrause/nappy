class_name CordonOfficer
extends Node2D
## One of day 12's cordon officers (`ParkCordon`), drawn as the policeman on foot
## (`art/events/policeman_*`, the sandy-ferret figure) in his standing posture, walking with a bob
## driven by the ground he covers, the way every moving thing is drawn
## (`docs/EVENTS.md`, "A moving thing has to look like it is moving"). Never his lunge: that is
## the chase, and these men chase nobody.
##
## **A figure, not an event.** He is not in the catalogue, carries no field, no caret and no
## badge, and is moved by `ParkCordon` rather than by anything of his own; `EventPictures.icon_for()`
## and the one-picture-per-row rule are about catalogue rows, which he is not.

const WAITING_BY_VIEW := {
	"front": "events/policeman_waiting_front",
	"back": "events/policeman_waiting_back",
	"side": "events/policeman_waiting_side",
	"front_diagonal": "events/policeman_waiting_front_diagonal",
	"back_diagonal": "events/policeman_waiting_back_diagonal",
}
## The bob: half a turn of a sine every this many pixels walked, this high — `EventInstance`'s own
## walking bob (`BOB_PER_PX`, `BOB_HEIGHT`).
const BOB_PER_PX := PI / 34.0
const BOB_HEIGHT := 2.5
## His contact shadow's radius.
const SHADOW := 7.0

var _heading := Vector2.DOWN
var _sector := EightDirection.nearest(Vector2.DOWN)
var _travelled := 0.0
var _moving := false

func _ready() -> void:
	# Moved from `_process` by `ParkCordon`, never from a physics tick, so there is nothing to
	# interpolate — the same opt-out as `EventInstance` and `CrowdAgent`.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

func _enter_tree() -> void:
	AtlasLibrary.acquire(&"events")

func _exit_tree() -> void:
	AtlasLibrary.release(&"events")

## This frame's walk: the way he faces and how far he moved.
func walk(heading: Vector2, moved: float) -> void:
	var was_moving := _moving
	_moving = moved > 0.01
	if _moving:
		_heading = heading
		_travelled += moved
	var sector := EightDirection.update(_sector, _heading)
	if _moving or was_moving or sector != _sector:
		_sector = sector
		queue_redraw()

## The picture he is drawn with now. Kept for the tests.
func picture() -> String:
	return WAITING_BY_VIEW[EventPictures.EIGHT_VIEW_BY_SECTOR[_sector]]

func _draw() -> void:
	Sprites.draw_shadow(self, Vector2.ZERO, SHADOW)
	var lift := absf(sin(_travelled * BOB_PER_PX)) * BOB_HEIGHT if _moving else 0.0
	Sprites.draw_standing(self, AtlasLibrary.region(StringName(picture())),
			Vector2(0.0, -lift), Vector2.ZERO, EightDirection.is_mirrored(_sector))

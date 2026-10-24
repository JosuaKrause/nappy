class_name CordonTape
extends Node2D
## One piece of day 12's police cordon (`ParkCordon`): a taped stretch of the park's edge, solid,
## or a stanchion the tape is strung on. Each stretch is a tile-long slice of the park's edge, its
## own node in the city's y-sorted entity layer at its own feet (`DrawLayer.add_slices()`), so a
## side running away from the camera sorts against her stretch by stretch, the way a closure's
## panels do (`City._spawn_barrier()`).
##
## **A stretch is drawn at the length it closes and is solid along all of it**: one static body the
## stretch's length and `DEPTH` deep, on the tape's own line, which is the park's own edge row half
## a barrier's depth in, so the sidewalk beside the park stays as wide as it was.
##
## Feet (`DrawLayer.slice_feet()`): a broadside stretch's are the middle of it; an end-on stretch's
## are its near end (the larger y), since an end-on picture is drawn up the screen from its feet.

enum Piece { TAPE, POST }

## How deep a taped stretch's body is, across the line. Thin, since tape is, and still several
## frames of a run deep, so nothing walks through it.
const DEPTH := 8.0
## How far above the ground the tape runs, which is how far up the screen an end-on stretch's band
## is drawn from the ground it runs over (`cordon_tape_along.svg`, `cordon_post.svg`).
const LIFT := 13.6

const TAPE_ACROSS := &"closures/cordon_tape_across"
const TAPE_ALONG := &"closures/cordon_tape_along"
const POST := &"closures/cordon_post"

var piece := Piece.TAPE
## Whether a stretch runs across the screen (a north or south side) rather than up it.
var across := true
## A stretch's length, in pixels along its line.
var length := Tuning.TILE_SIZE * 1.0

func _ready() -> void:
	if piece != Piece.TAPE:
		return
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(length, DEPTH) if across else Vector2(DEPTH, length)
	shape.shape = box
	body.position = Vector2.ZERO if across else Vector2(0.0, -length * 0.5)
	body.add_child(shape)
	add_child(body)

func _enter_tree() -> void:
	AtlasLibrary.acquire(&"street_kit")

func _exit_tree() -> void:
	AtlasLibrary.release(&"street_kit")

## The world rect the stretch's body covers. Kept for the tests.
func body_rect() -> Rect2:
	if across:
		return Rect2(position - Vector2(length, DEPTH) * 0.5, Vector2(length, DEPTH))
	return Rect2(position - Vector2(DEPTH * 0.5, length), Vector2(DEPTH, length))

func _draw() -> void:
	if piece == Piece.POST:
		Sprites.draw_standing(self, AtlasLibrary.region(POST), Vector2.ZERO)
		return
	if across:
		var native := Vector2(AtlasLibrary.native_size(TAPE_ACROSS))
		draw_texture_rect(AtlasLibrary.region(TAPE_ACROSS),
				Rect2(-length * 0.5, -native.y, length, native.y), false)
		return
	var width := float(AtlasLibrary.native_size(TAPE_ALONG).x)
	draw_texture_rect(AtlasLibrary.region(TAPE_ALONG),
			Rect2(-width * 0.5, -length - LIFT, width, length), false)

class_name TrafficLightDrawer
extends RefCounted
## What a signal head draws itself through: `draw_head()` stands the head, seen from one of its
## three views, and `draw_lamp()` paints the one lamp that is lit on it. The city builds one over
## its atlas and hands it to every head it stands (`City._spawn_signal_heads()`); a head nobody
## handed one (a suite's) makes its own over its own atlas when it first enters the tree.
##
## The head decides which view it shows and which lamp is lit, from the junction's signals; this
## decides what a head and a lit lamp look like. Kept apart so each is tested apart: a test hands a
## head a drawer that records what it is told to draw instead of drawing it, and checks which lamp
## the head showed (none at all with the power out), without reading what the head holds.

var _atlas: AtlasLibrary

func _init(atlas: AtlasLibrary) -> void:
	_atlas = atlas

## Stands the head's `picture` (`TrafficLight.HEAD`, `HEAD_SIDE` or `HEAD_BACK`) on `canvas` with
## its foot at the canvas's origin and its shadow under it, mirrored when `mirrored`.
func draw_head(canvas: CanvasItem, picture: StringName, mirrored: bool) -> void:
	# The 5.0 here is the signal head's own shape, a point — small enough that a `GroundShape`
	# instance bought nothing over the literal `Sprites.draw_shadow` already took.
	Sprites.draw_shadow(canvas, Vector2.ZERO, 5.0)
	Sprites.draw_standing(canvas, _atlas.region(picture), Vector2.ZERO, Vector2.ZERO, mirrored)

## Paints lamp `lamp` (0 red, 1 amber, 2 green) lit on a head drawn face-on, or on an edge-on one
## when `edge_on`, under the visor on the side `mirrored` turns it to. Where each lamp sits on the
## head is `TrafficLight.LAMP_HEIGHTS` and its patch `LAMP_SIZE`, matched by hand to the drawings.
func draw_lamp(canvas: CanvasItem, lamp: int, edge_on: bool, mirrored: bool) -> void:
	var colour := [Palette.SIGNAL_RED, Palette.SIGNAL_AMBER, Palette.SIGNAL_GREEN][lamp] as Color
	var size := TrafficLight.LAMP_SIZE_SIDE if edge_on else TrafficLight.LAMP_SIZE
	var across := 0.0 if not edge_on \
			else (-TrafficLight.LAMP_SIDE_OFFSET if mirrored else TrafficLight.LAMP_SIDE_OFFSET)
	var at := Vector2(across, TrafficLight.LAMP_HEIGHTS[lamp] as float)
	canvas.draw_rect(Rect2(at - size * 0.5, size), colour)

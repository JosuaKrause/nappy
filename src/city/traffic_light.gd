class_name TrafficLight
extends Node2D
## One signal head, standing on the corner of a junction and facing the arm it controls.
##
## It is the only thing in the game that tells the player when a main road is safe to cross, so
## it is held to the vocabulary's first rule — *the entity itself carries it* — rather than being
## a coloured dot: the head is drawn, the live lamp is painted in its own place on the head, and
## which lamp is lit is the whole message. There is no caret and no badge, because a signal is
## not a danger that changes over time; it is an instruction that is either given or not.
##
## Feet-anchored like everything else and added to the y-sorted layer, so she walks in front of a
## head on the near kerb and behind one on the far side of the junction.

const HEAD := preload("res://assets/props/signal_head.svg")
const HEAD_SIDE := preload("res://assets/props/signal_head_side.svg")

## Where each lamp sits on the head, as an offset from the node's feet, and how big the lit patch
## is. Matched by hand to the two drawings: both are 42 tall with the lamps at y 2, 8 and 14 from
## the top, and the side view shows a cone under a visor rather than a full disc.
##
## **The two views are the cue.** Four identical heads on one junction say nothing about which road
## each is stopping, and from directly above a head has no face to point with. So the ones facing up
## and
## down the screen are drawn face-on and the ones facing across it are drawn edge-on: what you can
## see of the lamp *is* which street it means.
const LAMP_HEIGHTS := [-38.0, -32.0, -26.0]
const LAMP_SIZE := Vector2(6.0, 4.0)
const LAMP_SIZE_SIDE := Vector2(3.0, 2.0)
## How far along its own visor the side view's lit cone sits, in px from the post's centre.
const LAMP_SIDE_OFFSET := 3.0

## The junction this head belongs to and which of its two arms it is showing. A head faces the
## traffic it stops, so one junction has up to four of them and each says something different.
var junction := Vector2i.ZERO
var arm_is_vertical := false
## Which way an edge-on head faces, so its visors point at the traffic they are stopping rather
## than away from it. Meaningless for a face-on one.
var _mirrored := false

var signals: TrafficSignals

## What was drawn last, so a head redraws on the two or three frames a minute its lamp changes
## rather than on every frame of the day. The lights are the one piece of scenery in this city
## that animates, and there are four at every junction on the spine.
var _lit := -1

## Points an edge-on head at the traffic it stops. `heading` is the way that traffic travels, so
## the visors have to face back down it.
func faces(heading: Vector2) -> void:
	arm_is_vertical = absf(heading.y) > 0.0
	_mirrored = heading.x > 0.0

func _process(_delta: float) -> void:
	var lit := _lamp()
	if lit != _lit:
		_lit = lit
		queue_redraw()

## 0 red, 1 amber, 2 green. Amber belongs to the arm losing its green, so an arm that is neither
## green nor ambering is simply red — there is no separate red-amber.
func _lamp() -> int:
	if not signals:
		return 0
	if signals.green_for(junction, arm_is_vertical):
		return 2
	if signals.amber_for(junction, arm_is_vertical):
		return 1
	return 0

func _draw() -> void:
	Sprites.draw_shadow(self, Vector2.ZERO, 5.0)
	Sprites.draw_standing(self, HEAD if arm_is_vertical else HEAD_SIDE, Vector2.ZERO,
			Vector2.ZERO, _mirrored)
	var lamp := _lamp()
	var colour := [Palette.SIGNAL_RED, Palette.SIGNAL_AMBER, Palette.SIGNAL_GREEN][lamp] as Color
	var size := LAMP_SIZE if arm_is_vertical else LAMP_SIZE_SIDE
	var across := 0.0 if arm_is_vertical \
			else (-LAMP_SIDE_OFFSET if _mirrored else LAMP_SIDE_OFFSET)
	var at := Vector2(across, LAMP_HEIGHTS[lamp] as float)
	draw_rect(Rect2(at - size * 0.5, size), colour)

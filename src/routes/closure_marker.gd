class_name ClosureMarker
extends Node2D
## One piece of a road closure: a panel of barrier, the sign on it, or the thing lying in
## the middle of the street.
##
## A closure is drawn as many small feet-anchored nodes rather than as one wide one, because
## a barrier across an east-west street runs *away* from the camera — its near end has to
## y-sort in front of the player and its far end behind her, and a single node can only be at
## one y. Each panel is its own node at its own y, so the whole line sorts correctly for
## free.

enum Piece {
	FENCE,   ## One panel of barrier.
	SIGN,    ## The panel in the middle, with the sign on it.
	CAUSE,   ## What closed the street, lying in the middle of it.
}

const FENCE_ACROSS := preload("res://assets/closures/barrier_across.svg")
const FENCE_ALONG := preload("res://assets/closures/barrier_along.svg")
const SIGN := preload("res://assets/closures/sign_closed.svg")

## What each kind leaves in the road. `CORDON` has nothing: an order is not an object, and
## the barriers are the whole of it.
const CAUSES := {
	RoadClosure.Kind.ROADWORKS: preload("res://assets/closures/roadworks.svg"),
	RoadClosure.Kind.FALLEN_TREE: preload("res://assets/closures/fallen_tree.svg"),
	RoadClosure.Kind.CRASH: preload("res://assets/closures/crashed_car.svg"),
	RoadClosure.Kind.RUBBLE: preload("res://assets/closures/rubble.svg"),
}

@export var piece := Piece.FENCE
@export var kind := RoadClosure.Kind.ROADWORKS
## True when the barrier line runs left to right across the screen.
@export var across := true
## Width of one fence panel, so a line of them covers the street exactly.
@export var span := 22.0

## The texture a piece shows, or null when it has nothing to draw.
static func texture_for(a_piece: Piece, a_kind: RoadClosure.Kind, is_across: bool) -> Texture2D:
	if a_piece == Piece.CAUSE:
		return CAUSES.get(a_kind)
	return FENCE_ACROSS if is_across else FENCE_ALONG

func _draw() -> void:
	match piece:
		Piece.CAUSE:
			var texture: Texture2D = CAUSES.get(kind)
			if not texture:
				return
			Sprites.draw_shadow(self, Vector2.ZERO, texture.get_size().x * 0.32)
			Sprites.draw_standing(self, texture, Vector2.ZERO)
		_:
			_draw_panel()
			if piece == Piece.SIGN:
				# On the barrier rather than beside it, so it shares the panel's y and cannot
				# be sorted behind the thing it is bolted to.
				Sprites.draw_standing(self, SIGN, Vector2(0.0, 2.0))

## One panel, stretched to exactly the width it is covering. A gap between panels would be a
## lie about where the player can walk, which is the same rule the event barriers follow.
func _draw_panel() -> void:
	var texture := FENCE_ACROSS if across else FENCE_ALONG
	var size := texture.get_size()
	if across:
		Sprites.draw_standing(self, texture, Vector2.ZERO, Vector2(span, size.y))
		return
	# Along the street the panels are stacked down the screen, so the span is their spacing
	# and the drawn width is the barrier's own thickness.
	Sprites.draw_standing(self, texture, Vector2.ZERO, size)

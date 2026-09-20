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

## Every picture below is a region name on the `street_kit` atlas group — `_enter_tree()`/
## `_exit_tree()` acquire and release it, so `AtlasLibrary.region()` only ever runs while it is
## held. **`FENCE_ACROSS`'s own native width is read elsewhere through `AtlasLibrary.native_size()`
## rather than `.get_width()` on this constant** — see `src/city/city.gd`'s own call site, which is
## outside this milestone's fence and still reads the old `Texture2D` shape until it is updated to
## match.
const FENCE_ACROSS := &"closures/barrier_across"
const FENCE_ALONG := &"closures/barrier_along"
const SIGN := &"closures/sign_closed"

## What each kind leaves in the road. `CORDON` has nothing: an order is not an object, and
## the barriers are the whole of it.
const CAUSES := {
	RoadClosure.Kind.ROADWORKS: &"closures/roadworks",
	RoadClosure.Kind.FALLEN_TREE: &"closures/fallen_tree",
	RoadClosure.Kind.CRASH: &"closures/crashed_car",
	RoadClosure.Kind.RUBBLE: &"closures/rubble",
}

@export var piece := Piece.FENCE
@export var kind := RoadClosure.Kind.ROADWORKS
## True when the barrier line runs left to right across the screen.
@export var across := true
## Width of one fence panel, so a line of them covers the street exactly.
@export var span := 22.0

## Acquires the `street_kit` group before anything here can be drawn — see `Building.
## _enter_tree()`'s own doc for why this is paired with `_exit_tree()` rather than folded into
## `_ready()`. `AtlasLibrary` reference-counts, so `CityEdge`, `TrafficLight` and this class
## acquiring the same group independently is still one page load.
func _enter_tree() -> void:
	AtlasLibrary.acquire(&"street_kit")

func _exit_tree() -> void:
	AtlasLibrary.release(&"street_kit")

func _draw() -> void:
	match piece:
		Piece.CAUSE:
			var name: StringName = CAUSES.get(kind, &"")
			if name == &"":
				return
			var texture := AtlasLibrary.region(name)
			# `texture.get_size().x * 0.32` is this cause's own point shape's radius, read off its
			# own picture the same way a tree's is.
			Sprites.draw_shadow(self, Vector2.ZERO, texture.get_size().x * 0.32)
			Sprites.draw_standing(self, texture, Vector2.ZERO)
		_:
			_draw_panel()
			if piece == Piece.SIGN:
				# On the barrier rather than beside it, so it shares the panel's y and cannot
				# be sorted behind the thing it is bolted to.
				Sprites.draw_standing(self, AtlasLibrary.region(SIGN), Vector2(0.0, 2.0))

## One panel, stretched to exactly the width it is covering. A gap between panels would be a
## lie about where the player can walk, which is the same rule the event barriers follow.
func _draw_panel() -> void:
	var name := FENCE_ACROSS if across else FENCE_ALONG
	var texture := AtlasLibrary.region(name)
	var size := texture.get_size()
	if across:
		Sprites.draw_standing(self, texture, Vector2.ZERO, Vector2(span, size.y))
		return
	# Along the street the panels are stacked down the screen, so their height is the span they
	# cover while their narrow width keeps the barrier's upright projection.
	Sprites.draw_standing(self, texture, Vector2.ZERO, Vector2(size.x, span))

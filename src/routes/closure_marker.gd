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

## What each kind leaves in the road, drawn lying left to right across the screen, which is
## across a north-south street. `CORDON` has nothing: an order is not an object, and the
## barriers are the whole of it.
const CAUSES := {
	RoadClosure.Kind.ROADWORKS: &"closures/roadworks",
	RoadClosure.Kind.FALLEN_TREE: &"closures/fallen_tree",
	RoadClosure.Kind.CRASH: &"closures/crashed_car",
	RoadClosure.Kind.RUBBLE: &"closures/rubble",
}

## The same causes lying down the screen, away from the camera, which is across an east-west
## street. Each is a picture of its own in the game's projection rather than a `CAUSES` picture
## turned, since turning one would lay its upright parts — a root plate, a car, a heap — on their
## sides. Every one lies along the bottom of its canvas over the same length of road its `CAUSES`
## picture spans, which is what `cause_feet()` centres on the street.
const CAUSES_VERTICAL := {
	RoadClosure.Kind.ROADWORKS: &"closures/roadworks_vertical",
	RoadClosure.Kind.FALLEN_TREE: &"closures/fallen_tree_vertical",
	RoadClosure.Kind.CRASH: &"closures/crashed_car_vertical",
	RoadClosure.Kind.RUBBLE: &"closures/rubble_vertical",
}

@export var piece := Piece.FENCE
@export var kind := RoadClosure.Kind.ROADWORKS
## True when the closure runs left to right across the screen, which it does on a north-south
## street (`RoadClosure.barrier_runs_across()`): it picks the barrier panel and the picture of the
## cause alike.
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
			_draw_cause()
		_:
			_draw_panel()
			if piece == Piece.SIGN:
				# On the barrier rather than beside it, so it shares the panel's y and cannot
				# be sorted behind the thing it is bolted to.
				Sprites.draw_standing(self, AtlasLibrary.region(SIGN), Vector2(0.0, 2.0))

## What closed the street, centred on the street's middle with its own contact shadow under it.
## Lying across the screen it stands on this node with a point shadow as wide as 0.64 of its
## picture; lying down the screen its shadow is a band down the screen instead, as long as 0.64
## of the road it lies along and as wide as the point shadow of a picture its own width would be.
func _draw_cause() -> void:
	var name := cause_picture(kind, across)
	if name == &"":
		return
	var texture := AtlasLibrary.region(name)
	# `x * 0.32` is a cause's own point shape's radius, read off its own picture the same way a
	# tree's is.
	var radius := texture.get_size().x * 0.32
	if across:
		Sprites.draw_shadow(self, Vector2.ZERO, radius)
	else:
		var lie := float(AtlasLibrary.native_size(CAUSES[kind]).x)
		GroundShape.segment(maxf(0.0, lie * 0.32 - radius), radius) \
				.draw_shadow(self, Vector2.ZERO, Vector2.DOWN)
	Sprites.draw_standing(self, texture, cause_feet(kind, across))

## The picture a cause is drawn with: its `CAUSES` one lying across the screen, its
## `CAUSES_VERTICAL` one lying down it, and `&""` for a kind that leaves nothing in the road.
static func cause_picture(cause_kind: int, lies_across: bool) -> StringName:
	var table: Dictionary = CAUSES if lies_across else CAUSES_VERTICAL
	return table.get(cause_kind, &"")

## Where a cause's picture stands, relative to the street's middle. Lying across the screen its
## feet are the middle; lying down the screen it spans the length of road its `CAUSES` picture
## spans across, up from its feet, so its feet stand half that below the middle and the length is
## centred on it. `int` rather than `RoadClosure.Kind`: see the **godot** skill on cross-script
## enums.
static func cause_feet(cause_kind: int, lies_across: bool) -> Vector2:
	if lies_across or not CAUSES.has(cause_kind):
		return Vector2.ZERO
	return Vector2(0.0, AtlasLibrary.native_size(CAUSES[cause_kind]).x * 0.5)

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

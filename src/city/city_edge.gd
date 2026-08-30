class_name CityEdge
extends Node2D
## Where the main road leaves the map: a tunnel at the north end of the spine, a bridge at its
## south end, and the east-west spine simply carrying on.
##
## Playtest 11 gave this as a design rather than as a finding, and the sentence in it is the whole
## brief: *"the player should be able to walk into those, which would be certain death once a car
## comes — that way it's not an artificial end but an emergent end."* A wall says *the game stops
## here*. A tunnel and a bridge say *the city goes on and this is how you would leave it*, and
## they are lethal for the reason every other stretch of carriageway is lethal, which the player
## has already learnt. Nothing new was needed for the danger; only for the sentence.
##
## **It does not move a walkable tile.** The exits are the last stretch of the spine as it already
## exists, which she can already stand on and already be killed on; what is added is the thing at
## the end of it. That matters because the walkable set is asserted tile for tile across every
## seed and block arc, and because a route out of the city must never count as a route to a calm
## area — see `tests/test_blocks.gd` and `docs/CITY.md`.
##
## Two things about how they are drawn, and both are about which side of a car they are on:
##
## - **The tunnel is in the y-sorted layer, anchored on the map edge.** Anything further north
##   sorts behind it, so the traffic recycling a tile outside the boundary goes into the dark
##   instead of blinking out in plain sight. That is the one job only y-sorting can do here.
## - **The bridge and the road are in the building layer**, under the entities, because they are
##   ground: a car leaving over the bridge is *on* the deck, and a deck that sorted against it
##   would sometimes be painted over the car.

enum Kind {
	TUNNEL,   ## North: the spine goes under. Occludes what is beyond it.
	BRIDGE,   ## South: the deck runs out between two parapets.
	ROAD_EAST,
	ROAD_WEST,
}

const TUNNEL := preload("res://assets/props/tunnel_mouth.svg")
const BRIDGE := preload("res://assets/props/bridge_deck.svg")
const ROAD_ON := preload("res://assets/props/road_on.svg")

@export var kind := Kind.TUNNEL

## Whether this piece belongs in the y-sorted entity layer rather than under it.
func occludes() -> bool:
	return kind == Kind.TUNNEL

func _draw() -> void:
	match kind:
		Kind.TUNNEL:
			_swallow_the_road()
			_blit(TUNNEL, Vector2(-0.5, -1.0))
		Kind.BRIDGE:
			_blit(BRIDGE, Vector2(-0.5, 0.0))
		Kind.ROAD_EAST:
			_blit(ROAD_ON, Vector2(0.0, -0.5))
		_:
			_blit(ROAD_ON, Vector2(-1.0, -0.5))

## The carriageway darkening a step at a time as it runs under the mountain. *(Playtest 14: "the
## tunnel needs the street to continue with a slight darkening of the tiles each step".)*
##
## `City._paint_outside_the_map` carries the spine's road through the border rather than burying it
## in rock, and this is what turns that stretch into a tunnel rather than a road with a picture at
## the end. One rect per tile, alpha climbing to nearly opaque under the arch, so the road does not
## stop being a road at any particular pixel — it just stops being visible.
##
## Drawn before the portal so the arch sits on top of its own darkest step, and drawn here rather
## than as five pre-darkened tiles in the tileset because the ramp is a property of *how deep the
## border is*: `City.OUTSIDE_DEPTH_TILES` may move and the art must not have to.
func _swallow_the_road() -> void:
	var tile := float(Tuning.TILE_SIZE)
	var width := Tuning.STREET_WIDTH * tile
	var steps := City.OUTSIDE_DEPTH_TILES
	for step in steps:
		# `step` 0 is the tile just outside the last kerb, so the first one is barely tinted and
		# the shading has already begun before she can see any of it is happening.
		var alpha := 0.92 * float(step + 1) / float(steps)
		draw_rect(Rect2(-width * 0.5, -tile * float(step + 1), width, tile),
				Color(0.05, 0.04, 0.04, alpha))

## Draws a texture at the node's own origin, with `anchor` saying which of its corners that origin
## is — `(-0.5, -1)` is bottom-centre, `(0, -0.5)` is the middle of its west edge, and so on.
## Written out rather than reusing `Sprites.draw_standing`, which only knows the feet-anchored
## case: an exit that leaves eastward is anchored on its side, not on its base.
func _blit(texture: Texture2D, anchor: Vector2) -> void:
	var extent := texture.get_size()
	draw_texture_rect(texture, Rect2(extent * anchor, extent), false)

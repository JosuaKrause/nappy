class_name CityEdge
extends Node2D
## Where the main road leaves the map: a tunnel at the north end of the spine, a bridge at its
## south end, and the east-west spine simply carrying on.
##
## **She can walk into one, and a car will kill her there.** That is the point: it makes the end of
## the map an emergent end rather than an artificial one. A wall says *the game stops here*; a
## tunnel and a bridge say *the city goes on and this is how you would leave it*, and
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
##   sorts behind it, so a car going under the mountain is *under* it: darkened inside the portal's
##   opening, then hidden by the mountain this piece paints over the rest of the border band, and
##   recycled out of sight rather than blinking out in plain view. That is the one job only
##   y-sorting can do here.
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
## The same tile the border paints north of the city, so the roof this piece puts over the tunnel
## is pixel for pixel the mountainside around it.
const MOUNTAIN := preload("res://assets/tiles/mountain.svg")

## How many tiles of road run under the portal before the dark has swallowed them: the height of
## the opening in `tunnel_mouth.svg`, in tiles. **The art and this number describe the same
## hole**, so one moves with the other. `City._border_source` carries the carriageway exactly
## this far out of the map and paints mountain beyond it — the road ends where the opening does,
## and above the portal there is only rock.
const TUNNEL_DEPTH_TILES := 3

@export var kind := Kind.TUNNEL

## Whether this piece belongs in the y-sorted entity layer rather than under it.
func occludes() -> bool:
	return kind == Kind.TUNNEL

func _draw() -> void:
	match kind:
		Kind.TUNNEL:
			_swallow_the_road()
			_blit(TUNNEL, Vector2(-0.5, -1.0))
			_roof_the_tunnel()
		Kind.BRIDGE:
			_blit(BRIDGE, Vector2(-0.5, 0.0))
		Kind.ROAD_EAST:
			_blit(ROAD_ON, Vector2(0.0, -0.5))
		_:
			_blit(ROAD_ON, Vector2(-1.0, -0.5))

## The carriageway darkening a step at a time as it runs into the portal's opening.
##
## `City._paint_outside_the_map` carries the spine's road `TUNNEL_DEPTH_TILES` out through the
## border rather than burying it in rock, and this is what turns that stretch into a tunnel rather
## than a road with a picture at the end. One rect per tile inside the opening, alpha climbing to
## opaque at the ceiling, so the road does not stop being a road at any particular pixel — it just
## stops being visible. **The whole fade happens inside the mouth**: the first step is the tile
## just past the last kerb and the last is fully dark, so nothing of the road shows above the
## portal, and a car going in is gone by the time it reaches the top of the opening.
##
## Only as wide as the carriageway, because that is all the road there is: the pavements stop at
## the city, and the opening's own side walls are part of the portal art.
##
## Drawn before the portal so the arch sits on top of its own darkest step, and drawn here rather
## than as pre-darkened tiles in the tileset because the ramp is a property of the *portal* — the
## art's opening and this constant describe the same hole, and the tileset knows nothing of it.
func _swallow_the_road() -> void:
	var tile := float(Tuning.TILE_SIZE)
	var width := Tuning.carriageway_width()
	var steps := TUNNEL_DEPTH_TILES
	for step in steps:
		var alpha := float(step + 1) / float(steps)
		draw_rect(Rect2(-width * 0.5, -tile * float(step + 1), width, tile),
				Color(0.05, 0.04, 0.04, alpha))

## The mountain over the tunnel, between the top of the portal and the far edge of the border band.
##
## The ground already paints mountain there — `City._border_source` stops the road at the
## opening — but the ground is *under* the traffic, and a car on its way out drives on to
## `Tuning.OUT_OF_SIGHT` before it is recycled, which is further than the portal is tall. This is
## the lid: the same tile the border uses, blitted on the tile grid so it is indistinguishable from
## the ground around it, in the y-sorted layer where a car north of the map edge sorts behind it.
## Without it the car is dark inside the mouth and then bright on top of the mountain.
##
## The whole corridor's width rather than the carriageway's, so a sprite hanging over its lane is
## covered too; the pavement columns are mountain underneath anyway, so the extra paint changes
## nothing a player can see.
func _roof_the_tunnel() -> void:
	var tile := float(Tuning.TILE_SIZE)
	var columns := Tuning.STREET_WIDTH
	var portal_rows := int(TUNNEL.get_size().y) / Tuning.TILE_SIZE
	var left := -columns * tile * 0.5
	for row in range(portal_rows, City.OUTSIDE_DEPTH_TILES):
		for column in columns:
			draw_texture_rect(MOUNTAIN,
					Rect2(left + column * tile, -tile * float(row + 1), tile, tile), false)

## Draws a texture at the node's own origin, with `anchor` saying which of its corners that origin
## is — `(-0.5, -1)` is bottom-centre, `(0, -0.5)` is the middle of its west edge, and so on.
## Written out rather than reusing `Sprites.draw_standing`, which only knows the feet-anchored
## case: an exit that leaves eastward is anchored on its side, not on its base.
func _blit(texture: Texture2D, anchor: Vector2) -> void:
	var extent := texture.get_size()
	draw_texture_rect(texture, Rect2(extent * anchor, extent), false)

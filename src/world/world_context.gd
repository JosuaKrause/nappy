class_name WorldContext
extends Node2D
## What the baby is allowed to ask about the world.
##
## `Baby` must never know what an event or a tile type is — it only asks "how loud is it
## here, and what is this ground doing to me". The debug world answers with hand-placed test data;
## the generated city and the event manager answer for real. Adding an event type therefore never
## touches the meter code.
##
## **Four questions, and neither of the ground ones is a bool.** Recovery is a rate — calm,
## precinct, ordinary street, main road — and so is how fast the sleepiness fills, because a
## single-block calm area fills the meter twice as fast as a four-block one. The rule that keeps
## this interface small is worth stating: **a new question generalises an old answer instead of
## sitting beside it.** A question that is a special case of one of these four is exactly what
## that rule exists to stop.
##
## **`excitement_sources_at()` is the one exception, and it generalises rather than sits beside.**
## It returns the same bodies `total_excitement_at()` sums, broken into `[source, contribution]`
## pairs so `Baby` can trace what actually lands on the meter back to whichever body put it
## there — `total_excitement_at()` is kept only because a page of existing callers want a bare
## number and summing the pairs themselves would be the same loop repeated at every call site.
##
## `City` still has an `is_calm_zone` of its own, for the debug overlay and the telemetry, which
## genuinely do want the yes/no. It is not on this interface because `Baby` has no use for it.

## What this ground multiplies the sleepiness gain by while she walks. 1.0 is anywhere that is not
## calm; calm ground is worth many times that, and a small calm area more again.
func sleepiness_multiplier(_world_position: Vector2) -> float:
	return 1.0

## What this ground multiplies the excitement decay by. 1.0 is an ordinary street.
##
## Asked every frame, so the world answers from the tile she is standing on rather than from
## anything it has to search for.
func decay_multiplier(_world_position: Vector2) -> float:
	return 1.0

## Alleys apply a constant excitement trickle. Shortcuts that cost you.
func is_alley(_world_position: Vector2) -> bool:
	return false

## Summed excitement per second from every active source at this point.
func total_excitement_at(_world_position: Vector2) -> float:
	return 0.0

## Every active source contributing at this point, as `[source, contribution]` pairs — the same
## bodies `total_excitement_at()` sums, broken out so `Baby` can trace each point that lands on
## the meter back to whatever body actually put it there, for `ExcitementHalo`'s colour. Empty for
## the debug world, which has no bodies to attribute to.
func excitement_sources_at(_world_position: Vector2) -> Array:
	return []

# ------------------------------------------------------------ the draw layers ---
# Not a question the baby asks: the world's own service to whatever it is handed to — an event
# manager and its events, the crowd, the resistance, `main` putting her down.

## Adds `node` to this world, drawn on `layer` (`DrawLayer.Layer`; an `int` for the reason
## `DrawLayer.z_of()` gives): `ENTITIES`, the y-sorted layer everything standing on the ground
## sorts in at its feet, unless the caller asks for another.
func add_entity(node: Node, layer: int = DrawLayer.Layer.ENTITIES) -> void:
	layers().node(layer).add_child(node)

## The nodes this world draws its layers in. The city and the building hand over the ones their
## scenes hold when they are built; any other layer, and every layer of a test's stand-in world,
## gets a node of its own the first time something is added to it.
func layers() -> WorldLayers:
	if _layers == null:
		_layers = WorldLayers.new(self)
	return _layers

var _layers: WorldLayers

# ------------------------------------------------------------- the player's walk ---

## What this world's ground does to her each frame she walks it, asked through its map
## (`WorldMap.process_player()`): the building's doors fade her through and its light follows the
## part she is in. Nothing in a world whose ground does nothing to her walk.
func process_player(_player: Node2D, _delta: float) -> void:
	pass

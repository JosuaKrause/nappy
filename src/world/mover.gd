class_name Mover
extends RefCounted
## Who is asking whether a piece of ground can be walked or driven: which layers of a map's
## blocked record stop it (`BlockedLayer`), and how wide it is. The one argument
## `CityMap.passable()`, `CityMap.clear_line()` and every `Navigator` call take, so "can this
## mover stand here" has one answer per mover rather than one per caller.
##
## **The layers are the solids of the world, in the order they are laid down.** The ground itself
## (a building, the void round an authored stretch, off the map), a precinct's posts, today's
## closures (the fenced park's ground included), the tiles a soft seal shuts to walkers, and the
## tiles under a stationary solid body. A mover names the ones that stop it: a figure on foot is
## stopped by all five, a car by all but the soft seals, which take only the pavement, and a
## plan of the city as built by the first two alone.
##
## A mover is a value: the shared ones (`lattice()`, `on_foot()`, ...) are built once and never
## changed, so a caller that wants a different radius asks for its own.

## The ground's own tile type: a building, the void round an authored stretch, off the map.
const GROUND := 1
## A precinct's posts (`CityMap.post_tiles()`).
const POSTS := 2
## Today's closures and the fenced park's ground (`CityMap.closed_tiles`).
const CLOSED := 4
## The pavement tiles a soft seal shuts to walkers (`CityMap.soft_sealed_tiles`).
const SOFT_SEALS := 8
## The tiles under a stationary solid body (`CityMap.obstructed_tiles`).
const BODIES := 16
## Street ground only — pavement, carriageway or crossing (`CityMap.is_street()`): what a car keeps
## to when it has to find its own way.
const STREETS := 32
## The layers a day puts down, as against the ground, the posts and the streets, which are the city
## as built. A mover standing on one may walk off it, and a line from inside one may see out of it
## (`CityMap.clear_line()`), since a figure placed on a solid has to be able to leave it.
const TODAY := CLOSED | SOFT_SEALS | BODIES

## The layers that stop this mover, `GROUND | POSTS | ...`.
var blocked_by := GROUND | POSTS
## How far its body reaches round the point it stands on, in px: a step is refused when this much
## past where it would land is solid (`Navigator.step()`).
var radius := 0.0

func _init(layers := GROUND | POSTS, body_radius := 0.0) -> void:
	blocked_by = layers
	radius = body_radius

## Whether `layer` (one of the constants above) stops this mover.
func is_blocked_by(layer: int) -> bool:
	return blocked_by & layer != 0

## The same layers at another radius.
func with_radius(body_radius: float) -> Mover:
	return Mover.new(blocked_by, body_radius)

## The mover of no body stopped by `layers`, shared: one is built per set of layers and handed to
## every caller that asks, so a question asked every frame by hundreds of walkers builds nothing.
static func of(layers: int) -> Mover:
	if not _shared.has(layers):
		_shared[layers] = Mover.new(layers)
	return _shared[layers]

## **The city as it is built**: the ground and the posts, nothing a day puts down. What every plan
## that guarantees the city stays walkable floods over (`CityMap.walk_field_from()`,
## `ReachabilityGrid`), and what `CityMap.is_walkable()` answers.
static func lattice() -> Mover:
	return of(GROUND | POSTS)

## The ground alone, posts left open: the lattice the route tree grows on (`RouteTree`), where a
## route crossing a mouth's row of posts is a detour by the pavement inside the same junction box.
static func ground() -> Mover:
	return of(GROUND)

## **A figure on foot**: stopped by everything that stops her — the ground, the posts, today's
## closures, the soft seals and every stationary body. What every event figure walks as, and what
## the red arrow's sweep and a placement that has to be reachable today ask.
static func on_foot(body_radius := 0.0) -> Mover:
	if is_zero_approx(body_radius):
		return of(GROUND | POSTS | TODAY)
	return Mover.new(GROUND | POSTS | TODAY, body_radius)

## **A car that drives**: stopped by the ground, the posts, today's closures and every stationary
## body, and kept to street ground. A soft seal takes only the pavements, so its carriageway stays
## open to a car (`CityMap.soft_sealed_tiles`).
static func vehicle(body_radius := 0.0) -> Mover:
	return Mover.new(GROUND | POSTS | CLOSED | BODIES | STREETS, body_radius)

static var _shared := {}

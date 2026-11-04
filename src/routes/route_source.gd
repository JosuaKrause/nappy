class_name RouteSource
extends RefCounted
## **The walk a day's placement is stated against, as the questions placement asks of it**: which
## streets the walk runs along, whether it runs along a tile's own cell, which street it starts in,
## where it starts and where it has to get to. The seal planner (`SealPlanner.plan_day()`), the
## event scheduler (`EventScheduler.build_day()`) and the route's kerb tint (`City.tint_the_route()`)
## ask these and nothing else, so none of them asks which kind of walk it was handed.
##
## **Two walks implement it.** A day's `RouteTree` — one branch from the doorstep to every calm area
## still worth reaching, so a street is on the walk when the tree runs along it — and the escape
## city's `FinalePlanner.Plan` — two chains from the service exit through three calm areas each to
## the tunnel and the bridge, so a street is on the walk when a chain walks its middle
## (`SealPlanner.runs_through()`). Which one a walk is the run flow decides, as a `DaySpec` setting
## (`DaySpec.closes_streets`: a day grows its tree and closes streets off it; the escape is handed
## its chains).
##
## **A `RouteSource` of this class itself is no walk at all**: no street on it, nothing carried,
## starting nowhere. It is what a rig with no route to hand stands a placement against, the shape
## `Corridor.of(null)` answers `AWAY` everywhere in.

## Every street the walk runs along, a whole `StreetNetwork.Segment` at a time, in
## `StreetNetwork.segments()`'s own order.
func streets_on_the_walk() -> Array[StreetNetwork.Segment]:
	return []

## Whether the walk runs along `segment` — at `along`, a tile on the street's own along axis, where
## the walk's shape makes that the question (a chain may walk one end of a street and not its middle);
## `-1` asks about the street as a whole. What a seal spares.
func walks_the_street(_segment: StreetNetwork.Segment, _along := -1) -> bool:
	return false

## Whether the walk takes or reaches the through-alley `rect`, so a seal leaves its mouths open.
func reaches_the_alley(_map: CityMap, _rect: Rect2i) -> bool:
	return false

## Whether the walk runs along `tile`'s own cell — the narrower of the two route questions, which
## asks which sidewalk of a street the walk is drawn down (`Corridor.carries_a_route()`).
func carries_a_route(_tile: Vector2i) -> bool:
	return false

## Whether `tile`'s street is on the walk, at the grain of the whole street: both kerb lines of every
## street the walk runs along, intersection to intersection. What the route's kerb tint marks.
func marks_the_kerb_at(_tile: Vector2i) -> bool:
	return false

## The street the walk starts in, which nothing seals: sealing it would seal her in. Null where the
## walk starts on no street.
func street_it_starts_in() -> StreetNetwork.Segment:
	return null

## The corridor the walk's prices and roles are stated against (`Corridor`): what a day's catalogue
## is placed by, wall and friction alike. Null for a walk that is not a tree, which grows none — the
## escape's chains, whose streets keep their way past what stands on them by `WalkGround` instead.
func corridor() -> Corridor:
	return null

## Where she starts the walk, in world space, `Vector2.INF` for no walk.
func start() -> Vector2:
	return Vector2.INF

## Where the walk has to get to, in world space: the escape's two ways out. Empty for a walk whose
## ends are the calm areas a day's guarantees reach through its own corridor
## (`EventScheduler._ensure_the_city_is_still_walkable()`), rather than points.
func ends() -> Array[Vector2]:
	return []

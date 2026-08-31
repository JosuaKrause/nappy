class_name Corridor
extends RefCounted
## The ground today's routes run through, as a question that can be asked about a **tile**.
##
## *(M50 step 2. The words are `docs/CITY.md`, "The words for it"; the tree they are stated
## against is `RouteTree`.)*
##
## `RouteTree` is a graph — a set of segment keys — and every placement decision in this game is
## about a tile. This is the one translation between the two, so that *inside the corridor* and
## *just outside it* mean exactly the same thing to an event, to a closure and to anything that
## draws either. Two copies of that translation is the `DangerEdge` defect M37 found, one
## milestone earlier and one system over.
##
## Three answers, and the middle one is the one the design is built on:
##
## - **`INSIDE`** — the tile belongs to a street on the tree. This is where **friction** goes:
##   *"benign blockers go on the route… to make it more challenging / force the player to think
##   their route through better."*
## - **`RIM`** — the tile belongs to a street that is *not* on the tree but meets one that is.
##   This is where a **wall** goes, and the adjacency is the whole of why: a wall bounds the
##   corridor, so it has to be visible from the junction where the wrong turning is taken. A
##   lethal thing four streets away bounds nothing.
## - **`AWAY`** — everywhere else. Still legal ground for a wall (a wall further out bounds less;
##   it does not bound the wrong thing), and never legal ground for friction to be *aimed* at.
##
## **And since the off-corridor ground stopped being merely unweighted, there is a fourth thing to
## ask and it is a number rather than a name.** *(2026-08-31: "areas that outside the paths should
## have blocking events all over — we don't want the player to step in those areas and it ranges
## from very costly to deadly.")* `depth()` is how far off the routes a tile is, in **turnings**:
## zero inside, one on the rim, and upwards. The three names above are the first two values and
## everything else, kept because they are what the design is written in; the number is what the
## *range* is stated over, and one cache answers both.
##
## **A tile that is on no street still has an answer**, which is the part that had to be got right
## rather than assumed. Sixteen rows of the catalogue stand on alley, park, square or courtyard
## ground, and `StreetNetwork.segment_containing` returns null for every one of them — so a
## classification written over segments alone would have silently made `alley_robbery`
## unplaceable while every test in the suite passed. A block interior takes the answer of the four
## streets around its block, and a junction takes the answer of the streets that meet at it.
##
## `INSIDE` wins over `RIM` wherever a tile could be both, because the corridor is a *place she is
## meant to walk* and the rim is defined as what is beside it: a street on the tree is on the tree
## however many turnings run off it.

enum Where {
	AWAY,    ## Two turnings off the corridor or more — `depth()` is what says how far.
	INSIDE,  ## On a street the day's routes run down.
	RIM,     ## On a street that meets one of those at a junction.
}

## Segment key -> how many turnings off the corridor it is. Zero for a street on the tree, one for
## the rim, upwards from there; a street the day cannot reach at all is absent. See
## `RouteTree.depths()`, and note that this replaced two sets — `_on` and `_rim` were the same
## dictionary asked for its zeroes and its ones.
var _depths := {}
## The covering set: the smallest set of streets such that every route touches one of them. Kept in
## order rather than as a set, because a **set piece** is placed once at each of them.
var _sites: Array[Vector3i] = []

## The corridor of a tree. An empty tree gives a corridor that answers `AWAY` everywhere, which
## is the right answer rather than a special case: a day with no reachable calm has no route for
## anything to be inside or outside of.
static func of(tree: RouteTree) -> Corridor:
	var corridor := Corridor.new()
	var cells := StreetNetwork.junction_count()
	corridor._answers.resize(cells.x * cells.y * 4)
	corridor._answers.fill(_UNKNOWN)
	if not tree:
		return corridor
	corridor._depths = tree.depths()
	corridor._sites = tree.covering_sites()
	return corridor

## The streets a set piece is placed on: every route touches one of them.
##
## *"We can have multiple candidate places and make sure all routes touch at least one of them."*
## It is deliberately **the whole list** rather than a pick — the guarantee is that she meets one
## whichever way she goes, and choosing one of them here would throw exactly that away.
func sites() -> Array[Vector3i]:
	return _sites

## The answer for every lattice cell, four to a cell, filled in on demand. `_UNKNOWN` for one not
## asked about yet.
##
## **A cache and not an optimisation of the arithmetic**, because the arithmetic is not what costs:
## the answer depends only on which cell of the lattice a tile is in and which of the four kinds of
## place it is within that cell, and `EventScheduler` asks it of every sidewalk in the city, once
## per role. Without this the scan allocated an `Array[Vector3i]` and did four `by_key` lookups per
## tile per role, and it doubled the run time of `tests/test_events.gd` on its own.
var _answers := PackedByteArray()
const _UNKNOWN := 255

## Where a tile stands in relation to the day's routes.
func where(tile: Vector2i) -> Where:
	var away := depth(tile)
	if away == 0:
		return Where.INSIDE
	return Where.RIM if away == 1 else Where.AWAY

## How many turnings off the corridor a tile is. Zero is on it, one is the rim, and it counts
## outwards; `DEEP` is the answer for ground the day's routes cannot reach at all.
##
## **The cap is what makes this a byte and it is also the design.** Beyond a couple of turnings the
## player is not straying, she is somewhere else, and pricing the fourth turning differently from
## the third would be a gradient nobody can feel — so the range saturates and the constant says
## where.
func depth(tile: Vector2i) -> int:
	var period := CityMap.period()
	var across_x := CityMap.corridor_offset(tile.x) >= 0
	var across_y := CityMap.corridor_offset(tile.y) >= 0
	var count := StreetNetwork.junction_count()
	var cell := Vector2i(floori(float(tile.x) / period), floori(float(tile.y) / period))
	var kind := (2 if across_x else 0) + (1 if across_y else 0)
	var slot := (cell.y * count.x + cell.x) * 4 + kind
	if slot < 0 or slot >= _answers.size():
		return DEEP   # off the lattice entirely: the frontages beyond the boundary
	if _answers[slot] == _UNKNOWN:
		_answers[slot] = _work_out(cell, across_x, across_y)
	return _answers[slot]

## As far off the corridor as this answers. Anything at or past it is simply *elsewhere*.
const DEEP := 3

func is_inside(tile: Vector2i) -> bool:
	return depth(tile) == 0

func _work_out(cell: Vector2i, across_x: bool, across_y: bool) -> int:
	var answer := DEEP
	for key in _streets_at(cell, across_x, across_y):
		if not _depths.has(key):
			continue
		answer = mini(answer, _depths[key] as int)
		if answer == 0:
			break
	return answer

## Whether this street is one of the ones the day's routes run down.
func holds_street(key: Vector3i) -> bool:
	return _depths.get(key, DEEP) == 0

## The streets a tile answers for.
##
## Three cases, and they are the three things a tile of this lattice can be. A tile on a street
## answers for that street. A tile in a junction answers for the up-to-four streets that meet
## there, because a junction is where the choice between them is made and it belongs to none of
## them (`StreetNetwork.segment_containing` says so, deliberately). A tile inside a block answers
## for the four streets around that block — an alley, a courtyard or a corner of a park is
## *reached* from the streets that bound it, and that is what puts it on somebody's route.
func _streets_at(cell: Vector2i, across_x: bool, across_y: bool) -> Array[Vector3i]:
	var found: Array[Vector3i] = []
	if across_x != across_y:
		var segment := StreetNetwork.by_key(Vector3i(cell.x, cell.y, 1 if across_x else 0))
		if segment:
			found.append(segment.key())
		return found
	var around := StreetNetwork.at_junction(cell) if across_x \
			else StreetNetwork.around_blocks(Rect2i(cell, Vector2i.ONE))
	for segment in around:
		found.append(segment.key())
	return found

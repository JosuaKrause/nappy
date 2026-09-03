class_name Corridor
extends RefCounted
## The ground today's routes run through, as a question that can be asked about a **tile**.
##
## The words are `docs/CITY.md`, "The words for it"; the tree they are stated against is
## `RouteTree`.
##
## `RouteTree` grows on `ReachabilityGrid` nodes now (M69), and every placement decision in this
## game is about a tile — so this is still the one translation between the two, and a street tile
## and a block-interior tile keep being told apart by two different questions on purpose.
##
## **A street tile answers at the grain of its whole street; anything else answers at the grain of
## its own cell.** A route is a thin chain of cells now, but a street is walkable frontage to
## frontage — three cells wide — and a player on it can be on either side of the specific line the
## tree's path happened to draw through it. Answering a street tile from the cell grid instead was
## tried and measured: the share of costly rows landing on the corridor nearly halved, because two
## thirds of every on-tree street's own pavement priced as one turning further out than it was.
## `RouteTree.segment_depths()` is the street-level question, asked exactly as it was before M69;
## `RouteTree.node_depths()` is the cell-level one, and it is what answers correctly for a park cut
## or an alley the tree actually takes — ground no street question could ever have told apart from
## the rest of the same park.
##
## Three answers, and the middle one is the one the design is built on:
##
## - **`INSIDE`** — the tile's street, or its own cell where it has no street, is on the tree. This
##   is where **friction** goes: *"benign blockers go on the route… to make it more challenging /
##   force the player to think their route through better."*
## - **`RIM`** — one turning further out. This is where a **wall** goes, and the adjacency is the
##   whole of why: a wall bounds the corridor, so it has to be visible from beside the ground the
##   wrong turning would have crossed. A lethal thing several turnings away bounds nothing.
## - **`AWAY`** — everywhere else. Still legal ground for a wall (a wall further out bounds less;
##   it does not bound the wrong thing), and never legal ground for friction to be *aimed* at.
##
## **And since the off-corridor ground stopped being merely unweighted, there is a fourth thing to
## ask and it is a number rather than a name.** *(2026-08-31: "areas that outside the paths should
## have blocking events all over — we don't want the player to step in those areas and it ranges
## from very costly to deadly.")* `depth()` is how far off the routes a tile is, in **grid steps**:
## zero inside, one on the rim, and upwards. The three names above are the first two values and
## everything else, kept because they are what the design is written in.
##
## **And one place inside the rim is asked about by name.** `is_in_a_gap()` is the street a
## player switches strands through — the rim is a band round the whole corridor, and a gap is a
## hole in the middle of it. It is a *further* preference inside the rim rather than a fourth band,
## which is why it is a question of its own and not another value of `depth()`. A gap is still a
## **street** by its own definition (`RouteTree.gaps()`), so this one question still goes through
## `StreetNetwork.segment_containing` rather than the grid.
##
## **A tile that is on no street still has an answer**, which is the part that had to be got right
## rather than assumed, and the grid gets it for free: sixteen rows of the catalogue stand on
## alley, park, square or courtyard ground, and every one of those tiles resolves to a node exactly
## like a street tile does.
##
## `INSIDE` wins over `RIM` wherever a tile could be both, because the corridor is a *place she is
## meant to walk* and the rim is defined as what is beside it.

## The grid the tree this corridor answers for was grown on. `null` for an empty tree, which
## answers `AWAY` everywhere without needing a special case anywhere below.
var _grid: ReachabilityGrid
## Node id -> how many grid steps off the tree it is, `DEEP` where the grid never reached it from
## the tree at all. A `PackedByteArray` indexed by node id rather than a `Dictionary`: node ids are
## dense over `0 ..< grid.node_count()`, and `EventScheduler` asks `depth()` of every sidewalk in
## the city once per role — a `Dictionary` lookup doubled `tests/test_events.gd`'s own run time the
## last time this class asked one per tile instead of indexing an array. Used for a tile with no
## street of its own; see the class doc for why a street tile is answered a different way.
var _node_depth := PackedByteArray()
## Segment key -> how many turnings off the corridor that whole street is. See
## `RouteTree.segment_depths()`.
var _segment_depth := {}
## The covering set: the smallest set of streets such that every route touches one of them. Kept in
## order rather than as a set, because a **set piece** is placed once at each of them.
var _sites: Array[Vector3i] = []
## The streets between two adjacent strands of corridor, as a set. See `RouteTree.gaps()`.
var _gaps := {}

## The corridor of a tree. An empty tree gives a corridor that answers `AWAY` everywhere, which
## is the right answer rather than a special case: a day with no reachable calm has no route for
## anything to be inside or outside of.
static func of(tree: RouteTree) -> Corridor:
	var corridor := Corridor.new()
	if not tree or not tree.grid:
		return corridor
	corridor._grid = tree.grid
	corridor._node_depth = PackedByteArray()
	corridor._node_depth.resize(tree.grid.node_count())
	corridor._node_depth.fill(DEEP)
	var depths := tree.node_depths()
	for node: int in depths:
		corridor._node_depth[node] = mini(int(depths[node]), DEEP)
	corridor._segment_depth = tree.segment_depths()
	corridor._sites = tree.covering_sites()
	for key in tree.gaps():
		corridor._gaps[key] = true
	return corridor

## The streets a set piece is placed on: every route touches one of them.
##
## *"We can have multiple candidate places and make sure all routes touch at least one of them."*
## It is deliberately **the whole list** rather than a pick — the guarantee is that she meets one
## whichever way she goes, and choosing one of them here would throw exactly that away.
func sites() -> Array[Vector3i]:
	return _sites

## How many grid steps off the corridor a tile is. Zero is on it, one is the rim, and it counts
## outwards; `DEEP` is the answer for ground the day's routes cannot reach at all or for a tile off
## the lattice entirely.
##
## **The cap is what makes this small and it is also the design.** Beyond a couple of turnings the
## player is not straying, she is somewhere else, and pricing the fourth turning differently from
## the third would be a gradient nobody can feel — so the range saturates and the constant says
## where.
func depth(tile: Vector2i) -> int:
	var segment := StreetNetwork.segment_containing(tile)
	if segment:
		return mini(int(_segment_depth.get(segment.key(), DEEP)), DEEP)
	if not _grid:
		return DEEP
	var node := _grid.node_at(tile)
	if node < 0:
		return DEEP
	return _node_depth[node]

## Whether a tile is on one of the streets that run **between two adjacent strands of the
## corridor** — the single street a player switches routes through.
##
## `RouteTree.gaps()` is what it means and why; this is that question asked about a tile, which is
## what a placement is stated in. Every gap is on the rim, so this is a refinement of `depth() == 1`
## rather than a fourth band — what a caller does with it is a *further* preference inside the rim.
## A gap is a **street** by definition, so a tile that belongs to none (a junction, or a block
## interior) answers no here even where its cell is on the rim.
func is_in_a_gap(tile: Vector2i) -> bool:
	if _gaps.is_empty():
		return false
	var segment := StreetNetwork.segment_containing(tile)
	return segment != null and _gaps.has(segment.key())

## As far off the corridor as this answers. Anything at or past it is simply *elsewhere*.
const DEEP := 3

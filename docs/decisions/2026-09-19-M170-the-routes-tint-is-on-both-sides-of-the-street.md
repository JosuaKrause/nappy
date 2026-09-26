## M170 — The route's tint is on both sides of the street · built 2026-09-19

> "let's do the mark for the correct path on the full segment (both sides) again -- that way those
> obvious problems now (with obstacles on the path side but no obstacle on the other side) are not
> obvious anymore -- I can still confirm whether you actually fixed those issues via the path
> debug view." · "also the full street segment from intersection to intersection -- no signle
> street tiles" ([PLAYTEST-97](../playtests/PLAYTEST-97.md))

*Asked for one side on 2026-09-15 ([PLAYTEST-76](../playtests/PLAYTEST-76.md), built as M150) ·
overturned by the player to both sides on 2026-09-19, because a one-sided mark makes a wall on the
marked side obvious against the empty sidewalk opposite.* One agent commit on
`feature/m170-route-tint-both-sides`; the stills are
`evidence/m170-route-tint-both-sides-2026-09-19/`.

**What it is.** `City._tint_the_route_kerbs()` asks `Corridor.of(_tree).depth(tile) == 0` again,
the reading M145 had and M150 replaced with `_tree.branches_on(tile)`. `depth()` answers at the
grain of a whole street segment, which gives both of the player's sentences at once: both curb
lines, and the whole segment whenever the tree walks any cell of it, so a route that leaves a
street through an alley or ends at a park partway along still tints it end to end. Nothing else
moved: the route lines of debug layer `5` and every placement rule keep reading the tree's own
sidewalk, which is how the player checks M129's walked-sidewalk rule against the ground.

**Checked rather than assumed:** a street the tree only crosses at a junction cannot light up,
because a junction cell resolves to no segment (`RouteTree._ensure_street_keys()` adds a segment
only when a colored cell lies on the segment's own tiles), and a main-road stretch the tree never
walks is off the growth graph. On the routes suite's seed: 27 crossed-only streets and 11 off-tree
main-road segments untinted, 72 partly walked segments tinted whole. Junctions have no curb tiles
at all. The routes suite's tint check asserts that every segment is tinted whole on both curb
lines or not at all.

## M150 — The tint follows the pavement the route walks, not the whole street · built 2026-09-15

*(2026-09-15, [PLAYTEST-76](../playtests/PLAYTEST-76.md): "why is the yellow tint on both sides?
clearly the bottom path cannot be on any route.")* One agent commit on
`feature/m150-tint-route-side`, reviewed on the PR; the two stills are
`evidence/m150-tint-route-side-2026-09-15/`.

**What it is.** `City._tint_the_route_kerbs()` tints a kerb tile when the tree carries it —
`not _tree.branches_on(tile).is_empty()` — in place of the corridor's depth being zero.
`Corridor.depth()` answers at the grain of a whole street on purpose, since every placement
rule is stated in it, so it tinted both pavements of every street on the tree; the tree
grows on the reachability grid's two-tile cells, where a street's six tiles split into a
pavement cell, a road cell and a pavement cell and the mid-block road cells are off its graph
since M129, so `branches_on` answers per pavement. `Corridor` is untouched. The routes
suite's tint check recomputes the expected set through `branches_on` and adds the assertion
that where a street has both kerb lines tinted, each side is a tree cell in its own right —
non-vacuous, since on the suite's seed 26 of 74 tinted streets carry the tree on both
pavements. That is the reading to keep in mind on the stills: the tinted street beside her
spawn is one of those, both pavements walked by a branch, so both are tinted; the one-sided
case is proven by the sweep over the whole map rather than by a still. `docs/CITY.md` says
the tint follows the tree's own pavement and never the street's far side.

## M108 — Eight-direction entity graphics · the crowd walkers, built 2026-09-11

The first of M108's binding items, the entry's own "bind crowd walkers first". Four agent commits
on `feature/eight-direction-walkers`, reviewed here. **One selector for every eight-view family.**
`EightDirection` (`src/visuals/eight_direction.gd`) is the stroller's sector selection lifted out
whole and made static: `nearest(heading)` picks one of eight sectors clockwise from east with no
hold, `update(current, heading, idle_threshold)` applies the 22.5° boundary and the 5° hold and
keeps the current sector when the heading is at or below the idle threshold, `is_mirrored(sector)`
names the three west sectors that mirror their east-authored partner. The stroller delegates to it
and its own two constants are gone; `tests/test_stroller.gd` passes unchanged, which is the proof
that nothing about her changed. Stateless by choice — the sector shown is the caller's own field,
and a wrapper would be a second name for the same int.

**The walker's binding is a table, not an if-chain.** `CrowdAgent.WALKER_VIEW_BY_SECTOR` maps the
eight sectors to the five authored views, and two dictionaries keyed by view name hold body and
trim, so the two layers can never disagree. **Facing comes from applied travel**: the walker's
along-lane `velocity()` plus the cross-lane steering it is doing this instant, signed and capped
at the steer speed of 90px/s. That second term is the whole point — a walker's lane is always
cardinal, so the diagonal views appear only while it is closing a cross-lane gap, rounding a corner
or stepping aside for her, a window of a few tenths of a second per turn. A walker at or below
`WALKER_IDLE_SPEED` (5px/s, well under the pedestrian floor of 46px/s) holds its last view, so a
queue or a give-way is a standing figure. **No reset call was added to `setup()` or `_recycle()`**:
both place a walker exactly on its lane axis with no steering running, which is a sector centre
45° from either neighbour, twice the hold's reach, so the ordinary update replaces a stale sector
on the next frame. That was the agent's way round the concurrent M111 branch owning both
functions, and it is pinned by the suite rather than assumed. Cars are byte-for-byte unchanged.

**Tests**: `tests/test_walker_views.gd`, the selector across all eight headings, the boundary
hold, the wrap at 360°, the idle threshold and the mirror set; the walker's sector, view and mirror
for every heading, the body-trim key invariant, a stopped walker keeping its view, and a fresh
heading standing in for placement and recycle. **Evidence**: two captures in
`docs/evidence/m108-walkers-2026-09-11/`, neither of which catches a diagonal moment — the window
is too short to photograph on purpose without forcing the steering, which the README says rather
than manufactures. **Open to overturn**: the idle threshold's value, and the choice to put the
selector under `src/visuals/` beside the texture resolver. Left as it was: the people matrix under
`docs/evidence/svg-people-2026-09-10/` still says the walker diagonals are prepared, because it is
dated evidence rather than the catalogue; `GRAPHICS.md` is what says they are live.

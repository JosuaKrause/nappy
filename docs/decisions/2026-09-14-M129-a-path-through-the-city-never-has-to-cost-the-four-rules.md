## M129 — A path through the city never has to cost · the four rules built 2026-09-14

*(2026-09-13, [PLAYTEST-69](../playtests/PLAYTEST-69.md); the reading decided in
[PLAYTEST-71](../playtests/PLAYTEST-71.md); the fourth rule's construction in
[PLAYTEST-75](../playtests/PLAYTEST-75.md): "why not just remove the street tiles and main street
blocks from the graph entirely?"; and "how is this path possible?" of a picture.)* Four agent
commits and one of the session's on `feature/m129-the-four-rules`, reviewed on the PR; the
probe's five runs are `evidence/m129-the-four-rules-2026-09-14/probe-*.txt` and the still is
`routes-after-2s.png`.

**The probe, end to end.** `tests/probes/m129_zero_cost_line.gd`, six seeds by one day per
act, under the decided reading; the baseline reproduces the re-run above exactly.

| | before | junctions | width | beat | mid-block |
|---|---|---|---|---|---|
| routes with a zero-cost line | 50/298 (16.8%) | 25.8% | 30.2% | 30.5% | 100/296 (33.8%) |
| the junction itself is taken (routes / cuts) | 135 / 401 | 140 / 290 | 128 / 241 | 127 / 240 | 129 / 216 |
| one row spans the street | 39 / 97 | 25 / 48 | 19 / 41 | 19 / 41 | 11 / 24 |
| a pacing row with no opening | 6 / 68 | 6 / 47 | 0 / 9 | 0 / 9 | 5 / 17 |
| mid-block crossings | 871 | 871 | 871 | 871 | 0 |
| routes with any carriageway cell | 258 | 258 | 258 | 258 | 0 |

**Rule 1, a route's junctions stay clear.** `RouteTree.junctions()` names the crossings a walk
cannot route around — the junction at each end of every street the tree runs along, plus any a
route's own cells cut through from a park or an alley — and `Corridor.route_junctions()`
carries them. `EventScheduler._leaves_the_route_junctions_open`, inside `_place_one`'s
candidate loop before the spacing, refuses a candidate where its reach *together with
everything already down* would leave the junction box with no four-connected walk joining the
route streets that meet there: checked before the row is accepted, nothing moved or deleted
after. Two readings of "covered" were weighed: a literal one (no reach touches the box) is
arithmetically empty, since a 200 px row could then stand on no corridor street at all, so
*the crossing stays open* is the rule, stated cumulatively because the crossing the probe names
most often is closed by a pair. Open means one walkable tile, which a stroller (28 px) fits
through. The test asserts the finished day and floods the box itself; with the refusal off it
reports 39 closed junctions on seed 4242.

**Rule 2, no single standing row takes a route street's whole width.**
`_leaves_a_line_past_it` refuses a counted row on a route street whose own reach alone would
leave no walk from one of that street's junctions to the other, asking the probe's own
question at placement time. A precinct needs no case and an alley, park cut or square is a
route cell on no street, so the rule says nothing there rather than refusing the alley rows the
corridor uses. With the refusal off: 9 rows spanning a route street on seed 4242.

**Rule 3, a pacing row leaves the line open for part of its beat.**
`_leaves_a_pacing_beats_opening`: on a route street carrying a pacing row, every counted row
reaching that street is asked together whether a walk from junction to junction survives,
and both directions are refused — the pacing row that would land where the rows already down
close its opening, and the standing row that would close one. A pacing row's denied ground is
the intersection of the discs at its beat's corners, exact since a disc is convex. Resiting
or resizing a beat was not built: every break the probe finds is another row's reach covering
the open end, not a beat too long or on the wrong side.

**Rule 4, mid-block crossings are not counted on.** Built as the player said: `RouteTree`'s
`_is_off_the_growths_graph` takes out of the graph the growth walks every carriageway cell
between two junctions and every main-road cell outside a junction, pavements included,
replacing the old rule that only refused to walk the spine's length. Applied in `_ways`, which
every probe and the trunk search go through; the shared `ReachabilityGrid`, the winnability
invariant, `ClosurePlanner`, `CrowdPockets` and `Corridor.depth()` are untouched, since she
can still walk on a road in play. A junction box is kept whole — nine cells, since the box is
six tiles square on a fourteen-tile period and both are even — because a route turning at a
junction passes through its corners. The spine keeps its existing fallback where the doorstep
has no other way out; a carriageway needs none, since a street's two pavements join through
the boxes at both ends. Mid-block crossings 871 to 0; routes touching a carriageway 258 to 0;
165 routes still cross the spine, at junctions. Two second-route *offers* were lost (298 to
296) and no calm area; reported, not repaired. With the filter off the geometry test fails
4,041 times on seed 4400.

**And the picture.** The still on the seed the player asked about showed the drawn polyline's
own first segment, a straight hop from the doorstep to wherever the tree joins the home
frontage, cutting diagonally across the carriageway where no route cell was — so part of "how
is this path possible?" was the drawing. Two axis-aligned legs through the point in front of
the door were tried first and still crossed the carriageway whenever the tree joined the far
pavement, so the connector is gone: the doorstep is not on the tree, and `RouteLines` now
starts each polyline at the route's own first cell, so every drawn segment is a step of the
tree or the calm connector.

**The one fork, resolved by measurement.** The entry's exclusion "anything off the corridor,
where the wall role is the design" reads two ways: exempt any row standing off the corridor
(built first: 24.2%, and the junction shape did not move, since the pair closing a crossing is
usually an ordinary row one turning out with its field reaching in) or exempt the `WALL` role
(shipped: 25.8%). `_copies_of` already makes *wall* and *off the corridor* the same set by
construction. Also tried and reverted: not spending a placement try on refused ground — it
changed nothing, since the loop returns on the first candidate with room.

**What is left, and why it is the player's.** A third of routes carry a zero-cost line where a
sixth did. Of the 196 still broken, `leaf_blower` stands in the cut on 156: it is a `WALL` by
its walk-through cost (37.7 against `Tuning.WALL_WORTH_OF_COST` 35.0) with a 200 px reach
across a 192 px street, exempt from all three placement rules by the entry's own text. Its
reach coming under the street's width, or the wall exemption narrowing, is the **balance**
rule's decision and stays in `TODO.md` under M129. The seals `SealPlanner` places before the
scheduler runs reach crossings the rules never see, the same question one step out. Act IV's
share fell after rule 4 (18.4% to 12.5% on 48 routes), one act of one sample. And
`_test_the_day_is_placed_by_role`'s friction-on-corridor floor moved from 0.45 to 0.35 with a
new floor of 0.45 over the narrow rows alone, since the junction rule pushes the wide rows one
turning out by design; the old docstring's 64% was stale before this branch.

**What CI found on the merge result, and what it was.** The full suite's blocks suite failed on
one seed: two pits on one kerb line 832 px apart, under the 896 px floor. The branch touches
neither the street trees nor that suite. `CityGenerator._place_hard_blockers` grows a reference
`RouteTree` during generation and shuffles its candidate pools with the run's RNG, so the fourth
rule, which changes which segments are on the tree, changes how many draws that shuffle consumes
and every later roll of that seed's city — the expected shape of a correct graph change. What
the new city exposed was older: `StreetTrees` held the spacing inside a run and refused only
the exact streets another run had taken, so two runs a block apart on the same line could plant
their nearest pits under the floor, and no seed in the sweep had happened to do it. Fixed where
the run is accepted, never by moving a pit afterwards: `_too_close_to_a_run_on_the_same_line`
refuses a candidate run whose block gap to an accepted run on its line is under
`_min_run_gap_blocks()`, derived from the spacing, the block size, the period and the mouth
margin — three empty blocks at today's tuning. The agent's choice, open to overturn: the gap is
checked between runs rather than between planted pits, since the check has to come before either
run's pits exist.

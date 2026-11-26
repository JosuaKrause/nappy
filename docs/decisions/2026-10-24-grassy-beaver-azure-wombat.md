# grassy-beaver — The tutorial route's side-street mouths leave out every pair that reaches past a lane · 2026-11-26

Day 1 seals each side street's mouth on the tutorial route with a soft pair (crisp-beaver, #1807). The pairs left
out were a hand list, the delivery van and the market stall, the two that teach a lesson. The café tables were not on
it, and they reach 56px across her line (`EventDef.line_reach()`), near the market stall's 58px. A café pair beside a
lesson's crossing could take both lanes of the sidewalk, `RouteLineRule` then refused the lesson's tiles, and the
lesson left day 1: on main before #1807, seed 4242 lost both the delivery van and the yeller this way. The defect is
from the review of #1807.

**The left-out set is derived.** `SealPlanner._is_left_out_of_a_mouth()` leaves out a soft pair holding a lesson row
(`DawnTutorial.NOISE_PASSED_WIDE`, `SHUTS_HER_SIDEWALK`) or any row whose line reach passes the distance between the two
lanes of a sidewalk (32px, `TUTORIAL_MOUTH_MOST_REACH`; the 32px is the builder's proposal, open to overturn). The construction pair, at exactly 32px, is the widest that
stays; the café tables (56px) and the market stall (58px) go, and a later row is judged by its own reach rather than
by an id somebody remembers to list. `tests/test_seals.gd` asserts that no ordinary side street's mouth body reaches
past a lane, which fails with the café pair back in.

**Measured** with `tests/probes/grassy_beaver_lessons.gd` (144 seeds, rows standing on the route's units):

| row | before | after |
|---|---|---|
| market stall | 140 | 143 |
| delivery van | 137 | 141 |
| homeless yeller | 115 | 120 |

No stray row stood on the route's units in either run. The seeds still missing a lesson lose it to something other
than a café at a mouth.

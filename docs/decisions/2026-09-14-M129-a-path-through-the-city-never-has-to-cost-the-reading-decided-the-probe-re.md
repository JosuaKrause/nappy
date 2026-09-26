## M129 — A path through the city never has to cost · the reading decided, the probe re-run 2026-09-14

*(2026-09-13, [PLAYTEST-71](../playtests/PLAYTEST-71.md), the three readings: "time pass -- don't
route around them"; "the player can cross the street, wait, then come back without ever
getting excited by it"; "it costs by design"; "flocks are basically free already -- don't count
it as block, just count is scenery".)* Two agent commits on `feature/m129-reading-and-flock`,
the first stopped by a usage limit and the second a fresh agent on the same branch; reviewed on
the PR. Each of the four answers overturns the reading the session above recommended.

**A flock is scenery.** *A placed flock stands off the day's routes · overturned on 2026-09-13.*
`EventDef.scenery` is a per-def boolean checked first in `EventScheduler._role_for`, answering
`NONE` — the role already meaning *placed for a reason that is not about the corridor* — before
the cost test that would call a 42-over-168px field a wall, so `_copies_of` neither pulls the
row off the corridor nor weights it onto one. The agent chose a flag beside `hard_fail` and
`city_wide`, which `_role_for` already reads as decision fields, over an id match in scheduler
code, and `NONE` over a fifth role since no downstream reader needed a new value. The field, the
trigger and the rise are unchanged and `validate()` still refuses the row a body. The test that
the row is map-placed on every day stays; `_test_a_flock_is_scenery` checks the role on every
placement of a sampled run and that a flock lands on the day's own corridor at least once, so
the corridor half cannot pass vacuously.

**The probe reads the decision.** `BEAT_OPENING` — a pacing row blocks only the ground its beat
never leaves free — is the primary reading; a mobile row that does not pace, a region door
(`checkpoint_hut`, `checkpoint_gate`) and a scenery row are filtered out before a row is built,
so no reading sees them; the swept-route and doors-out readings are gone, since with those
exclusions they had nothing left to distinguish. Two comparison figures stay: the whole-beat
reading, because *primary* means something only against a second reading, and catalogue rows
only, without the seals and the region wall's own body, because how much of a break is the
day's own placement is a question the primary reading cannot answer. The region wall's body is
not filtered: only its doors were overturned. Pacing is `def.mobile and not def.paces`, read off
the def's own fields.

**The result**, same six seeds, same four days, 298 routes, about half a minute. Routes with a
zero-cost line:

| reading | act I | act II | act III | act IV | all |
|---|---|---|---|---|---|
| primary: a pacing row only where its beat never opens | 29 of 88, 33.0% | 18 of 88, 20.5% | 3 of 73, 4.1% | 0 of 49 | 50 of 298, 16.8% |
| a pacing row over its whole beat | 23 of 88, 26.1% | 10 of 88, 11.4% | 2 of 73, 2.7% | 0 of 49 | 35 of 298, 11.7% |
| primary, catalogue rows only | 29 of 88, 33.0% | 18 of 88, 20.5% | 10 of 73, 13.7% | 2 of 49, 4.1% | 59 of 298, 19.8% |

A broken route is broken in 3.4 stretches on average and 12 at worst, 248 broken routes. The
failing shapes under the primary reading, by the routes each breaks first and by every cut:

| routes | cuts | shape |
|---|---|---|
| 135 | 401 | the junction itself is covered (`cafe_tables` + `homeless_yeller` at one crossing, seed 129129 day 1, breaks three routes alone) |
| 39 | 97 | one row covering the street's whole width alone (`leaf_blower`, 200px, most often) |
| 55 | 200 | a cut that is not a straight band across one street |
| 6 | 68 | a pacing row whose beat never leaves an opening (`homeless_yeller` with `cafe_tables` or `construction` at the open end) |
| 12 | 69 | two rows on the same pavement closing a street together (`market_stall` + `busker`, `poster_crew` + `ice_cream_van`) |
| 1 | 13 | a body with the far pavement also taken (`construction` + `cafe_tables`) |
| 0 | 0 | two friction fields on facing pavements |

The rows most often in a cut: `cafe_tables` and `homeless_yeller` (183 of 248 broken routes
each), `leaf_blower` (176), `poster_crew` (126), `roadblock` (112), `ice_cream_van` (110),
`delivery_van` (109), `market_stall` (107), `busker` (93). `dog_walker` and `police_patrol`, at
the top of the first table, are gone from it: both travel rather than pace, so the decision
takes them out. The mid-block count is unchanged — 258 of 298 routes on a carriageway between
junctions, 871 crossings, all on ordinary streets — since nothing about the grower moved.

**What follows.** The yeller's beat, second shape under the old reading, is fifth under the
player's: passing a pacing row by timing is most of what it costs, and what remains of it is a
beat whose open end is closed by another row. The covered junction stays the shape to cut the
first rule against, and a single wide row the second; the rule that a pacing row leaves the
line open for part of its beat now guards six routes rather than forty-seven and its number is
the reach at the far end of the beat where a second row stands. The junction rule's exclusions
are the four kinds the decision took out of the reading.

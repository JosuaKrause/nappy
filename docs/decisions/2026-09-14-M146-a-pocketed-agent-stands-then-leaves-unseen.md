## M146 — A pocketed agent stands, then leaves unseen · built 2026-09-14

*(2026-09-14, [PLAYTEST-75](../playtests/PLAYTEST-75.md): "I get the remove entity when there is
no route idea. maybe let's do instead stop the entity if there is no way. and despawn once
offscreen" — "it looks very weird otherwise".)* One agent commit on
`feature/m146-pocket-standstill`, reviewed on the PR.

**What it is.** M119 (below, the crowd with nowhere to go leaves) had an agent a seal went up
around pace to the far seal and back until it was out of view, then recycled; the pacing is
what looked wrong. Now `CrowdAgent._process` asks the pocket question ahead of the step: while
`_is_in_a_pocket()` holds, nothing of the step runs — no along-step, no steering, no turn, no
gait, no lookahead, no divert — only the redraw, and out of view it is recycled as before. The
clocks at the top of `_process` keep ticking so nothing resumes strangely when a pocket opens,
and the pocket flood already refreshes on every change to the day's holds, so an agent stops
the frame the seal goes up and walks on the frame the pocket opens. A `_pocket_factor()` beside
`_hold_factor()` and `_yield_factor()` reads `velocity()` down to zero while pocketed, which is
what puts a walker on its standing frame (the gait rests on speed, not on whether the step
ran) and, for free, flattens a pocketed body's field to a plain falloff and makes its projected
approach answer "nowhere", as a stopped body's should. Make-way and bump still land from
outside. `_test_a_pocket_empties_once_it_is_out_of_view` now also holds every caught agent's
position within a pixel across the watched seconds, checked non-vacuous by disabling the
branch once. `docs/MECHANICS.md` and `docs/CITY.md` say a caught agent stands.

**One fork the agent resolved and reported.** M119's own test that a turn-around commits to its
new heading sealed all four arms of a junction and counted reversals inside the box — ground
that is now a pocket and now stands, so reversals fell to zero, a real failure. It now counts
reversals on the four arms, which are held segments and not pocketed ground (the flood labels
only legal-but-trapped ground), so an agent already on an arm when the seal goes up still
finds both ways shut and still reverses: the single-seal-on-open-ground case M119's stride
rule stays for, checked non-vacuous for the suite's seed.

**No burst.** Three attempts on M119's own seeds found no four-armed sealed junction with agents
caught in it in frame, since no flag aims the camera at a tile; the test is the proof. Whether a
standing crowd in a sealed crossing reads as people who gave up or as frozen is the review
item.

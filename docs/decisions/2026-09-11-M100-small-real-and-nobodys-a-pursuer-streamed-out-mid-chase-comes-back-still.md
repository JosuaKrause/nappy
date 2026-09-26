## M100 — Small, real, and nobody's · a pursuer streamed out mid-chase comes back still chasing, fixed 2026-09-11

The other half of the defect the heated patrol surfaced: `EventInstance.resume()` had taken the
notice as a third argument since the first half, and nothing passed it, because
`EventScheduler.Planned` had nowhere to keep it. One agent commit on `feature/pursuer-remembers`,
reviewed here. `Planned` carries `noticed_at` beside `age` and `travelled`; `_stream_out()` reads
it off the live instance and `_stream_in()` hands it back on `resume()`, so a `pursues_within`
row streamed out after noticing her returns still chasing, its chase clock continuing from the
notice rather than restarting. The test drives `EventManager`'s own stream-out and stream-in on
a hand-built `alley_robbery` plan — the one row that carries `pursues_within` cold, so no heat
level and no scheduler roll is needed — and asserts both `not is_waiting()` and a continuing
`chase_age()`; `tests/test_heat.gd` already held the instance half. **Chosen where the design
was silent**: the test calls the manager's private stream methods directly, which is the file's
existing convention, and the streamed instance is left to the rig's city teardown, as every
other live instance in that file is. In play this is the first time a robber or a heated van
that followed her off screen keeps following when the screen comes back.

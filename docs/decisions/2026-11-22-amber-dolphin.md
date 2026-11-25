# amber-dolphin — What the events are set up in is built once and handed down whole · 2026-11-22

**What was asked.** Fable's change to row 3b of minty-quail's `event-interface.md` (the event manager's parts), from its
verdict on the design Opus wrote in its place (the record calm-lemur-jolly-dolphin): what the events are set up in is
built once, where the world is built, and handed down whole. Built as #1635 by Sonnet agents (the first built and pushed
it and stalled before reporting; a second checked it against the design, ran the suites and the parity and opened the
pull request), reviewed adversarially and then by Fable against its design.

**What was built.** One `EventSurroundings` per world, built complete by the simulation builder and handed to the
manager as it is made, stating each default once and owning the world's one record of where she is; the world keeps that
one object and answers from it, and every live event is handed the same one. The manager's pass-throughs (`use_trace()`,
`use_timing()`, `use_atlas()`, `draw_nothing()`, `draw_in()`) and the world's per-field copies are gone; the
protest target is the one late hand-in, told to the shared object. As the design picked, the city's map is asked of the
surroundings and the two setups are one `setup(run, streets, poster_walls)`. `EventManager.use_run()` went too: the
rigs that used it set up on open ground.

**Differences from the design:** a suite hands a recording drawer and a listener through two surroundings builders only
suites call, kept in `tools/test_only_members.txt`, where the world's `use_drawer()` was kept before; the builder's
timing is none until handed, so the null timing sink is stated once, in the surroundings; the manager's public `world`
stays, since the design did not list it.

**Measured.** On main and the branch: the observers' suite line for line (timings masked), the excitement and look
fingerprints identical, the events-cost probe's chain identical in all its runs with the per-tick cost within noise, the
boot suite's atlas check and the navigator check passing. The conversion script for the suites is in the pull request's
description, rewritten from the diff since the first builder's was lost.

# minty-quail — The interior suite walks her on real physics ticks, and the masked man's margins are measured on the game's own body (tests through public seams) · 2026-11-05

minty-quail's `tests-public-seams.md`: `tests/test_interior.gd` and `tests/stroller_steer.gd`, which
moves to `tests/probes/stroller_velocity_step.gd` for the one probe that still steps her by hand.
Tests only.

**Built.** Her own physics step, the building's event manager and her camera run on real ticks in
tree order, sped up by raising the tick rate and the time scale by one factor
(`PhysicsTicks.pass_ticks_faster()`, which restores both). Her body slides along the walls as the
game moves it (`move_and_slide`), where the old rig pushed it by hand without sliding. The
screen-edge badge processes on its own real frames, and from the masked man's warning on the walk
runs at real time, since the badge reads his closing speed as his step over the frame's time; the
badge cases start her one row on from the door, as he already warns from her first tick, and the
door-line table keeps its full walks. The rims are read through what the excitement halo and the
source rim read, and the debug layers through `field_runs()`.

**Measured on the game's own body.** Which walker lines the masked man catches, and every runner
getting through, are unchanged. The margins are wider: on the tightest runner's line he comes within
36.4 px of her centre, where the hand-pushed rig gave 24.6 px, against his 23.5 px catch. A runner
who starts after he does gets through up to 10 ticks late and is caught from 13 ticks on (12 ticks
gets through by 1.4 px); the test pins a start 16 ticks late as caught. The suite's wall time is
about four times what it was, since a headless frame costs about the same whatever its work and the
badge stretch runs at real time.

**Choices, open to overturn.** Re-pinning the late start and the tightest margin to what the game
does, rather than changing the masked man's catch or speed to keep the old numbers, is the
orchestrator's pick on the board question masked-man-late-run, which the player has not answered.
The badge cases skipping the stretch from the door to her second row, and the badge's first-frame
check exempt from lengthened frames, are the orchestrator's calls; whether a slow frame brings the
badge up late in play is not established.

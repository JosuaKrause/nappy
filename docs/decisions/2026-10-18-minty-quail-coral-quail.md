# minty-quail — The interior suite steers, latches, flashes and walks its vents on real input and ticks (tests through public seams: W14) · 2026-11-04

minty-quail's `tests-public-seams.md`: `tests/test_interior.gd`, about half of it, and
`src/interior/interior_scene.gd`.

**Built.** Private-read lines 35 to 7, hand-called frame functions 17 to 3. Steering is read off a
real `Stroller` per tile with a key held and one physics tick let pass, through `Stroller.steering`,
which `PosterWalls` reads too; the door's release latch is driven through `teleport_to_door()` and
the map's `process_player()` and read as whether the fade to black rises on real frames; the
explosion's window flashes are read off the windows' pictures in the tree over a night on real
ticks, beside a twin building, the first flashes falling on the ticks the section's seeded stream
gives through `InteriorScene.distant_flash_wait()`, a pure static every flash of the night draws
through; his catch ends the section on real ticks through `hard_fail_triggered`; the vents' clocks
and grates run on real ticks with a player handed through `use_player()`; the halo and the edge
badge on real frames, the badge handed its atlas as `main` hands it. Every events call hands a
fresh `RunState`. `windows_lit()` and `window_count()`, which only the suite called, are gone. The
suite takes about twice as long for its real ticks and stays under two minutes.

**Not done, and what each wants:** the masked man's walks (`_meet_the_masked_man()` and the four
tests on it, about seventy walks of up to 20 s with margins of a few pixels at 30 ticks a second),
which want a long walk run at the same step faster, or fewer walks; the second masked man up the
same shaft, convertible at about 30 s more; her body walking every flight at 45 degrees
(`tests/stroller_steer.gd` still calls her physics frame by hand), about twenty real-tick walks; the
rim's hold and alpha, the badge arrow and the debug layers' outline, plain canvas draws that no
drawer kind (roof, front, signal head, event) covers, which want a drawer of their own.

# minty-quail — The boot suites read what the booted game shows, and the full run is three suites on real ticks (tests through public seams: W22) · 2026-11-04

minty-quail's `tests-public-seams.md`: `tests/test_boot_handing.gd`, `tests/test_camera_start.gd`,
`tests/test_atlas_loading.gd` and the full run, now `tests/test_full_run_a.gd`, `_b.gd` and `_c.gd`
over `tests/full_run_rig.gd`. Tests only, with the verify skill's and two comments' names of the
full run suite following the split.

**Built.** Private-read lines 3, 1, 3 and 1 to 0, hand-called frames 2 and 1 to 0, and the old
global run state gone from all four. The boot handing suite sees the crowd handed her through the
crowd's field, which centres on her only once the crowd has her: carried away from the doorstep
behind the title it stays put, and after the tap it stands on her. The camera start suite rebuilds
the home's view from the doorstep and the view's extent. The atlas suite boots `main` with each
parent over a sitting it parks and reads the pages off the sitting's atlas, checking the boot
played the parent it was told. The full run ticks the events on real physics ticks at the 0.1 s
step it always took, one seed a suite so each stays under two minutes, and checks on each seed that
the ticks moved the events that travel, which nothing guarded before.

**Not done:** the camera start suite's copy of how the city frames the home's view, which would
drift if the city's own did; its check of the home's viewport fails only with all three of the
pieces that prepare it removed, as before.

# minty-quail — The scenery animation suite reads the city on its own frames and through its drawers (tests through public seams: W5d) · 2026-11-04

minty-quail's `tests-public-seams.md`: the scenery animation suite and its probe, on the roof drawer
(record sandy-raven). Tests only.

**Built.** `test_scenery_animation.gd` (private-read lines 40 to 3, hand-called frame functions 5 to
0) reads a roof's rotors off the units a recording roof drawer (standing them through the real one)
was told to stand, turned by the building's own process frames in the tree; the frame's length is
set through `Engine.time_scale`, restored before the next frame, so no wall clock decides a check. A
building that never notes a vent, whose rotors would never turn, now fails the suite, which calling
its frame by hand had hidden. Event scenery is read through `SpreadLook.slices()` and the body as
the instance's own static body, on a map handed to `setup()`; water through its material, the
ground's own clock on real frames and the atlas it holds; the repaint through
`City.tint_the_route()`, the game's own caller. The city is on a run of its own. The probe reads the
same, and the event's clock. Checks 7086 to 7104; nine mutation runs.

**Not done:** `SceneryLayer._alternates`, which wants the scenery layer to draw through a drawer
handed in, a new drawer kind to be designed; the probe's `Building._vent_timer`, which only a public
member no game class reads could answer.

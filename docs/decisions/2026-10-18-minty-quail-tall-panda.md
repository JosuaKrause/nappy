# minty-quail — The event gait, caret and flame reads go through the event drawer and real frames (tests through public seams: W15) · 2026-11-04

minty-quail's `tests-public-seams.md`: the event drawing leftovers, `test_event_redraw.gd`,
`test_event_strides.gd`, `test_drawn_view.gd` and `test_acts.gd`, on the event drawer (record
azure-plover). Tests only.

**Built.** No suite writes an event's gait or caret state any more (private-read lines 6, 5, 4 and
1 to 0). A fire's flames, its front and `FireLook`'s sizes are read off what a recording drawer was
told to stand; strides off what the drawer stands as the event walks, a held event walked by
`walk_on_by_hand()`, the call a scene recipe uses, and the idle offset through `idle_offset()`;
redraws are counted by the engine's `draw` signal, and the stride check walks to two distances
where the bob quantizes equal, so only the stride can move the picture's key; the flash compares a
marked cyclist with an unmarked twin; the caret's 0, 1, 2, 0 run uses a copy of a row with
`hard_fail` set, built in the test since catalogue rows are shared across suites. That the gate
works out no caret off screen is probed by moving her far off after the gate's frame and asking for
the caret, since nothing else observes it. `tests/drawn_event.gd` gained a map and siting for
`stand()` and `build()`, `frames()` and `shown()`. Every drawn column of a burning facade is checked at its middle and one pixel in from each edge, so a run that loses its last flame fails; the standing dog's rest pose is checked in every view; the off-screen caret probe has an on-screen control that answers true. Of the mutation runs the PR lists, one, flames squeezed to the
run's width, is caught neither before nor now, and matters only for runs under 22 px, which the
city does not make.

**Not done:** the walks are still stepped by `step()` per tick, read through `gait_is_stepping()`
and `idle_is_stepping()`; a walk driven by the manager on real physics ticks would take hundreds of
frames a check. The caret and its flash are drawn by the look itself, not through the drawer, and
are read by the draw count and by `wants_a_mark()` and `caret_strength()`.

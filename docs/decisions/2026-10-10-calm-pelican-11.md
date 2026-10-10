# calm-pelican — The 5% button reach is a minimum, and no catch shrank · 2026-10-10

From the re-review of PR #603 (round-gecko, the unused joystick becomes Run). The player asked for
"the effective radius of all buttons … 5% over the visual radius" because buttons were "easy to
miss"; applied exactly, round-gecko made the existing catches smaller (pause from a 46px to a
27.3px radius, the round title, pause-screen and summary buttons from a 122.7px square to a 48.3px
circle). The player, asked (inbox #648 in [leafy-puffin](../playtests/2026-10-10-leafy-puffin.md)):

> why does the button reach decrease anything??? the 5% should go over the visible size making the area *larger*!

**Read as, open to correction: every catch is the larger of its old catch and 1.05 times its drawn
radius.** Built in PR #654:

| Catch | Before round-gecko | Round-gecko | Now |
|---|---|---|---|
| Pause, the press and the release that fires it (drawn 26px) | 46px radius | 27.3px radius | 46px radius |
| `ModeButton`: the round title, pause-screen and summary buttons (drawn 46px) | 122.7px square | 48.3px circle | the square and the circle together, which is the square |
| Run (drawn 49px) | separate 34px discs, a 46px catch | the whole half past the steering edge | unchanged |

`ButtonGeometry.margin_radius()` gives 1.05 times a drawn radius; `TouchControls.PAUSE_CATCH_RADIUS`
is the larger of `PAUSE_OLD_CATCH_RADIUS` (46px) and that; `ModeButton.contains_design_point()` is
the 1.05 circle or the button's rect grown by a third of its radius. Run needed no change: its
whole half already catches a press, which holds the disc and 1.05 times its radius on both sides,
and a test now pins that. The tests in `tests/test_touch.gd` and `tests/test_pause.gd` pin each
catch against both its old extent and 1.05 times its drawn radius; with the source reverted they
fail 17 checks. Nothing drawn changes, so there is no picture.

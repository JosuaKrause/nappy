# The resistance places and removes against the whole view, not the visible area

**Medium · from the re-review of PR #597 (M226 + dappled-swan, warn before off-screen arrivals and
share the visible view).** #597 rewired the resistance director's only "can she see it" test from
the whole screen to the visible area, which in joystick mode leaves out the two bottom corners under
the touch controls (`src/main.gd`, `_resistance.set_sight(_city.events.sees)`). That is right for
noticing a chalk mark, but the same test decides where a relocated chalk mark, a waiting robber and
the task targets may be placed, when a waiting robber may vanish, and when the taken neighbor may
vanish (`src/resistance/resistance_director.gd`: `_box_shows()`, `_mark_shows()`, `_guard_shows()`,
used by `_nearest_alley_within()`, `_draw_guard_position()`, `_pick_near()`, the mast and neighbor
target pools, the relocation guard in `_track_sight_and_reposition()`, and
`_take_the_neighbor_away()`).

The player's rule, inbox #598 in [olive-hedgehog](../../playtests/2026-10-05-olive-hedgehog.md):
"off screen is not the same as visible -- the corners get removed for visible not for off screen",
and "I don't want any pop in". [Dappled-swan](../../decisions/2026-10-05-dappled-swan.md) and
`VisibleView`'s own doc say placement uses the whole view, corners included.

The case: joystick mode, she walks on more than 400px past an unread mark, and the nearest
qualifying alley mouth lies under the bottom-left control disc; the mark and its waiting robber are
created inside her camera's view, under the controls.

Give the director a second test for placement and removal, wired from `main` to the whole camera
view (for example an `EventManager.on_screen(point)` asking `PendingWarning.seen_from(_visible,
her).sees(point)`), use it wherever something is placed or removed, and keep the visible area for
the notice dwell only. Add a joystick-mode test where the only candidate spot is under a covered
corner and must be refused, and make the `_sight` doc comment say which test answers which question.

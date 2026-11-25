priority: later

# merry-finch — The sixteen-bearing touch case cannot see her body radius in the touch circle · filed 2026-11-23

No player's words name this finding; it is the filer's, and the band `later` is the filer's proposal, not asked for.

**Found** by the builder of pull request #1652 (minty-quail row 5, the resistance).

**What holds today.** `_test_touching_a_tasks_body_from_any_side_completes_it` in `tests/test_resistance_steps.gd` walks her up to the delivery van's and the roadblock's bodies from sixteen bearings and checks a touch from a pressed ring (her edge one pixel off the body's outline) and from a far ring (`solid_reach()` plus her body radius plus `ContactPoint.REACH` plus 2px). The far ring lies past both touch circles, the one with her body radius and the one without, and the pressed ring lies inside both, so taking `Tuning.PLAYER_BODY_RADIUS` out of the touch circle in `src/resistance/contact_point.gd` (the reach `solid_reach() + Tuning.PLAYER_BODY_RADIUS + within`, about line 198) fails nothing. Main does the same. To show it: delete `+ Tuning.PLAYER_BODY_RADIUS` there and run `tools/test.sh test_resistance_steps`.

**What the fix must hold.** The case adds a ring between the two circles (past the circle without her body radius, inside the circle with it) and checks that a touch there completes the task, so removing the radius from `contact_point.gd`'s touch circle fails the suite.

**Proposed, not asked for:** the band `later`, and the extra ring as the fix.

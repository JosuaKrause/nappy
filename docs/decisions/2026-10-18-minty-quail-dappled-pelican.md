# minty-quail — The world's and the player's test-only members go internal · 2026-11-12

**The ask.** A public member only its own class and the tests use becomes internal, its tests checking what the class
does from outside, one staying public only where nothing outside can confirm the behavior, with its reason written
down (curly-rabbit #1098). This pass takes the world's and the player's twelve lines of the test-only list.

## What was built

- **Private**: the screen cover's `left`, `right` and `in_force` (suites call `left_corner()`, `right_corner()` and
  `is_in_force()`, which the visible view calls); the visible view's `joystick` (suites ask whether the view sees the
  covered corners); the walk field's `done` (`is_done()`); the stroller's `steering` (`steering_direction()`, which the
  poster walls call); the excitement source's `player_at` and `player_sensitivity` (suites keep what they told it, and
  the frozen projection reference is handed the sensitivity); the spawn siting's `region()`, now `_region_today()` (the
  suite checks what the siting refuses on day 10 instead).
- **Deleted**: `Baby.world()`, which nothing in the game called; `test_main` reads which world `main` handed her from her
  decay rate, and two checks that held nothing without it are gone.
- **Kept, with reasons on their lines**: `ExcitementSource.clock()`, since an agent's outward signs move on the same
  tick for other reasons and cannot count its steps; `Stroller.pose()`, what she is drawn as, which a headless run draws
  to nothing. A drawer handed to her would let suites record it, but the game has no second drawer to hand, so it would
  exist only for tests.
- **Each new outward check fails when its behavior breaks**: the builder broke each in turn and saw it fail.

## Verified

`tools/check.sh` and the field-read, test-only member, layer, typing and override checks and lint pass; the touched and
owners' suites pass; CI is green.

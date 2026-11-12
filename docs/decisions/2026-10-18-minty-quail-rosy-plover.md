# minty-quail — The resistance's, routes', root files' and run flow's test-only members go internal · 2026-11-12

**The ask.** A public member only its own class and the tests use becomes internal, its tests checking what the class
does from outside, one staying public only where nothing outside can confirm the behavior, with its reason written
down (curly-rabbit #1098); a member nothing in the game reads gets a reader, is tested through what the game shows, or
is deleted (curly-rabbit #1095). This pass takes sixteen lines: the resistance's, two of the routes', the root files',
the sitting's, and the run flow's summary model and calendar.

## What was built

- **Deleted**: `GroundShape.across()` (two checks that only restated it go, the rest read `rounding_radius()`),
  `RouteTree.streets()` (the suite walks `streets_on_the_walk()`, the method the game calls), and `RunTrace.recording()`,
  a factory only tests called, replaced by a test fake extending the run trace and handed in where the game hands it.
- **Private**: the sitting's `restarted_at_msec` (`restart_requested_at_msec()`), the cordon tape's `piece` and `across`
  (a tape is read as a cordon piece with a body), the happenings' `spine_x()`, the park cordon's `park`, the park
  closure's `area` (a filter that never skipped anything goes), the calendar's `checkpoint_day()` (shown by the
  checkpoint saved at dawn and by the go-back landing on it), the summary model's `heading`, `title`, `note` and
  `brief`, and the run configuration's `headless` (`is_headless()`).
- **Kept, with its reason on its line**: `RunConfig.parse()`, the only way to build a configuration besides reading the
  process's command line, which a test cannot set; a configuration is data, built rather than mocked.
- **Each converted check fails when its behavior breaks**: the builder broke ten in turn.

## Verified

`tools/check.sh`, the field-read, test-only member, layer and typing checks and lint pass; the 60 suites naming a
changed member or using the trace pass; CI is green.

# minty-quail — A dead helper of the park cordon is deleted · 2026-11-12

**The ask.** Code nothing reaches is deleted (`dead-code-sweep.md`, inbox #1180 in gray-dolphin).

## What was built

- **`ParkCordon._point_at()` is deleted** from `src/resistance/park_cordon.gd`: a private helper answering the point a
  given distance clockwise from the cordon line's north-west corner, which nothing calls: before the deletion,
  `rg -n '_point_at' src tests tools` finds its definition and, besides it, only a test's name in
  `tests/test_orientation.gd` that contains the word. Nothing else changes.
- **Left**: `EventsAhead.walk_siting()`, the item's other member, which polite-tapir's placement step 4 removes.

## Verified

`tools/check.sh` and the field-read, test-only member, layer and typing checks pass; the cordon's, the park return's and
the resistance steps' suites pass; CI is green.

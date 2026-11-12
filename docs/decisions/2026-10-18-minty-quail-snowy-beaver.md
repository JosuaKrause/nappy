# minty-quail — A dead helper of the park cordon is deleted · 2026-11-12

**The ask.** Unreachable code is deleted (`dead-code-sweep.md`), module by module (inbox #1268 in olive-ferret).

## What was built

- **`ParkCordon._point_at()` is deleted** from `src/resistance/park_cordon.gd`: a private helper answering the point a
  given distance clockwise from the cordon line's north-west corner, which nothing calls (`rg -n '_point_at' src tests
  tools` finds only its definition, and `CarTurn.point_at`, another class's member). Nothing else changes.
- **Left**: `EventsAhead.walk_siting()`, the item's other member, which polite-tapir's placement step 4 removes.

## Verified

`tools/check.sh` and the field-read, test-only member, layer and typing checks pass; the cordon's, the park return's and
the resistance steps' suites pass; CI is green.

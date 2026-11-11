# minty-quail — The city map's suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is: "we type when we can" (inbox #1280 in
olive-ferret). This is the city map's pass of `typed-everywhere.md`'s "What is untyped in a test
goes as its suite is converted", after the city map and its generator were typed
(minty-quail-rosy-pelican) and the runner was typed in every suite (minty-quail-downy-kestrel).

## What was built

- **`test_generator`, `test_blocks`, `test_city_map` and `test_world_passability` are typed**, and
  each loses its opt-out line. No line under `src/` changed.
- **`test_blocks` reads each node of `City.props()` as a `Prop`**, since the method answers
  `Array[Node2D]`; an `Array[Prop]` answer would make the cast unneeded, which is the city scene's
  pass to decide.
- **`test_city_map`'s `_plain` drops its branch for a packed array**, which is already a value.

## Reads left

None: no line of these suites is in `tools/field_reads.txt` or `tools/test_only_members.txt`.

## Verified

The four suites and `test_city_map_cache` pass, `tools/typing_census.py --check` holds, and no
game file changed, so the identity probes do not apply. No check was deleted or moved.

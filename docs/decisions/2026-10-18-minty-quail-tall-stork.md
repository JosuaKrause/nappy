# minty-quail — The telemetry's suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is: "we type when we can" (inbox #1280 in
olive-ferret). This is the telemetry's pass of `typed-everywhere.md`'s "What is untyped in a test
goes as its suite is converted", after the telemetry's own files were typed
(minty-quail-woolly-marten) and the runner was typed in every suite (minty-quail-downy-kestrel).

## What was built

- **`test_telemetry`, `test_telemetry_observer`, `test_visit_counter` and `test_observers` are
  typed**, and each loses its opt-out line. No line under `src/` changed.
- **The recording page counter's bus is typed as the bus's script** rather than `Node`, which types
  every signal the suite reads through it. **The boot callbacks of `test_observers` take `Main`**,
  a preload of `res://src/main.gd`, which has no class name.
- **A Variant-valued `back()` became an index** where the suite needs the type.

## Reads left, each with its reason

The suites read fields of their own fakes only, but for `counter.run.header.day`, a `RunState`
field read through the fake's run: no game method answers the day there, so it stays, and goes with
a run's parts (`field-reads.md`). The frame recorder's suites are not in this pass: the hand-in cut
that rewrites the recorder takes them.

## Verified

The four suites pass, `tools/typing_census.py --check` holds, and nothing a game file runs changed,
so the identity probes do not apply. No check was deleted or moved.

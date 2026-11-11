# minty-quail — The telemetry's suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is: "we type when we can" (inbox #1280 in
olive-ferret). This is the telemetry's pass of `typed-everywhere.md`'s "What is untyped in a test
goes as its suite is converted", after the telemetry's own files were typed
(minty-quail-woolly-marten) and the runner was typed in every suite (minty-quail-downy-kestrel).

## What was built

- **`test_telemetry`, `test_telemetry_observer`, `test_visit_counter`, `test_observers`,
  `test_burst_capture` and `test_performance` are typed**, and each loses its opt-out line. No line
  under `src/` changed.
- **The recording page counter's bus is typed as the bus's script** rather than `Node`, which types
  every signal the suite reads through it. **The boot callbacks of `test_observers` take `Main`**,
  a preload of `res://src/main.gd`, which has no class name.
- **A Variant-valued `back()` became an index** where the suite needs the type.

## Reads left, each with its reason

The suites read no field of the telemetry's own classes. They read and write many fields of other
modules' classes (the run's parts, the live event, the day, the day spec, the map, the plan, her
facing), and those stay until each module's pass; `tools/check_field_reads.py` reads only `src/`,
so it does not list them. `counter.run.header.day` has no method the game calls, as the game reads
the field itself. The frame recorder's and the frame trace's suites (`test_frame_record*`,
`test_frame_trace`) are not in this pass: the hand-in cut that rewrites the recorder and the trace
takes them.

## Verified

The six suites pass, `tools/typing_census.py --check` holds, and nothing a game file runs changed,
so the identity probes do not apply. No check was deleted or moved.

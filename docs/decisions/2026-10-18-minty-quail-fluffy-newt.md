# minty-quail — The telemetry suites build no city and read the telemetry classes through methods · 2026-11-07

minty-quail's `tests-one-module.md`, telemetry, in #1222: each suite tests its one module with
everything else mocked, the city built only where a suite tests the city (inbox #1159 and #1156 in
gray-dolphin), and a test reads its subject only through methods (inbox #1182 in gray-dolphin).

**Built.**
- **`test_telemetry`'s map pictures and `write_map` build no city:** a hand-built
  `StreetMap.full()` map with the home, a calm block, a taken street, a paved vertical street and
  the spine, a `RouteTree` subclass that answers only `cells()`, and hand-made `Planned` objects,
  one per role plus a lethal, a costly stationary, a routed and an unsited one. The two tracing
  cases (a trace changes neither a planned day nor the arcs) and the straight-line routed check keep
  a cached real city by their stated reason, since the promise spans the log and the planners.
- **`test_frame_record` boots nothing;** its real-boot case moved unchanged to
  **`test_frame_record_wiring`**, whose header says why: each fact in it is `main` composing the
  recorder with the world it times.
- **Methods for what the suites read**, read by the game too: `TelemetryLog.file_path()`,
  `FrameLedger.keep_this_frame()` and `is_keeping()`, `FrameRecord.frame_ledger()`,
  `FrameTiming.is_on()`, `Sitting.frame_record_file()` and `use_frame_timing()`;
  `TelemetryLog.recorded_lines()` is a `[kept]` test-only member, since the run log is a file the
  game only writes. `FrameRecorder`, `FrameRecordTiming`, `main.gd` and the `Telemetry` autoload read
  through them, and nine lines left `tools/field_reads.txt`.
- **Measured** (local, heavily loaded): `test_telemetry` about 498 s to about 90 to 140 s.

**Choices where the design was silent, open to overturn:** the placements picture asserted once on
the hand-built set rather than over days 3 and 9; the ledger's frame count read as `rows().size()`
rather than through a test-only method; the timed-body case (`EventInstance` under the record) and
the scheduler's straight-line check left in place for the events' pass.

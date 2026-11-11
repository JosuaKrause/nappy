# minty-quail — The run log's and the page counter's files are typed (minty-quail, typing) · 2026-11-10

**The ask.** Code is typed wherever the language can type it (inbox #1280 in olive-ferret), and a
module's pass types its receivers and deletes its files' first-line opt-out (the godot skill,
"Types"; `docs/todo/2026-10-18-minty-quail/field-reads.md`, "Every receiver gets a class the check
can tell"). A Fable planning agent cut the telemetry module's typing as one pull request.

## What was built

- **Five files lose their opt-out line**: `src/run_trace.gd` (an enum's key read into a `String`
  before it is lowered), `src/telemetry/frame_ledger.gd` and `telemetry_map.gd` (loop variables
  typed), `telemetry_screen.gd` (the main loop read as a `SceneTree`), and
  `src/autoload/visit_counter.gd` (handed the event bus's own script as its type, so its signals
  are typed).
- **`src/telemetry/telemetry_observer.gd` keeps one warning, `unsafe_property_access`**: its event
  manager is typed `EventManager`, which `DayWorld.events()` already hands it, and the stale
  `untyped_declaration` its line named (the typing census found it) is gone. Typing the manager
  lets the field-read check see `EventManager.sources`, read for the run log's loss line; that read
  is the events' interface's to convert, so the observer keeps its warning until then.
- `tests/test_telemetry_observer.gd`'s stand-in source extends the fake event manager, since
  `watch()` now takes an `EventManager`; its unused class goes.
- Nothing is added to or removed from `tools/field_reads.txt`, `tools/test_only_members.txt` or
  `tools/layer_map.py`.

## Parity

The run log is line for line what it was (`tools/test.sh observers`, against its untouched
fixture). What every source charges her (`probes/excitement_fingerprint.gd`, its `XF` lines less
`XF_COST`) and every event, crowd agent and meter on every tick
(`probes/m159_tick_sweep_events_cost.gd`, the `chain` values) give one hash each on `main` at
`651606332` and on the head.

# GoatCounter, the run log and the UI are observers of domain events

Three channels are fed side by side at each call site:
- **Direct run-log calls from game logic:** `Telemetry.note` from `src/resistance/` (48 calls),
  `src/events/` (26), `src/city/` (7), `src/routes/` (5) and `GameState` (7), against
  `event_bus.gd`'s own rule that "the telemetry stays out of the files that decide things".
- **`TelemetryObserver` called directly by `main`** (`day_finished` near 2280, `section_lost` near
  1143, `escaped` near 1197, `start_day` near 2032) plus 7 bus subscriptions.
- **`VisitCounter` (GoatCounter)** listening to about 35 bus signals, about 20 of which exist only for
  it, emitted by `main` at hand-placed points (near 422, 1146, 1200, 2287, 2295) in a required order
  (`day_lost_to` just before `day_ended`); `main`'s loss-cause helpers are documented as partners of
  `VisitCounter`'s private `_loss_event_suffix`, a cross-file contract kept in comments.

So any new path that ends a day or a section has to remember every channel, and one that forgets
loses its counts without an error, which is what the escape does (`escape-as-day-spec.md`). The rule
that every charge ends in exactly one of `pursuit_caught`/`cut_short`/`ended` is kept by convention
across `EventInstance`, `EventManager` and `main` (`end_the_charges_still_running`). The run log's
begin and end are called from five places in `main` and the pause screen's quit; `--no-telemetry` is
parsed raw twice. Adapters reach into `main` by string: `frame_trace.gd` and `frame_recorder.gd` do
`_main.get("_in_the_title")`, which returns null after a rename. Autoloads call UI and dev code
(`GameSave` calls `TitleScreen.build_text()`, `VisitCounter` reads `ControlsMode`, `Telemetry` calls
`AutoScreenshot`).

**Build:** one domain event per fact with its whole payload (for example
`day_ended(spec, result, cause, elapsed)`, and pursuit phases from `events-composed.md`); the run log,
GoatCounter and the UI subscribe; nothing in simulation calls them. One `RunSession` owns the run
log's begin and end. GoatCounter's event names stay as `docs/TELEMETRY.md` lists them, so the page
counts keep their history; a renamed or new name is listed there in the same PR.

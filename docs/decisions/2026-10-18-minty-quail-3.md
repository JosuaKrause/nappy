# minty-quail — GoatCounter, the run log and the UI are observers of domain events · 2026-10-19


minty-quail's `observers.md`, the refactor's third PR (PR #815). The item: game logic fed three
channels side by side at each call site (93 direct `Telemetry.note` calls from resistance, events,
city, routes and `GameState`; `TelemetryObserver` called directly by `main`; `VisitCounter`, the
GoatCounter sender, listening to about 35 bus signals emitted by `main` at hand-placed points in a
required order, with `day_lost_to` just before `day_ended` and `main`'s loss-cause helpers a
comment-only partner of `VisitCounter._loss_event_suffix`), so a new path that ended a day had to
remember every channel; the run log's begin and end came from five places in `main` and the pause
screen; adapters read `main` by string; autoloads called UI and dev code.

**Built.** One `RunSession` (`src/telemetry/run_session.gd`) owns the run log: `main` makes it first
and only calls `open()`, `open_the_escape()` and `close()`; it builds and holds the
`TelemetryObserver`, keeps the one rule for a log a reload carried over, and writes everything else
off the bus (`day_started`, a new `day_planned`, `day_ended`, a new `escape_section_started`, and
`escape_lost`/`escape_out` carrying what the log writes). `day_lost_to` is gone: `day_ended(day,
result, cause, elapsed)` carries the cause, so `VisitCounter` keeps no pending cause, and
`controls_chosen` carries `(joystick, by_key)` instead of the UI's enum. The 93 game-logic lines go
through one injected sink, `RunTrace` (`src/run_trace.gd`), handed down by whoever builds the
component (`main` to `GameState`, `City` and `ResistanceDirector`, and on to their parts; static
planners take it as a trailing parameter) and silent until handed. `ChargeRecord`
(`src/events/charge_record.gd`) owns the rule that a charge ends in exactly one of caught, cut short
or ended, replacing three booleans and five senders in `EventInstance`. The build stamp is
`BuildInfo` (`src/build_info.gd`) and the wait for a drawn frame `DrawnFrame.wait()`
(`src/drawn_frame.gd`), so `GameSave` and `Telemetry` no longer call the title screen or dev code;
`FrameTrace` and `FrameRecorder` are handed Callables instead of reading `main` by string.
GoatCounter's names are unchanged; the escape's counts are left as they were, for
`escape-as-day-spec.md`.

**Verified at test parity** (inbox #813): `check.sh` and `lint.sh`, and every suite the change
reaches, 0 failures; the full suite is CI's. One new suite, `tests/test_observers.gd`, kept as the
cheapest proof of parity: it boots the game, loses day 1 to a car, to crying, to a catalogue row and
to dusk, wins it, starts day 2 and runs a handed-over escape, and checks the exact GoatCounter names
for all of it plus a checkpoint, the three endings, a fresh run, a resume and a reload, and the run
log line for line against `tests/fixtures/observed_run_log.txt`, recorded before any code moved.

**Choices made where the design was silent, open to overturn:** one injected sink for the 93 lines
rather than a domain event per line, since each line is the deciding system's own reasoning built
from values only in scope where it decides, and the facts other observers need already have bus
signals; the build stamp moved down a layer rather than being handed in, which would cost two `git`
spawns per boot; `day_started` keeps its payload; an authored recipe day now gets a day header, so
its lines carry the day's clock rather than `0.0` (every recipe tool runs with `--no-telemetry`);
`ChargeRecord` is handed `EventBus` by its instance; `GameState._trace` is private and exempt from
the save-field guard, and the test runner hands `GameState` a silent trace between suites.

**Left:** `Telemetry` is still called directly by the texture lines in `ground_layers.gd` and the
atlas library, `GameSave`'s save lines and the dev rigs (`RouteRig`, `StillWatch`, `DevRig`);
pursuit phases are `events-composed.md`'s and attach to `ChargeRecord`.

**For the remeasuring step:** GoatCounter's names per fact before and after the release, and a
played run's log against one from before the refactor for the same seed, the recipe-day header the
one expected difference.

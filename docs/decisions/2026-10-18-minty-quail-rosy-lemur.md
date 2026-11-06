# minty-quail — The save, run, telemetry and screen tests stop calling functions only tests call (tests through public seams) · 2026-11-05



minty-quail's `tests-unseen-reads.md`, the save, run, telemetry and screen build (the last numbered
build), under the player's answer that a public member only tests call is deleted where possible,
the tests going through a fake or what the game shows, and one kept only when nothing else can give
the information and the test needs it (inbox #1095).

**Built.**
- Deleted from `src/`, each with its tests moved: `RunState.save_snapshot()` (the game writes a
  save through `GameSave.file_data()`, which reads the run's parts' `state_data()`, and the tests
  now read that); `RunCalendar.settled_yesterday()` (the tests read `settled_this_act()`, which the
  day reads); `RunState.penalise_resistance()`, which nothing in the game called; the save
  indicator's `shows_struck()` (the tests read the drawn icon's atlas region against the
  save-unavailable picture); the save's flush table's `waits_for()` (the tests read `is_empty()` and
  the answers the settle callable they hand in records); `RunSession.observer`, `VisitCounter.should_send()`
  (the counter is handed a recording outbox and the tests read what reaches it);
  `RunStateRegistry.unregistered_in()` (a helper of the run-state suite's own over `parts()`);
  `GoatCounterOutbox.gate_allows()`, which the game never asked (it asks `may_ever_send()` and
  `send()`, and the truth table now runs through those two); and `TitleScreen.mode_name_shown()`,
  whose readers, the finale rig's escape-resume check among them, read the drawn mode label.
- `docs/MECHANICS.md`, `docs/TELEMETRY.md`, `docs/ARCHITECTURE.md` and the comments in the save,
  run and outbox files name what the game calls.
- One check is gone with `penalise_resistance()`: that resistance progress never goes negative,
  which no game path can make happen; the player called it pointless and was glad it went
  (inbox #1097). The visit counter suite gains seventeen
  checks, the outbox gate's sixteen input combinations checked one by one and one more of its truth
  table; every other count is unchanged.

**Kept.** `Telemetry.begin_memory_log()`, the one way a test gets a live run log with no file on
disk; why, and what would let it go, stand in the item. The four `main.use_*` hand-ins and
`TouchControls.use_clock()`, which `main` and the touch controls read themselves, real by default
and a fake when a test hands one in. `Stroller.indicator_sources`, whose readers are other builds'
suites and which nothing else the stroller exposes can stand in for; the presentation suite reads
it too.

**Open to overturn:** the struck save symbol is compared by its atlas region, since a reparented
symbol takes its page again and holds a new texture object; `settled_this_act()` stands in for
`settled_yesterday()`; the finale rig reads the mode label through a small helper of its own.

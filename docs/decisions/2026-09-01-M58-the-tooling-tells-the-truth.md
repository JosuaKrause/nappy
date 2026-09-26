## M58 — The tooling tells the truth · `feature/the-tooling-tells-the-truth`

The 2026-09-01 audit's mechanical findings, built same-day, seven commits, each verified in
isolation and the full suite green after the sweep:

- The rules hook's matcher covered `NotebookEdit` (which sends `notebook_path`, so it could never
  match) and missed `MultiEdit` (which sends `file_path`, so batched edits silently skipped the
  rules). Now `Edit|Write|MultiEdit`. The hook also matched paths by substring anywhere on disk;
  it now exits early for anything outside the repo root — verified by feeding it literal hook JSON
  for `/tmp/elsewhere/src/events/x.gd` (silent) against an in-repo path (injects).
- `shot.sh` and `test.sh` gained the missing-Godot guard the other tools had; `test.sh`'s
  `/dev/null` import pass had been swallowing exactly that failure. `check.sh` now checks both its
  invocations' exit statuses — it could print `OK` over a crash that printed no error string.
- `README.md` documents `--ending bad|neutral|good`.
- **`tools/stats.sh`** — the consumer for playtest 17 finding 3's run tagging. Splits `run-*.log`
  (playtest) from `rig-*.log` (headless), defaults to playtest runs only, and counts only
  documented log entries: runs, days won/lost, loss causes, most-met events. First real output over
  the folder: 49 playtest runs, 14 days won / 20 lost (9 crying, 8 hard fails, 3 timeouts), the
  yeller, the cat and the dog the most-met events — against 55 rig runs that would have drowned
  those numbers, which is the skew the player named.
- **The dead-code sweep**, every symbol re-grepped over `src/` and `tests/` at deletion time, none
  skipped: `EventBus.day_ended`, `EventBus.event_finished`, `EventInstance.finished`,
  `Baby.fell_asleep`/`woke_up`/`started_crying` (all emitted, zero listeners —
  `EventBus.baby_state_changed` and `DayController.day_finished` carry the load),
  `DayController.stop()`, `Corridor`'s `Where` enum with `where()`/`is_inside()`/`holds_street()`
  (superseded by `depth()`), `TrafficIndex.lane_count()`, `BlockPlan.final_purpose()`,
  `Building.roof_depth()`. `GameState.finish_day()` now calls `is_final_day()` instead of inlining
  the same comparison three lines below the query it ignored.

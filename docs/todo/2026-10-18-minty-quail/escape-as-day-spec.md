# The escape's two sections are day specs run by the day's own code

The player's frame: "the escape is just like a normal day with some special settings", "nothing
should be different" (minty-lemur #785). Today:
- **`FinaleController`** (`src/finale/finale_controller.gd`) wraps a `DayController` set up with no
  home, so the day's win can never fire, and adds its own exit check, section and restart.
- **A second boot:** `main._ready_escape()` (near 647-797) builds its own HUD, pause, summary and title,
  and starts the run log with `Telemetry.begin_finale`; its own handlers
  (`_on_finale_summary_continued`, `_on_escape_title_start`, `_on_finale_section_started`,
  `_on_finale_section_lost`) and its own `_process` branch and readout (`_process_the_finale`,
  `_write_the_escape_readout`). The `if _interior:` branch in `_process` (near 2540) cannot run.
- **A lost section skips the day's finish path** (`_on_finale_section_lost` near 1138 against
  `_on_day_finished` near 2256): no loss cause, no `day_ended` with its cause, no
  `end_the_charges_still_running`, no `Telemetry.write_map`/`end_day`, and the screen is the retry
  brief (`DaySummary.show_finale_brief`), whose doc says "There is no reason line and no lost note".
  The player: "losing an escape should still state the reason like the rest of the game. nothing
  should be different. right now it doesn't and it just shows "Escape the city". not sure what led to
  this divergence" (minty-lemur #785). GoatCounter gets only a bare `nappy-escape-lost`, with no
  section, result or cause; a section's retry is never counted as a start.
- **Counted as the wrong day:** escape charges are labelled with `GameState.day`, so the masked man
  lands in `nappy-day-14-*`. Encounter counts are off in the escape (`EventManager._walking_the_finale`
  near 968 and 976; `InteriorEvents` has no `EncounterWatch`). `_on_finale_escaped` (near 1193) never
  closes running charges. `GameState.play_seconds` advances only on the day path, so the ending's
  played time leaves out the escape. The player: "telemetry should work the same also in escape both
  apartment and city -- just making sure this is also proper" (minty-lemur #785).
- **Mode flags read globally:** `Blackout._in_the_escape()`, `PosterWalls`, `GameState` (the
  checkpoint guard, no nerve back, `spend_a_nerve_in_the_escape` duplicating `finish_day`'s loss
  branch), `HUD.set_finale` (the hundredths clock), `DayController.emit_every_frame`.

**Build:** a `DaySpec` (goal tiles and whether she must be asleep there, length, clock precision,
loss policy for nerves and restarts, darkness, posters, crowd density, rows and placement, the
world), injected into `DayController`, which loses its null-home special case; each escape section is
a spec with its own day number (proposed: 15 the building, 16 the city), so every counter, loss
cause, run-log entry and summary goes through the day's path: a lost section shows the day's outcome
screen with its reason, then the retry. `FinaleController`, `_ready_escape`, `show_finale_brief` and
the escape-only handlers and flags go; one boot, one `_process`, one finish path. The section's own
words ("Escape the building", "Escape the city") are the spec's title, shown where "Day N" stands.

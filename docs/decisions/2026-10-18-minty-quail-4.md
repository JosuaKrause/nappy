# minty-quail — The escape's two sections are day specs run by the day's own code · 2026-10-20


minty-quail's `escape-as-day-spec.md`, the refactor's fourth PR (PR #816). The player: "the escape is
just like a normal day with some special settings", "nothing should be different", and "losing an
escape should still state the reason like the rest of the game. nothing should be different. right
now it doesn't and it just shows "Escape the city"" (minty-lemur #785). The escape ran through
`FinaleController`, a `DayController` with no home wrapped in its own exit check, section and
restart; a second boot in `main` with its own HUD, pause, summary, title and handlers; and a lost
section skipped the day's finish path, so it showed the retry brief with no reason, sent GoatCounter
a bare `nappy-escape-lost`, closed no charges and counted no play time.

**Built.** A `DaySpec` (`src/day/day_spec.gd`) holds a day's number, its title, world, goal, length,
hundredths clock, light, darkness and what a loss or a win costs; `DaySpec.for_day()` and
`for_section()` build the two shapes, and the spec names no UI: `main.escape_section_spec()` hands a
section its words ("Escape the building", "Escape the city"), shown where "Day N of 14" stands. The
building is day 15 and the city day 16; `GameState.day` stays 14 through the escape, so the escape
plan's random streams and the save keep their keys. `DayController` is handed the spec and wins at
its goal: home asleep on a day, the service exit in the building, the tunnel or the bridge in the
city; its null-home special case and `emit_every_frame` are gone. `main` has one boot, one
`_process` and one finish path: `FinaleController`, `_ready_escape`, `show_finale_brief` and every
escape-only handler and flag are gone; `_start_section()` is the section's `_start_day()`, and
`_on_day_finished()` ends every day, a section's loss closing the charges, sending `day_ended` with
its cause and showing the day's outcome screen with the reason and the section's words, whose
continue is the retry. `GameState.finish_day(result, spec)` replaces `spend_a_nerve_in_the_escape()`.
`Blackout`, the HUD clock and the day's clock read the spec, not an escape flag. GoatCounter names an
event by the day the last `day_started` announced, so the escape sends `nappy-day-15-*` and
`nappy-day-16-*` (listed in `docs/TELEMETRY.md`) and the `nappy-escape-*` names still fire. The run
log opens a section header per attempt (`Telemetry.begin_section`). From `likely-bugs.md`:
`play_seconds` counts the escape, the charges running when she escapes are closed, and
`show_finale` hides the note line.

**Verified at test parity** (inbox #813): `check.sh`, `lint.sh` and `ci_telemetry_kinds.py`, and 42
suites, 0 failures; the full suite is CI's. Tests that pinned the escape-only behaviour now pin the
new one: `test_finale`'s lost section is one real-boot test (the outcome screen with its reason,
then the retry's brief, the clock standing still behind it); `test_finale` boots a resumed escape
from a save on disk and checks it opens on the title, and a handover on the brief; `test_observers`'
escape half of the run-log baseline was re-recorded (the day half unchanged); and
`test_run_checkpoints`' hard run shows the outcome screen before GAME OVER.

**A retry goes from the outcome screen to the section's brief, then the walk**, as a lost day goes
from its outcome screen to the day's brief: that keeps both the player's "restarting should still
have the day brief for both the apartment escape and the city escape even if the nerves don't go
down" (PLAYTEST-94 10) and "nothing should be different" (minty-lemur #785).

**Choices made where the design was silent, open to overturn:** the building's win goes straight to
the city's brief, with no won-day screen, but sends `nappy-day-15-won`; a hard run's last nerve shows the outcome screen,
then GAME OVER; on `--start-escape` the epilogue's continue reloads into the escape with no title;
Esc does not open over a section's brief or the epilogue and does open over a lost section's outcome
screen, as on a day, and focus loss opens over no summary screen; a scene
recipe's lost section still fails or reloads at once; the building draws no map and the city's maps
have no corridor; a resumed escape's title sends `nappy-controls-*`; the debug readout shows `day 15
escape the building`.

**Left:** posters, crowd density, rows and placement as spec settings are `escape-placement.md`'s;
`_escape_from_a_run` stays on `main` for `main-and-state.md`'s `RunFlow`; the building counts no
encounters until `world-map.md` puts it on the day's event manager.

**For the remeasuring step:** GoatCounter's new day-15 and day-16 names; the escape's blackout
moving from day 14 to `nappy-day-16-blackout` and the masked man's counters to day 15; unchanged
`nappy-escape-*` counts; a `nappy-controls-*` count from a resumed escape's title. The run log of an
escape: a section header per attempt, `to <cause>` on lost lines, the building's `home` line, no
`woke` or `asleep` at the walk-out, the city's dawn and dusk maps, attempt numbers on its picture
filenames, and the ending's played time including the escape. Pictures of the outcome screens: a
lost building section, a lost city section, a hard run's last nerve, both briefs and the epilogue.

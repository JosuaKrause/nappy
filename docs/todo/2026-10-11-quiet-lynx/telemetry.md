# Telemetry, on GoatCounter

"Telemetry" in the player's words means GoatCounter (`docs/TELEMETRY.md`, "The page counts visits"),
so these are GoatCounter events, each named `nappy-...` like the others. The statements are 1
("needs telemetry whether someone chooses hard mode and whether they are restarting from a checkpoint
after losing all nerves"), 3 (answer 4) and 5 (answer 7).

- **`nappy-mode-hard` or `nappy-mode-normal`**, sent once when a fresh run begins, next to
  `nappy-run-fresh`.
- **`nappy-day-N-began`** stays as it is, for every run. **`nappy-day-N-began-hard`** is added for
  hard runs only, so a normal run's count is the total minus the hard one: *"so we know how far
  people get in each mode"* (statements 3 and 5: "Add a hard-only copy").
- **`nappy-checkpoint-N-from-day-M`**, sent when a normal run restarts at checkpoint N after losing
  its last nerve on day M.
- **The per-event stats (influenced, lethal and the like) are not split by mode**: *"hard mode
  doesn't affect gameplay -- only restart pacing"* (statement 3).

**Proposed, not asked for:** the run log (`Telemetry.note`) also writes a line for the mode when a
run begins and for a checkpoint restart, so a run read top to bottom shows where it went back to.
These are logs, not GoatCounter, and are kept apart from the events above.

`docs/TELEMETRY.md` gains the new names in the same pull request.

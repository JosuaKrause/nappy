## M100 — Small, real, and nobody's · a screenshot is numbered, not timed, fixed 2026-09-11

*(2026-09-11, playtest 56: "phot capture must use real time not game time otherwise at the end of
the day all pictures get overwritten"; playtest 57, on the first fix: "HHMMSS-mmm- errrrr why this?
just count the seconds from beginning of the app", then "actually why not just count up the
screenshot numbers?".)* `Telemetry.snapshot()` and `snapshot_now()` named a picture from the day
clock, `%03.0fs<attempt>-<kind>.png`, so two pictures in one second of the day collided and a day
whose clock held at zero under `--invincible` overwrote every shot into one name — playtest 57 asked
for seven at the held clock and kept three. Three agent commits on `feature/capture-real-time`, and
two designs rejected on the way: the time of day to the millisecond, which the player found
unreadable, and seconds since the application started, superseded a minute later by the simpler
shape. **What stands**: `Telemetry._next_shot_name(kind)` gives `%03d<attempt suffix>-<kind>.png`
from one per-run counter, `_shot_serial`, shared by `auto/` and `asked/` so a number places a picture
against every other picture of the run, reset only when a run's log begins and never by a day or an
attempt; the burst folders keep their microsecond stamp. The disk guard the first design needed is
dead under a counter and was removed. Tests pin the shared counter, its survival across a day and
a retried attempt, and two distinct names at a held clock; a rig with a three-second invincible day
produced `001-attempt1-asked.png` and `002-attempt1-asked.png`. `docs/TELEMETRY.md` describes the
names.

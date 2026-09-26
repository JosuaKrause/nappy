## M192 — A curfew day is the old full day, and a free day is longer · built 2026-09-24

*(2026-09-24, the player: "Maybe we could make the curfew have the currently normal time and the
normal time be a bit longer"; asked 210 s or 225 s for days 1 to 5, "210".)*

**Days 1 to 5 are 210 s (`Tuning.DAY_LENGTH_SECONDS`), days 6 to 14 180 s
(`CURFEW_DAY_LENGTH_SECONDS`)**, stated as two lengths; the 0.8 multiplier is gone. 225 s was
offered and not taken: at `SLEEPINESS_GAIN_WALKING` (0.42/s) a whole day of clean street walking
would reach 95 % of the meter, nearly winning a teaching day without a calm place. At 210 s it
reaches 88 % on an ordinary day and 76 % on a curfew day (60 % before), so the street alone still
never settles her; `tests/test_meters.gd` holds that in `day_length()` and needed no change, and
its calm-stretch and grace-of-three checks now measure against 180 s, a looser bound. The late
days' timing (M181, the late days are timed) shows every measured run inside 180 s, the tightest
with 70.5 s left bar day 9 on 90210 at 7.2 s.

**The escape stays 180 s**, `FINALE_LENGTH_SECONDS` stated on its own rather than tied to the
ordinary day, so it does not grow by accident; whether it should grow was asked and is open.
`NEIGHBOR_WALK_HOME_SECONDS` stays 55 s, its docstring now against a 180 s day.

**Numbers moved with it**: docstrings in `tuning.gd`, `event_director.gd` and
`event_catalogue.gd` (pacing notes read as the ordinary day's, so 210 s), `docs/MECHANICS.md`,
`docs/TELEMETRY.md`'s day-6 example lines, `test_event_manager.gd`'s note, and
`tests/probes/m128_park_beats.gd`'s `_SLEEP_CAP_SECONDS` (200 → 230 s, a margin over the ordinary
day that would otherwise have cut the sweep short; re-run, the busker floor is unchanged).
`test_balance.gd`'s arterial-plateau note was re-measured, not retyped: flat through 210 s.
Every 180 or 144 that is a radius, an unrelated constant or a quote was read and left.

**Open to overturn**: keeping the name `DAY_LENGTH_SECONDS` for the ordinary day; the pacing notes
read as the ordinary day's; TELEMETRY's example lines updated as illustrations.

## M100 — Small, real, and nobody's · an invincible mode for playtesting, built 2026-09-11

*(2026-09-11, playtest 56: "can you add an invincible mode for playtesting? that way I can check
off basically all items in one go", "and it let's me inspect things more thoroughly".)* Three
agent commits on `feature/invincible-mode`, reviewed here. **One predicate.**
`DayController._ignores_loss(result)` answers true for any result but a win while
`DevFlags.invincible()` is on, and the three losing paths ask it before `_end()`: the crying
branch returns before setting a failure reason, so the baby stays crying with no text written; the
hard-fail handler returns before its text lookup; the dusk check clamps the clock to exactly zero
and falls through to the unchanged return-and-won logic. A won day ends as it always did. **The
flag** is `--invincible` on the command line or `?invincible=1` in a debug web build, read through
the same args-and-query split `--svg` uses, false in a release build like every dev flag, and a row
in `DEV_FLAG_TABLE` so `tools/run.sh` and `tools/shot.sh` accept it unchanged — the CLI help test
caught that `README.md`'s flag table needed the row too. **On screen**, the word `INVINCIBLE`
rides the existing debug header string rather than a new label or colour; **in the run log**, the
day header line carries `invincible` beside the seeds, once per day. **The test seam** is a static
override on `DevFlags`, because the runner reads the same command-line list a test would otherwise
have to fake; a test sets it, drives each loss path, asserts the day still runs, then asserts a win
still ends it and that with the flag off each path ends the day as before. **Chosen where the
entry was silent**: the day header rather than the run's first line, since that is where the seed
is; the clock clamped at zero rather than run negative. **Evidence**: one capture under
`docs/evidence/m100-invincible-2026-09-11/`, clock still counting, the word in the header, the
status line reading crying with no summary screen. `REVIEW.md`'s intro names the flag as the way to
walk its list in one sitting.

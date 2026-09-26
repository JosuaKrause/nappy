## M100 — Small, real, and nobody's · invincible freezes the clock and the meter, 2026-09-12

*Asked for on 2026-09-11 as everything else real · overturned the same day, playtest 57: "when
invincible the timer should never go down and excitement should never go up. this is just noisy
flashing of alarms and the day gets dark."* The flag's first build kept the day running with every
meter real, which meant the baby cried at once and stayed crying, the alert flashed for the whole
run, and the clock ran the light down to dusk and held it there. One agent commit on
`feature/chalk-and-invincible`. **What stands**: `DayController._process()` skips the countdown
outright under `DevFlags.invincible()`, so `fraction_remaining()` and the light stay wherever the
day started — asked directly rather than through `_ignores_loss()`, which answers whether a result
ends the day, a question a clock that never reaches zero never asks. `Baby._update_excitement()`
empties its source list under the flag, so nothing adds to the meter and nothing reaches
`accumulate_landed()`, which is what charges the halo; decay still runs, so the meter may fall.
Sleepiness, the crowd, the events, the closures and the checkpoints all still run; the HUD word and
the day header's log note stay. **Chosen where the design was silent**: the run clock shown on an
ending (`GameState.play_seconds`, M107) keeps counting real time under the flag, because it
measures the player's session and not the day. Open to overturn. Three tests in
`tests/test_invincible.gd` pin the frozen clock, the meter that does not rise against a live noise
source, and both moving with the flag off; the earlier test that pinned the clock clamping at zero
was rewritten, since that state is now reached only by a day started with no time at all. A live
picture on seed 2199579682, day 7, showed the clock at the day's own starting length and
excitement at zero.

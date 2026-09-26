## M100 — The push at the top is tightened to 9.5 over 3 seconds · built 2026-09-24

*([PLAYTEST-128](../playtests/PLAYTEST-128.md): "we can make the extra push needed to end the day a
tiny bit more aggressive/tighter".)* `Tuning.EXCITEMENT_OVERFLOW_TO_CRY` moves from 10 to 9.5
points; `Tuning.EXCITEMENT_OVERFLOW_WINDOW` stays 3 seconds. Follows M96, the day ends crying only
after a push at the top, whose reason still holds: one bump at the cap leaves 8.88 points of
overflow and keeps her awake, a 0.62-point margin.

**Measured with `tests/probes/m96_crying_at_the_top.gd`**, which now sweeps 10/3s, 9.5/3s, 10/4s
and 9.5/4s and reports time to cry as well as peak mass:

| Scenario | 10/3s | 9.5/3s (taken) | 10/4s | 9.5/4s |
|---|---|---|---|---|
| one bump from 95 | awake (3.73) | awake | awake | awake |
| one bump at the cap | awake (8.88) | awake | awake | awake |
| two bumps 0.3s apart at the cap | cries (15.72) | cries | cries | cries |
| `night_raid` walked past | 5.00s | 4.97s | 5.00s | 4.97s |
| `night_raid` stood in | 0.43s | 0.42s | 0.43s | 0.42s |
| `curfew_announce` walked past | 1.80s | 1.78s | 1.80s | 1.78s |
| `curfew_announce` stood in | 0.35s | 0.33s | 0.35s | 0.33s |
| `abduction` walked past | 2.43s | 2.38s | 2.43s | 2.38s |
| `abduction` stood in | 0.50s | 0.48s | 0.50s | 0.48s |

**A longer window changed nothing measured**: every loud source clears the threshold well inside
3 seconds, so a fourth second never holds anything old enough to count. Only the mass moves
anything. **Open to overturn, chosen by the agent:** 9.5 over the other candidates, as the
smallest change that keeps a real margin over the single bump. The gain it buys is small — a few
hundredths of a second on every loud row — which is what "a tiny bit" was read as; a tighter
number below 8.88 would make one bump at the cap cry, which playtest 126's reason for the gate
rules out.

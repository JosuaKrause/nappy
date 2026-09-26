## M140 — The phone reading · measured 2026-09-14

*(Six phone screenshots of the live page, v0.10.6 (6615746), day 1, seed 123, sent on
2026-09-14 without a word — [PLAYTEST-74](../playtests/PLAYTEST-74.md);
`evidence/playtest-74-phone-motion-2026-09-14/`.)* The run the `REVIEW.md` item asked for
after playtest 73: `?debug=1&seed=123&skip=motion`, then `&skip=motion,crowd`, all within the
first ten seconds of the day, on the same seed as playtest 73's six loads so the four settings
now sit on one city. *Standing* is speed 0 on the sidewalk before a step; the rest are walking
at speed 92. Under `motion` the 234 agents stand where the day placed them, drawn, and every
agent's `_process` and `Crowd._physics_process` return at once; under both words they stand
undrawn as well.

| skipped | where | s left | fps | draws | objects | primitives | process last / mean / max ms | physics last / mean / max ms |
|---|---|---|---|---|---|---|---|---|
| motion | road | 178 | 33 | 716 | 1989 | 6031 | 33.5 / 32.9 / 33.5 | 6.2 / 6.1 / 6.2 |
| motion | crossing | 174 | 39 | 806 | 2238 | 6311 | 32.1 / 43.2 / 46.2 | 8.8 / 9.0 / 9.0 |
| motion | road | 172 | 33 | 710 | 1926 | 5554 | 47.7 / 45.5 / 47.7 | 8.8 / 8.2 / 8.8 |
| motion, crowd | standing | 179 | 37 | 772 | 2272 | 5724 | 34.1 / 56.1 / 57.6 | 6.3 / 4.3 / 6.3 |
| motion, crowd | crossing | 176 | 36 | 668 | 1907 | 4829 | 38.2 / 34.8 / 38.2 | 9.7 / 5.6 / 9.7 |
| motion, crowd | road | 171 | 45 | 639 | 1836 | 4522 | 27.8 / 28.3 / 29.8 | 6.2 / 6.0 / 6.2 |

**Parking the crowd's scripts is the first setting that moves the phone's frame.** Against
playtest 73's table (M139, the phone reading, below), where the crowd walking read 28 to 29
fps with a `process` mean of 41 to 50 ms and `skip=crowd` alone lifted nothing, `motion` reads
33 to 39 fps with a mean of 33 to 46, and `motion,crowd` reads 36 to 45 with a mean of 28 to
56 — the 56 is the standing load, whose `max` of 57.6 says the screenshot's own stall landed
inside the mean's second. So the crowd's scripts are worth about five to ten frames a second
on this phone, and its drawing a few more on top once the scripts are gone. What that also
says is the size of the rest: with the crowd neither ticking nor drawing the phone sits at 36
to 45 fps and 28 to 35 ms a frame, so at least two thirds of the phone's frame is not the
crowd at all.

**The `physics` mean did not fall, so the physics line is not the crowd's.** `Crowd._physics_process`
returns before its first line under `motion`, and the physics mean reads 6.1 to 9.0 ms a tick
with it parked against 7.3 to 7.5 walking (and 4.3 to 6.0 parked and undrawn, the lowest
readings being the standing load and the one with the fewest objects). What runs in that tick
with the crowd gone, read from the code on 2026-09-14: `EventManager._physics_process`
(retiring finished rows, streaming the day's events around her, placing what is owed ahead,
summoning what has been sighted, telling the pursuers where she is, warning about the ground,
checking detentions, the hard fails and the city-wide sources), `Baby._physics_process` (its
excitement scan asks every live event and every one of the 234 agents for `contribution_at`
her position, every tick, parked or not), `Stroller._physics_process` (her own move and the
camera), `ContactPoint`, and the engine's own physics step over every body in the tree. The
project leaves the tick rate at the engine's default of sixty a second, so at the phone's 33
to 45 fps that tick runs once or twice a frame and its 6 to 9 ms is twelve to eighteen of a
frame's 22 to 30 — the larger and least understood half of what is left. The desktop's
physics line reads 1.8 ms for the same work (M139, one atlas for the crowd, the desktop
table), so this is the web interpreter's price for the same scripts rather than a phone doing
more.

**The two oddities from playtest 73 stand.** The `process` mean still outruns the frame the
`fps` line implies (45 fps is 22 ms a frame and the mean beside it reads 28.3; 33 fps is 30
and the mean is 45.5), and `last` equals `max` on four of six process readings, the
screenshot's own stall again. Neither is any closer to explained; the `fps` line remains the
number to read.

**What it opens, asked on 2026-09-14 and not filed.** Two probes are on the table and they are
not the same size. The slower tick for the agents nobody can see (M140, the crowd's scripts
parked, below) can win at most the off-screen share of the five to ten fps the crowd's
scripts cost, since an on-screen agent has to step every frame. The physics tick is the
larger cost and nothing has yet said which of its five callers is the weight — the baby's scan
over 40 live events and 234 agents is the one whose cost scales with the population and runs
sixty times a second whether the crowd moves or not, and it is the first thing a probe of that
tick would want to skip. The recommendation is the physics tick first, because a number that
is not understood is worth more than a number that is. The felt half — whether the lag still
feels the same — is still the player's, and still unanswered in words.

**What closes.** The phone item in `REVIEW.md` for the motion reading.

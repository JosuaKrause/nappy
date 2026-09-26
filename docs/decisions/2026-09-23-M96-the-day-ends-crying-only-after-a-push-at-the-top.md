## M96 — The day ends crying only after a push at the top · built 2026-09-23

*([PLAYTEST-126](../playtests/PLAYTEST-126.md), statements 1, 2 and 8: "the bar can reach 100 but we
need also like 10 over 3s to actually end the day ... removing "undeserved" failures where you
just bump into a single predestrian in an aggravated state" · "yes, let's merge 10 over 3s".)* The
bar still nets incoming against decay and clamps at 100; once it sits at the cap, a further
positive net — what the clamp would otherwise pile on top — is summed over a sliding window, and
the baby cries only when that mass reaches `Tuning.EXCITEMENT_OVERFLOW_TO_CRY` (10 points) within
`Tuning.EXCITEMENT_OVERFLOW_WINDOW` (3 seconds). The mass is never reset, only aged out of the
window, and nothing holds the bar at 100: the moment incoming falls under decay it falls at the
ordinary rate. Asleep and awake share the one gate, since `SLEEPING_SENSITIVITY` already damps
what reaches it.

**Measured with `tests/probes/m96_crying_at_the_top.gd`** against 10/3s, 5/2s and 15/3s: one bump
from 89 now reaches 97.8 and never touches the cap — the decay has moved since the 2026-09-11
measurement that made 89 a cliff — and from 95 it leaves 3.7 over the top; one bump at the cap
leaves 8.9, awake at 10/3s and crying at 5/2s, which is why 5/2s was not taken; two bumps 0.3s
apart at the cap leave 15.7 and cry under every setting, as do the loudest stationary rows
(`night_raid`, `curfew_announce`, `abduction`) walked past or stood in. 15/3s behaved exactly as
10/3s in every case measured. **Open to overturn, chosen by the agent:** counting the overflow
net of decay rather than raw incoming, so a street she is recovering on does not count as fast as
an unopposed one; the one gate for asleep and awake.

## M75 — What the city costs to walk through · built 2026-09-06

Playtest 25's six gameplay findings, built as one balance change because some take cost out of the
city and some put it back, and measuring any of them alone measures the wrong thing.

**The barrier rows went silent, and that is the largest single change to what a day costs the
project has made.** *"static blockages in general shouldn't increase excitement"*, with the player's
own exception in the next breath: *"except for things like ice cream trucks which have inherent
excitement"*. So `construction` (was 11.0), `market_stall`, `cafe_tables`, `delivery_van` (was 8.0)
and `barricade` (was 6.0) stopped emitting; `ice_cream_van` (13.0 over 48/240px, the named
exception) and `leaf_blower` (20.0 over 40/200px) kept their fields. The scale is M64's doing: day 1
plans 147 `cafe_tables`, 124 `market_stall` and 84 `delivery_van` — 355 static bodies, because
sealing puts a barrier on every street off the day's route tree — and fields sum, so the measured
symptom was excitement going **35 → 69 in fifteen seconds of calm ground** in the player's own run
(`docs/evidence/archive/session-captures/2026-09-05/run-181812-seed3038142309-v0.2.0-6-gedeed04-dirty/`), with the log reading
`near market_stall 184px … in 14.2/s (crowd 3.6, events 10.6)`.

**Two of the five kept a field instead of losing it, and that is a narrower answer than the item
asked for.** `cafe_tables` and `market_stall` are crowds rather than scenery, so the player's
adjacent sentence governed them — *"restaurants should only increase your excitement when you're
actually close … but they should nonetheless"* — and the reach was tightened rather than removed:
**170px → 90px** for the café, **185px → 95px** for the stall. 90px is one and a half tiles past a
two-tile (64px) pavement and comfortably inside the 448px block period, so a café can never bill the
far side of its own street.

**Why those two numbers are a stopgap and were recorded as one.** *(2026-09-05: "that number was so
big because it was a point source before".)* A circle centred on a point has to be wide enough to
stand in for a body that is not a point, so the radius was doing the body's job — it over-reaches
perpendicular to a 48px café frontage and under-reaches along it. The fix is M61's third bullet, a
field as the Minkowski sum of the body and a kernel; both catalogue docstrings say so where the
numbers are.

**The startle spike is a short duration at high intensity, and no `impulse` field was added.**
*"dashing cat and dog (not pursuing) are basically useless right now — they need a bigger impact"*.
`cat_dash` went 15.0 → **17.0** and `loose_dog` 24.0 → **32.0**. The cat was deliberately held under
`Tuning.MARK_WORTH_A_DETOUR` so it does not acquire a caret for the first time — the crouch is its
own silhouette — which moved that threshold's stated gap from *between `market_stall` and
`construction`* to *between `cat_dash` (+24) and `checkpoint` (+29)*. **The order mattered and was
stated**: raising the cat while the baseline was still pinned near 100 by the barrier fields would
have made contact an instant loss, which is not what was asked for, so the silencing was measured
first.

**Two rows reported as unmissable were one finding wearing two hats.** `chatting_mother`'s
`detain_radius` and `cyclist`'s lethal `inner_radius` were both **26px** and both went to **33px**.
The chatting mother's 26 was deliberate — it sat under the 32px between a pavement's two walking
lanes so the far lane could never trigger it — and **that reasoning is what the player overturned**:
*"the chatting lady has a way too small capture radius"*. What it gives up is that walking her far
lane no longer avoids her, and the note stayed in the code rather than being deleted. The cyclist
was a defect, not a design change: it already carries `hard_fail`, and the player closed the worry
that the day loop was swallowing it — *"cyclist radius should be bigger, then. that observation was
from local"* — since the desktop build is the one where dying demonstrably works.

**Alleys got a probability where there was none.** *"the probability of blocking off alleys should
be way lower"*, and the player separated the two things that word covers: *"at least for full
blockages — robbers can be frequent"*, so `alley_robbery`'s frequency is untouched.
`SealPlanner._seal_alley_mouths()` had walled both mouths of every qualifying through-alley
unconditionally, every day; `Tuning.ALLEY_MOUTH_SEAL_CHANCE` is now **0.15**, rolled once per alley.
**Sealing one mouth instead of both was rejected as the wrong half-measure** — a through-alley with
one end walled is still not a way through — so the roll is on the alley rather than on the mouth.
0.15 was started low rather than derived, the same way `SEAL_THINNING_FRACTION` was, and is meant to
move against a played day.

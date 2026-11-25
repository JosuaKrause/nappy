# minty-quail — The end remeasure's escape, run logs and GoatCounter names · 2026-11-24

**What it is.** Group L of minty-quail's end remeasure (the entry's README, step 3): the
escape's mix and walks, the run log for the same run against one from before the refactor, and
GoatCounter's names. The evidence, its commands and every per-seed figure are in
`docs/evidence/minty-quail-end-logs-2026-11-24/`. Head is
`f98443b5b19ddada1899c13c4d939d84049ea453`; the pre-refactor tree is the tag v0.29.2
(`094536ab0a34842aa4dfd523dde2191d8c6814e5`), the last release, which keeps downy-tapir's escape
changes out of the comparison. Nothing under `src/`, `tests/` or `tools/` changed, and nothing
is judged: a number is listed and sized, as the entry's README asks.

**The escape's mix and walks** (`tests/probes/escape_winnable.gd`, 24 seeds, head, two full
runs). The mix equals what the record polite-tapir-coral-badger measured after the switch: 0.66
dangers a street, 34% of streets with none, trucks 181, explosions 178, vans 89, roadblocks 46.
The walks differ: out by the tunnel on 10 of 24 (recorded 12) and by the bridge on 9 of 24
(recorded 10), the mean time out 59.7 s and 54.6 s (recorded 64.9 s and 58.5 s). The two runs
agree on all 48 walks, outcome and time, so the spread is none. **The move has a cause:
lilac-owl** (#1545, merged 2026-11-19, two days after the recorded row), where the roadblock's
posted guard follows her round the corner and catches a straight walker about 140 px sooner, a
change the player agreed to (inbox #1534 in velvet-alpaca). The review of this PR bisected 6
seeds, both exits: the commit before #1545 gets 6 of 12 walks out, #1545 gets 4 of 12, and head
equals #1545 walk for walk. It is listed and not fitted: a gameplay number gets no entry of its
own from the remeasure, and the player's words leave a deviation to playtest (inbox #1278 in
olive-ferret).

**The run log** (four runs, v0.29.2 beside head, side by side). Day 1 and day 9 keep the same
header, the same kinds of line in the same order and the same outcome; the plan's events line
differs by design (placement moved on purpose at almost every step) and the walks differ with
it. The escape's log header moved on purpose (one `escape` header became `day 15 Escape the
building` and `day 16 Escape the city`, minty-quail-3 and -7), and a line `plan every unit drawn
before she sets off` is new. v0.29.2's route rig has no escape walker, so the escape's walk and
the building's lines have no pre-refactor counterpart: its escape runs stop at the rig's
wall-clock limit.

**The frame line's physics figure** is the same engine monitor in both trees (`frame_cost.gd` is
byte-identical; it writes the longest physics tick of the previous second), and it reads higher
because work moved onto the 30 Hz tick on purpose: the events (minty-quail-21), the crowd
(minty-quail-33), and the day and the resistance. Past the first 5 s of day 1 the process column
fell from 9.19 to 5.97 ms and physics rose from 3.78 to 18.18; day 9 over every line, physics
6.64 to 12.45. This is no slowdown and no defect. The consequence is sized and listed for the
timings group, which measures the frame profile: the worst frame averaged after start-up rose
from 10.5 to 21.7 ms on day 1 (day 9, every line, 16.0 to 18.1 ms).

**GoatCounter's names.** The quoted `nappy-` literals of the page counter are the same 14
strings at head and at v0.29.2 (`grep -o '"nappy-[^"]*"' visit_counter.gd | sort -u` on each
tree's file), and the builders the same templates. Against the first version of
`tests/test_observers.gd` (`6992c9bff`) one sent list moved, the escape's: the blackout went
from `nappy-day-14-blackout` to `nappy-day-16-blackout`, and the building and the city are each
counted as a day of their own (15 and 16), with the masked man's loss under day 15
(minty-quail-4 and -7). Every other sent list is equal, `docs/TELEMETRY.md` already lists the
day 15 and 16 names, and the task guard's and the lesson dog's names stand at v0.29.2 already,
minty-quail-17 having moved only which counts they hold. **The counts against `docs/stats/` were
not taken**: the live site counts released builds only and nothing merged since v0.29.2 is
released. They are owed after a release, for an entry after minty-quail that is not yet filed
(the plan's pick, open to the player's overturn).

**The behaviors the records hold with a probe or a suite.** The stairwell probe's fifteen
figures (minty-quail-21) are equal. `test_events_pursuit`'s 2.00 s warning measures 2.02 s
(recorded 2.07 s): the suite's own rig was rewritten since (#1646, #1650), and 2.02 s keeps the
contract of never shorter than its number and at most a tick longer. `escape_density.gd`'s own
rows are 200 over 10 seeds (recorded 203; military_convoy 72, abduction 37, roadblock 18,
finale_explosion 73), which moved with the placement changes since and is listed.

**Not measured here.** The recorded recipe's log (minty-quail-3) needs a window and is group
P's. The police patrol's share, which minty-quail-downy-toad and -jolly-toad said would be
fitted at the remeasure, is not fitted: one declared table replaced the fitted ones
(polite-tapir-coral-owl).

**Defects.** None found.

**Footprint.** The evidence folder holds one README, 25 files under `raw/` and no pictures,
about 0.2 MB.

# minty-quail — The end remeasure's escape, run logs and GoatCounter names · 2026-11-24

**What it is.** Group L of minty-quail's end remeasure (the entry's README, step 3): the escape's mix
and walks, the run log for the same run against one from before the refactor, and GoatCounter's names.
The evidence, its commands and every per-seed figure are in
`docs/evidence/minty-quail-end-logs-2026-11-24/`. Head is `f98443b5b19ddada1899c13c4d939d84049ea453`;
the pre-refactor tree is the tag v0.29.2 (`094536ab0a34842aa4dfd523dde2191d8c6814e5`), the last release,
which keeps downy-tapir's escape changes out of the comparison. Nothing under `src/`, `tests/` or `tools/`
changed, and nothing is judged: a number is listed and sized, as the entry's README asks.

**The escape's mix and walks** (`tests/probes/escape_winnable.gd`, 24 seeds, head, two full runs).
The mix equals what the record polite-tapir-coral-badger measured after the switch: 0.66 dangers a
street, 34% of streets with none, trucks 181, explosions 178, vans 89, roadblocks 46. The walks differ:
out by the tunnel on 10 of 24 (recorded 12) and by the bridge on 9 of 24 (recorded 10). The two runs agree
on all 48 walks, outcome and time, so the spread is none, and the move is not noise. It is
**unexplained**: the record's walks were taken before the escape's sections became day specs and before
the later placement and tick changes (records minty-quail-8 and -21 among them), and no run between
them was kept. It is listed and not fitted: a gameplay number gets no entry of its own from the
remeasure, and the player's words leave a deviation to playtest (inbox #1278 in olive-ferret).

**The run log** (four runs, v0.29.2 beside head, side by side). Day 1 and day 9 keep the same header,
the same kinds of line in the same order and the same outcome; the plan's events line differs by design
(placement moved on purpose at almost every step) and the walks differ with it. The escape's log header
moved on purpose (one `escape` header became `day 15  Escape the building` and `day 16  Escape the
city`, minty-quail-3 and -7), and a line `plan  every unit drawn before she sets off` is new.
v0.29.2's route rig has no escape walker, so the escape's walk and the building's lines have no
pre-refactor counterpart: its escape runs stop at the rig's wall-clock limit. **One reading is
unexplained and sized**: the `frame` line's `physics` figure, averaged over a log's frame lines, is 23.3
ms in head against 6.0 in v0.29.2 on day 1 (medians 13.3 and 3.1) and 12.5 against 6.6 on day 9, while fps and the worst
frame are close (132 against 138 fps; the worst-frame mean 30 against 18 ms). Whether the column
measures the same thing in both trees was not established, so it is for the orchestrator to read as a
possible bug entry or not; this record does not.

**GoatCounter's names.** The `nappy-` name literals of the page counter are the same 21 strings at head
and at v0.29.2, and the builders the same templates. Against the first version of
`tests/test_observers.gd` (`6992c9bff`) one sent list moved, the escape's: the blackout went from
`nappy-day-14-blackout` to `nappy-day-16-blackout`, and the building and the city are each counted as a day
of their own (15 and 16), with the masked man's loss under day 15 (minty-quail-4 and -7). Every other sent
list is equal, `docs/TELEMETRY.md` already lists the day 15 and 16 names, and the task guard's and the
lesson dog's names stand at v0.29.2 already, minty-quail-17 having moved only which counts they hold.
**The counts against `docs/stats/` were not taken**: the live site counts released builds only and nothing
merged since v0.29.2 is released. They are owed after a release, as an entry of their own after
minty-quail (the plan's pick, open to the player's overturn).

**The behaviors the records hold with a probe or a suite.** The stairwell probe's fifteen figures
(minty-quail-21) are equal; `test_events_pursuit`'s 2.00 s warning measures 2.02 s on the tick (recorded
2.07 s); `escape_density.gd`'s own rows are 200 over 10 seeds (recorded 203; military_convoy 72, abduction
37, roadblock 18, finale_explosion 73). The latter two moved with the placement changes since, and are listed.

**Not measured here.** The recorded recipe's log (minty-quail-3) needs a window and is group P's.
The police patrol's share, which minty-quail-downy-toad and -jolly-toad said would be fitted at the
remeasure, is not fitted: one declared table replaced the fitted ones (polite-tapir-coral-owl).

**Defects.** None found; one reading (the frame line's physics figure) is for the orchestrator to judge.

**Footprint.** The evidence folder holds one README, 25 files under `raw/` and no pictures, about 0.2 MB.

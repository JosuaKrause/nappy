## M125 — CI runs the shards on eight runners, planned from measured times · built 2026-09-13

*(2026-09-13: "CI is still 12min — any ideas for improving those times?", then "let's do all
three".)* The last green run before this spent 9m16s in its test step for 25.7 minutes of suites
serial — an ideal of 6.4 minutes across four shards, and the gap was two things: the planner
bin-packed by a hand-written cost table that was wrong by up to three times (events at 279s
against a measured 185, crowd at 82 against 227, the balance suite missing), so the heaviest
suite sat in the lightest bin; and four Godot processes contended for one runner's four cores.
Two agent commits on `feature/ci-measured-shards`, reviewed here.

**The planner packs by measured time.** `tests/suite_costs.txt` is one row per suite, in
milliseconds, read by `tools/test.sh`'s cost function; a suite without a row is planned at a
stated default with a warning rather than dropped. `tools/test.sh --record-costs` runs the full
suite and rewrites the file from that run's own per-suite lines, refusing to overwrite on a row
count that does not match the suites on disk, so a crashed shard cannot write a short table.
Seeded from the last green run on main. A separate recording script was rejected: the mode
shares the planner and the shard logs with the rest of `test.sh`.

**Eight shards on eight runners.** `tools/test.sh --shard I/N` plans the same N-way split every
runner plans from the same file, validates `I` and `N` before the import pass, runs one shard in
one process and lets the runner's partial-run note through. `ci.yml` is three jobs: the cheap
gates (lint, cli help, the Python tools, the boot check), a fail-fast-off matrix of eight
shards, and a job named `test` that needs both and fails if either failed, so main's ruleset,
which requires a check of that name, is untouched. Eight because `test_crowd.gd` at about 227s
is a floor no split can lower, and eight puts every other shard at 187 to 189s beside it. The
PR's own run: gates 1m7s, shards 2m53s to 4m22s, **4m29s wall** against 9m16s. The trade is
stated: each runner is a fresh checkout, so the import pass runs eight times for less latency.
A composite action to share the Godot cache steps between the jobs was rejected as more moving
parts than two bounded changes justify.

**What it leaves.** The longest suite is now the whole of CI's time, and the queue's M125 entry
holds the split of `test_crowd.gd` and the pass over the four suites still over budget.

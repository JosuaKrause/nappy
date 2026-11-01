# golden-swan — The local shard kill limit follows the plan · 2026-11-01 · not from an entry


The player agreed on 2026-11-01 to fix this now as its own pull request (inbox #931 in the board question tawny-quail-followups).
`tools/test.sh` killed a local parallel shard after a fixed 600 s and reported it hung. The plan from
`tests/suite_costs.txt` at the default four shards had grown to about 660 s per shard, so a healthy shard was killed;
several agents lost full runs to it on a loaded machine and raised the override to 1500 and 2400 s.

**What changed.** Each shard's limit is 2.5x its own planned time plus 120 s, computed from the bin-packing the runner
already does; `TEST_SHARD_TIMEOUT_S` still replaces every shard's limit. `--plan` prints each shard's planned time and
limit; `--help` states the rule. `TEST_SUITE_COSTS` names an alternative cost file, which the runner's own test uses.

**Why those numbers.** Other agents' Godot processes share the cores, and a shard at twice its planned time is slow, not
hung, so the factor is above 2. The floor covers engine start-up and a shard with little planned work. A real hang is
still named at a small multiple of what the shard should take, well inside a CI job's own budget (CI uses
`--shard I/N`, which no limit bounds).

**Rejected.** A higher fixed number: it goes stale again whenever the suites or the shard count change, which is how the
old one failed.

# bouncy-badger — Measured CI shard balancing and transient runner contention · 2026-10-02

**Source.** [silver-llama, CI shard delays](../playtests/2026-10-02-silver-llama.md)
records the player asking to rebalance, observing that the slow shard varies,
and proposing fewer shards if limited runner availability is causing queueing.
This revisits M125, eight runners planned from measured times, without changing
its requirement to keep complete test coverage.

**Measured cause.** The timing table lacks nine newer suites and assigns each
the five-second fallback. In the latest main run, one of them, spent-park
coverage, takes 114.430 seconds. Resistance is also underestimated: its old
191.571-second cost compares with 239.453, 397.509 and 299.208 seconds in the
three sampled main runs. These are actual suite times, separate from waiting.

The two newest main runs are created ten seconds apart. All eight shards in
the first start within one second; six in the second start after ten or eleven
seconds, while two start after forty-six and fifty seconds. Earlier jobs finish
around those delayed starts, consistent with transient shared runner contention.
The actual account plan and quota remain unavailable through the read-only API.
The nearby non-overlapping run also starts all eight within one second.

Waiting contributes to the latest slow shard, but its test step itself lasts
381 seconds after nine seconds of setup. The other overlapping run's slow shard
starts with its peers and executes for 505 seconds. Source inspection explains
the workloads: resistance repeatedly builds cities and schedules events across
seed/day grids; crowd closures repeatedly simulate and scan agents; spent-park
coverage repaints maps, rebuilds routes and plans events across fourteen days.
This inspection is not a profile attributing time to individual functions.

**Built.** `tools/ci-costs.sh --runs 3` regenerates every suite cost from twenty-four
shard logs in the three newest successful main runs, with no missing suite or
failed fetch. The deterministic planner keeps all 102 discovered suites once.
The eight-shard plan isolates resistance and disperses expensive neighboring
suites. Workflow settings and test assertions remain unchanged.

Reweighting both the old and refreshed assignments with the same new costs
projects a maximum of 381.967 seconds versus 312.057 seconds: a 69.910-second
reduction, about 18.3 percent. Resistance alone sets the latter floor. The seven
other bins each project about 287.9 seconds. This is redistribution evidence,
not a measured end-to-end CI speedup; runner variability, setup and waiting are
outside the additive suite-cost model.

**Count choice, open to overturn.** Keep eight. With the same refreshed costs,
four projects 581 seconds, five 465, six 387, seven 332, and eight through ten
312. Reducing to six adds about seventy-five seconds of projected execution,
against the roughly forty-second extra start delay observed during this overlap.
It might have allowed six jobs to start together in this instance, but shared
account usage cannot guarantee simultaneous starts. More than eight cannot beat
the indivisible resistance-suite floor. Reconsider the count if sustained
queueing in ordinary non-overlapping runs outweighs the smaller plan's execution
cost; no such persistent limit is established by these samples.

**Verified and limits.** The generator's dry run reproduces the table. Before
plans at four through eight and refreshed plans at four through ten each contain
every discovered suite exactly once. Headless import/boot and whitespace checks
pass; no local full suite runs. CI runs every game suite on the PR merge result.
Initial baseline plan captures mixed cold atlas setup with engine errors and
are rejected as clean verification. Fresh baseline captures after successful
headless setup contain no engine error and preserve the same assignments and
projected reduction; their verification and hashes are retained.
The calibration samples differ in revision and runner load, including ground
runtime changes, so their mean estimates scheduling costs rather than measuring
an isolated runtime change. No assertion, seed sweep or gameplay behavior is cut.

The [compact evidence and rerun commands](../evidence/bouncy-badger-ci-shards-2026-10-02/README.md)
retain source revisions, run identifiers, suite timing fragments, old/new plans,
the same-cost calculation and every count comparison. Full CI logs and temporary
coverage outputs remain outside the repository.

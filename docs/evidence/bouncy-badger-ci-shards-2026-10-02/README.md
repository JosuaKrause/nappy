# CI shard balancing evidence

Collected 2026-10-02 from GitHub-hosted Linux CI with Godot 4.7.2. The question is
whether varying slow shards reflect execution or runner waiting, and whether fewer
shards would improve total completion time. The decision is
[bouncy-badger, measured CI shard balancing](../../decisions/2026-10-02-bouncy-badger.md).

`summary.json` retains the source run IDs and full commit IDs, job waiting/setup/
execution measurements, suite workload observations, all candidate count maxima,
generator command and limits. The run order is chronological: non-overlapping
36812212526, then overlapping 37083163561 and 37083176322. These are existing CI
runs, without controlled warmups or host-load matching. Selection uses the three
newest successful main runs available to `tools/ci-costs.sh --runs 3`.

`assignment-comparison.json` records the old eight-way assignment and refreshed
assignment using the same refreshed suite costs. It includes all bin loads,
coverage, input hashes and concrete suite moves. Maximum projected execution falls
from 381.967 to 312.057 seconds, reaching the indivisible resistance-suite floor.
`before-8-shards.txt` and `after-8-shards.txt` retain those exact assignments; their
printed maxima use their respective tables, so the before file's printed 256-second
estimate is not the old assignment's reweighted 381.967-second load.

`plan-maxima.txt` preserves four-through-ten candidate-count comparisons. Timing
fragments preserve the expensive suites behind the reported slow jobs. All suite
costs are in the PR's generated `tests/suite_costs.txt`; `compare-eight-shards.awk`
is the collector used to sum them against the two retained assignments. Original
scratch paths in JSON identify collection inputs; retained files have the same
basenames and hashes here. Full logs, redundant plans and temporary coverage lists
remain in scratch space.

## Recalculate the retained comparison

From the repository root at this PR's committed evidence revision, write output
to fresh scratch space. This calculation needs awk, not the engine:

```sh
shard_scratch=$(mktemp -d)
shard_evidence=docs/evidence/bouncy-badger-ci-shards-2026-10-02
awk -f "$shard_evidence/compare-eight-shards.awk" tests/suite_costs.txt \
  "$shard_evidence/before-8-shards.txt" "$shard_evidence/after-8-shards.txt" \
  > "$shard_scratch/loads.tsv"
rg --files tests -g 'test_*.gd' | sed 's#.*/##' | sort > "$shard_scratch/expected.txt"
for shard_plan in before-8-shards after-8-shards; do
  awk '/^shard / {for (i=4; i<=NF; i++) print $i}' \
    "$shard_evidence/$shard_plan.txt" | sort > "$shard_scratch/$shard_plan-suites.txt"
  diff -u "$shard_scratch/expected.txt" "$shard_scratch/$shard_plan-suites.txt"
done
```

Equal sorted lists prove neither omissions nor duplicate suites. Input SHA-256
values are in `assignment-comparison.json`; revalidate them before interpreting
the calculation on a different source checkout.

## Regenerate historical plans or a fresh calibration

Fetch the durable PR ref before creating clean detached source checkouts; the
implementation commit below contains the recorded new table. Keep the engine
configurable through `GODOT` if an initial atlas/import setup needs it:

```sh
git fetch origin refs/pull/454/head
shard_rerun=$(mktemp -d)
git worktree add --detach "$shard_rerun/base" 6006fa6999a786640851f867b08e8e5d82876d8a
git worktree add --detach "$shard_rerun/refreshed" b98c33d860872ce4f7b5a36aed556412a4e45ea6
for shard_count in 4 5 6 7 8 9 10; do
  (cd "$shard_rerun/refreshed" && TEST_SHARDS="$shard_count" ./tools/test.sh --plan) \
    > "$shard_rerun/refreshed-$shard_count.txt"
done
(cd "$shard_rerun/base" && TEST_SHARDS=8 ./tools/test.sh --plan) \
  > "$shard_rerun/base-8.txt"
```

The plan command does not execute test suites. Inspect every command's outcome;
on a fresh checkout an asset prerequisite failure is not an accepted plan. Use
`tools/check.sh` to complete headless setup if needed, then rerun the failed plan.

`gh run view RUN_ID --json jobs,createdAt,headSha` and
`gh run view RUN_ID --job JOB_ID --log` retrieve the named scheduling records and
timing fragments while GitHub retains them. The generator's
`tools/ci-costs.sh --runs 3 --dry-run` fetches the newest successful main runs at
rerun time; it is a fresh calibration and need not reproduce these historical
numbers. The recorded source run IDs define this collection.

The benefit is projected from an additive cost model. Source revisions differ,
host speeds vary, and unknown account-wide usage affects scheduling. No matched
before/after CI wall-time experiment or guaranteed runner concurrency is claimed.

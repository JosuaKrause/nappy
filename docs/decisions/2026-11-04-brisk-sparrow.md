# brisk-sparrow — CI caches its suite timings · 2026-11-04


The player asked that CI read the previous run's timings and balance from them on the fly
(frosty-owl #1061).

**Built.** CI plans its eight shards from timings CI measured itself on the run before.
- A `plan` job (before `shards`, no Godot) restores the newest cache entry whose key starts
  `suite-costs-v1-` (this commit's own key first), falls back to the committed
  `tests/suite_costs.txt` on a miss, and freezes the file once per run as a job output. A pull
  request sees its own branch's entries and main's.
- Each `shards` leg writes that output to a file and runs `tools/test.sh --shard I/8` with
  `TEST_SUITE_COSTS` on it, so all eight plan the same split. It then hands its own timing lines
  back as a job output of its own, `costs_1` to `costs_8`; distinct names kept the matrix legs from
  overwriting each other, and a leg fails if it measured anything other than the suites it was
  planned.
- A `costs` job merges the eight with the frozen file (`tools/ci-costs-merge.sh`, whose row rules
  it shares with `tools/ci-costs.sh` through `tools/lib_suite_costs.sh`) and saves the cache under
  `suite-costs-v1-<sha>`. It fails, saving nothing, if an output is empty or a suite is measured
  zero or two times.
- The committed `tests/suite_costs.txt` stays: it plans local runs and is CI's fallback.

**Choices.**
- A measured row is blended half and half with the frozen row, rounded: one slow shared runner
  moves a row halfway, and a lasting change is followed within a few runs. A suite with no old row
  takes its measurement.
- The cache is saved only when every shard succeeded. A failed check can end a suite early and
  record a short time, and a hung, crashed or cancelled shard did not finish its list.
- `costs` is not required by the `test` gate: it is skipped whenever a shard did not pass, and a
  cache write is not a test failure. The gate warns when it ran and failed. `plan` is required.
- No artifact is added, so no retention is set; a cache has no retention setting (GitHub evicts an
  entry unused for 7 days).

**Rejected.**
- Each shard restoring "latest" itself: two shards could see different files, and a re-run of one
  shard could see a newer one, so suites would run twice or not at all.
- The player's own two-key design (`suite-costs-v1-<sha>` saved at the end and
  `suite-prev-costs-v1-<sha>` saved first, read exactly by the shards): replaced by job outputs,
  which the player agreed to (frosty-owl #1061), read as instead of the second key.
- An artifact for the plan or for the timings: job outputs held (about 6 KB against a 1 MB limit)
  and need no retention.
- Handing the merge script already-parsed rows: its first run found no timings in them and `costs`
  failed; the legs hand over the runner's own lines as printed.

**Re-run caveat.** A re-run of only some shards reuses the first attempt's `plan` output, so the
split is identical, but it also reuses its `exact` flag. A re-run of `costs` can therefore try to
save a key the first attempt saved; the save reports that it cannot reserve it, as a warning, and
the job succeeds. Skipping the save covers only a `plan` that itself hit the key.

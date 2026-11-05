# brisk-sparrow — CI caches its suite timings · 2026-11-04


The player asked that CI read the previous run's timings and balance from them on the fly
(frosty-owl #1061).

**Built.** CI plans its eight shards from timings CI measured itself on the run before.
- A `plan` job (before `shards`, no Godot) restores the newest cache entry whose key starts
  `suite-costs-v1-` (this commit's own key first), falls back to the committed
  `tests/suite_costs.txt` on a miss, and freezes the file once per run as a job output. The cache
  action searches the run's own scope first: a pull request restores the newest entry its own runs
  saved, and main's newest only when it has none of its own.
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
- The player agreed to these choices (inbox #1068 in gentle-walrus).
- A measured row is blended half and half with the frozen row, rounded: one slow shared runner
  moves a row halfway, and a lasting change is followed within a few runs. A suite with no old row
  takes its measurement.
- The cache is saved only when every shard succeeded. A failed check can end a suite early and
  record a short time, and a hung, crashed or cancelled shard did not finish its list.
- `costs` is not required by the `test` gate: it is skipped whenever a shard did not pass, and a
  cache write is not a test failure. Its checkout, merge and save steps are `continue-on-error`, and a
  last step turns a failure of the merge or the save into a warning annotation, so the job, the run
  and `test` stay green; only a timeout or a lost runner can still fail the job. A red run would count as a failure to `tools/agent-status.sh` and hide the run from
  `tools/ci-costs.sh`, which lists only successful runs on main. `plan` is required.
- A local `tools/test.sh --shard I/8` plans from the committed `tests/suite_costs.txt`, so it
  reproduces CI's shard I only with `TEST_SUITE_COSTS` pointed at that run's table, which the
  `plan` job's log prints whole. The cost-file header, shared by the committed file and every cache
  entry, says what plans from it and every way it is refreshed.
- The shard count is spelled in `SHARD_COUNT`, the matrix, the eight outputs and the `costs` env; a
  comment at `SHARD_COUNT` names them and `costs` refuses to save and warns if the outputs it reads are not
  `SHARD_COUNT` many.
- No artifact is added, so no retention is set; a cache has no retention setting (GitHub evicts an
  entry unused for 7 days).

**Rejected.**
- Each shard restoring "latest" itself: two shards could see different files, and a re-run of one
  shard could see a newer one, so suites would run twice or not at all.
- The player's second key, `suite-prev-costs-v1-<sha>` saved first and read exactly by the
  shards: replaced by the `plan` job's output, which the player agreed to (frosty-owl #1061), read
  as instead of the second key. The first key, `suite-costs-v1-<sha>` saved at the end, is what was
  built.
- An artifact for the plan or for the timings: job outputs held (about 6 KB against a 1 MB limit)
  and need no retention.
- Handing the merge script already-parsed rows: its first run found no timings in them and `costs`
  failed; the legs hand over the runner's own lines as printed.

**Re-run caveat.** A re-run of only some shards reuses the first attempt's `plan` output, so the
split is identical, but it also reuses its `exact` flag. A re-run of `costs` can therefore try to
save a key the first attempt saved; the save reports that it cannot reserve it, as a warning, and
the job succeeds. Skipping the save covers only a `plan` that itself hit the key.

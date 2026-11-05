priority: now
upnext: true

# brisk-sparrow — CI caches its suite timings and the next run balances from them · filed 2026-11-04

**The ask.** The player: "is there a way we can cache the CI timings? that way the next CI can read
the previous version and balance using that info on the fly" (frosty-owl #1061). Asked about by name
afterwards, the design is theirs: "my idea would be to have suite-costs-v1-${{ github.sha }} that is
written at the end with the current sha's timings and one suite-prev-costs-v1-${{ github.sha }} that
is written at the first step with the value of suite-costs-v1- and the shards read
suite-prev-costs-v1-${{ github.sha }} exactly (including the sha so no latest but exactly the sha).
could that work?", then, on a job output instead of an artifact: "what's a job output? if that works
also good", and last "yes, let's do that also for the individual timings don't forget to set the
retention either" (frosty-owl #1061).

**Read as:** the checked-in table `tests/suite_costs.txt`, which `tools/test.sh` bin-packs CI's
eight shards from and which `tools/ci-costs.sh` refreshes by averaging the last green runs' timing
lines through hand-run pull requests, stops being the thing CI balances from. CI keeps its own most
recent timings in a cache and each run plans from the previous run's.

**The design the player's words settle:**

- The plan job reads the newest cache entry whose key starts `suite-costs-v1-` (the restore prefix)
  and hands that table, frozen, to the shards as a job output (the plan job writes it to
  `$GITHUB_OUTPUT`, a shard reads `needs.plan.outputs.costs`; about 6 KB against a 1 MB limit).
  Every shard, and a re-run of one shard, reads the same table, so they agree on who runs what.
  A run on a pull request falls back to the newest entry `main` saved.
- Each shard hands its own measured timings back to an end job as a job output, the same way.
- The end job merges them and saves the cache under `suite-costs-v1-${{ github.sha }}`, so the next
  run restores it by the prefix.
- Any artifact the workflow still uses has its retention set.

**Proposed, not asked for:** the band, `now` with `upnext: true`, since a builder is already working
on it; the player named none.

**Left to the builder, open to the player's correction:** whether a suite measured this run replaces
its old row or is averaged with it, and whether the cache is saved only when every shard finished
(a crashed shard leaves its suites unmeasured, and the old row stays, as `tools/ci-costs.sh` keeps
one today). What becomes of `tools/ci-costs.sh` and the checked-in `tests/suite_costs.txt` (the
fallback when no cache entry exists) is the builder's to say in the pull request.

Playtest: [2026-11-04-frosty-owl](../../playtests/2026-11-04-frosty-owl.md), statement #1061.

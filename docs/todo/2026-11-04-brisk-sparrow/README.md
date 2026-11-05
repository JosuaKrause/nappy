priority: now
upnext: true

# brisk-sparrow — CI caches its suite timings and the next run balances from them · filed 2026-11-04

**The ask.** The player: "is there a way we can cache the CI timings? that way the next CI can read
the previous version and balance using that info on the fly" (frosty-owl #1061). Their own design
came next: "my idea would be to have suite-costs-v1-${{ github.sha }} that is written at the end
with the current sha's timings and one suite-prev-costs-v1-${{ github.sha }} that is written at the
first step with the value of suite-costs-v1- and the shards read suite-prev-costs-v1-${{ github.sha
}} exactly (including the sha so no latest but exactly the sha). could that work?" Then, on the
orchestrator's alternatives: "can the plan job upload an artifact for the shards to read?", "what's
a job output? if that works also good" and, last, "yes, let's do that also for the individual
timings don't forget to set the retention either" (frosty-owl #1061).

**Read as:** the checked-in table `tests/suite_costs.txt`, which `tools/test.sh` bin-packs CI's
eight shards from and which `tools/ci-costs.sh` refreshes through hand-run pull requests, stops
being the thing CI balances from. CI keeps its own most recent timings in a cache and each run plans
from the previous run's. The job output (below) takes the place of the player's own second key,
`suite-prev-costs-v1-${{ github.sha }}`: the orchestrator recommended it over that key and over an
artifact, and "if that works also good" and "yes, let's do that" are read as agreeing to it instead
of the second key, not as well as it. The player's first key, `suite-costs-v1-${{ github.sha }}`
saved at the end, stays. A reader who meant "as well" corrects this.

**The orchestrator's design, which the player agreed to** (the claims are the orchestrator's, not
the player's words):

- A plan job, which this change adds (the `shards` job today needs only `classify`), restores the
  newest cache entry whose key starts `suite-costs-v1-` and hands that table, frozen, to the shards
  as a job output (it writes `$GITHUB_OUTPUT`, a shard reads `needs.plan.outputs.costs`; about 6 KB
  against a 1 MB limit). Every shard, and a re-run of one shard, then reads the same table. A run on
  a pull request falls back to the newest entry `main` saved.
- The shards are one matrix job, whose legs share one set of job outputs, so each leg hands its
  timings back to an end job under an output of its own, one name per shard; one name would keep
  only one leg's value.
- The end job merges them and saves the cache under `suite-costs-v1-${{ github.sha }}`.
- Retention is set on every artifact this change adds. A cache entry has no retention setting
  (GitHub evicts one unused for 7 days).

**Proposed, not asked for:** the band, `now` with `upnext: true`, since a builder is already working
on it; the player named none.

**Left to the builder, open to the player's correction:** whether a suite measured this run replaces
its old row or is averaged with it, and whether the cache is saved only when every shard finished
(a crashed shard leaves its suites unmeasured, and the old row stays, as `tools/ci-costs.sh` keeps
one today). What becomes of `tools/ci-costs.sh` and the checked-in `tests/suite_costs.txt` (the
fallback when no cache entry exists) is the builder's to say in the pull request.

Playtest: [2026-11-04-frosty-owl](../../playtests/2026-11-04-frosty-owl.md), statement #1061.

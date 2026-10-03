priority: now

# bouncy-badger — Rebalance CI test shards from measured suite timings · filed 2026-10-02

The player asks why the slow shard varies, whether runner queueing explains it,
and whether fewer shards would let them all start together. Their words are in
[silver-llama, CI shard delays](../../playtests/2026-10-02-silver-llama.md).

The `now` band is the filer's proposal for this requested tooling work.

Proposed, not asked for: refresh the generated suite costs using successful CI
logs, compare plans at several shard counts and preserve every test. Reduce the
count if scheduling evidence and total completion time support it; fewer shards
alone cannot guarantee simultaneous scheduling on shared hosted runners.

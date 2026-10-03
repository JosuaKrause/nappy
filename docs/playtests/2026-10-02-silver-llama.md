# Playtest silver-llama — Shard one takes much longer than the other test shards

2026-10-02.

The player asked about CI after the save and nearby-ground PRs merged:

> but one thing can we rebalance the test shards? shard 1 takes much longer than the rest. why is it taking so long?

The assistant began comparing suite timings and job scheduling. The player then
observed a different slow shard and proposed reducing concurrency if runner
availability is the cause:

> hmm, it seems random this time it's shard 4

> is it based on queueing?

> if it's queueing and there is a limited amount of runners available? then maybe let's reduce the number of shards so all can go in parallel?

The assistant found that the latest shard four started about forty seconds after
most shards, then executed tests for over six minutes. Scheduling contributes,
but this observation alone does not establish a runner quota or justify a shard
count. Compare scheduling, suite execution and refreshed plans before choosing.

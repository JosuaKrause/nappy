**Find what an earlier suite leaves behind, and make the suite that leaves it clean up.** Run the
fourth of four shards (`./tools/test.sh --shard 4/4`, `tools/test.sh --plan` names its suites),
then narrow the suites run before each failing one until the one that breaks it is found. Fix it where
the README's **Proposed, not asked for** says, so every suite starts from the state a process of
its own would give it. Done when the four checks pass in the 4-shard run
and in their suites alone.

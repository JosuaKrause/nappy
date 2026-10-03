# Explain and rebalance the CI shards

Compare recent successful CI runs, separating job start delays, setup and actual
suite execution. Find which expensive suites dominate the slow shards, why their
tests take that time, and whether a concurrency limit is established or merely
suspected. Explain the varying slow shard with measurements rather than inference
from its name.

Refresh `tests/suite_costs.txt` with `tools/ci-costs.sh`, preserving the measured
source and generator provenance. Compare smaller shard counts with eight using
the same measured costs. Select a count based on completion time and observed
scheduling; if the evidence cannot choose, report the fork before changing it.
Do not weaken assertions, skip suites or change gameplay to shorten CI.

Retain compact before and after evidence and verify that every discovered suite
appears exactly once in each plan. CI verifies the complete suite on the resulting
PR; projected timings must be labeled separately from measured job durations.

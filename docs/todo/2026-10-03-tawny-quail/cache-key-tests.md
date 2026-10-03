**The prediction-reuse tests can fail when a cache key field goes missing**
([#439's review](https://github.com/JosuaKrause/nappy/pull/439#pullrequestreview-5400270439), reuse
identical danger prediction samples; no correctness bug was found in either cache).

The review removed each key field in turn and reran the suite; these survived:

- `tests/test_prediction_reuse.gd`, the crowd checks for each jolt field and `kind`: the test adds
  1.25 to a jolt on a body that was never startled, so the jolt never reaches the query point.
  Removing `kind`, `_jolt`, `_jolt_for`, `_jolt_intensity`, `_jolt_inner` or `_jolt_outer` from
  `CrowdAgent`'s key one at a time leaves the suite green. That matters in play: `_jolt` decays every
  render frame while her position changes on 30 Hz ticks, so a key without it would replay a stale
  value. Startle the body first, change one field at a time, and check that `sampling_runs` rose.
- The event checks: `shape.kind` and `shape.half_extents` change only together, and the core
  fields change at a point their core never reaches (a 64px core, the point 170px out). Change kind
  and extents separately, test the core inside its reach with a moving player, and check
  `sampling_runs` rose.
- `tools/test_experiment_preflight.py`'s test that the audit refuses to instrument its own
  repository runs the real audit on the real checkout; if that guard regresses, the test rewrites
  `src/events/event_instance.gd`, `src/crowd/crowd_agent.gd` and the profile observer before it
  fails. Copy the audit script into a throwaway git repository and test the refusal there.
- The two evidence runners (the classification one and the prediction one) are copies, the second
  weaker, and both are now load-bearing (the preflight test runs them; CI's sparse checkout keeps
  them). Move the shared runner under `tools/` before a third experiment copies it. This was
  raised before the merge as optional and left.

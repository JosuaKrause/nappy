# The pass probe's comments name a suite that does not exist

`tests/probes/m174_pass.gd` prints what walking past an event costs her, and its static functions
are shared: `pass_net_averaged()`, one simulated pass averaged over the event's pulse, is called by
`tests/test_events_emission.gd`, `tests/test_events_scenery.gd`, the probe
`tests/probes/m205_note_handover.gd` and `tools/cost_table.gd` (which also reads its `OFFSETS`). Two of its comments say they are public
so that `tests/test_events.gd` shares them, the one above `historical_def()` (the event rows as they
stood before a change of the yeller's reach) and the one above `pass_net_averaged()`; no
`tests/test_events.gd` exists. The relationship test the second names is in
`tests/test_events_emission.gd`, and `historical_def()` has no caller outside the probe.

*Proposed, not asked for:* both comments name what calls each function today, and
`historical_def()` becomes private to the probe, since nothing else calls it. This is not a failure
of a run and goes with whatever the probe's own item decides, or alone.

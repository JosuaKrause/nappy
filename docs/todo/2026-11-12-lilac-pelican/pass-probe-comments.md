# The pass probe's `historical_def()` is public and nothing outside the probe calls it

`tests/probes/m174_pass.gd` prints what walking past an event costs her, and its static functions
are shared: `pass_net_averaged()`, one simulated pass averaged over the event's pulse, is called by
`tests/test_event_phase.gd`, `tests/test_events_scenery.gd`, the probe
`tests/probes/m205_note_handover.gd` and `tools/cost_table.gd` (which also reads its `OFFSETS`).
`historical_def()` (the event rows as they stood before a change of the yeller's reach) is public
too, and has no caller outside the probe.

*Proposed, not asked for:* `historical_def()` becomes private to the probe, since nothing else
calls it. This is not a failure of a run and goes with whatever the probe's own item decides, or
alone.

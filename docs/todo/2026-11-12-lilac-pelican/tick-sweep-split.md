# The tick sweep probe's split step no longer matches the real one

`tests/probes/m159_tick_sweep_events_cost.gd` times the baby's influence sweep and the events'
physics step per tick, on fixed seeds and days, in two modes: `whole` runs the real
`EventManager._physics_process()`, and `split` makes the events' step's calls one by one in its own
copy of their order, timing each apart. Both chain a hash over every event's and agent's state and
the baby's meters after every tick, and the probe checks the two chains agree, which is what shows
the split is still the step the game runs.

**Its first failure:** six of its checks fail; the first is that on seed 478156010, day 9, the
split step does not change every event, agent and meter exactly as the real one does, and day 14
fails the same way (the record 2026-10-18-minty-quail-snowy-magpie). Its records still hash the same
on `main` and on that pass's head, so it measures what it measured; whether the split measures the
game's step is what fails.

**A real difference, not only a stale probe, until shown otherwise.** Read against
`EventManager._tick_the_events()`, the probe's copy (`_split_events()`) leaves out two calls the real
tick makes, `streaming.bring_back_what_repeats()` and `checkpoints.warn_at_the_doors()`, and calls
the doors' watch without the tick's `delta`; that is a likely cause, not run to confirm.

*Proposed, not asked for:* fixed, by making the split's calls the real tick's (or by the tick
exposing its parts so the probe times them without a copy that drifts), then showing the two chains
agree on every seed and day. Deleting it loses the per-call cost of the events' step, which the
refactor's end remeasure reads.

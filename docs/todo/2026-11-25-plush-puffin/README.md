priority: later
after: 2026-10-18-minty-quail

# plush-puffin — Streaming's lookup costs 165 microseconds a tick more than before the refactor · filed 2026-11-25

**The ask.** None. The remeasure's README asked whether a cheaper lookup in `EventStreaming.stream_around()` (the call that decides each tick which placed events are live around her) is worth an entry; the orchestrator ruled that the comparison is v0.29.0, the refactor's own additions (row 3a's plan questions and the state table, #1598), and by that comparison the answer is yes.

**Evidence.** Split mode's stream column: head 272.2, 269.8 and 271.0 µs a tick against v0.29.0's 106.6, 105.9 and 105.9 in three rounds started together: +165 µs, 18% of head's events step (928 µs), slower in every round with no overlap. Against pre-3a (202f964ec) the difference is +80 µs (289.1, 293.2, 289.1 against 208.7, 210.6, 208.3), 8% of head's step of 988 µs, which is row 3a's own share and stays as context. Per plan: 924 ns against 285 beside v0.29.0, though a day holds 292.9 plans on head against 371.7. Figures: `docs/evidence/minty-quail-end-timings-2026-11-25/README.md` (table T4) and `docs/evidence/minty-quail-end-timings-2026-11-25/raw/sweep_end_vs_v029_*` and `docs/evidence/minty-quail-end-timings-2026-11-25/raw/sweep_v029_side_*` (beside v0.29.0), `docs/evidence/minty-quail-end-timings-2026-11-25/raw/sweep_end_vs_pre3a_*` and `docs/evidence/minty-quail-end-timings-2026-11-25/raw/sweep_pre3a_side_*` (beside pre-3a); the reading is in minty-quail-downy-finch.

**Proposed, not asked for:** the band `later` and the bar (slower in every round beyond spread and by more than a tenth of the events' whole step) are the filer's proposal (the remeasure's planner, minty-quail-downy-finch), open to the player's correction; the plainer alternative is to file no entry and let a phone's frame record (polite-plover) decide first.

**What would close it.** `tools/test.sh probes/m159_tick_sweep_events_cost.gd` on head beside v0.29.0, three rounds started together, reading split mode's stream column and planned events, after the lookup is made cheaper: the stream column within a tenth of the events' step above v0.29.0's, or the remainder named as the plan questions' price and accepted.

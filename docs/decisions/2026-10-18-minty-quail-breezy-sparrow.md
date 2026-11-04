# minty-quail — The scheduler, arrow, event phase and event manager suites read what the game asks, and a day's spec carries its share of walls kept (tests through public seams: W23) · 2026-11-04

minty-quail's `tests-public-seams.md`: `tests/test_events_scheduler.gd`,
`tests/test_resistance_arrow.gd`, `tests/test_event_phase.gd` and `tests/test_event_manager.gd`, with
`src/day/day_spec.gd`, `src/events/event_scheduler.gd` and a sentence of `docs/EVENTS.md`;
`tests/test_pursuer_on_foot.gd` and `tests/test_events_solid.gd` were looked at and left.

**Built.** Private-read lines 3, 2, 1 and 1 to 0. A day's spec carries the share of its walls the
day keeps, `DaySpec.wall_row_share`, which `DaySpec.for_day()` sets (the gatehouse day's share
moved there from the scheduler) and `EventScheduler.build_day()` reads, so the scheduler suite
plans a day twice through `build_day()`, as the game plans it and with every wall kept, and
compares the two; it checks that only placed wall plans are taken out, since where the fill starts
is not exposed. The arrow suite reads the siting through `EventsAhead.walk_siting()`; the event
phase suite holds the robber's notice by standing her inside his stand-off, where
`notice_her_at()` holds it every tick; the event manager suite reads an arrival's intensity through
`current_intensity()`. Five mutation runs; narrowing the siting band to nothing is not caught,
since the offer widens an empty band.

**Not done:** the pursuer suite's tick, which calls the manager's private tell and hard-fail check:
real manager ticks over its fifty-six whole encounters ran past eight minutes against about twenty
seconds, so it wants a cheaper real-tick path or a manager tick for the pursuit alone that the game
also calls; the solid suite's walked sidewalk bands, which only the scheduler asks and which want
handing to another game class, a design of its own; the notice that runs for a while and is then
held, which the stand-off cannot reach, since he lunges the moment she is back at it.

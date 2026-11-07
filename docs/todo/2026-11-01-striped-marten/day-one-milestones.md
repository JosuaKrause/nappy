# Day 1's first obstacle passed is counted

The player: "agree with the goat measuring" (curly-moose #819), answering the proposal: GoatCounter
events for day 1's milestones (first obstacle passed, first crossing, park reached, asleep, home),
read before and after this entry, and three to five first-time phone players watched without help.

**What is left: first obstacle passed.** Only the events know an obstacle was passed. The encounter
watch (`src/events/encounter_watch.gd`) emits `encounter_seen` and `encounter_influenced`, but a
static row (a fallen tree, roadworks, a crash, a skip) is never influenced. It needs a signal such as
`EventBus.obstacle_passed(day)` emitted beside the other two, and one handler in `VisitCounter`
calling `_reach_a_milestone("first-obstacle")`, under **telemetry**'s rules and `docs/TELEMETRY.md`'s
naming, on day 1 only. It is built once #1169 (the day's events after dawn, which owns
`src/events/`) has merged, and ships ahead of grassy-beaver (a day one that teaches), so a window
before the change exists to compare against.

# minty-quail — The run log's three summary lines are asked of the parts · 2026-11-11

**The ask.** No class takes a whole `City` when it reads only parts of it, so no test of it has to
build a city ("the city should never be built for tests that don't test the actual city",
inbox #1156 in gray-dolphin; "no test should build a real object that it doesn't test", inbox #1159 in
gray-dolphin): the summary lines of `city-hand-ins.md`'s third pull request, in the cut the board
question hand-ins-third-cut proposes (several pull requests; built on that pick). Where each line
goes was the hand-ins' builder's proposal and the orchestrator's, open to the player's correction.

## What was built

- **The run log's three summary lines leave the city scene**: the road closures' line is asked of
  the day's streets (`DayStreets.closure_summary()`), the events' line of the event manager
  (`EventManager.event_summary()`, which asks each plan its row's id), and the calm areas' line of
  the map with the run's block arcs handed in (`CityMap.calm_summary(arcs)`), since which calm areas
  are spent is the run's state, not the map's.
- **The run log's session (`RunSession`) is handed the run's block arcs** at setup and asks the
  streets, the map and the event manager for the lines; the day director's start print asks the
  same.
- **A road closure says its own words** (`RoadClosure.summary_words()`, such as "roadworks
  v(8,6)"), so the streets' line reads no field of a closure; `tools/field_reads.txt` lost two lines
  and gained none.
- The day director's fake city lost its two summary overrides; the streets' and the map's suites
  check the "none" line directly, and the event manager's checks its line before a day and after.

## Choices open to overturn

- **`RoadClosure.summary_words()`** is a method outside the builder's files, added so the streets'
  line reads no closure field rather than adding two lines to the field-read list (the builder's).
- **The run log's session is handed the run's block arcs** as an argument of its setup, since it
  has no listed read of the run's attempt state and the field-read list may not grow; the
  alternative is a listed read of the run's state (the planner's).

## Left, each with its reason

- **The danger edge's uses in the run log's session** (its edge field and `watch()`'s edge
  parameter), listed layer breaks, are a pull request of their own, which `standing-layer-breaks.md`
  names; this pass rewrites the session only for the summary lines.

## Verified

The event manager, day director, day streets, city map, telemetry, observer, burst capture, day loop and closure
suites pass; `./tools/check.sh`, the layer check, the field-read check and the test-only members
check pass.

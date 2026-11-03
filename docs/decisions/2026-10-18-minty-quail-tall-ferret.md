# minty-quail — The crowd and crowd-yields suites read what the crowd does (tests through public seams: W3b) · 2026-11-03

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the crowd and crowd-yields
suites, subtask W3b of the scoped plan. No `src/` change and no seam added.

**Built.**
- `test_crowd.gd` (private-read lines 35 to 10) reads the walker's door answer through
  `WalkerStrategy.door_answer_for()` over a thousand rolls and the crowd's own draw through
  `door_is_shut()`, and which bodies spend a roll off a pinned actor's rolled speed over forty
  seeds; a bump through a real `Stroller` handed to `Crowd.use_player()`, the crowd's own physics
  frames and `EventBus.crowd_bumped`; the crossing look-ahead through `LaneStrategy.cannot_go_on()`;
  recycles as interpolation resets; a walker coming out of a hut on a real door day; gates through
  four real-car scenes. Its strike test starts its own day, since a reversed run showed it leaned on
  what a neighbour left.
- `test_crowd_yields.gd` (14 to 0) reads each figure's move off the map's moves, streams its plan
  with `EventStreaming.add()`, and hands the manager its world through `setup_world()` with a fresh
  `RunState`.
- Both suites build their city on a run of their own. Checks 458 to 475 and 36 to 44; eighteen
  mutation runs.

**Open to overturn:** no tick rate pinned, since the real-frame waits are bounded by frame count and
compare no times; the door-day builder copied from the closures suite for the hut test (about thirty
lines). The pull-away check skips a car with a barrier in its look-ahead and requires one with a
clear road.

**Not done:** the hut half of the bucket-edge test, which wants a city that can be handed a region
plan, since the crowd builds huts only from the city's own door bodies and no real door day puts a
hut on a bucket edge.

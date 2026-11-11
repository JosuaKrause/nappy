# minty-quail — The still watch, the debug readout, the frame recorder and the frame trace are handed their parts · 2026-11-11

**The ask.** No class takes a whole `City` when it reads only parts of it, so no test of it has to
build a city ("the city should never be built for tests that don't test the actual city",
inbox #1156 in gray-dolphin; "no test should build a real object that it doesn't test", inbox #1159 in
gray-dolphin): the smaller cases of `city-hand-ins.md`'s third pull request. The player's recorded
answer on its size was three pull requests ("yes three prs is fine", inbox #1173 in gray-dolphin); cutting
the third into several is the orchestrator's pick, on the board as hand-ins-third-cut and not yet
answered, built on since it drops nothing the player asked for.

## What was built

- **The four developer tools no longer name `City`**: the still watch (the dev mode that holds
  still pictures), the debug readout, the frame recorder and the frame trace are each handed the
  parts they read and keep them in underscore fields. The still watch takes the map and the traffic
  signals; the readout's world view takes the world, the map and the day's streets (`DayStreets`),
  from which it reads the route tree; the recorder takes the ground mode as a value read once at
  setup; the recorder and the trace take the events and the crowd.
- **`main.gd` hands the parts** at the four places it set the tools up, through the getters it
  already had. Two methods are added: `City.traffic_signals()`, beside `ground_mode_in_force()`, and
  `CityMap.is_alley()`, beside `is_calm_zone()`, which holds the alley reading that `City.is_alley()`
  and the readout both ask.
- **What counts as a city in the readout** is one answer, that its map is a `CityMap`, asked for its
  tile, calm and alley lines, its events and crowd lines and its capture context.
- The still watch's and the debug layers' rigs hold a map and signals or a bare world, and build no
  `City`; `tools/field_reads.txt` lost its eleven `City` reads by these tools.

## Choices open to overturn

- **The third pull request is cut into several**, this one the four tools (the orchestrator's pick,
  hand-ins-third-cut); the plainer alternative is one large third pull request.
- **The readout asks the alley of the map** it already keeps, and the route tree of the day's
  streets, rather than taking either as a part of its own (the builder's).
- **The recorder takes the ground mode once at setup** rather than asking for it each frame (the
  builder's).

## Left, each with its reason

- **The developer's rigs, the day director, `main.gd` and the day planner** still take the city:
  they are the item's remaining smaller cases.

## Verified

The still watch, debug layer, hitbox, frame record, frame trace, power station, main, burst
capture, route line, observer and frame graph suites pass; `./tools/check.sh`, the layer check,
the field-read check and the test-only members check pass.

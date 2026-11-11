# minty-quail — The developer's rig, the route rig and its planner are handed what they read · 2026-11-11

**The ask.** The city scene is no longer handed whole to whoever reads a few of its parts: each
consumer is handed what it reads (the hand-ins, `city-hand-ins.md`, on the design in #1166's
description, inbox #1173 in gray-dolphin, cut into further pull requests as the board's
hand-ins-third-cut proposes). This one is the developer's rigs among "the smaller cases", and the
listed layer break "a day's start asks the dev rig where a --spawn target is"
(`standing-layer-breaks.md`).

## What was built

- **The developer's rig is handed its parts** in place of the city: `DevRig.update_follow_camera()`
  takes the events (none in the escape's building, where it does nothing), `for_spawn_target()` the
  map, the events, the day's streets, the resistance, the run's header and the trace,
  `first_event_position()` the events, the map and the trace, and `make_overview_camera()` the
  camera's bounds. They stay static functions with their parts as arguments.
- **The route rig and its planner** keep the map, the events and the day's streets in underscore
  fields, and the rig hands the planner the trace it already holds. No `City` is named in the three
  files of `src/dev/`.
- **The day director names no `DevRig`**: `use_the_flags()` is handed two callables by
  `main._new_director()`, one answering where the `--spawn` flag starts her and one applying the
  `--meters` override to the baby. `_put_her_down()` keeps its own condition (the first day, a start
  from her doorstep) and asks them; with none handed she starts at the world's start and the bars
  are untouched. A doorstep start still answers the doorstep. The listed break leaves
  `tools/layer_map.py`.
- **`tools/field_reads.txt` loses seven lines** under `[City]` (the developer's rig's `events`, `map`
  and `trace`; the route rig's and its planner's `events` and `map`) and gains none.
- **The day director's suite** hands its rig the two callables, as the game does.

## Choices open to overturn

- **The route rig comes too**, though the item names only the rig and the planner: it held the city
  for the same two parts and to hand it on (the planner's).
- **The callables take the flag's values as arguments** (the target, the override) rather than
  reading the run's config themselves, so `main` gains no read of a config field (the builder's).
- **`ParkCordon.is_closed()` takes a `[kept]` line in `tools/test_only_members.txt`.** Typing the
  route rig's read of the map resolved it to `CityMap.is_closed()`, and showed that only tests ask
  the cordon whether it has closed. The `[own file only]` group only shrinks, so the line says so,
  and the typing pass of the resistance's steps and day 12's cordon decides whether its suites go
  through what the closed cordon does outward (the orchestrator's).

## Left, each with its reason

- **The day director's and `main`'s own reads of the city**, and `day_planner.gd`, stay in "the
  smaller cases": the event manager's hand-in takes the day planner, and the rest waits on who builds
  the event manager and the crowd.

## Verified

At test parity: the developer's rig, route rig, route building and day director suites, and the run
log line for line against its recording, pass; `./tools/check.sh`, the layer check, the field-read
and test-only-member checks against the base, and the lint pass.

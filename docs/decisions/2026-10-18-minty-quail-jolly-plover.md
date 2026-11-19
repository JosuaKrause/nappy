# minty-quail — The debug layers are handed the props instead of asking whether their world is a City · 2026-11-19

**The ask.** No class takes a whole `City` when it reads only parts of it, so no test of it has to
build a city ("the city should never be built for tests that don't test the actual city",
inbox #1156 in gray-dolphin; "no test should build a real object that it doesn't test",
inbox #1159 in gray-dolphin): the debug layers were a reader of `city-hand-ins.md`'s list that asked
its world whether it was a `City`.

## What was built

- **`DebugLayers.setup()` takes the props as a source**, a `Callable` answering the world's props
  (`Array[Node2D]`), kept in an underscore field. The shadow layer asks it each draw; an invalid
  `Callable` is the building's, which has no props.
- **A source and not a list**, because the city rebuilds its props each day while the layers are set
  up once per world; a list handed at setup would go stale at the next dawn.
- **`DebugReadout.show_the_world()` takes the source** beside the world and hands it on; `main`
  hands `_city.props` in a city and an invalid `Callable` in the escape's building.
- **What stays**: the bodies' subtree root is still a `Node2D` (the city or the building's scene);
  the layers only walk its collision nodes and test nothing about its kind. `debug_layers.gd` has no
  `is City` test left.
- No behavior changes: the props outlined are the same ones as before.

## Choices open to overturn

- **A `Callable` rather than a small props-provider interface**, the plainer choice and the one
  `DebugReadout.setup()` already uses for the screen name (the builder's).

## Verified

The debug layer, hitbox, wall shield and interior suites pass; `./tools/check.sh`, the layer check,
the field-read check and the test-only members check pass.

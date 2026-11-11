# minty-quail — The escape city's rigs are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin): one
pass of `typed-everywhere.md`'s "What is untyped in a test goes as its suite is converted", cut by
the typing plan of 2026-11-11 into file-disjoint passes.

## What was built

- **The escape city's two rigs are typed and lose their opt-out line**: `finale_rig.gd` and
  `escape_roadblock_rig.gd`. Each function keeps its name, argument order and answer; the suites
  that load them (`test_finale_a`, `_b`, `_c`, `test_barrier_stays`) pass, and the five probes that
  load `finale_rig.gd` still load. Loop variables are typed; a stage `RoadblockRig.build()` hands
  back in an untyped array is cast to `RoadblockRig.Stage` where it is closed; the boot and hand-in
  callbacks take `Node`, the seam's type, and cast to `main.gd` preloaded as a constant, as
  `tests/test_observers.gd` does, since `main.gd` has no class name. No line under `src/` changed.

## Left, each with its reason

- **Search: none.** `FinalePlanner` is static functions, and the events' fields are
  `event-interface.md` row 4a's.
- **`main.gd` has no class name**, so a rig reaches it through a preloaded script; giving it one is a
  change under `src/` this pass does not make, noted for the root's pass.
- **`RoadblockRig.build()`, in this pass's own `escape_roadblock_rig.gd`, still returns an untyped
  `Array`**, so each caller casts the stage it closes; typing that return is left open.

## Verified

The four suites pass, `tools/typing_census.py --check` holds (the probes included), and no check was
deleted or moved.

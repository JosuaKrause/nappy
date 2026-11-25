# minty-quail — The developer's rigs' suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin):
`typed-everywhere.md`, one pass per module. This pass is the developer's rigs (`src/dev/`); its search
covers `DevRig`, `AutoScreenshot`, `WalkPlan`, `DebugLayers`, `RouteLines`, `RigLock` and `TrailerText`.

## What was built

- **Eight suites parse without their file-level opt-out line**, which each loses: `tests/test_dev_rig.gd`,
  `test_auto_screenshot.gd`, `test_debug_layers.gd`, `test_route_lines.gd` (`untyped_declaration`),
  `test_walk_plan.gd` (`untyped_declaration`, `unsafe_method_access`), `test_debug_hitboxes.gd` and
  `test_rig_press.gd` (`unsafe_property_access`), and `test_trailer_flags.gd` (`unsafe_method_access`).
- **Loop variables take their writers' types**; engine nodes and input events are cast to their
  classes where a member is asked; a pair loop in `test_walk_plan.gd` became a typed helper, and
  `test_trailer_flags.gd`'s pulled-back camera pose is a small class in place of an untyped array.
- **One write is converted**: `tests/test_rig_press.gd` locks a rig's gate through
  `RigLock.setup()` with a rig's config, the call the game's `main` makes, where it set `locked_out` by
  hand; each test frees its lock, which gives the input map's bindings back. No method answers the
  searched classes' other fields. No check deleted or moved; nothing under `src/`, the helpers or
  `tools/test_only_members.txt` changed. `test_dev_rig`'s spawn, closure and door cases stay as
  they are, since typing comes first (`tests-one-module.md`, entry 9).

## Fields read and written, by class

Built with `tools/field_answers.py --counts` on the eight files, each named method read in its class.

- **`AutoScreenshot`** (searched): `simulation_clock`, written → no method (the game's `main`
  assigns it the same way).
- **`RigLock`** (searched): `locked_out`, written → `setup()` (converted); read → no method.
- **`City`**: `events`, `map`, `run`, `spawn_siting`, `trace` → no method.
- **`CityMap`**: `block_plans` → `plans_by_block()`; `seed_used` → `city_seed()` (through the
  suite's own holder, which the tool cannot tell).
- **`EventDef`**: `outer_radius` → `heard_within()`; written for a fixture row: `id`, `pursuit`,
  `telegraph_time` → no method.
- **`EventManager`**: `stream_radius`, written → no method.
- **`EventPlan`**: `def` → `row()`; `def.id` → `row_id()`; `position` → `placed_at()`; `facing` → no
  method.
- **`RegionPlanner.RegionPlan`**: `door_bodies` → no method.
- **`RouteTree`**: `branches` → no method; **`RouteTree.Branch`**: `routes` → no method (both
  through the suite's own holder).
- **`RunConfig`**: `layers_override`, `parent_override` → no method.
- **`RunState`**: `header` → no method.
- **`ZoomOutCamera`**: `simulation_clock`, written → no method.

## Verified

At test parity: the eight suites pass; the typing census, the field-read and the test-only-member
checks pass.

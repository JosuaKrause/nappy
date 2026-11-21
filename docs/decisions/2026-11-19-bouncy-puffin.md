# bouncy-puffin — The routes' region plan answers through methods · 2026-11-20

**What was asked.** The entry bouncy-puffin, a finding of the design of minty-quail's row 3a: the routes' region plan
and the gate's state (`RegionPlan` and `GateState`, inner classes of `src/routes/region_planner.gd`, the model) were
read field by field across objects, by the city scene, the closure planner, the crowd, the street siting, the
resistance, the day director and the dev rig; fields are not API (inbox #1173 in gray-dolphin; **designing-classes**).
Built by a Sonnet agent as #1596.

**What was built.** Both classes are lifted into files of their own, `src/routes/region_plan.gd` and
`src/routes/gate_state.gd` (the routes' folder is already the model in `tools/layer_map.py`), so the field-read check
sees their readers; GDScript has no type alias, so the spelling `RegionPlanner.RegionPlan` is gone everywhere.
`RegionPlan` answers `wall_segments()`, `door_segments()`, `walled_alleys()`, `door_alleys()`, `wall_plans()`,
`door_plans()` and `gate_states()`, and is built through `add_*` methods by the planner and the scene recipe. `GateState`
answers `ground_point()`, `is_boom_up()` (in place of the yes-or-no `raised`), `held_for()`, and is told
`set_boom_up()`, `hold_for()` and `release_hold()`; `stopped_for` is private. Every reader under `src/` asks a method.
The suites and probes read and build plans and gates by hand in about 270 lines, so those fields stay public, each a
`[kept]` line in `tools/test_only_members.txt`, the rest of the entry. Nothing a
player sees changes.

**Open to overturn, the builder's where the item left it open:** lifting the two classes into files (the item named it
the builder's design question; the orchestrator's brief picked it); `RegionPlan`'s `add_*` builders.

**The queue.** The entry stays open on what is left: the suites' and probes' reads go through the methods and the
fields go private, with a table of each field's replacement, since minty-quail's row 4a rewrites only what its own
tables list. Row 3c of minty-quail's `event-interface.md` no longer lists the region plan's fields as left in the dev
rig and the scene recipe runtime.

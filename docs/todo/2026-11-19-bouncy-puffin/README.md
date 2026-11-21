priority: now

# bouncy-puffin — The suites read the routes' region plan through methods, and its fields go private · filed 2026-11-19

**The finding.** The design of row 3a of minty-quail's `event-interface.md` (the dawn and the walk's ground ask rows
and plans) found the routes' region plan and the gate's state read field by field across objects. Every reader under
`src/` now asks `RegionPlan` and `GateState` (`src/routes/region_plan.gd`, `src/routes/gate_state.gd`) through
methods (the record bouncy-puffin); the suites, their rigs and the probes still read and build plans and gates by hand,
so nine fields stay public, each a `[kept]` line in `tools/test_only_members.txt`. The rule that fields are not API
(inbox #1173 in gray-dolphin, **designing-classes**) covers them, and minty-quail's list is frozen, so this is an
entry of its own (inbox #1268 in olive-ferret); minty-quail's row 4a rewrites only the events' own classes.

**Item:** `region-plan-methods.md`.

**Proposed, not asked for:** the band `now` (the refactor's own work, beside minty-quail and polite-tapir; no
player's words name it beyond the rules above).

# polite-tapir — The building says she came through a door · 2026-11-23

Pull request 4 of Fable's design for polite-tapir's standing layer breaks (the design's section 5).
`InteriorScene` (world: the escape's building) type-tested her class when a door had faded to black
(`player is Stroller`, then `reset_at()`, else a bare `global_position` for a test's `Node2D`), so
the world named the simulation. It now only says she arrived, by a signal of its own beside
`exit_requested`: `arrived_through_a_door(at, look)`, emitted under the black after the release
latch is armed and the light is set. `main._build_the_escape_building()` connects it to her own
`reset_at()`. `_teleport_to_door()` and `_start_door_transition()` lose their `player` parameter;
`process_player()` keeps its signature (`WorldContext`'s). The `Stroller` entry of
`tools/layer_map.py` is deleted, and the clause of `standing-layer-breaks.md` that handed it to a
"building's pass" goes with it.

**Why a signal and not a callable handed in.** The class already tells `main` of its other transition
the same way, and the building and her are built together in one place, once a boot, so one connection
lasts as long as both.

**No guard for an unconnected building.** A building with nothing connected fades and leaves her where
she stood, so a test that walks a door without connecting fails on its next position check, loudly.

**Tests.** `test_interior` connects her `reset_at` for the real rig walking both stairwells, and a
stand-in handler (position and physics interpolation reset) for the bare `Node2D` in the release-latch
case, which is the stand-in's own business now.

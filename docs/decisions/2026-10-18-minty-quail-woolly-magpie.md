# minty-quail — The route rig asks events, rows and plans through methods (event interface row 3c) · 2026-11-18

**What it is.** The route rig's part of row 3c of minty-quail's `event-interface.md`: the route rig
and its planner (`src/dev/route_rig.gd`, `route_rig_planner.gd`, which walk a planned route through
a day for tests and probes) ask rows, live events, plans and the event manager through methods. An
Opus builder built it to the design. It changes nothing in play: each replacement gives the answer
the field read gave.

**What was built.** Methods added, nothing else changed: on the row `stands_as_a_fixed_body()` (the
same five tests the rig made and `EventSpawner.obstructed_footprint()` still makes); on the live
event `is_a_standing_lethal_place()`, `lethal_reach()` and `stands_as_a_fixed_body()`; on the plan
`faces_now()`, `stands_as_a_fixed_body()`, `body_pieces()`, `ground_shape()`, `solid_reach()`,
`detain_distance()`, `gate()` and `its_event_is_gone()`. The rig's private copy of
the fixed-body test is gone, and its three copies of "the door's live position, else its planned
one" are one helper. `tools/field_reads.txt` lost 21 lines and gained none. One run of the
`m184_route_timing` probe (day 13, seed 4242) gives the same thirteen route lines on main and on the
branch.

**Where the design was silent or departed from.** The live event answers `stands_as_a_fixed_body()`
too, which the design names on the plan only, since the rig asks a live body; the plan's
`solid_reach()` and `ground_shape()` are added because its `obstructs_within()` is a different
number; the plan answers whether a door's live event is gone (`its_event_is_gone()`), since the event manager hands the live event out only to a caller that commands it (inbox #1278 in olive-ferret); the rig
keeps its own map-aware planned position rather than `where_it_stands_now()`, which for a plan not
in the world ignores the map and would move a sidewalk body off its band.

**Left in the rig:** the world map's `obstructed_tiles` and `size` (the blocked tiles' owner), and
the call to the live event's private `_spread_is_vertical()` (3b).

**Proposed, not asked for, open to the player:** the departures above; the method names.

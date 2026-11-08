# minty-quail — Why a street is held is worked out once · 2026-11-08

minty-quail's `re-derived-cases.md`, the case filed as "the held streets' reasons", in #1252.

**Found again in the code.** The case as filed does not hold: `CrowdPockets._shut_the_held_segments()`
reads held ground and works out no reasons, and `ResistanceSteps.stands_on_held_ground()` is a policy
by step kind (a door contact may stand on the street its door holds). The repeat was in `Crowd`: each
dawn it rebuilt the door segments from the region plan's doors and the home block's bordering
streets from the network, the sets `DayPlanner` had just held knowing why, and handed both to every
agent (`CrowdAgent.door_segments`, `home_segments`) and to `CrowdPockets.refresh()`.

**Built.** `HeldStreets` (`src/city/held_streets.gd`, the model layer) records each held segment's
reasons as a mask (closure, wall, door, home street, seal), owned by `CityMap` and handed out through
`held_streets()`; `hold_segment(key, why)` takes the reason, and `DayPlanner`, `SealPlanner` and
`SceneRecipeRuntime` say why they hold one. `LaneMover` and `CrowdPockets` ask it (`is_for`,
`is_crossable`); `Crowd` keeps no door, home or crossable sets and the agents' two sets are gone.
`tools/field_reads.txt` loses 7 lines.

**Measured.** The placement fingerprint is byte-identical to main's (15787 lines).

**Choices where the design was silent, open to overturn:** `stands_on_held_ground()` is left as it
is; a mask rather than one reason per segment, since a segment held as a wall or closure kept the
door and home carve-outs before; a method on `CityMap` rather than a public field.

# The whole-switchback stair module, superseded by the tile kit

`stair_down.svg` was a single 64×64 picture of both flights and both landings of one stairwell,
drawn after the front-to-back rejection recorded in `../stairs-front-to-back-2026-09-10/`. The
player rejected this later, correctly-oriented sideways version too, in PLAYTEST-54 (see
`docs/playtests/PLAYTEST-54.md`, "The inner stairs have to be walkable tiles"):

> also I like the fire escape stairs but the inner stairs don't work. I think the misunderstanding
> here is that the inner stairs need to work as tiles and need to be walkable so they need to be
> actually 2.5D and be separated in handrail and stair tiles and landings.

The defect was not the geometry — the sideways switchback direction was correct — it was that one
picture cannot be a walkable `TileMapLayer` cell: a player cannot stand on part of a single 64×64
image, and the picture could not be laid out per floor at the length a real hallway needs. It is
superseded by the M112 stair tile kit in `assets/interior/`: `stair_flight_e.svg`,
`stair_flight_w.svg`, `stair_landing.svg`, `stair_rail_e.svg`, `stair_rail_w.svg`,
`stair_rail_level.svg` and `stair_newel.svg` — separate floor tiles, walkable one at a time, with
the handrail as its own overlay layer so she walks behind it.

This file is preserved for historical reference only. It is not design guidance, a style
reference, or an implementation target for new art; no import sidecar belongs in this ignored
archive.

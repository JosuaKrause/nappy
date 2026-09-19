# The stairwell's broad decks, rails and landing overlays, superseded by the tile grammar

Thirteen sources that drew a stairwell as a **presentation assembly laid over a separate walkable
map**: broad multi-tile flight decks (`stair_flight_run_{e,w}.svg`, `stair_flight_short_e.svg`),
the landings under them (`stair_landing_{floor,turn,vertical}.svg`), the handrails in front of and
behind each run (`stair_rail_run_{e,w}.svg`, `stair_rail_run_{e,w}_rear.svg`,
`stair_rail_short_e.svg`, `stair_rail_short_e_rear.svg`) and the cap closing the bottom of the
shaft (`stairwell_shaft_cap_bottom.svg`).

They are superseded by the ten-column symbol grammar the player drew and corrected, in
`InteriorMap.STAIRWELL_ROWS`, whose reviewed `m158_stair_side_*` tiles **are** the ground: one
32×32 TileSet source per symbol, painted by the same parse the collision pass reads, so there is
no second assembly to keep in step with the map. The player accepted those tiles in PLAYTEST-83
and again in PLAYTEST-84 — *"the stairwell graphics are solved"* — and with them accepted there is
nothing left for a deck, a rail or a landing overlay to be drawn on top of.

**`stair_flight_run_{e,w}.svg` and `stair_flight_short_e.svg` here are not the files of the same
name in `../escape-interior-diagonal-treads-2026-09-12/`.** Those are the earlier version, whose
treads were 45° diagonal strokes; the player rejected them in PLAYTEST-60 (*"the staircase floor
graphic should be vertical lines for steps"*). These are the vertical-tread successors that
answered that, kept in the tree until the grammar replaced the whole approach.

These files are preserved for historical reference only. They are not design guidance, a style
reference, or an implementation target for new art; no import sidecar belongs in this ignored
archive.

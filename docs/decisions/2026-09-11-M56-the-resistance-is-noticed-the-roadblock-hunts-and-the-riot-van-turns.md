## M56 — The resistance is noticed · the roadblock hunts and the riot van turns, built 2026-09-11

The two build items left after the raid, on `feature/roadblock-guards-leave`: one agent's
uncommitted work, interrupted, committed as it stood and finished by a second agent, reviewed
here. **The roadblock's guards leave their post.** `roadblock` carries `heat_response HUNTS`, the
same rung as `abduction` and `night_raid`: below `Tuning.HEAT_HUNTS_LEVEL` it is the band it
always was, and at or above it the derived copy `pursues` at the shared speed, notices her at the
shared trigger, chases for `PURSUIT_TIME` and is `hard_fail`. A band does not chase, so the
hunting posture is a guard on foot — `guard_standing.svg` while it closes to its stand-off,
`guard_lunging.svg` once it gives chase — on the same `is_waiting()`/`is_telegraphing()` switch
the robber and the cat already read. **Two things had to move for the kill to be reachable.** The
row's `inner_radius` went from the M61-derived 24 to 86, because `EventDef.validate()` refuses a
`hard_fail` body whose obstruction plus her own 14px radius reaches inside the lethal radius, and
the band's 60px capsule plus 14 is 74 — 86 keeps the 12px margin the raid has. And the hunting
copy's field is widened in `EventDef.at_heat()` to at least the shared trigger, because the
row's cold `outer_radius` (179, M61's 215 less the band's half-length) sat 1px under
`Tuning.HEAT_HUNTS_WITHIN` (180) and `Tuning.validate_pursuit()` refuses a row that notices her
from outside its own field. **Rejected**: padding the cold radius to 180, which would have put a
number belonging to the ladder into an exact, documented derivation the cold row has no use for;
the derivation-side fix holds the contract for any later `HUNTS` row too and leaves the cold
shape, the cost table and `required_telegraph_time()` untouched. **The silent choice, open to
overturn**: nothing is left behind once the guards go — the generic pursuer rule already frees
the body the frame a pursuer stops waiting, and the design said nothing about the interval, so
the smaller rule was to add none. A named test in `tests/test_heat.gd` asserts the whole shape
at every heat level, the reachability arithmetic included.

**The band reads as one barrier**, M100's defect from playtest 55 (*"the barrier itself also
doesn't read as a continuous element"*): `roadblock_segment.svg` and `roadblock_end.svg`, drawn
through `_draw_spread` the way `roadworks` is, the hazard stripe bleeding across every seam;
`checkpoint_block.svg` stays as the badge's icon, since a badge is read small and the block is
still the clearest single frame of a held street. **The riot van turns**: `_draw_riot_van()`
picks the nearest of eight headings from the van's own heading — front, back, side and the two
diagonals, three of them mirrored — which is M108's octant selection seeded on the one row that
carried the family, to be generalised rather than copied by the next row that needs it.

**Not captured.** Two rig attempts to frame a forced roadblock failed — the row never placed in
the window from the doorstep, and a corner spawn was killed by traffic first — so the drawing
was checked by rendering the textures headless and there is no evidence image. The measurement
against the nerves is the milestone's one open item and waits for act III.

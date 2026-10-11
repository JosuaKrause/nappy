# jolly-hare — The fire truck is lethal in front while it drives and solid parked · 2026-10-11


[calm-kestrel](../playtests/2026-10-04-calm-kestrel.md), inbox #558:

> the fire truck has no collision at all -- I can walk through it without it being lethal

Asked what touching it should do, the player chose "Lethal driving, solid parked (Recommended)". It
keeps its off-screen warning: "fire truck has heavy penalty" (inbox #598 in
[olive-hedgehog](../playtests/2026-10-05-olive-hedgehog.md)).

**The truck is built the way [sunny-finch](2026-10-07-sunny-finch.md) built the police car.**
`EventCatalogue._fire_truck()` drives (`def.drives`) with a capsule body, `GroundShape.segment(16,
13)`, 58px long and 26px wide, the size of the fire engine's drawing. While it drives its route it
is lethal only in front of it, after a car's 1.6s warning, and never beside or behind; its flank
stops her. Once parked at the kerb by the fire it is solid on every side and ends nothing. Its
one-second off-screen badge ([M226](2026-09-26-M226.md)) is unchanged, and `obstructs_radius` stays
0, so no planner reads the body: parked, it stands in the near lane inside the 340px field the
siting check already keeps off her only way. A loss to it names its own cause, "The fire engine
never slowed down. You were in the road.", logged and counted as `fire-truck`
(`lost-hard-fail-fire-truck` in GoatCounter). The picture is anchored over the body by the police
car's helpers, now shared. `tests/test_fire_truck_body.gd` covers the row, the warning before the
strike, nothing striking beside or behind, the parked body solid and harmless, the route-redundancy
guarantee with its tiles blocked on seed 4242, the loss line and the picture's anchor; ten of its
checks fail with `drives` off. The stills, [truck-body-2026-10-11](../evidence/truck-body-2026-10-11/),
show her walking into the parked engine's flank, from a recipe derived from
`scene-recipes/fire-truck.json`; a scene recipe cannot take a burst.

*Proposed at filing and built, open to the player's correction:* lethal only in front while it
drives, as a car is, rather than its whole body. *Chosen where the entry was silent:* the body is
the drawing's size; the loss line's wording. **Seen, not measured:** with the body, the passive
mother in `scene-recipes/fire-truck.json` cries at 13.5s, 0.3s before the recipe's old end, so the
recipe now ends at 13.0s; the cost table is unchanged.

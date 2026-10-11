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
stops her. Once parked at the kerb by the fire it is solid on every side and ends nothing. **It is created
standing**, as every car that drives now is (`EventInstance.setup()`): just out of sight up a
north-south street is 222–263px from her, inside the 1.7s of 190 px/s its warning reaches, so a truck
driving from its first frame struck her 0.8–1.0s after its mark, under the 1.39s it takes to walk off
the road; standing, it waits off screen until she is out of its lane, as a car that has stood does.
The patrol car, at 74 px/s, warns from about 150px, nearer than anything is created, so it is unchanged.
Its field is still priced from its centre (`EventDef.field_from_its_centre`), not from the body, so
what it costs is unchanged and the siting check's 340px still covers it. Its
one-second off-screen badge ([M226](2026-09-26-M226.md)) is unchanged, and `obstructs_radius` stays
0, so no planner reads the body: parked, it stands in the near lane inside the 340px field the
siting check already keeps off her only way. A loss to it names its own cause, "The fire engine
never slowed down. You were in the road.", logged and counted as `fire-truck`
(`lost-hard-fail-fire-truck` in GoatCounter). The picture is anchored over the body by the police
car's helpers, now shared. `tests/test_fire_truck_body.gd` covers the row, the warning in full where the game creates the truck,
from all four sides (failing from the north and south before it was created standing), nothing
striking beside or behind, the parked body itself solid and harmless, the field priced from its
centre, the distinct routes from home to every calm area kept with every tile the parked body touches
blocked (a street-wide control body through the same check closes the street, so it can fail), the
loss line and the picture's anchor. The stills, [truck-body-2026-10-11](../evidence/truck-body-2026-10-11/),
from recipes derived from `scene-recipes/fire-truck.json`, show her walking into the parked engine's
flank, and the engine driving in behind her with its doubled caret and the mark over her; a scene
recipe cannot take a burst.

*Proposed at filing and built, open to the player's correction:* lethal only in front while it
drives, as a car is, rather than its whole body. *Chosen where the entry was silent, open to overturn:* the body is the drawing's size; the loss
line's wording; every car that drives is created standing; and, through `drives`, the engine stops at
red lights and before a zebra she waits at, and stands while she is in its lane, as the patrol car
does, which can delay its arrival.

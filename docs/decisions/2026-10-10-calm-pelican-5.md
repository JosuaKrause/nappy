# calm-pelican — Walls inside the building stop excitement too · 2026-10-10

From the re-review of PR #567 (polite-rabbit, excitement does not go through a wall): the player
said "Excitement should not go through **any** wall", but indoor events were spawned with no map,
so `EventInstance._walled_off()` answered "not walled off" indoors, and #567 had deleted the queue
entry while its record listed interiors as left open.

**Built in PR #642.** A probe over every walkable point within each indoor source's reach (seed
4242) found the fire, the mouse and the steam never reach her through a wall, but the masked man did
from most steps of his shaft, up to 33 of about 220 points a step — so the check was built rather
than the item dropped. `InteriorScene.wall_grid()` turns the building plan into a `CityMap` of two
kinds, sidewalk where she can stand and building everywhere else, so the city's own
`CityMap.wall_between()` answers indoors at the same depths; `InteriorEvents._spawn()` hands it to
every source through `EventInstance.set_walls()`. The explosion stays unwalled, since its indoor
instance only carries a bang from outside that has already come through the walls.

The debug fields layer now cuts an outline where a wall stops the field (`DebugLayers.open_runs()`),
so it agrees with the meter behind buildings. To keep it cheap, outlines off screen are not built, a
standing source reuses its cut, and an outline with no deep building ground asks no wall question;
the outline is asked along its whole length in pieces of at most 8px, not only at its
corners, so a wall falling between two corners is not missed; one screen at her doorstep measured
1.9–2.9ms cold and 0.7–0.8ms with nothing moved, and a screen round an event 4.6–6.4ms cold on
average (headless, parked probe `tests/probes/calm_pelican_fields_layer_cost.gd`). The building-end answer from
bouncy-kestrel (#568) replaces "open to them" in `city_map.gd`, `docs/EVENTS.md` and
`tests/test_wall_shield.gd`, and `docs/MECHANICS.md` describes the wall rule as built: shallower at
open ends, and a 2x2 building blocks only through its centre. A still and a crop of the cut layer
are in [calm-pelican-fields-cut-2026-10-10](../evidence/calm-pelican-fields-cut-2026-10-10/README.md).

**Chosen where the item was silent, open to overturn:** an indoor wall is any cell
`InteriorMapPlan.is_walkable()` refuses, rubble and gaps between parts included; the explosion stays
unwalled; the layer cuts rather than tints, and cannot see a walled or open stretch shorter than one 8px piece
between two of the other kind; a flock's birds are cut along the line from the flock's centre, the line
`contribution_at()` already uses. No interior picture was taken: the masked man stood behind the
edge badge in the stairwell still, and the suite holds the interior instead.

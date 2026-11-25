**The south water is drawn the new way in the game**, once the player has chosen the look and the
way it is drawn (the review item amber-puffin, from the standalone experiment's figures in the record
amber-puffin). The new drawing replaces only the south water's `SceneryWater` surface; the bulkhead,
the bridge and the rest of the ground stay in the static layer, every other water keeps its drawing,
and the water's clock still pauses with gameplay. The probe's shader, `tests/probes/voronoi_water.gdshader`,
draws in world coordinates, so the chunks the ground streams in meet without a seam.

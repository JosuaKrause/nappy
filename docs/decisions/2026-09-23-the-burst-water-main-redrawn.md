## The burst water main, redrawn · 2026-09-23

*([PLAYTEST-123](../playtests/PLAYTEST-123.md), statements 24 and 35: "can you have an opus agent
redraw the water main break image?", then "new water main looks good".)* One Opus agent on
`feature/burst-main-redraw`; art only, no code changed.

**What changed** in `art/events/burst_water_main.svg` (north-south street) and
`burst_water_main_vertical.svg` (east-west): water fountains upright out of the break, the crater
reads as a hole (a lit far wall, shaded ends, pooled water) ringed by heaved asphalt slabs, the
split main runs along the street with both broken mouths showing, a puddle spreads across the road
with run-off to both kerbs, and the barriers are striped boards on legs with an amber lamp,
end-on on the east-west street as the roadworks barrier's vertical file already is. Canvas sizes,
anchors, the fit to the 192px obstruction, the choice of file by street axis and the absence of a
shadow are unchanged. `--spawn event:burst_water_main` puts one on screen for a still.

**Open to overturn, chosen where the brief was silent.** The fountain, the one part standing
above the ground, which the no-shadow rule's reasoning ("the crater is on the ground") did not
foresee; the fallback is foam and pooled water only. The main along the street rather than across
it. The barriers where the old ones stood, near the building line.

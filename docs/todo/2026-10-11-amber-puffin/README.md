priority: now
after: 2026-10-18-minty-quail

# amber-puffin — The south water is a blue base with drifting Voronoi lines · filed 2026-10-11

[mossy-ferret](../../playtests/2026-10-11-mossy-ferret.md), #708:

> we need to redo the water+its animation at one point. we basically just need a blue base and we can create white lines via randomly placing centroids and drawing the voronoi outlines of each region. then we oscillate the intensity of each centroid which will move the voronoi boundaries around in a way water looks. we will have to start with a standalone experiment

and, on its scope and cost:

> I meant only the water at the south end of the map -- this technique won't work for other water instances. we could prerender into tiles if performance becomes an issue

*The band is the filer's proposal:* "at one point" names no time.

**What it replaces.** The south water is drawn from the `tiles/water` atlas region on its own
`SceneryWater` canvas, absent from the static ground, and a shader shifts each tile's sample by less
than a pixel on a clock that pauses with gameplay (`docs/GRAPHICS.md`, "City ground and buildings";
`docs/CITY.md`, the map's border). That motion was approved with the
[record that separated the scenery's animation](../../decisions/2026-09-26-M159-crowded-scene-cpu-attribution-and-separate-scenery-animation.md); this entry
replaces it for the south water only. Every other water, the burst water main's fountain included,
keeps its drawing and its motion.

**The look asked for.** A blue base; white lines that are the outlines of the Voronoi regions of
randomly placed centroids; and each centroid's intensity oscillating, which moves the boundaries
"in a way water looks".

**What it must keep.** The bulkhead, the bridge and the other ground stay in the static layer, and
the water's clock still pauses with gameplay. The phone's renderer is bound by the pixels it fills
([velvet-marten](../../playtests/2026-10-11-velvet-marten.md)'s records), so the experiment measures
the effect's cost per frame; if it costs too much, it is prerendered into tiles, as the player
offered.

The work is [a-standalone-experiment.md](a-standalone-experiment.md), then bringing it into the game.

**Band `now`, after the refactor.** [tiny-lark](../../playtests/2026-11-01-tiny-lark.md), #930: "actually I'm interested in trying that on the side after the refactor; let's move to now".

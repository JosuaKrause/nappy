# amber-puffin — Judge the Voronoi water by eye and choose how it enters the game · 2026-11-25

**What to do.** Open the two clips and the two stills in
[the evidence folder](../evidence/amber-puffin-voronoi-water-2026-11-25/README.md): `curved.gif` and
`straight.gif` are a quarter of the game's view at the desktop's scale, the south water as a blue base
crossed by white outlines that drift as each centroid's intensity swings; `curved-full-view.png` is the
whole view; `tile-repeated-full-view.png` is one tile of the same water repeated, as a prerendered tile
would draw it. Today's water, for comparison, is `waterfront.gif` in the m159 scenery-animation folder.

**Where to look.** Whether the outlines' motion reads as water, the size of the cells against a
32-pixel tile, the width and brightness of the lines, the short hooks the curved look draws where a
region shrinks to nothing, and in the tile still how plainly the pattern repeats every 384 world pixels.

**The question a run answers.** Which look, curved or straight, reads as the south water ("in a way
water looks", mossy-ferret #708), with what changed about it; and which way it enters the game: drawn
live over the water (about 10 to 20 times today's water's cost a pixel on the desktop's GPU, unmeasured
on a phone), one tile drawn live every frame and repeated (about today's cost, with the repeat and
softer lines), or a loop of baked frames (today's cost and several megabytes of memory)?

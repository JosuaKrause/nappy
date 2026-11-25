# amber-puffin — The south water as drifting Voronoi lines, drawn outside the game, and what each way of drawing it costs · 2026-11-25

**What was built.** The entry's standalone experiment, a scene of its own: `tests/probes/voronoi_water.tscn`
with its script and its shader beside it, under `tests/`, which the export leaves out and no suite
runs. It draws the south water the way the player described it (mossy-ferret #708): a blue base, the
average colour of today's water tile; one centroid in each cell of 48 world pixels, jittered inside it
by a hash of the cell; the outlines of their regions in white; and each centroid's intensity
oscillating on a period of its own between 3 and 7 s, which moves the outlines. Nothing in the game
changed. Run with `--capture DIR`, it writes each look's frames for a clip; with `--measure FILE`, the
cost of each way of drawing the water at phone-sized canvases. The evidence, the commands and the full
figures are in [the evidence folder](../evidence/amber-puffin-voronoi-water-2026-11-25/README.md).

**Two looks.** The intensity is taken off a pixel's distance to each centroid, so the outlines are
curves (`curved.gif`), or off the squared distance, a power diagram, so they stay straight
(`straight.gif`). The curved one is the default, since it moves more like water; which reads better
is the player's to judge, with the review item amber-puffin. Where two neighbours' intensities differ
by more than the distance between them, the weaker region shrinks to a sliver and can vanish, which
the curved look shows as a short hook ending in open water; a smaller intensity or a smaller jitter
makes fewer of them, at less motion.

**Why one centroid a cell.** A pixel then weighs only the nine cells round its own, so its cost does
not grow with the size of the water. A sampled check of 8,000 points a setting compared the nearest
two centroids among those nine with those among the 49 round it: with a jitter of 0.8 of a cell no
outline pixel differed at intensities up to 0.3 of a cell, and with a full jitter a few did at 0.2
and 0.3. So the jitter is 0.8 and the intensity 0.25. Rejected: centroids placed with no grid at
all, which a pixel could only find by weighing all of them or through a lookup built for it.

**What it costs.** On the desktop's Apple M2 under the Compatibility renderer, one pass of the curved
lines over a whole 1920x1080 canvas (a phone held sideways at the ratio the player's phone reported,
the game keeping 16:9) took 3.1 ms, and 1.3 ms at 1280x720, against 0.16 and 0.07 for today's water
and 0.12 and 0.04 for a flat fill; an earlier run gave 2.6 ms for the curved lines and 0.25 for today's
water at 1920x1080. So the lines cost about 25 times a flat fill and 10 to 20 times today's water, a
pixel. The south water fills less than half the view, since the camera keeps her centred and she
never stands south of the bulkhead. A phone's GPU is slower than the M2 by a factor not measured here,
and the phone's renderer is already bound by the pixels it fills (velvet-marten's frame records).
The engine's own GPU timer reads 0 under this renderer, so the probe measures wall time with the GPU's
queue drained; other agents' headless test runs were running through it.

**Prerendering into tiles.** A tile of eight cells (384 world pixels) wraps seamlessly when the
centroids' hash repeats every eight cells. Drawn once and repeated, it costs a frame what today's
water does (0.13 ms a pass at 1920x1080); drawn again every frame so it keeps moving, it adds 0.21 ms
for the tile itself, about its share of the canvas's pixels at the live shader's rate. Its costs are
what it shows: the pattern repeats every 384 world pixels, which the full-view still makes plain, and
at one texel a world pixel its outlines are magnified two or three times on screen and soften. A
loop of baked frames instead needs every period to divide the loop, which the shader's `loop_seconds`
setting does, and memory: a 12 s loop at 12 fps is 144 frames, 21 MB for one 384-pixel tile at one
byte a texel, or 5 MB for a tile of four cells.

**Left open.** The look, its settings, and which of the three ways it enters the game by (drawn live
over the water, a live tile repeated, a baked loop) are the player's, asked in the review item
amber-puffin; the work of bringing it into the game is the entry's remaining item.

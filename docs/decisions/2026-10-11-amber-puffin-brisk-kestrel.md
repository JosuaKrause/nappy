# amber-puffin — The south water drawn in the game as one live tile of drifting Voronoi lines, and what it costs a frame · 2026-11-25

**What was built.** The entry's last item: the south water drawn the way the player described it
(mossy-ferret #708), in the game, for the south water only, on the three picks of the review item
amber-puffin, which the player has not answered yet: curved outlines, the experiment's settings,
and one live tile repeated. `SouthWaterTile` (`src/city/south_water_tile.gd`, the world layer) is
a `SubViewport` of eight cells of 48 world pixels a side, a texel a world pixel, whose one
`ColorRect` draws the experiment's shader, moved from the probe to
`assets/shaders/south_water.gdshader` with the centroids wrapping every eight cells. Each
`SceneryWater` surface draws its cells as regions of the tile's texture, each cell from the square
it covers in the world taken modulo the tile, unclipped with the texture repeating so the filter
wraps at the tile's edge, so the chunks the ground streams in meet without a seam
(`tests/test_south_water_tile.gd` sweeps the regions). The ground (`SceneryGround`) makes the tile
with its first water surface, hands it to every surface, sets the tile's clock from the city clock
every frame, which stops when gameplay pauses, and keeps the tile drawing every frame while a
water surface stands and not at all otherwise (`tests/test_scenery_residency.gd` holds both). The
boot's shader warmup draws through the tile's material instead of the atlas water's, with a
transparent draw colour the shader multiplies in. Every other water, the burst water main's spray
included, keeps its drawing; the bulkhead, the bridge and the rest of the ground stay in the static
layer.

**The sea wall stands in the water.** The bulkhead's picture painted a strip of the old water at
its foot, which sat as a dark band with a hard edge above the new water along the whole waterfront;
the review found it a blocker. The strip is now transparent in `art/tiles/bulkhead.svg` and in its
transfer, but for a one-pixel contact shadow (black at 40%, the darkening the transfer's own
waterline gave its painted water), and the ground draws the water beneath the bulkhead row too,
still laying the sea wall on its TileMap, with `SceneryWater` shown behind its chunk.
`GroundTiles.stands_in_water()` says which source's picture leaves its foot to the water.
Rejected: the surface drawing the strip's rows over each bulkhead cell, smaller but writing the
strip's height into code beside a picture that can change. The transfer's edit is a script in the
evidence folder (`bulkhead-foot.py`), which checks its input's hash.

**What went.** The atlas water's ripple shader (`assets/shaders/scenery_water.gdshader`), which
nothing else drew, and with it each surface's own material, clock, `_process()` and its hold on
the `ground` atlas page; `SceneryGround.use_atlas()`, which only handed the library on to the
surfaces, and the city's call of it. The experiment's scene and script (`tests/probes/voronoi_water`),
since the game's shader replaces its own and the measurement it made is recorded; the record
amber-puffin's evidence names the revision that reproduces it. The suite case that checked a
surface's ripple material and its page (`tests/test_scenery_animation.gd`), since a surface has
neither. The atlas water picture (`art/tiles/water.svg`, its transfer, its membership line and
source 31 of the ground tile set, with `GroundLayers`' branch that removed that source from the
composed sheet), which nothing drew any more, and the two suite checks that only asserted its
region exists; `GroundTiles.WATER` stays as the id the city paints a water cell with. The tall-llama item on nearby scenery loading lost its bullet asking for the water's docs
and `SceneryWater`'s header to be rewritten, since this change rewrites all three.

**The filter.** The tile is drawn with linear filtering, as the experiment's live tile was; the
project's default is nearest, which would draw the lines as stepped pixels two screen pixels wide
on the desktop. Open to the player's correction with the look.

**What it costs.** On the desktop's M2, the game's own frame entries from four alternating runs of
main and the branch on each of two walks, the waterfront where the water fills the lower half of
the view and M139's walk, which never reaches the water: the frame took 6.18 ms on main and 5.70
on the branch at the waterfront, 7.27 and 7.20 on M139's walk, with single runs of one side
differing by two milliseconds. So the water drawn this way costs the desktop nothing these runs can
measure; the experiment put the tile's own drawing at 0.21 ms a frame on this machine. Draw calls
moved by about one a frame where the water is in view, primitives by about twenty on both walks,
unattributed. A first set that ran all of main's runs before all of the branch's read the branch
two to five milliseconds slower on both walks, the one without water included, while another
agent's headless run took a full core: it is kept as the trial that shows the drift, and the
alternating set is the reading. No phone was measured. The figures, the commands and the stills
and clips are in [the evidence folder](../evidence/amber-puffin-in-the-game-2026-11-25/README.md).

**Left open.** The three answers of the review item amber-puffin, which stays: the look (curved, or
straight with the shader's `metric` at 1), the settings (each a uniform of the shader, the cell
size and the eight cells a side constants of `SouthWaterTile`), and the way of drawing (the live
tile, or the shader over every water pixel, or a baked loop, each a change to how the surfaces draw
the same shader).

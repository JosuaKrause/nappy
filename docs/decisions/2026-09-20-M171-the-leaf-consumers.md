## M171, the leaf consumers — built 2026-09-20

A consumer move of the milestone, pull request #248.

**Built.** `Building`'s forty pictures are region names on the `buildings` page; `CityEdge`,
`ClosureMarker` and `TrafficLight` draw from `street_kit`, and `CityEdge` also holds `ground`
for the mountain; `ModeButton`, `TouchControls` and `SaveIndicator` draw from `ui`;
`InteriorScene` and `InteriorTileSet` from `interior`. Each consumer acquires its group in
`_enter_tree()` and releases it in `_exit_tree()` — the pair rather than `_ready()`, which
fires once, so a node that re-enters the tree keeps the count right — and an empty
`StringName` is "nothing to draw" where a function returned `null`. `City`'s count of fence
panels across a closed street reads `AtlasLibrary.native_size()` for the panel's width.
`tests/test_atlas_leaf_consumers.gd` checks what a headless run cannot, since it never calls
`_draw()`: every region name a consumer holds resolves on the group it acquires, and every
group's count returns to nought when its consumers are freed.

**The interior TileSet shares the page.** The first version cropped each tile out of the page's
image into its own `ImageTexture`, on the reasoning that a `TileSetAtlasSource` needs a uniform
grid. That is true of a source holding many tiles; each source here holds one. A source whose
texture is the shared page, whose `margins` are the region's corner and whose
`texture_region_size` is the region's size puts tile (0,0) exactly on the region — proved
against this engine with a throwaway script before it was written, including two sources at
different offsets on one page. Cropping was refused in review because it rebuilt one texture
per tile at runtime, which the milestone exists to remove, and made the group's extruded
padding pointless. The TileSet therefore needs `interior` acquired for as long as it is used;
`InteriorScene` acquires before it builds and releases after its `TileMapLayer` has gone.

**The brief's fence was wrong here too.** It kept the agent out of `city.gd`, where the fence
panel count read `get_width()` off a `ClosureMarker` constant that this change turns into a
region name, so the first version could not parse on its own.

**Open to overturn.** Per-node acquisition — every `Building` takes its own reference — where
an owner could hold one; PLAYTEST-109's loading rule replaces these lifetimes with startup and
the day brief in any case.

## M171, the decoration — built 2026-09-20

A consumer move of the milestone, pull request #247.

**Built.** `Prop`'s swing frame, bollard, sacks and both trees, `Litter`'s five decals,
`CityDecals`' tree pit and `City`'s door are region names on the `decoration` page. `City`
acquires the group in `build()`, where it asked the runtime packer for it, and releases it in
`_exit_tree()`. Every shadow shape and the door's offset read `AtlasLibrary.native_size()` where
they read `get_size()` off a preloaded source, and `StreetTrees.footprint_radius()` — the tree
clearance the closure and event planners use ahead of any city existing — reads the same table,
which answers with nothing acquired. The "draw the source picture until the pack is collected"
path in `Prop` and `CityDecals`, `CityDecals.decoration_sources()` and the group's trip through
`TextureAtlas` are gone: a baked page is there as soon as it is acquired.
`tests/test_atlas_decoration.gd` pins each shadow and the tree footprint to the region table,
and the group's count to one while a city stands and none after it is freed.

**The brief's fence was wrong three times, and the first version was red for it.** It kept the
agent out of `street_trees.gd`, which left the two trees as the only decoration pictures still
loaded individually, and out of `tests/test_texture_atlas.gd` and `tests/test_telemetry.gd`,
which the change breaks: one read `decoration_sources()`, the other used two prop textures as
convenient inputs to the runtime packer. A pull request carries what its own change breaks; the
fence was lifted and the three were fixed on the branch. The runtime packer's suites take their
real group from the café event family and the mouse pictures, since the events are the last
family that packer serves.

**Found on the way.** A suite that fails to parse hangs the test run instead of failing it:
the runner never reaches `quit()`, so the shard that owned the broken suite ran until another
shard's failure cancelled it.

**Open to overturn.** The door's constant keeps its name, `DOOR_TEXTURE`, while holding a
region name.

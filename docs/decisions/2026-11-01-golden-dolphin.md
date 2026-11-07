# golden-dolphin — The basement's floor decals lie under her feet · 2026-11-07

golden-dolphin, in #1204: the basement's puddle, debris and rat decals sat in the building's
depth-sorted layer, so each was drawn over her feet while she stood on its northern half.

**Built.** `InteriorScene._rebuild_overlays()` adds them with `add_entity(sprite,
DrawLayer.Layer.GROUND)`, the floor tiles' own layer, where the vent's grate already lies for the
same reason (M100, the basement vent is a floor grate). Only the chandeliers stay depth-sorted,
since they hang above her; the rat is a still sprite, so nothing moving changed layer.
`tests/test_interior.gd`'s `_test_the_floor_decals_are_drawn_under_her` holds each decal outside
her layer and below her, and fails on the old code. Before and after stills are under
`docs/evidence/basement-decals-2026-11-07/`.

**Choice where the design was silent, open to overturn:** the smallest change, the existing loop
adding to the ground layer, with no new class or helper.

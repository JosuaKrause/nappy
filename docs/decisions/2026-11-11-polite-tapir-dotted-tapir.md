# polite-tapir — The props' trees: TreePictures holds the tree pictures and their reach, and the street trees name no Prop · 2026-11-19

**What was asked.** polite-tapir's `standing-layer-breaks.md` holds the layer breaks
`tools/check_layers.py --list` prints, which the player asked not be forgotten (inbox #1268 in
olive-ferret). This group is the props' trees: `src/city/street_trees.gd` (model) named `Prop` (world)
for `Prop.TREES`; the item's sentence, the orchestrator's proposal, gave it a pull request of its own.
Fable's quota is out and the player answered "yes, continue with one fable task at a time and use opus
for it" (grassy-bison #1560), so an Opus agent designed and built it in Fable's place; the pull request
(#1568) carries the `fable-only` label. It was
held unmerged for Fable's review of the design (entry grassy-ibis) until the player lifted that
hold while Fable's quota is out (inbox #1571), and merged on its Opus review.

**What was built.** One fact was derived in two places: `Prop` sized a tree's ground shape (where its
shadow is drawn from) as 0.28 of its picture's width, and `StreetTrees` kept its own 0.28 for
`footprint_radius()`, the ground kept clear of events around a tree, which an authored scene also uses
to refuse two trees overlapping. `TreePictures` (`src/city/tree_pictures.gd`, placed in the data layer
by its own entry in `tools/layer_map.py`) holds the two tree picture names and the 0.28 and answers
`region(variant)`, `shape(variant, scaled)` and `widest_reach()`, with `Prop`'s exact arithmetic.
`Prop` loses `TREES` and asks it; `StreetTrees` loses its copy and `footprint_radius()` and reads
`widest_reach()`; `src/city/recipe_city_builder.gd` reads `widest_reach() * 2` for the overlap check,
the same number. Placement and shadows do not change: a probe printing every tree spot, a hash of the
cleared ground, the streets a fallen tree may take and 80 shadow radii on two seeds gives the same 134
lines on main and on the branch. `tests/test_atlas_decoration.gd`'s footprint test, which restated the
formula, now holds that no tree picture reaches past the cleared ground and the widest reaches exactly
it. The `Prop` use leaves `tools/layer_map.py`'s list and no break is added.

**Open to overturn (the designer's, and Fable's to judge):** the name `TreePictures`; its place in
`src/city/` rather than `src/visuals/`; deleting `footprint_radius()` rather than keeping a pass-through.

**Left as found.** `City.MIN_TREE_SPACING` (`40.0 * 1.25`, the least two park trees stand apart so their
canopies do not read as one clump) is another copy of a tree picture's width. It is no layer break and a
balance-governed constant, so this pull request leaves it; it is the next place to look for the same fact
derived twice.

**The item.** The group leaves `standing-layer-breaks.md`'s list and its sentence there; the item stays
open for its other groups.

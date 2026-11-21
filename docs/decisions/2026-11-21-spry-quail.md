# spry-quail — Every size of a tree is the tree pictures' own · 2026-11-21

**What was asked.** The entry spry-quail, a change Fable wanted in its review of #1568 (the tree pictures and their
ground are a data class, `TreePictures`), a pull request of the fable-only entry polite-tapir that merged on an Opus
design while Fable's quota was out (the record calm-lemur). The player accepted Fable's changes: "yes, fables
complaints are valid. get the fix and then let fable review again". Built by a Sonnet agent as #1613 from Fable's
design, then reviewed adversarially and by Fable against its design.

**What was built.** Every size of a tree is stated once, in `TreePictures`: `drawn_size()`, `street_tree_shape()` and
`widest_canopy()`, on which `shape()` and `widest_reach()` are built. A street tree takes `street_tree_shape()` as its
ground and is drawn at its picture's own size, a park tree at the size its scale gives, through one private draw.
`City`'s park-tree scale roll reads `PARK_TREE_SCALES`, and the spacing between planted trees is the widest canopy
times the largest scale (`min_tree_spacing()`), worked out once per block; the literal `MIN_TREE_SPACING` goes. The
test that built a whole real city to hold a street tree's size together is gone, since the size is stated once.

**Measured.** A throwaway probe on main and the branch: the spacing is 50.0 at full precision, and `widest_reach()`,
eighty shadow radii, the street-tree pits, the footprint tiles and every park tree's position, variant and scale in one
built city per seed (two seeds) are the same bit for bit. Nothing a player sees changes, and no balance number moves.

**Open to overturn:** the builder's departure from the design: `min_tree_spacing()` is public and read by a test, and
`tools/check_test_only_members.py` refuses a public member only tests read (the call inside `city.gd` does not count),
so it carries a `[kept]` line in `tools/test_only_members.txt`; the other way is a private method with the test
restating the product.

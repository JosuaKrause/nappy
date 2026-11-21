# Every size of a tree is the tree pictures' own

Three sizes of a tree are still stated outside the class that now owns them. The first is the one
the pull request reported and left as "the next place to look".

**What is wrong today.**

- **The park trees' spacing restates two numbers.** `City.MIN_TREE_SPACING := 40.0 * 1.25`
  (`src/city/city.gd`) is the least two park trees stand apart, so two canopies do not read as one
  clump. Its 40 is the tree pictures' width, written as a literal with a comment saying where it
  comes from; its 1.25 is the top of the park trees' scale roll, written again where the roll is
  made (`rng.randf_range(0.75, 1.25)` in `_dress_block()`). Nothing holds either to its source:
  `tests/test_blocks.gd` only checks that trees stand at least the constant apart. A tree redrawn
  wider, or a larger roll, leaves canopies overlapping with nothing failing.
- **The drawn size is worked out twice.** `Prop._draw_tree()` computes
  `Vector2(native_size(name)) * _scale_factor`, the first line of `TreePictures.shape()`.
- **A street tree's size is stated in two places and held together by a real city.**
  `TreePictures.widest_reach()` assumes a street tree is drawn at its picture's own size;
  `City._spawn_street_trees()` happens to dress one with no scale; `Prop._draw_street_tree()`'s
  comment says "unscaled" while its code scales by whatever it was dressed with. The one check that
  the three agree, `_test_the_planner_and_the_prop_agree_on_a_tree_footprint` in
  `tests/test_blocks.gd`, builds a whole real `City` to read one number off its props.

**The design.** All in `TreePictures` (`src/city/tree_pictures.gd`, data), which gains three
answers and keeps its arithmetic:

- `drawn_size(variant: int, scaled: float) -> Vector2`: `Vector2(native_size(region(variant))) *
  scaled`, exactly the expression `shape()` has today. `shape()` and `Prop._draw_tree()` both ask it.
- `street_tree_shape(variant: int) -> GroundShape`: `shape(variant, 1.0)`, the one place that says
  a street tree stands at its picture's own size. `widest_reach()` is the widest of these.
  `Prop`, for `Kind.STREET_TREE`, takes this as its ground shape and draws at
  `drawn_size(_variant, 1.0)`, as its own comment already says; `dress()`'s comment says the scale
  is a park tree's. Only `City._spawn_street_trees()` dresses a street tree, and with no scale; if
  the builder finds another caller that passes one, it stops and reports rather than changing what
  is drawn.
- `widest_canopy() -> float`: the widest picture's width at its own size, in px.
- `City` states the park trees' scale roll once (`const PARK_TREE_SCALES := Vector2(0.75, 1.25)`,
  smallest and largest, read by the roll) and the spacing becomes
  `static func min_tree_spacing() -> float`, `TreePictures.widest_canopy() * PARK_TREE_SCALES.y`,
  worked out once per `_dress_block()` call and handed to `_too_close_to_a_planted_tree()`.
  `MIN_TREE_SPACING` goes; its comment's reasoning (two canopies closer than their own width read
  as one shape) stays on the function.

**Tests.** `tests/test_blocks.gd`'s spacing case reads `City.min_tree_spacing()`. Its real-city
footprint case is deleted: with a street tree's size stated once, the bare-prop case in
`tests/test_atlas_decoration.gd` (every tree picture's street-tree prop reaches no further than
`widest_reach()`, and the widest reaches exactly it) holds the whole relationship with no city
built (inbox #1156 in gray-dolphin: a city is not built for a test that is not about the city);
it gains one check, a street tree dressed with a scale reaching the same, which is what the deleted
case held the city to.
No test restates 40, 1.25 or 50.

**Order, one pull request:** `TreePictures`' three answers; `Prop`; `City`; the two suites.

**What holds parity.** No number moves: the spacing is 50 px on today's pictures, as now, so the
park trees' seeded placement is the same roll for roll, and every shadow radius and the cleared
ground are the same bits. Shown as #1568 showed it, with a throwaway probe diffed on base and
branch: every street-tree pit, the hash of `StreetTrees.footprint_tiles()`, the streets a fallen
tree may take, eighty tree shadow radii, and, new, every park tree's position, variant and scale in
one built city on two seeds, plus the spacing printed to full precision. `src/city/city.gd` is on
**balance**'s list of files; the builder reads it and says in the description that the number is
unchanged.

**Cost.** Small: three files under `src/city/` (`tree_pictures.gd`, `prop.gd`, `city.gd`) and two
suites, one of which loses its only real-city build for this fact.

**What it collides with.** Nothing running: minty-quail's `event-interface.md` rows 4b and on own
the events' files, none of these. It can be built now, beside them. silver-egret and plaid-chipmunk
(the two shadow entries above) will touch `Prop`'s shadow drawing; whichever lands second merges
a few lines, with no conflict of meaning.

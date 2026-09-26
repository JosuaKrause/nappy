## M171, the rectangle packer — built 2026-09-20

Pull request #251, the packing half of [PLAYTEST-109](../playtests/PLAYTEST-109.md)'s notes on
the baked pages: *"it would be better to arrange things in a more squarish image"* and *"a
greedy approach is fine but don't let obvious empty space go wasted"*.

**Built.** `AtlasLibrary.plan()` is a MaxRects packer: it keeps every free rectangle a
placement leaves, places members largest padded area first, ties in the bake's alphabetical
order, each into the free rectangle it wastes least of, and grows the page downward when
nothing free fits. It packs the same members at a deterministic set of widths — the widest
member, twice the square root of the padded area, the running sums of the eight widest
members' widths, and seventeen even steps between — and keeps the smallest page inside
`AtlasLibrary.aspect_ceiling()`, the narrower on a tie. The suite holds every page to a fill
floor that rises with member count and to that same aspect ceiling, as rules over whatever
groups exist, and `tests/test_atlas_packer.gd` pins the two refused shapes on synthetic
input: small members end up beside a tall one inside its height, and two large members that
fit side by side only above the square-root width come out on one row. Three forced bakes
are byte-identical. The bake hashes its own script and `atlas_library.gd` as inputs, so a
checkout baked by the shelf packer re-bakes by itself.

**Measured**, member area with its 1px border over page area, shelf packer to this one:
buildings 1810×68 56% to 240×338 85%; crowd 854×50 82% to 190×218 85%; decoration 464×56 66%
to 144×162 74%; events 2042×382 62% to 948×560 91%; ground 2042×70 72% to 308×342 98%;
head_indicators 134×30 87% to 72×58 84%; interior 1948×260 28% to 466×326 94%; street_kit
1096×260 48% to 454×358 84%; stroller 1812×50 93% to 366×242 95%; ui 782×132 98% to 262×392
99%. The bake went from about
0.3s to about 1.8s, since every group is packed at some thirty widths; it runs only when the
sources moved.

**Rejected.** Rows sorted by height — offered to the player and refused: *"you will get dead
space where you can easily put smaller things"*. A guillotine packer: its cut runs the whole
free rectangle, so the strip beside a tall member is as tall as the member whatever needs it.
**The square root as the width rather than the start of a search**, which was the first
version: `street_kit` came out 366×552 with an empty 190×258 block beside the tall road
picture, because the second road picture and the tunnel were each a few pixels too wide for
the gap, the three stacked, and every small member found a tighter hole lower down. It was
found by looking at the page, not by its fill number. A unit test of two transposed
equal-area rectangles: stacked and side by side have the same bounding area, so either is a
correct answer; the test uses unequal areas.

**Open to overturn.** The fill floor, `52 + 5·ln(members)` clamped to 35–90, and the aspect
ceiling, the larger of 1.8 and one plus the biggest member's side over the square root of the
area. An oversize member is named by index in `plan()`'s result.

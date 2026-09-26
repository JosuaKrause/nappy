## Street-tree beds are ground, not upright props — 2026-09-12

PLAYTEST-64 shows the tree bed drawing over the stroller. The player asked for the bed to be
a tile rather than an object. `CityDecals`, the existing flat ground layer between `Ground`
and `Buildings`, now owns the tile-sized bed at its existing center anchor. `Prop` retains
the tree's upright art, shadow and collision. This uses the existing ground-decal mechanism
rather than adding a new terrain kind or changing which tiles can be walked on.

The city registers the planted positions once and redraws the ground layer when the day's
fallen-tree plan changes. Both the tree and its bed retain the existing hidden state for an
emptied pit. The blocks suite verifies nonempty planted trees, one ground bed per tree, and
the actual scene's z-index and sibling ordering beneath entities. Import/boot and the focused
blocks suite passed in the isolated implementation checkout. Human appearance review remains
in `REVIEW.md`; the supplied full telemetry run is preserved under
`docs/evidence/playtest-64-2026-09-12/`.

# brisk-rabbit — The city edge's road stubs, which nothing reaches, are deleted · 2026-11-19

**What was asked.** Designing polite-tapir's group "the city edge's kinds" (record polite-tapir-gentle-llama),
the designer found that two of `CityEdge`'s pieces, `Piece.ROAD_EAST` and `Piece.ROAD_WEST` (the road
stubs, a road continuing past the city edge), are reached by nothing: the city stands only the tunnel, the dark
ramp and the bridge. The rule is that code nothing reaches is deleted (inbox #1180 in gray-dolphin,
**designing-classes**). No player's words name the stubs beyond the rule.

**What was built.** The two pieces are gone from `src/city/city_edge.gd` with what only they reached: the
`ROAD_ON` constant and the two draw branches that used it, the picture `art/props/road_on.svg`, its line in
`assets/atlases/membership.json` (the street kit page drops to 23 members), and its entry in
`tests/test_atlas_leaf_consumers.gd`. `docs/GRAPHICS.md`'s row for the edge's pictures names the tunnel mouth and
the bridge deck only. A search for the names across `src`, `tests`, `tools`, `assets` and `docs` found no other
reader. Nothing a player sees changes, since nothing drew the stubs. The baked atlas pages are git-ignored, so
the rebake leaves no file to commit.

priority: bug
after: 2026-11-19-curly-stork

# olive-lynx — A body stood twice moves half a tile: the record of a live body's tiles is off for rows stood on their band's middle · filed 2026-11-20

**The finding.** The design of curly-stork (a planned body's pieces laid out once), a step of the refactor, found that
`BodyStance.stands_at()` (`src/events/body_stance.gd`, where a planned body stands on its street) is not idempotent
for a row it centers on its sidewalk band's middle: standing an already-stood point reads the lane past the band's
middle line and moves the point half a tile toward the other lane. Two live callers hand the record of standing bodies
(`EventSpawner.obstructed_footprint()`) an already-stood point: `EventBody.tiles_at(body_position(), heading)`, the
body's own tiles a pursuer's or noticer's line of sight leaves out (`EventInstance.clear_line_to()`), and
`EventSpawner.move_extra()` (`instance.global_position`). On the design's day cities (eighteen cities, days 1 to 14) every such record comes out half a tile
off for the rows stood on the band's middle: the market stall, the café tables, construction, scaffolding, the leaf
blower, the unmarked van, the loudspeaker and the night raid. The effect today is mostly hidden: a line that starts
inside its own body sees out of it (`WorldMap._line_is_clear()`), and `move_extra()` moves only day 13's task guard,
who has no standing body. The design's measurements are in the orchestrator's design folder (`curly-stork.md`,
section 9).

**Read as** (the filer's, open to the player's correction): a bug a refactor step finds, filed `bug` (inbox #1519 in
breezy-magpie): the code does what its own docs say it should not, since the record of a body's tiles is meant to be
the body's own solid (`event_spawner.gd`'s comment where the record is laid out: "so the record and the body are one
solid").

**Item:** `stand-once.md`.

**Proposed, not asked for:** the band `bug` (the reading of "bug" above), which of the two fixes the item names, the suite that holds it and the pictures it asks for if a sight line a player can see moves.

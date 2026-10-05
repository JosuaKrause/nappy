# Playtest bouncy-kestrel — The wall's depth: one tile, or the middle of a one-tile wall

2026-10-04, about pull request #567 (excitement does not go through a wall). One note captured in the
session, #568. The player's words are copied word for word, after what they answered.

## #568 — Wall shield depth: one tile, or the middle of a one-tile wall

Said on 2026-10-04 about PR #567 (excitement does not go through a wall), reported as: "a source
reaches you only if the line between you doesn't pass 16 px, half a tile, into a building ... Half a
tile is a single constant if you'd rather block a whole tile deep." Earlier (#554): "the blocking
should happen in the middle of the wall (or one tile deep)".

> if the line between you doesn't pass 16 px, half a tile, into a building -- half a tile was only supposed to be done if the wall is only one tile wide otherwise it should be one tile

Asked on 2026-10-04: "Walls and excitement, buildings two tiles thick (about 15–20% of buildings,
mostly 2x8 strips): with your rule (block at one tile deep, or the middle of a one-tile wall), such a
building blocks a line only along its middle. Near either end, within 32px of the end face, a line
straight through 64px of building is never 32px from open ground, so it passes. Keep that, or block
it?" Options: "Block at the middle (Recommended)" — any line that crosses the building's middle line
is blocked, near the ends too; "Keep the literal rule" — lines near a strip's ends pass. The words
below are the player's own answer.

> Near the end of the building the same spacing is used so a 2x8 building has a 6 unit long line through its middle

## Routing

**#568** → built in pull request #567: a building blocks a line once it is a tile deep, and a one-tile
wall at its middle; a 2x8 building blocks along a middle line six tiles long, one tile in from each
end, as built.

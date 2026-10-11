Place each chalk mark on the tile one step into its alley from the mouth `_alley_mouths()` chose,
along the alley's long axis (for a courtyard passage, one step from the street end toward the
court), so that touching it at `ContactPoint.REACH` needs her inside the alley: the mark's centre
48px in, she touches it no further out than 12px inside the mouth, her 14px body wholly past the
street edge. Choosing the mouth stays as it is (the mouth's reachability, walled and sealed alleys
refused, `GameState.completed_resistance_alley_tiles`); only where the mark stands and what it is
touched from move. Verify it with a walk that touches the mark and one standing on the pavement at
the mouth that does not.

**The mark's guard keeps his distance from the mark.** `THROUGH_THE_ALLEY` and
`_guard_two_thirds_through()` measure from the alley's edge today, so a mark 32px further in would
bring him from about 155px to about 123px, inside his 140px notice, against
[M213](../../decisions/2026-09-26-M213.md) ("never nearer than 176px") and quiet-yak's "Two-thirds
wins". He moves one tile further in with the mark; where the alley is too short for that, the
two-thirds rule and the 176px floor are weighed exactly as they are today with the mark's new place.
[downy-otter](../../decisions/2026-09-27-downy-otter.md), a mark is always where she can walk to it,
holds for the new tile: the reachability check runs on the tile the mark stands on, not the mouth.

**Proposed, not asked for** (open to the player's correction): where a courtyard passage is one
tile long, the tile one step in is courtyard ground, and the mark stands there. The pinned
marks in the scene recipes (`_the_pinned_mark()`, `docs/SCENE_RECIPES.md`) move one tile in the
same way, and `docs/MECHANICS.md`'s sentence that a mark sits at the alley's mouth says it stands
one tile in from it.

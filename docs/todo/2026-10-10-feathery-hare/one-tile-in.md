Place each chalk mark on the tile one step into its alley from the mouth `_alley_mouths()` chose,
along the alley's long axis (for a courtyard passage, one step from the street end toward the
court), so that touching it at `ContactPoint.REACH` needs her inside the alley: the mark's centre
48px in, she touches it no further out than 12px inside the mouth, her 14px body wholly past the
street edge. Choosing the mouth stays as it is (the mouth's reachability, walled and sealed alleys
refused, `GameState.completed_resistance_alley_tiles`); only where the mark stands and what it is
touched from move. Verify it with a walk that touches the mark and one standing on the pavement at
the mouth that does not.

**Proposed, not asked for** (open to the player's correction): where a courtyard passage is one
tile long, the tile one step in is courtyard ground, and the mark stands there. The mark's own
guard keeps his distance from the mark rather than from the alley's edge, so moving the mark in
moves him with it: `THROUGH_THE_ALLEY` and `_guard_two_thirds_through()` measure from the alley's
edge today, and a mark 32px further in would bring him from about 155px to about 123px, inside his
140px notice (M213, "never nearer than 176px", and quiet-yak's "Two-thirds wins"). The pinned
marks in the scene recipes (`_the_pinned_mark()`, `docs/SCENE_RECIPES.md`) move one tile in the
same way, and `docs/MECHANICS.md`'s sentence that a mark sits at the alley's mouth says it stands
one tile in from it.

# minty-quail — Her fields, the screen-edge badge's and the move proposal's go private · 2026-11-23

**What was asked.** `field-reads.md`: every read of another class's field goes through its methods (inbox #1173 in
gray-dolphin). Built as #1684 by a Sonnet agent, for her part's, the screen-edge badge's and the move proposal's fields
that only tests still read.

**What was built.** `Stroller.atlas`, `carrying` and `facing`, `DangerEdge.atlas` and `MoveProposal.yields` and
`on_the_list` are underscore-private; the game and the suites ask `is_carrying()`, `facing_direction()`, `gives_way()`
and `is_on_the_list()`. Two seams only tests call are `[kept]` with their reasons: `Stroller.turn_to()` (a suite sets
her heading exactly, which the hysteresis, pram-offset and cue-side cases need; resetting her also resets her drawn
view) and `DangerEdge.draws_from()` (the badge acquires no page, so nothing else shows which library it was handed).
The atlas boot suite checks her rig by what it acquired on the sitting's library and the badge by `draws_from()`; its
walk over nodes holding a public `atlas` stays for the others. Suites that flipped one rig between pushing and
carrying build one rig per state, since the game never flips one back.

**Measured.** The sixteen touched suites: 32060 checks on main, 32064 on the branch, none failing; the four added are
the boot suite's checks of her rig and the badge in the day and in the building.

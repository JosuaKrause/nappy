# minty-quail — Her fields, the screen-edge badge's and the move proposal's go private · 2026-11-23

**What was asked.** `field-reads.md`: every read of another class's field goes through its methods (inbox #1173 in
gray-dolphin). Built as #1684 by a Sonnet agent, for her part's, the screen-edge badge's and the move proposal's fields
that only tests still read.

**What was built.** `Stroller.atlas`, `carrying` and `facing`, `DangerEdge.atlas` and `MoveProposal.yields` and
`on_the_list` are underscore-private; the game and the suites ask `is_carrying()`, `facing_direction()`, `gives_way()`
and `is_on_the_list()`. No seam only tests call was added: the suites set her heading with the game's own
`reset_at(where, look)`, and where her drawn view must hold at a sector edge (the hysteresis cases) they steer her
with analog input, which turns her exactly onto the heading. The atlas boot suite checks her rig by what it acquired on
the sitting's library and the badge by raising a stand-in danger for the booted edge (`setup()`, as the escape
re-points it) and reading what the recording library was asked to draw; its walk over nodes holding a public `atlas`
stays for the others, and its non-vacuity guard applies to the day alone, since her rig was the building's only such
node. Suites that flipped one rig between pushing and
carrying build one rig per state, since the game never flips one back.

**Measured.** The sixteen touched suites: 32060 checks on main, 32066 on the branch, none failing; the six added are
the boot suite's checks, in the day and in the building, that the boot built the badge and her rig, that her rig
acquired on the sitting's library and that the badge drew from it. Made to fail on purpose, the boot checks fail when
the badge or her rig ignores the library handed in, the hysteresis checks when the margin is zero, and the suites that
place her through `reset_at()` when it ignores the position.

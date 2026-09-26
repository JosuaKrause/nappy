## She stops flickering on the diagonal · built 2026-09-02

*(2026-09-02: "when going diagonally the graphic flickers — only change the graphic once it goes
over 50 degrees or below 40 degrees and stick with the previous graphic otherwise.")*

**A hard switch on 45° with a facing that wobbles across it.** `_draw_mother()` and `_draw_pram()`
each asked whether the facing was more horizontal than vertical, so a diagonal walk flipped the
drawing frame by frame. The fix is a 40°/50° hysteresis band: side-on below 40° off the horizontal,
front-or-back above 50°, and in between whatever was drawn last.

**One decision, not two.** It is computed once a frame into a shared member both drawings read —
two independent hystereses would let her face one way while the pram faced the other, which is
worse than the flicker it would be fixing. A doorstep placement or a rewound day resets it rather
than carrying it, because a day that did not happen has no last frame.

**The east/west mirror needs none**, and this was reasoned rather than assumed: turning from mostly
east to mostly west sweeps through mostly north or south at 12 rad/s, deep inside the front-or-back
band, so the sign has settled long before the side view returns.

**Two neighbouring sign tests were left alone deliberately.** The pram's own column test already
argues for a distance rather than an axis test, and its boundary sits at due north; the y-sort check
flips at due east. Both are far from the diagonal and neither was ever exposed to this.

**The test is the interesting part**: `tests/test_stroller.gd` oscillates the facing between 40° and
50° and asserts the drawing never changes. One that only probed 0° and 90° would have passed before
the bug existed.

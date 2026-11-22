priority: bug

# calm-sparrow — An event's caret strength may depend on whether its look asked earlier in the same tick · filed 2026-11-22

No player's words name this; it is a finding of the Opus review of [#1638](https://github.com/JosuaKrause/nappy/pull/1638#pullrequestreview-6014446627) (minty-newt, the events' looks are handed the drawn view; `git show 58ca0869d --stat`), filed from a refactor step's review.

**Found.** The excitement fingerprint probe (`tests/probes/excitement_fingerprint.gd`) was run with its events always drawn (no drawn view handed) and again gated by the screen. Two caret values for one event flipped: `car_accident`, seed 4242, day 1, ticks 223 and 225 (caret 1 on one side, caret 0 on the other, as main has it).

**What holds today.** Whether the look's gate asking `caret_strength()` changes what a later ask in the same tick answers is unverified. The two runs differ in two `XF` lines of the probe's output, which shows that the caret an event charges her can differ with whether it was drawn.

**How to show it.** Run the probe on main with and without `DrawnView.on(t)` handed to its builder, as #1638 built it, and diff the `XF` lines.

**What the fix must hold.** The caret an event charges her is the same whether or not it is drawn: asking `caret_strength()` is side-effect free, or the charge is derived once per tick and read by both the look and the charge.

*Proposed, not asked for:* the band `bug` (the filer's; a bug a refactor step finds is filed `bug`, inbox #1519 in breezy-magpie).

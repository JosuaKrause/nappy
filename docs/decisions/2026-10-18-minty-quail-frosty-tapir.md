# minty-quail — The resistance's two suites walk the neighbor home, and no suite sets a live event's phase by hand (tests-one-module, the events) · 2026-11-23

**What was asked.** `tests-one-module.md`'s events entry: the suites that called `EventInstance.transition()` to
put a live event in a phase reach it the way the game does or take a fake (inbox #1156 and #1159 in gray-dolphin;
curly-rabbit #1098). Built as #1669 by a Sonnet agent from an Opus design, for the resistance's replacement and
placement kinds suites, the last two.

**What was built.** The three cases that parked day 10's neighbor by hand walk the neighbor home on the neighbor's own
steps through a rig helper and check the neighbor parked at her door before the director ticks. With the scenery and
prediction suites' change (#1663), no suite calls `transition()`, so its line leaves the test-only list, and the
events entry of `tests-one-module.md` is done.

**Measured.** The replacement suite went from 1019 checks to 1022 (about 30 s to 36 s locally, the real walks), the
placement kinds suite from 279 to 280. Disabling the director's parked branch failed the "reaching the door first"
checks in both; a helper that never advances failed the new parked check in all three places.

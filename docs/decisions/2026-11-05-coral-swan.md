# coral-swan — A slow frame cannot bring the masked man's badge up late: nothing it measured is left · 2026-11-25

*Filed by the orchestrating session, not from a playtest.* The entry asked whether, on a slow
device, the screen-edge badge came up a frame or more after the stairwell masked man started
running, because the badge's model (`BadgeModel._measure`) read his closing speed as his step over
the frame's time, and on frames longer than a physics tick that first reading often fell under the
closing-speed threshold (record minty-quail-breezy-pelican).

**Closed unmeasured, since its subject is gone.** tawny-wombat (#1759) deletes the badge's
measuring: every badge is now a warning put up before its danger exists, carried on to the thing it
created until she can see it, or a charger's own start out of her sight
(`EventInstance.was_warned_of()`), and `BadgeModel` reads no speed, no step and no frame time. The
masked man is set off by a place (`SetOffWatch`): his warning goes up and he comes on the same
physics tick, told he came under a warning, so the first frame the edge draws after that tick
carries his badge whatever that frame's length. There is no reading left for a long frame to put
under a threshold, so the measurement the entry asked for has nothing to measure.

**Rejected.** Measuring it anyway on the lengthened-frame flag: it would measure the deleted path.
The entry's proposed remedy, reading closing speed per physics tick, goes with the measuring it
would have fixed.

**Its paused draft pull request, #1216, is closed by the orchestrating session**: its work was the
measurement this record closes.

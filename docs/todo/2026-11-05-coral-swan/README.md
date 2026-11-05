priority: later

# coral-swan — Find out whether a slow frame brings the masked man's screen-edge badge up late · filed 2026-11-05


*Filed by the orchestrating session, not from a playtest; open to the player's correction.*

**Context.** Moving the interior's masked-man walks onto real frames (record
minty-quail-breezy-pelican) showed that the screen-edge badge's model (`BadgeModel._measure`) reads
the masked man's closing speed as his step divided by the frame's time, and on the first frame he
runs takes the larger of the smoothed and the raw reading. With frames longer than a physics tick,
that first reading often fell under the closing-speed threshold, so the badge's first-frame check
holds only at real time and is exempt from the lengthened-frame runs. Whether the same happens in
play on a slow device, the badge pointing at him a frame or more after he starts running, is not
established.

**The work.** Measure it: the masked man's run on a lengthened frame (the dev flag that lengthens
frames, or a phone frame record) and the frame the badge comes up on. If it comes up late, the badge
reads closing speed per physics tick rather than per frame, so a slow frame cannot delay it; if it
does not, the item closes with the measurement in its record.

**Read first:** record minty-quail-breezy-pelican (`tools/decisions.sh minty-quail-breezy-pelican`);
the **cues** skill; `src/ui/` for `BadgeModel`; `tests/test_interior_masked_man.gd`'s badge cases.

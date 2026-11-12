priority: next
after: 2026-10-18-minty-quail
after: 2026-11-11-polite-tapir

# sunny-osprey — The crowd's lanes move onto the map's one navigator, if it pays · filed 2026-11-07

**The ask.** On the board's crowd-lanes-on-navigator (should the crowd's lane movement, how walkers
and cars follow their sidewalk and road lanes step by step, move onto the map's one navigator, the
piece that steers her and the pursuers, as part of the refactor?), the player asked "what's the
benefit of the new design over the old?", then, told it "gains very little", "what is the gain from a
design standpoint?", and, told every walker and car would move slightly differently and need
remeasuring, "slightly differently as in...? bad differently or good differrently? not sure we need
remeasuring, though -- of what?" (inbox #1155 in gray-dolphin). The question was then taken off the board as fully
discussed in the chat (inbox #1155 in gray-dolphin).

**Read as:** the outcome that stood when the question left the board: lane movement on the navigator
is not part of the refactor (minty-quail and polite-tapir); it is work of its own after the refactor's remeasuring.
The player's last questions (whether the difference in motion is better or worse, and what would be
remeasured) are open, and this entry answers them in its design before anything is built.

**What it would buy, from the chat:** the lane movement already asks the same blocked record as the
navigator; the navigator adds its swept step (no long frame carries a walker through a thin solid)
and one code path for everything that moves. **What it costs:** lane-following on top of the
navigator, a per-frame check in the busiest loop, and slightly different motion for every walker and
car, against a bug never seen.

*Proposed, not asked for:* the band, `next`, after minty-quail and polite-tapir (the player named none).

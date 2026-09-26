## M109 — Convert the SVG catalogue to PNG · the timed main integration, 2026-09-12

PLAYTEST-62 requested a twenty-minute delay before picking up the storefront and finale updates.
The timer fired at 13:52:51 UTC. The conversion tip was
`caface6d71dc20447a8b2b247510f0bb992285d7`, fetched main was
`0225a242b421d9b47f60d3365b4cd9b9190a18d9`, and their base was
`105ef597927137cd475f950a2b9e4fc78be878f1`. The sole textual conflict was the independent
history insertions at the top of this file; both sets remain intact. Main's storefront
PLAYTEST-61 and the conversion's PLAYTEST-62 have distinct identities. The milestone and
numbered-record audit found no independent identity collision requiring renumbering.

The semantic review compared the pending tree with both tips. Main's wider, mixed storefronts
and shallow hallway indents/vertical stair treads retain their SVG sources and existing callers;
none has a corresponding PNG in this increment, so the resolver shows the updated source.
The conversion adds only the carrying rig and garbage/litter resources, preserving their own
canvases, anchors and alpha. Its recursive visual audit loads actual Godot resources and keeps
the original-SVG fallback checks. No source or runtime drawing contract is replaced by the merge.

Main also brings rare street-tree runs, event footprint exclusion, and daily emptied pits for
fallen trees. Those placement and refresh changes remain intact. Sacks use building-front or
alley positions, trees use the curb lane, and litter remains a decorative ground layer; the PNG
replacement changes none of those rules. The current city/event docs and tree tuning references
agree. Queue reconciliation retains main's completed tree and interior-item removals and the
conversion's remaining catalogue work. Both sets of human visual-review questions remain open.

The carrying motion capture used the pending merged tree above (`caface6-dirty`, with main's
assets and runtime changes present), seed 4242, 1280×720, `--start-escape floor:2 --invincible
--walk 1e1w1e1w --press snapshot_burst 1`, and a still after six seconds. Whole run:
`docs/evidence/style-transfer-player-family-2026-09-12/runtime/rig-100126-seed4242-v0.8.2-739-gcaface6-dirty/`;
the `asked/burst-2662283-001` sequence retains all 36 PNGs, `burst.json` and its sibling MP4.
Recorded frames span 0.004674–2.920421 seconds, with completion at 2.986075 seconds. Ordered
frames show east/west travel and gait changes with stable baby placement and recognizable hair
and clothing, alongside the updated hallway indents. They do not cover all eight turns; the
source comparison sheet supplies those static views. The interior log records only the burst
and reports a zero city position, so actual travel is established by the frames, not that field.
The final still is `docs/evidence/archive/session-captures/2026-09-12/m109-carrying-gameplay.png`.
The capture skill records the integer-duration walk syntax after the rejected decimal script
in the litter run; it passed frontmatter validation. Human appearance review remains open.

The merged checkout passed import/boot, focused `blocks city_decay events routes seals visuals
stroller presentation_mode orientation interior`, and `visuals --svg`, plus doc lint and
whitespace/conflict-marker checks. The full suite remains the PR's CI gate.

A final clean merge takes queue-only main `b5649bf5416bd1c389668997221872d87cfc9718` into
`41bb53c7caed22c21dd63833e196763718b9b34e`, with base
`0225a242b421d9b47f60d3365b4cd9b9190a18d9`. Main revises the existing M110 crowd-obstacle,
M98 return-pressure and M102 finale instructions; it introduces no independent numbered record.
The merged queue preserves those instructions and the conversion's M109 remainder separately.
Comparison with both parents confirms no runtime, asset or test change in this second merge;
the preceding placement sweeps therefore verify the same executable tree. Import/boot, focused
visuals in both modes, doc lint and conflict-marker checks are the final merge gate.

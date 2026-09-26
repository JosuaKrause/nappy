## Amber otter — The park fence has upright supports and mounted signs · drawn 2026-09-26

[Player's words](../playtests/2026-09-26-amber-otter.md): keep the once-per-game fence logic, fix
the vertical sections that look rotated sideways, delegate the graphics. The first upright-rail
preview was rejected: signs were scattered, corners had no visible pole joining the perpendicular
runs, and the whole did not read as a fence.

The new proposal uses a dedicated `ParkFenceMarker` to leave street barriers unchanged. Its SVG
post has a visible square shaft, cap, collars and planted foot. The narrow end-on rail mounts
4px inward from the support so it cannot hide that shaft, with supports about 44px apart. One
corner pole joins each pair of runs. One composite mounted sign remains at each run's midpoint;
the nearest panel whose elevated rail can overlap the sign draws that plate after its rail.
The small inward offset is an illustrative construction choice to keep height legible, not a
physics or route change. All drawing dimensions remain open to visual judgment.

The run's terminal panel and post share an exact ground-coordinate expression: accumulating
panel spans independently produced a fractional Y difference, so y-sorting could overrule the
intended draw order at a short archway. The focused integration check protects the shared
endpoint and the unjoined entrance's ordering. Boot/import, lint/XML and the spent-park and
atlas-consumer suites passed; current native-size corners, sign, short entrance and fitted
overview are the `poles-*` files in `docs/evidence/m129-spent-park-closed-2026-09-25/`.
These are proposed artwork, not a player approval; the judgment is in `REVIEW.md`.

Earlier pictures are preserved in the same folder. The second attempt stopped the side runs one
tile short; the third shifted old end-on columns upward 7.4px and added broad 8px posts. The
unbound draft bent two rails into concentric outlines. The first `upright-*` revision kept a
single ground line but hid its poles behind the rail, and the player rejected it. Its exact
pole/rail proportions explained why correct projection alone did not make a recognizable fence.

The graphics repair preserves the existing late-game single-fence exception, selection,
collision, event spoiling and routing. The sound experiment requested in the same conversation
is developed separately and contributes no assets or runtime code to this work item.

**Once-per-run review correction.** Independent review reproduced a bookkeeping defect with
seed 14040: the act III fence selected on day 9 disappeared on day 12, and reading the empty
daily state back into `GameState` erased its history, allowing a second fence on day 13.
`GameState.remember_fenced_park()` now retains only the first nonempty choice, and `CityMap`
distinguishes that historical choice from a physically active fence. The original act lifetime,
save schema and art are unchanged; a run that has never fenced an area can still select its first
in act IV. Act-boundary and real save/reload regressions failed seven checks before the fix and
passed afterward with the focused spent-park/save suites (55,008 checks, no failures). Boot and
lint also passed. The city guarantee's rationale now correctly excludes fenced ground before
counting reachable calm areas; the spare reachable area covers event spoiling.

**Main reconciliation.** Merged main `97f42f3427b253615fb93e9d5eebe172429665b9` into branch
`22347b1bf0d899235358d57b9d912a100e56f39e`, from base
`2ac17470a8975accc25668c9aba82cb415dd6816`. The only conflict was both sides inserting
decision records at the file's top; both sets were retained. Main's orientation/restart
protection and this PR's spent/fenced-state handover occupy separate startup paths and survive
together. Main's playtests 143–144 and the branch's continuation of 140 and dated Amber otter
record are distinct; no identity needed renumbering. Main's queue additions and completed
restart removals remain, while the spent-park work stays removed on this branch. Boot/lint and
focused main, held-restart, save, spent-park and atlas-consumer checks passed. The save fixture's
camera now explicitly uses physics processing, removing an engine override warning without a
runtime behavior change.

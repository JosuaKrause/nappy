## M100 — An entry beside a plain edge keeps room for its own picture · built 2026-09-13

*(2026-09-13, [PLAYTEST-69](../playtests/PLAYTEST-69.md): "people still come out from outside the
map" — a re-report of playtest 66's finding after M120.)* Two agent commits on
`feature/m100-map-edge-entries`, reviewed here; the counts are in
`docs/evidence/m100-map-edge-entries-2026-09-13/`.

**The diagnosis, before the fix.** `tests/probes/m100_map_edge_entries.gd` drives
`CrowdAgent._recycle()` at each plain edge and samples `Crowd.start_day()` separately, counting
entries whose *drawn picture* reaches past the true edge with a centre every existing check calls
legal. Every recycle sample beside a plain edge was unsafe — walker north 199 of 199, walker west
179 of 179, car west 235 of 235, off-spine car north 224 of 224 — because M120's rule that a
walker or an off-spine car gets no room past the edge collapses the entry roll to the boundary
coordinate itself, legal by the centre-only `_entry_band_fits()`, while the picture straddles the
line: a walker's canvas rises its whole height above its position and nothing below, since
standing sprites are anchored bottom-centre. The day-start placement, which never runs the
recycle's room check, did the same rarely (1 of 234 beside an east edge). Nobody genuinely stood
past the edge once M120 held the centre. So the first of the entry's three candidates was the
cause, the second a minor contributor, and the third did not occur.

**The fix.** `CrowdAgent._entry_picture_clearance()` reads the real texture sizes and the same
anchor arithmetic the body drawing uses, and answers how far this kind's picture reaches past its
own coordinate — the larger of the two directions, applied symmetrically, which is the one silent
choice and is conservative only on the side that already had room. `_entry_band_fits()`, the
final clamp on the room beyond the map, and `setup()`'s own placement loop all ask
`_within_the_map_with_room_for_its_picture()` wherever `_entry_room()` grants nothing past the
edge. After it the probe reports zero unsafe entries at every edge and zero at day start; sample
counts drop because the unsafe axis-and-direction fails its own roll and the loop settles
elsewhere, which is the point. Two tests in `tests/test_crowd.gd` beside M120's own entry test
pin a partial 45px of room rather than a flush edge, since a flush edge gives the unsafe
combination no chance of acceptance and so collects nothing; both fail without the fix. M120's
pull-apart rule for entries that bunch beside an edge is untouched. The burst is
`after-north-edge-burst/`, thirty-six frames at the true north edge with nobody's picture in the
mountain band.

## M108 — Eight-direction entity graphics · the event people, animals and riders, built 2026-09-11

The second binding item, "bind live event people, animals and riders". Five agent commits on
`feature/eight-direction-event-people`, reviewed here. **One selector, one helper.**
`EventInstance._select_view()` is the walker's own sector hold applied generally, reading the
instance's `_view_sector`, and `_draw_eight_view()` draws a family's texture dictionary by that
view with `EightDirection.is_mirrored()`; `setup()` picks the nearest sector for the placed
facing with no hold, so a fresh instance never inherits a stale one. **Per family**: the dog walker
and his dog read one shared selection so the dog always faces the walker's travel; the yeller,
busker, poster crew, leaf blower, cyclist and charging dog go through the helper, a stationary one
showing its site facing and a moving one its travel; café sitters share one view and mirror from
the frontage's own site facing, which is new — they were always front-on and unmirrored; the
plain protester rank takes the octant view only when there is nothing to point at, the eight
pointing poses untouched; the van victim faces the van, a pure east-west direction by
construction; the chatting mother reads her pacing heading in both states; the waiting robber
faces *her* directly from the player position, and the lunging one reads the heading `_chase()`
already keeps pointed at her; the cat and the loose dog read their travel; each pigeon holds its
own sector, since a flock is eleven bodies wheeling independently. **Two families stay as they
were, on purpose.** The gunman's firing axis only ever reaches the side view, and the prepared
side source is byte-identical to the live one, so its front, back and diagonal views stay
prepared. The mouse stays on the single mirrored side picture: the catalogue's own docstring for
the alley mouse says the row picks no picture by heading, and binding it would have left that
sentence false in a file outside the item's fence — open to overturn, one row in the dictionary
once somebody decides the dash wants a front and a back.

**Chosen where the design was silent, each in its commit message**: the café sitters' new
per-instance directionality; the waiting robber facing her from the player position rather than
gated on the pursuit-notice threshold; the victim's heading taken from the walk-to-van direction;
per-bird sector state. **Tests**: `tests/test_event_views.gd` — the selector wiring per family,
table completeness and distinctness, the state pairs staying distinct, targeted facing with and
without a known player, and SVG fallback with no PNG transfer present. **Evidence**: eight sheets
under `docs/evidence/m108-event-people-2026-09-11/`, native and 3×, rendered by
`tests/probes/m108_event_people_sheet.gd` from the runtime selection rather than assembled from
sources, plus two `tools/shot.sh` captures. `EightDirection` needed nothing it did not have.

## M108 — Eight-direction entity graphics · the event vehicles and the police car, built 2026-09-11

The event half of the vehicle item. Four agent commits on `feature/eight-direction-event-vehicles`,
reviewed here. **One helper, one extra bit.** Every family goes through
`EventInstance._draw_eight_view()`, which gained a `side_faces_west` flag: `EightDirection.
is_mirrored()` mirrors the three west sectors on the assumption of an east-authored side picture,
and `facings.csv` records that the delivery van, fire engine, unmarked van and army truck are
authored facing west, so for those the mirror on the side sector alone is inverted; every front,
back and diagonal view is authored for its own compass point and mirrors the plain way. **Per
family**: the delivery van and the ice-cream van are parked facing due east by their placement and
only ever show the side view; the reversing lorry is sited exactly east or west against a building
and the same; the fire engine and the army truck read their travel heading along their routes; the
abduction van faces east while waiting and its chase heading once hunting, sharing one sector field
with the victim, safe because the two are only ever aligned or opposed; the police car reads its
patrol heading and is the one event vehicle whose diagonals are seen in play, since it turns corners.
**The riot van is generalised, not copied**: `_draw_riot_van()` is gone, the family's table through
the shared helper reproduces M56's hand-written octant match exactly, and a second test transcribed
from that match pins it independently of the shared tables. **Left as they were, on purpose**: the
moving-van seal keeps its side-or-vertical axis choice, since its vertical picture is an authored
across-the-street scene rather than an end view, and its front, back and diagonals stay prepared;
the burnt-out car was never in the family list.

**Registration needed no offsets.** Every prepared vehicle source is bottom-centre anchored at
canvas width over two and full height, the same convention as the side views and every family
bound before, and the helper draws at the node the shadow is centred on; a test rasterises each
front, back and diagonal source and asserts its ink reaches within 8px of the canvas bottom, the
README's own tyre-contact figures being 2 to 5px. **Two things a person should know.** Binding the
delivery van and the abduction van to the CSV's documented west authorship flips their rendered
mirror: parked facing east they now face east, where the old code assumed east-native art and drew
them facing west — a correction with no effect on shape, shadow or obstruction, in `REVIEW.md`.
And the riot van's side picture is authored facing west by the same CSV while its selection keeps
the east-native mirror sense, so a riot van heading east shows a west-facing cab — the evidence
sheet shows it backwards beside the unmarked van and the army truck. The agent preserved it because
the instruction was exact reproduction; it is filed as a defect under M100, one flag and one test
expectation. **Tests**: `tests/test_event_views.gd` — every family's view and mirror per sector
against `facings.csv`, the kerb-parked vans keeping their axis view, the lorry only ever side-on,
the riot van's octant table, the grounding check. **Evidence**: four sheets and two `--layers 2,3`
captures under `docs/evidence/m108-event-vehicles-2026-09-11/`, rendered by
`tests/probes/m108_event_vehicles_sheet.gd`, a copy of the people probe with the extra flag.

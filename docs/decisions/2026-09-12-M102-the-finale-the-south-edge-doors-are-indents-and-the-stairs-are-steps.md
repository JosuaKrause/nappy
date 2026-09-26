## M102 — The finale · the south-edge doors are indents, and the stairs are steps, 2026-09-12

*(2026-09-12, playtest 60, on the M112 graphics pass: "the downwards leading doors in the
hallways are fronwards facing doors now. the placement is good but they should be small indents
in the wall -- nothing more -- where closed doors should be the indent + a brown bar closing the
indent (this is indicating the closed door)"; "the staircase floor graphic should be vertical
lines for steps".)* Two agent commits on `feature/interior-indents-and-steps`, reviewed here
against the stills. **The doors**: `open_threshold.svg` and `apartment_threshold.svg` share one
28×16 canvas and one shape, a 20×16 recess with 2px dark returns in the skirting's own colour and
a patch of the floor's colour visible at the back; no frame, chain or panelled slab. The locked
one adds the only difference, a 4px warm brown bar across the mouth with a lighter top and darker
bottom edge, which is the whole of what says closed. Both stay anchored bottom-centre at the
south edge, and their positions are unchanged, so no code moved. **Chosen where the words were
silent**: the bar's colour and thickness, and the shared canvas matched to the skirting height
rather than either old size. **The stairs**: the three flight decks keep their outline, two-tone
fill, canvas and top-landing origin byte for byte; only the cross-hatch changed. A clip path
reuses each deck's own body, and inside it six pairs of vertical strokes (four on the basement's
short run), a light line with a dark shadow offset toward the descent, stand at the same
along-run positions the old diagonals used, thickening toward the bottom landing so the run still
reads as descending. The decks' along-length edge trim was left alone, since it is the deck's
rim and not a step. **Rejected sources** are archived under
`docs/evidence/archive/rejected-graphics/escape-interior-doors-as-fronts-2026-09-12/` and
`…/escape-interior-diagonal-treads-2026-09-12/`, each with a README quoting the playtest, since
this is a human rejection of the M112 drawing. Evidence:
`docs/evidence/m102-interior-indents-and-steps-2026-09-12/`, native and 3× sheets, a composite of
both indents over real floor and skirting, and stills at `--start-escape floor:2` (five barred
recesses along the south edge, no door silhouettes) and `--start-escape stairwell:left` (vertical
bars crossing the diagonal deck behind the unedited rail). Whether the bars read as closed doors
and the lines as steps at play scale is in `REVIEW.md`.

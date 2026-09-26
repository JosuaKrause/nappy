## M100 — Small, real, and nobody's · the riot van's side view mirrors on east, fixed 2026-09-11

Found on the event-vehicle binding's own evidence sheet, where the riot van read backwards at east
and west beside the unmarked van and the army truck. `facings.csv` records `riot_van.svg` as
authored facing west like those two, but the van's selection kept the east-native mirror sense M56's
hand-written octant match had, preserved on purpose when that match was generalised because the
instruction was exact reproduction. One agent commit on `feature/riot-van-side-mirror`: the van's
`_draw_eight_view()` call passes `side_faces_west`, the transcribed octant test pins the corrected
side mirror at east and west and every other octant exactly as before, the sheet probe's own
hard-coded flag is corrected, and `vehicles-security-{native,3x}.png` are re-rendered with row three
reading the same way as rows one and two. M56's heat tests needed nothing.

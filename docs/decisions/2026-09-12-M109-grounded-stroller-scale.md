## M109 — Grounded stroller scale — 2026-09-12

PLAYTEST-65 identified floating wheels after the hand-contact adjustment and suggested enlarging
the stroller so its handle-to-wheel height matches the mother's hand-to-foot height. The selected
drawing scale is 7/6 about the unchanged bottom-center anchor: 42×35 side/diagonal and 35×35
front/back draw rectangles from the existing PNGs and SVGs. No art was regenerated. Placement
uses horizontal distance 24px, north 17px, south 9px, the existing 0.7 Y projection and no fixed lift.

East and west wheels and feet reach the same baseline. The nearest hand/handle landmarks remain
under one native pixel apart in both gait frames and the diagonal views. North/south anchor depth
continues to project the stroller ahead of her on the ground; flattening those positions to screen
Y=0 would reopen approximately 8.5px/4.2px north-east/south-east grip gaps. This keeps projection
consistent while removing the four-pixel side-view float. The uniform scale is open to visual
judgment, with the final PNG/SVG `grounding-*` comparisons in
`docs/evidence/pram-contact-2026-09-12/`.

Collision remains the separate unsquashed 14px body-center offset and 8px radius. Touch-stop
keeps its 24px radius; the side-view pram ground center is about 33px from the stop circle's lifted
center. Shadows, cues and debug anchors follow the same visible ground position. Tests preserve
aspect ratio, integer draw extents, continuous offset and collision/input separation. The root
import/boot and 1,017 focused graphics, stroller/gait, touch, orientation and presentation checks
passed, with 120 stroller/gait checks in forced-SVG mode. No additional live capture was taken;
travel and turn appearance remain in REVIEW.

The frozen recipe retains every source PNG/SVG, local rasterizer, tool/font versions, placements
and forty-three SHA-256 records. All six PNG/SVG contact, original-snapshot and grounding variants
regenerate without a hash mismatch. The original PNG review snapshots are byte-identical to the
first committed sheets, including their footer; primary comparisons use the runtime facing-based
draw order. The script and safe regeneration commands are linked from the graphics recipe index.

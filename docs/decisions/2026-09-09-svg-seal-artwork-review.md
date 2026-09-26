## SVG seal artwork review · 2026-09-09

The player asked: "review the open PRs and check the new images for correctness and consistency
with the art style -- for now we are going with the svg graphics as main graphics -- maybe even
improve the pictures". SVG remains the main presentation; `VISUALS.md` now explicitly scopes its
PNG requirements to the opt-in illustrated overhaul.

Review of M64, eight seal pictures, found that a vertical whole-scene texture was passed through
the bottom-centred standing-sprite helper at the event origin. With a 192px scene, the picture ran
from -192 to 0 while its obstruction spanned -96 to +96. The new whole-scene drawing path moves
its standing anchor to +96, centres the scene on the ground point, and gives its shadow the same
vertical orientation. Horizontal scenes and repeated segments keep their existing anchors;
collision and placement are unchanged. A bounds regression checks both street axes.

The outer crown circle of each fallen-tree asset extended five pixels beyond its canvas. Moving
that circle inward preserves the full outline in both directions without changing the canvas or
the obstructed width. The SVG palette and outline weight are retained.

The moving-van redraw and rename arrived concurrently in the author's commit `9b72a2e`; they are
preserved. Alternative vehicle drafts from this review were discarded because PLAYTEST-50 carries
the player's more specific direction request. The crash's side-view cars rotated onto their noses
and the burnt car's missing directional view remain open in that record and in TODO.md. The skip
uses a 40px canvas against a 44px collision diameter; the moving van uses 62px against 56px.
Their visible footprint and street alignment need the same review before accepting the art.

The before/after ground-anchor captures use seed 4000, day 1, `--spawn event:car_accident --follow`
and a 0.2-second capture delay. They establish placement, not acceptance of the vehicle perspective:

- `evidence/shot-2026-09-09-seed4000-d9856f2-seal-ground-before.png`
- `evidence/shot-2026-09-09-seed4000-9b72a2e-dirty-seal-ground-after.png`

Verification: Godot import/boot, the focused events and seals suites, SVG/XML and documentation
lint, and visual inspection of the asset sheet and these gameplay captures. The full suite is CI's
gate. PRs 65 (review comments), 67 (expected-impact carets), and 68 (ignoring documentation assets)
had no actionable finding in this review; PR 66 retains the vehicle-art findings above.

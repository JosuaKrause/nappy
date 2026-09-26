## Graphics prototype review — 2026-09-06

The player asked to review the proposed graphics and identified the study's single-family houses
as inappropriate for a city. The apartment-block direction became explicit in VISUALS.md and the
architecture expansion paused for review; projection and other independent implementation could
continue. Revised-lighting captures were offered as review material, not approved art:
`evidence/archive/rejected-graphics/graphics-study-review-day1.png`, `evidence/archive/rejected-graphics/graphics-study-review-day14.png`, and
`evidence/archive/rejected-graphics/graphics-study-review-motion.mp4`. These came from standalone street-study revision
`05d3924` with corrected actor revision `7dfab84`, captured in one bounded Compatibility run.
The motion file encodes its 24 captured frames at 12 fps; it is not a gameplay demonstration.

The graphics draft integrated main through `2bac221` and opened PR #19 at the player's request
as a tracking draft, not a completed overhaul. The headless boot, focused HUD/main/pause/quit
suites and lint passed. Initial articulated model work and its wheel/gait corrections were merged
into the draft; the live game renderer was not replaced.

A single externally bounded windowed street-study capture exited normally. Its early frame is
`evidence/archive/rejected-graphics/graphics-study-first-render.png`, rendered from `2c5c713` with the Compatibility backend,
1280x720 window and `--preview-capture`. Review rejected it as a production target: paving and
facades were washed out, roof planes lacked material detail, shadows were visibly jagged, and
actors were too small. `Camera3D.size = 20` had treated a desired horizontal span as the default
vertical span. Corrections returned to the Luna city agent before live renderer integration.
The roof-reveal and browser-performance gates remained open. This evidence is a standalone art
study, not a gameplay trace or a claim that the whole overhaul was present.

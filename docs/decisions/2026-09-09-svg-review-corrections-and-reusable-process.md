## SVG review corrections and reusable process · 2026-09-09

The player requested review of PR 66's comments and a skill describing the SVG workflow.
The review's two GRAPHICS.md findings are confirmed against `SealPlanner`: burnt cars are a hard
seal of four bodies across the street, and collapsed frontage is one street-spanning hard body
whose debris texture repeats. Neither is a soft pavement pair. EVENTS.md now distinguishes the
wide scene's centred span across the street from its bottom-grounded upright depth on a
north–south street. The wide-scene test drops segment-count arithmetic from `_draw_spread`, a
path these looks do not execute, and keeps the per-axis texture and drawn-bounds checks.

The malformed Playtest 19 summary is rewritten as ownership pointers; the open vehicle
collision/silhouette audit belongs to M100, small, real, and nobody's. The lint failure banner
names lint hits rather than volatile facts, since XML failures contribute to the same total.

`.claude/skills/svg-art/SKILL.md` records the actual source-authoring, Godot rendering, visual
comparison and integration process, with pitfalls from the car projections, broad crash shadow,
crater spokes and invalid old fence XML. SVG edits trigger it through `project-rules.sh`; the
shared `.agents/skills` link exposes the same skill to Codex. The skill keeps prepared art separate
from runtime behavior and requires the catalogue and milestone assignments to follow bindings.

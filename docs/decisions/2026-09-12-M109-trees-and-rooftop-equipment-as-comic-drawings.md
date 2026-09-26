## M109 — Trees and rooftop equipment as comic drawings — 2026-09-12

PLAYTEST-65 asked to continue SVG style transfer. This batch added twelve PNG derivatives:
two trees, the ground tree bed, overhead bollard cap, water tank, two HVAC units, vent stack,
two skylights and two ducts. The existing SVGs supplied subjects, projections, canvases and
functional placement; the urban and cardinal references supplied comic forms, ink and shading.
No SVG, runtime transform, collision body or animation changed for this batch. The existing
texture resolver binds the trees and bollard through Prop, the bed through CityDecals and the
roof equipment through Building.

The tree crowns use authored foliage and branch shapes, with distinct broad and narrow forms.
The opaque tree bed uses fixed full-tile extraction. Transparent props retain their generated
silhouettes and gaps; roof canvases retain their native margins rather than forcing every
visible object to the bottom edge. The standing runtime anchor remains bottom-center, and the
ground bed remains center-anchored. These props have no collision bodies.

Review rejected painted checker backgrounds with ghost outlines. Built-in image edits supplied
white backgrounds before the authorized extractor ran, preserving gray roof materials. Review
also caught crops containing neighboring subjects and an undersized vent, skylights and HVAC
variant. Correct subject crops restored source-scale occupancy without stamping the SVG alpha
onto the redraws. Native and enlarged comparisons cover all twelve final derivatives. Exact
prompts, raw outputs, input atlases, source hashes, registration measurements and the extraction
recipe are retained in `docs/evidence/comic-city-props-2026-09-12/`.

The missing-PNG fallback test uses a synthetic texture path, because the bollard now has a
replacement. The pairing audit asks Godot's resolver to load every discovered replacement so
a duplicated import UID cannot silently substitute another prop. Prop checks distinguish the
opaque ground bed, bottom-anchored trees, centered bollard disc and roof margins. Human
appearance review remains in REVIEW.

The final tree capture used seed 4242, `--spawn park --walk 1s1e --invincible`, at four seconds.
Both tree silhouettes and their grounding are visible at gameplay scale; the camera does not
cover rooftop equipment or street-tree beds. The whole run and final still are preserved under
`docs/evidence/archive/session-captures/2026-09-12/rig-165213-seed4242-v0.8.2-806-g9959141-dirty/`.
The dirty changes were documentation only. The twelve-prop source sheet supplies the remaining
static asset coverage, and player acceptance remains separate.

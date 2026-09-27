Establish where the player indicators are clipped, checking all five source images and the
actual atlas-backed draw. The sleep glyph's outline crosses its top SVG edge, while the baby
waves may extend beyond their image bounds. Confirm those observations by comparing the current
raster with the same artwork rendered on a larger canvas. Keep the cue's existing world-space
registration and scale when adding padding; do not enlarge its gameplay collision or change
the camera, warning logic, thresholds or glyph design.

Proposed, not asked for: use only the padding needed to retain the authored stroke and filter
margin, compensating the draw anchor if image dimensions change. If clipping instead arises
at the viewport edge, report that separately before changing cue placement. Retain a compact
before/after image showing the restored edges and the runtime registration, and run the
affected verification gates. This is separate from the scenery animation PR.

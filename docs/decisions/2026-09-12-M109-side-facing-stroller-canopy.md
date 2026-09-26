## M109 — Side-facing stroller canopy — 2026-09-12

PLAYTEST-65 identifies the reversed canopy in the two side views and explicitly requests an
upper-texture flip excluding the handle. The side PNG mirrors rectangle `(11, 0, 33, 16)` with
exclusive bounds. Pixels outside it, including the handle and lower chassis/wheels, are identical.
The runtime's existing west mirror supplies the other corrected side. Other stroller facings,
mother sprites, ground anchors and animation are unchanged. The existing SVG already places the
hood beside the handle and remains the subject authority.

`docs/evidence/stroller-side-canopy-2026-09-12/` preserves inputs, their hashes, the deterministic
pixel operation and labeled east/west 12× comparison. The canopy closes beside the handle in both
reviewed textures. Root import and focused visual checks pass; its in-game appearance waits in
`REVIEW.md`.

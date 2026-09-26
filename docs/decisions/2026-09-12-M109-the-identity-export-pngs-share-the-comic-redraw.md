## M109 — The identity/export PNGs share the comic redraw — 2026-09-12

The all-textures correction in PLAYTEST-64 also covers the four generated identity/export
rasters outside the runtime replacement tree. The audit traced `logo.png` to `logo.svg`, both
stroller PNG sizes to `icon_stroller.svg`, and the social card to the logo composited onto white.
They were included rather than silently deferred as unbound gameplay art: the README uses the
logo and web export uses the social card.

One generated comic stroller mark supplies all four outputs. The authored wordmark, tagline,
colors, canvas sizes and navy rounded backing plates stay intact. Review rejected an extraction
that dropped the icon backing plate: its SVG explains why the cream mark needs that dark plate
to remain readable on light pages. The social card is still opaque RGB at 1280×640; the logo
and icon variants remain RGBA, with transparent space outside the badge. Inputs, the raw mark,
exact prompt, mappings and reproducible registration live in
`docs/evidence/comic-identity-2026-09-12/`.

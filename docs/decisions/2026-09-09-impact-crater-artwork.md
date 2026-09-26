## Impact-crater artwork · 2026-09-09

PLAYTEST-50 requests "graphics for impact craters of various sizes 1x1 2x2 and 3x3 tiles".
The three `assets/props/impact_crater_*.svg` decals have 32×32, 64×64 and 96×96 canvases, matching
the 32px tile size. Their ground anchors are the canvas centres: (16,16), (32,32), (48,48).
Transparent margins let existing ground show around the irregular asphalt rims, exposed earth
and dark depressions. No runtime placement, event row or collision behavior was requested or added.

The first renders looked too much like constructed circular pits: regular rings and tan radial
strokes read as spokes. The reviewed revision uses uneven chipped contours and dark branching
cracks; the larger crater exposes a brighter lower earth face below its dark upper interior.
All three were rendered with Godot and visually inspected. Enlarged previews are
`evidence/svg-impact-crater-1x1.png`, `evidence/svg-impact-crater-2x2.png` and
`evidence/svg-impact-crater-3x3.png`. XML validation and Godot import/boot verify the assets.

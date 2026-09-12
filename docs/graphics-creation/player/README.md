# Player SVG authoring sources

This is the active authoring directory for the player mother SVG family. It preserves the
high-fidelity F (carrying) and P2 (pushing) source artwork used to create the accepted PNG
sprites, while the runtime catalogue keeps the pre-PR SVGs for the twenty files that existed
before the player-art PR. The ten `_c.svg` files introduced by that PR remain in the runtime
catalogue and are also preserved here.

The runtime SVGs are still the fallback and the explicit `--svg` review path. The accepted PNG
counterparts remain unchanged and are selected by default when their dimensions match. Keeping
the authoring copies under `docs/graphics-creation/player/` prevents high-fidelity generation
references from becoming an implicit runtime fallback.

`manifest.json` records the byte hashes, native canvases, runtime-to-authoring pairing, whether
each runtime source existed before the PR, accepted PNG hashes, and the current generation recipe
for every member of the thirty-file family. The recipe links point to the retained P2 pushing
and F carrying records in `docs/evidence/`; those records remain historical evidence and are not
changed here.

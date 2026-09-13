# Player SVG authoring sources

This is the active authoring directory for the player mother SVG family. It preserves the
high-fidelity F (carrying) and P2 (pushing) source artwork used to create the accepted PNG
sprites. The runtime catalogue supplies the game's vector artwork. Both families contain
contact and together poses for every authored direction.

The runtime SVGs supply the fallback and the explicit `--svg` review path. The accepted PNG
counterparts are selected by default when their dimensions match. Keeping
the authoring copies under `docs/graphics-creation/player/` prevents high-fidelity generation
references from becoming an implicit runtime fallback.

`manifest.json` records the byte hashes, native canvases, runtime-to-authoring pairing, frame
roles, accepted PNG hashes, and the generation recipe
for every member of the thirty-file family. The recipe links point to the retained P2 pushing
and F carrying records in `docs/evidence/`, which preserve the source inputs and reproduction
instructions.

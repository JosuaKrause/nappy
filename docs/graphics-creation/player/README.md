# Player SVG authoring sources

This is the active authoring directory for both player presentations. The female sources preserve
the high-fidelity F (carrying) and P2 (pushing) artwork used to create the accepted PNG sprites.
The male sources supply a short-haired parent in a blue overshirt, with the same functional
registration and complete pushing/carrying pose matrix. The runtime catalogue supplies the game's
vector artwork. Every state contains contact and together poses for every authored direction.

The runtime SVGs supply the fallback and the explicit `--svg` review path. The accepted PNG
counterparts are selected by default when their dimensions match. Keeping
the authoring copies under `docs/graphics-creation/player/` prevents high-fidelity generation
references from becoming an implicit runtime fallback.

`manifest.json` records the byte hashes, native canvases, runtime-to-authoring pairing, frame
roles, accepted PNG hashes, and the generation recipe
for both complete families. The recipe links point to the retained P2 pushing, F carrying and
[male player records](../../evidence/male-player-2026-09-19/GENERATION.md), which preserve source
inputs and reproduction instructions. Male authoring SVGs and runtime fallbacks are byte-identical;
the female high-fidelity creation references remain separate from their runtime fallback artwork.

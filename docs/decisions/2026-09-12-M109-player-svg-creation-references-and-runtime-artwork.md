## M109 — Player SVG creation references and runtime artwork — 2026-09-12

PLAYTEST-65 asks to preserve the SVGs revised for high-fidelity player graphics separately and
restore the older in-game SVGs, then clarifies that newly introduced SVGs should stay. The twenty
pre-existing mother SVGs are restored byte-for-byte to the PR base,
83a60d1522574714ce038dff3a607a536d800614. The ten new together-frame SVGs remain unchanged.
All thirty high-fidelity creation SVGs are preserved in `docs/graphics-creation/player/`, with
runtime/source/PNG pairings, hashes, dimensions and F/P2 recipe links in its manifest.

The accepted illustrated PNGs, their registration, animation bindings and pram placement do not
change. The runtime SVGs remain the explicit SVG-mode and missing-PNG fallback; the dedicated
creation folder stays outside runtime imports. XML validation, import/boot, the focused SVG
visuals/stroller suites and doc lint pass. The byte comparisons establish the requested restoration;
the generation-reference family remains available without replacing the runtime SVG art.

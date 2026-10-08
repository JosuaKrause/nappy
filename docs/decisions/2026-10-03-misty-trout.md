# misty-trout — Hide the south-facing stroller handle · 2026-10-07

[Minty-hedgehog](../playtests/2026-10-03-minty-hedgehog.md), statement 9, asks to hide the
south-facing stroller's handle and suggests removing the black bar in the larger image before
scaling it down. The repair removes the cross-hood bar and its mounts from that large drawing,
then registers the result to the existing 30×30 south-facing PNG.

The source is the accepted comic-rig atlas's second cell, named `pram_back` upstream and assigned
to `art/illustrated/svg-transfer/rig/pram_front.png` by the final travel-direction recipe.
`art/rig/pram_front.svg` depicts the opposite, baby-visible concept and has no offending handle;
neither source SVG needs invented geometry to legitimize this correction to the existing PNG.
The source naming does not change the accepted travel contract: north shows the baby, south
shows the outside of the hood. No texture swap or runtime binding changes.

The built-in image generator edits the existing large drawing. Its exact prompt and retained
raw result, immutable source hashes and deterministic registration script are in the
[generation record](../evidence/stroller-hidden-handle-2026-10-07/GENERATION.md). Registration
continues the accepted shared 28-color palette, aspect-preserving fit and bottom ground anchor
at y=30, with real alpha. That recipe reuse is an implementation choice open to correction.
The southern diagonals have side handles rather than the cross-hood bar; their images and
approved wheel arrangement stay byte-identical, as does north.

Native, enlarged and high-resolution comparisons show the static repair beside the adjacent
views. A production still at source `2166bfe92d6be1e4431aefd71217cd6b50b72141`, seed 4242,
after two seconds walking south with invincibility, shows the baked south-facing region at
normal game scale. It establishes the hidden bar and grounding, not turn motion or player
approval. No gameplay, offsets, scale, shadows, canvas, atlas membership or save behavior changes.

Import/boot and rebake pass, as do 3,280 focused atlas, visuals, stroller, presentation and
orientation checks. Registration reproduces the installed PNG byte for byte. The evidence
script passes Ruff and strict mypy; lint and whitespace checks pass. The player approves the
unchanged drawing in [snowy-raven](../playtests/2026-10-07-snowy-raven.md): "stroller handle fix
looks good!!!". That answers the appearance review; independent PR review and CI remain separate.

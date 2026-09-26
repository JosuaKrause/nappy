## M109 — Garbage and litter as comic drawings — 2026-09-12

PLAYTEST-64 extended the style-transfer correction to every generated texture. The seven prop
derivatives were redrawn from their existing SVG concepts with the urban and cardinal style
references. A painterly first pass lost its forms in native-size mottling; the selected pass
uses broad shadow planes, few folds and a gray metal can without invented red branding.
Both raw candidates and prompts are preserved under `docs/evidence/comic-props-2026-09-12/`.

The final registration preserves generated alpha, fits uniformly within the source footprint,
bottom-aligns garbage sacks and centers ground litter. It does not stamp the source's round
sack outline onto the new drawing. Review caught neutral background stripes caused by treating
the color-extension output as RGBA; preserving the pre-extension alpha removed them. Blanket
white removal was also rejected because it can erase enclosed white paper and metal highlights.
The retained script removes only edge-connected white background and uses the existing
checkerboard extractor. The actual root checkout reproduced all seven runtime files byte for
byte from the saved clean atlas. Human acceptance and gameplay appearance remain separate.

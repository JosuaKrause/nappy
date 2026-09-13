# Comic prop redraw generation

This evidence records a redraw of the seven existing litter and garbage PNG derivatives. The
approved urban and cardinal reference images are style authority: they establish the irregular
ink contours, warm muted palette, graphic comic rendering, and deliberate shadow planes. The SVG
atlas remains the subject, color identity, canvas, placement, and anchor authority. Existing
rejected or earlier generated PNGs are not style references.

The first generator prompt is preserved in [`prompts/comic-props-atlas.txt`](prompts/comic-props-atlas.txt)
and its raw candidate remains at [`raw/comic-props-atlas-generated.png`](raw/comic-props-atlas-generated.png).
The selected clean redraw uses [`prompts/comic-props-atlas-clean.txt`](prompts/comic-props-atlas-clean.txt)
and its raw RGBA atlas is [`raw/comic-props-atlas-generated-clean.png`](raw/comic-props-atlas-generated-clean.png),
at 1774×887. Inputs inspected before generation and retained under
`source-references/` are `graphics-reference-urban-01.jpeg`, `graphics-reference-cardinal.jpeg`,
and the SVG source atlas `litter-sheet-svg.png`.

The selected atlas uses the existing row-major seven-cell order: `garbage_sack`, `garbage_sacks_pile`,
`litter_can`, `litter_apple`, `litter_bag`, `litter_newspaper`, and `litter_cup`; the eighth
cell is empty. The local `register-comic-props.py` keeps each derivative on its native SVG canvas
and uses measured generated bounds with the source anchor and approximate source footprint for
uniform placement. It preserves generated transparent gaps and outlines; it does not mask the
artwork with the SVG alpha. Registration output and measurements are retained in `comparisons/`
and `registration-unmasked.json`. Runtime PNGs are the seven files in
`assets/illustrated/svg-transfer/props/`; their existing `.import` sidecars and identities are
preserved.

The reproducible extraction command, using the repository's already provisioned environment, is:

```sh
uv run python \
  docs/evidence/comic-props-2026-09-12/register-comic-props.py register \
  /tmp/nappy-comic-props-registration \
  docs/evidence/comic-props-2026-09-12/raw/comic-props-atlas-generated-clean.png
```

No windowed captures were taken. Native-size and enlarged comparison sheets were inspected,
including real alpha and native canvas placement. The selected clean redraw uses broad planes and
minimal folds so the sack forms remain legible after downsampling; the can is gray metal without
the source-absent red branding. The runtime boundary and transparent holes come from the generated
redraw, with the source SVG supplying the canvas, anchor, and approximate functional footprint.

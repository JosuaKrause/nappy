# Comic identity and export redraw

This record covers the four generated or derived PNG identity assets. The authored SVGs remain
the source of the wordmark text, layout, brand colors, canvas sizes, and stroller concept. The
approved urban and cardinal references supply only the comic rendering language: confident ink
contours, broad cel-shaded planes, and restrained highlights. No SVG files were edited.

The built-in image generator received these inspected inputs in order:

1. `.claude/worktrees/comic-props/assets/icon_stroller_640.png` — source stroller identity raster,
   preserved as `source-references/icon-stroller-before.png`.
2. `.claude/worktrees/comic-props/assets/logo.png` — logo layout and wordmark identity raster,
   preserved as `source-references/logo-before.png`.
3. `docs/evidence/graphics-reference-urban-01.jpeg` — approved comic style only.
4. `docs/evidence/graphics-reference-cardinal.jpeg` — approved comic style only.

The source SVGs for the identity rasters are preserved alongside them. The exact prompt is preserved in
[`prompts/stroller-mark.txt`](prompts/stroller-mark.txt), and the raw transparent redraw is
[`raw/stroller-mark-generated.png`](raw/stroller-mark-generated.png). The generated stroller is
redrawn with clean comic forms while retaining the cream bassinet, tan bar, cream wheels, slate
hubs, angled handle, and blue sleep letters.

The reproducible registration command writes only to a fresh output directory:

```sh
uv run python \
  docs/evidence/comic-identity-2026-09-12/register-identity.py \
  /tmp/nappy-comic-identity-registration
```

The script keeps the existing native canvases and positions one generated mark in each source
layout, with the source slate rounded plate restored behind both icon variants. Its output
`icon_stroller_640.png` and `icon_stroller_1280x640.png` are RGBA canvases; `logo.png` combines
the redrawn stroller with the preserved source wordmark and tagline. `social-card.png` derives from that logo
on an opaque white RGB canvas. The social card therefore has explicit lineage
`logo.svg → logo.png → social-card.png`; it is not independent generated art.

`registration.json` records each PNG mapping, canvas, anchor, and social-card mode. Native and
2× nearest-neighbor comparisons are retained under `comparisons/`. The existing PNG `.import`
sidecars are preserved. No gameplay captures were taken.

Copy the four verified PNG outputs into `assets/` after reproduction. Preparation and
registration use CPython 3.14.7 and Pillow 12.3.0 from the repository environment.

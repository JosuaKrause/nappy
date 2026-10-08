# South-facing stroller handle removal

The installed south-facing stroller hides its handle. Its high-resolution source is the second
cell of the accepted comic stroller atlas, labeled `pram_back` by that atlas and assigned to the
runtime `pram_front` slot by the final travel-direction recipe. The similarly named runtime
`art/rig/pram_front.svg` depicts the opposite, baby-visible concept and already has no handle, so
it stays unchanged.

`generated-pram-back-no-handle.png` is the retained output of the built-in
`image_gen.imagegen` precise-object edit. [The saved prompt](prompt.txt) names the accepted cell as
the edit target and asks to remove only the dark cross-hood handle and its mounts, reconstructing
the cream hood and navy rim beneath it while preserving the stroller's body, wheels, palette,
projection and true alpha. Image generation is nondeterministic; the retained output and its hash
are the source for reproducible registration.

`register.py` checks the accepted atlas, extracted atlas, installed direction context and retained
output by SHA-256. It applies the comic-rig recipe's existing subject bounds, shared palette,
aspect-preserving fit and bottom ground anchor to a 30×30 runtime image. The script also writes a
native comparison, an 8× nearest-neighbor comparison and a fitted source comparison. The context
sheets show north and the unchanged southeast and southwest views beside south before and after;
they establish the static family comparison, not live turning or player acceptance.

Reproduce into a fresh directory with the project's Python 3.14 and locked Pillow environment:

```sh
UV_CACHE_DIR=/private/tmp/nappy-uv-cache uv run python \
  docs/evidence/stroller-hidden-handle-2026-10-07/register.py \
  --raw docs/evidence/stroller-hidden-handle-2026-10-07/generated-pram-back-no-handle.png \
  --output-dir /private/tmp/stroller-hidden-handle-rebuild
```

Compare the rebuilt runtime image with the installed derivative:

```sh
cmp /private/tmp/stroller-hidden-handle-rebuild/pram_front.png \
  art/illustrated/svg-transfer/rig/pram_front.png
```

`manifest.json` records the source cell, hashes, dimensions, registration measurement and tool
versions. The southeast and southwest stroller pixels remain governed by the southern wheel
arrangement recipe; their side handles are perspective details rather than the reported dark bar
across the cardinal south hood.

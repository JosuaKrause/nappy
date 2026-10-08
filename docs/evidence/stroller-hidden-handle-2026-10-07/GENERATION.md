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

## Runtime still

`runtime-south.png` is a 1280×720 capture of commit
`2166bfe92d6be1e4431aefd71217cd6b50b72141` at two seconds into day 1, seed 4242. The rig walks
south under `--invincible`, so the stroller uses the runtime cardinal-south atlas region at normal
camera scale while the day stays open long enough for the capture:

```sh
./tools/shot.sh /private/tmp/nappy-stroller-handle/runtime-south.png 2 \
  --seed 4242 --walk south --invincible
```

The still confirms that the baked runtime view hides the cross-hood handle at game scale and keeps
the stroller grounded ahead of the mother. It does not establish turn animation, non-south
facings, or player approval. The run's other automatic artifacts are unrelated to this static
visual claim and stay in scratch space.

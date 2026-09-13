# Layered ground asset build

`assemble.py` builds the asset layers from frozen illustrated inputs and verifies their hashes. It
needs Python with Pillow through the project `uv` environment. It rejects unknown arguments and
refuses to replace an output directory or published component directory.

Build a fresh review bundle, then verify it:

```sh
uv run python \
docs/evidence/layered-ground-2026-09-12/assemble.py build \
--output-dir /tmp/layered-ground-build

uv run python \
docs/evidence/layered-ground-2026-09-12/assemble.py verify \
--bundle-dir /tmp/layered-ground-build
```

The frozen inputs record accepted-damage source revision
83a60d1522574714ce038dff3a607a536d800614, the selected sidewalk-floor authority revision
62d1c344dccbf77e7cb8052ea09b337a76ce994e, tile inputs, SVG renders, source-SVG hashes, the
assembly script hash, and Pillow version. The selected floor PNG and the paired
`assets/tiles/sidewalk.svg` source are recorded with their source blobs and retained SHA-256 values.

To reproduce a retained bundle without reading mutable tile assets, use its frozen inputs with the
same assembly script, then compare the two bundle trees:

```sh
uv run python docs/evidence/layered-ground-2026-09-12/assemble.py build \
--input-bundle docs/evidence/layered-ground-2026-09-12/bundle \
--output-dir /tmp/layered-ground-rebuild
diff -r docs/evidence/layered-ground-2026-09-12/bundle /tmp/layered-ground-rebuild
```

The bundle creates four 32×32 opaque bases: reusable sidewalk, alley, grass, and asphalt. Asphalt
is the equal channel-wise mean of the frozen normal-road image at rotations 0°, 90°, 180°, and
270°. A wrapped-offset candidate is scored against the plain rotational mean and retained in the
bundle manifest; the smoother candidate becomes the base. Grass is a Gaussian-blurred green base
followed by the same equal quarter-turn mean, plus three full illustrated clump cutouts. The
manifest records its edge means and repeat seam error; `grass-base-repeat-native.png` and its 4×
counterpart review the repeated base along both axes.

Curb and paint overlays use their existing SVG source only for functional placement. Their pixels
come from the illustrated PNG. Damage uses broad audited regions and foreground color segmentation
from the accepted source PNG: it preserves fissure branches, hole rims, debris, and growth while
removing shared-floor seams. It never stamps an SVG alpha shape over the illustrated detail.

`compiled-tiles/` and the native and 4× checkerboard, street, and foreground review sheets are
verification previews only. Runtime loading uses `assets/illustrated/svg-transfer/tiles/layers/`:
the four bases, transparent components, generated import sidecars, and `manifest.json`. The
manifest declares source bases, clockwise component rotations, every decorated source-ID layer,
and the three grass component IDs. Build a new published directory only when it is empty, then
verify it against the fresh bundle:

```sh
uv run python \
docs/evidence/layered-ground-2026-09-12/assemble.py publish \
--bundle-dir /tmp/layered-ground-build --component-dir /tmp/layered-ground-components

uv run python \
docs/evidence/layered-ground-2026-09-12/assemble.py verify \
--bundle-dir /tmp/layered-ground-build --component-dir /tmp/layered-ground-components
```

To replace only a verified grass base in the existing component directory, preserving every other
published base, transparent component, and the engine contract:

```sh
uv run python docs/evidence/layered-ground-2026-09-12/assemble.py install-grass-base \
--bundle-dir /tmp/layered-ground-build \
--component-dir assets/illustrated/svg-transfer/tiles/layers --replace
```

To replace the shared sidewalk floor in both the engine layer directory and the normal texture
resolver, preserving every other base, transparent component, and the engine contract:

```sh
uv run python docs/evidence/layered-ground-2026-09-12/assemble.py install-sidewalk-floor \
--bundle-dir /tmp/layered-ground-build \
--component-dir assets/illustrated/svg-transfer/tiles/layers --replace
```

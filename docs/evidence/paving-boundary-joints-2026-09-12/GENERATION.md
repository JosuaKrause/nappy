# Paving boundary joints

The paving family uses complete slab joints across tile boundaries. Sidewalk and brick courses
retain their stagger: a boundary through the middle of a brick does not receive an extra wall.
Joint profiles include their shaded core and lighter shoulders, matching the interior joints'
weight. The plaza already has complete joints and retains its pixels.

`bundle/frozen-inputs/` contains the immutable material PNGs and the corresponding SVG layout
authorities. The sidewalk material comes from PR #138, revision
62d1c344dccbf77e7cb8052ea09b337a76ce994e. The other material inputs come from
c48a544cd11c89946b4216ed61200b5aed8c6668, including the muted quiet-square and plaza images.

Registration uses source pixels only. `bundle/manifest.json` records every copied pixel as
`[destination, source]`, with row-major indices on the 32×32 tile. All other pixels stay untouched.
This explicit registration preserves the reviewed joint profiles without depending on mutable
runtime files, approximate seam coordinates, recoloring or additional generation. The manifest
records original, SVG, reviewed and registered hashes, the script hash and Pillow version.
The `freeze` command records a reviewed pixel-copy arrangement and rejects any introduced color
that cannot be traced to its material input. `build` replays that saved arrangement.

Reproduce and verify from the repository root:

```sh
uv run python docs/evidence/paving-boundary-joints-2026-09-12/register.py build \
  --input-bundle docs/evidence/paving-boundary-joints-2026-09-12/bundle \
  --output-dir /tmp/paving-joints-rebuild
diff -r docs/evidence/paving-boundary-joints-2026-09-12/bundle /tmp/paving-joints-rebuild
uv run python docs/evidence/paving-boundary-joints-2026-09-12/register.py verify \
  --bundle-dir docs/evidence/paving-boundary-joints-2026-09-12/bundle \
  --target-dir assets/illustrated/svg-transfer/tiles
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script docs/evidence/paving-boundary-joints-2026-09-12/render_sources.gd -- \
  --output-dir /tmp/paving-svg-review
```

The Python commands use the project's `uv` environment with Pillow. Both entry points reject
unknown arguments and existing output directories and provide `--help` and `-h`.
The registered sidewalk and alley also supply their matching `tiles/layers/` bases; curbstones,
markings and shared damage remain separate engine components. The layered-ground recipe freezes
these registered bases before composing its review tiles. Quiet-square and plaza generation
recipes retain their upstream material registration; this recipe owns the final joint placement.

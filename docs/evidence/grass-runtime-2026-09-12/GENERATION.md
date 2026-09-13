# Runtime grass binding probe

This probe boots the project’s actual `scenes/main.tscn`. After validating its command line, the
probe instantiates `Main`, which generates the city, calls `City.build()`, starts day one, and then
the probe reads the live `Ground` node.
It does not call `TextureResolver.reset_for_tests()` or construct a standalone TileSet.

Run it from the repository root with:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  res://docs/evidence/grass-runtime-2026-09-12/grass_runtime_probe.tscn -- \
  --seed 3339657913 --output-dir /tmp/grass-runtime-result
```

The recorded run uses Godot 4.7.2 and seed `3339657913`, matching the reported gameplay capture.
The process reports `dev_flags_svg_requested: false`. Both source 12 (park grass) and source 17
(forest) hold a generated 256×32 texture with all eight 32×32 atlas cells present. The 9×9
inspection patch around tile `(42, 26)` contains source-17 cells at `(38..41, 22..27)`; their
selected atlas coordinates vary from 0 through 7. Tile `(42, 26)` itself is source 30 (precinct),
so it is retained as the reported coordinate while the nearby source-17 cells provide the forest
runtime check.

The output directory contains `runtime-result.json`, both live atlas PNGs, and native/4× crops of
the actual ground cells around the reported forest area. The JSON records SHA-256 hashes for the
probe, scenes, runtime sources, manifest, tileset and grass/forest inputs, so the capture is tied to
the exact source tree that produced it. The empty texture resource path is
expected: `GroundLayers` creates the shared atlas with `ImageTexture.create_from_image()` after
loading the soft base and clumps from the layer manifest.

The retained `runtime-result-3339657913-v2/` directory contains the JSON, atlases and crops from
the guard follow-up. The probe accepts only `--output-dir` and one integer `--seed`; `--help`/`-h`,
unknown arguments, invalid seeds, duplicate flags and existing output directories exit before Main
is instantiated and leave no output directory.

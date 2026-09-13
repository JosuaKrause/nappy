# Layered ground runtime layout

This record captures pixels copied from the TileSet produced by `GroundLayers.build_tile_set`, then
places them with `GroundTiles.source_for` and the runtime grass atlas coordinate selector. It does
not reconstruct components outside Godot.

Generate a new directory from the repository root:

```sh
godot --headless --path . \
  res://docs/evidence/layered-ground-layout-2026-09-12/layout_capture.tscn -- \
  --output-dir /tmp/layered-ground-layout
```

The command rejects unexpected arguments and an existing output directory. Its `manifest.json`
records the exact command, city seed, source hashes, crop coordinates, grass-atlas dimensions and
the source/atlas-coordinate grids. It produces native and nearest-neighbor 4× PNGs for normal and
main junctions, both normal run axes, the main vertical run, and a park-grass patch on days 1 and 14.

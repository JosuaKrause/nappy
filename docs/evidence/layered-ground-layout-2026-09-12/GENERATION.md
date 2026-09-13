# Layered ground runtime layout

This record captures pixels copied from the TileSet produced by `GroundLayers.build_tile_set`, then
places them with `GroundTiles.source_for` and the runtime grass atlas coordinate selector. It does
not reconstruct components outside Godot.

The retained layouts use source revision
7e262bc234438ab4c6540ec2e9cdd77361eb511e. Use a checkout of that revision for an exact rebuild;
the manifest records input hashes and the Godot version. Run `./tools/check.sh` in that checkout
to import its resources, then generate a new directory from its repository root:

```sh
ground_godot_bin="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
"$ground_godot_bin" --headless --path . \
  res://docs/evidence/layered-ground-layout-2026-09-12/layout_capture.tscn -- \
  --output-dir /tmp/layered-ground-layout
```

Set `GODOT` to the engine binary on other installations.

The command rejects unexpected arguments and an existing output directory. Its `manifest.json`
records the exact command, city seed, source hashes, crop coordinates, grass-atlas dimensions and
the source/atlas-coordinate grids. It produces native and nearest-neighbor 4× PNGs for normal and
main junctions, both normal run axes, the main vertical run, and a park-grass patch on days 1 and 14.

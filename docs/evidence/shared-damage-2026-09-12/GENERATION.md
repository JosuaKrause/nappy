# Shared damage atlas review

This headless Godot review builds the runtime TileSet in its default PNG presentation mode. Each
native sheet is one 192×32 atlas: six accepted stencils of one severity, composited in engine over
the named road, sidewalk, or alley base. The 4× neighbor uses nearest-neighbor scaling for pixel
inspection. The sheets establish source registration and composition; they do not replace a
gameplay review of damage placement.

Run from the repository root with a fresh output path:

```sh
godot --headless --path . \
  res://docs/evidence/shared-damage-2026-09-12/damage_atlas_review.tscn -- \
  --output-dir docs/evidence/shared-damage-2026-09-12/review
```

The probe rejects an existing output path and every unsupported argument. Its `manifest.json`
records the Godot version, source IDs, atlas dimensions, variation count, command and SHA-256
hashes of every runtime input. `--help` and `-h` print its usage without creating output.

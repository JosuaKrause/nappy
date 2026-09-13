# Shared damage atlas review

This headless Godot review builds the runtime TileSet in its default PNG presentation mode. Each
native sheet is one 192×32 atlas: six accepted stencils of one severity, composited in engine over
the named road, sidewalk, or alley base. The 4× neighbor uses nearest-neighbor scaling for pixel
inspection. The sheets establish source registration and composition; they do not replace a
gameplay review of damage placement.
The retained review uses source revision 7e262bc234438ab4c6540ec2e9cdd77361eb511e, including the
registered sidewalk and alley bases and the common variation pools.

Run from the repository root with a fresh output path:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  res://docs/evidence/shared-damage-2026-09-12/damage_atlas_review.tscn -- \
  --output-dir /tmp/shared-damage-review
```

The probe rejects an existing output path and every unsupported argument. Its `manifest.json`
records the Godot version, source IDs, atlas dimensions, variation count, command and SHA-256
hashes of every runtime input. `--help` and `-h` print its usage without creating output.

The six sidewalk-origin stencils are extracted from the layered-ground bundle's frozen accepted
inputs. The extractor calls the assembly script's audited damage mask directly, records both the
retained input and resulting component hashes, and refuses an existing output directory:

```sh
uv run python docs/evidence/shared-damage-2026-09-12/extract_sidewalk_damage.py \
  --bundle-dir docs/evidence/layered-ground-2026-09-12/bundle \
  --output-dir /tmp/shared-damage-sidewalk-components
```

The assembly script's sidewalk branch removes only the audited source-slab rows and columns. Dark
fissures and green growth crossing those locations remain, while pale floor-joint pixels do not;
the source SVG remains placement provenance and is not changed.

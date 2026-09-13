# Side-facing stroller canopy

The closed canopy side sits beside the handle in both side facings. `flip_canopy.py` mirrors
the upper texture rectangle `(11, 0, 33, 16)` horizontally; bounds are exclusive. The handle
lies to its left. All pixels outside this rectangle, including the lower frame and wheels,
are preserved exactly. The runtime mirrors the complete east-facing texture for west.

`inputs/` preserves the illustrated texture and its SVG source, which already places the hood
beside the handle. Input hashes guard against drift. This is the player's requested pixel flip;
it does not generate new artwork or change the mother, other stroller facings or draw offsets.

Run with the project's locked Pillow environment from the repository root:

```sh
uv run python docs/evidence/stroller-side-canopy-2026-09-12/flip_canopy.py \
  --output-dir /tmp/stroller-canopy-rebuild
diff -r docs/evidence/stroller-side-canopy-2026-09-12/review /tmp/stroller-canopy-rebuild
```

The output includes the runtime PNG, a labeled east/west texture comparison at nearest-neighbor
12× scale, and a manifest with bounds, input/output/script hashes and Pillow version. Labels use
Pillow's default font. The comparison is static asset evidence, not a gameplay capture.
The command provides `--help` and `-h` and rejects unknown arguments and existing output paths.

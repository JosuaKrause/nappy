# Texture integration procedure

## Preserve inputs

Read `docs/VISUALS.md` for reference roles. Preserve the SVG, its native and enlarged raster, and
the exact prompt and reference paths; rejected-graphics governs which generated outputs and drafts
are retained.
Generation need not reproduce identical pixels; extraction must be reproducible from the saved
output.

For a direct-PNG family explicitly authorized under illustrated-png, preserve the reviewed
generated source, exact prompt and references, hashes, native dimensions and registration
recipe in place of an SVG source. The exception is scoped to the authorized family.

Each family's generation, registration and rebuild commands are in its own evidence folder's
`GENERATION.md` or `README.md`. Run Python recipes with `uv run`, and choose a
fresh output directory each time. Inspect retained highlights and transparent gaps; registration
alone does not establish faithful interior geometry or sufficient gameplay detail.

## Integrate

Place reviewed derivatives at `art/illustrated/svg-transfer/<family>/<name>.png` for the
corresponding `art/<family>/<name>.svg`. Keep the native canvas dimensions and placement.
Authorized direct PNGs use a named `art/illustrated/<family>/` folder and direct atlas membership;
their reviewed dimensions and anchors define registration without a placeholder SVG.
Do not change draw offsets, camera scale or animation to compensate for a misregistered transfer.
`art/` has a `.gdignore`: no `.import` sidecars, the bake reads the files (VISUALS.md, "Where the
pictures live"). Do not copy a worktree's `.godot/` cache.

## Verify the player's checkout

Read the verify skill, then run from the folder the player will use:

```sh
./tools/check.sh
./tools/test.sh atlas visuals stroller player_presentation ground_layers orientation
./tools/lint.sh
git diff --check
git status --short
```

Inspect every error, including resource import failures. The full suite runs in CI. Every tool
that starts the engine (`check.sh`, `test.sh`, `shot.sh`, `run.sh`) rebakes in the default PNG
mode, so an `--svg` bake cannot be tested or captured through them. Compare against the SVG with
source previews at the same scale (svg-art, "Render with the game's SVG parser").
Keep captures bounded to one or two windowed runs. Preserve only the relevant artifacts with the
provenance session-captures requires, and record build, flags and coverage in the entry's decision
record under `docs/decisions/`.

For comic redraws, preserve generated alpha within the native canvas and align functional
anchors. Save the actual registration script with each family. Opaque terrain retains full
coverage and directional joins retain their functional alignment.

Review appearance at gameplay scale, frame consistency, silhouettes, transparent gaps and ground
contact. A still does not verify smooth motion or every facing. Keep unverified gates explicit,
and review each family before accepting its derivatives into the asset catalogue.

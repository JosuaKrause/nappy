# Texture integration procedure

## Preserve inputs

Read `docs/VISUALS.md` for reference roles. Preserve the SVG, its native and enlarged raster,
the exact prompt and reference paths, and the actual generated output for accepted assets and
candidates suggested for human review or rejected by a human. Drafts rejected only internally
by an assistant stay outside the repository.
Generation need not reproduce identical pixels; extraction must be reproducible from the saved
output.

The rig's generation inputs and commands are in
`docs/evidence/comic-rig-2026-09-12/GENERATION.md`. Its `convert.py` uses
`tools/remove-checkerboard.py`, preserves generated alpha and fits each drawing to its native
canvas and ground anchor. Run it with the repository's locked Python tools:

```sh
uv run python docs/evidence/comic-rig-2026-09-12/convert.py prepare /tmp/nappy-rig-sources
uv run python docs/evidence/comic-rig-2026-09-12/convert.py register \
  /tmp/nappy-rig-registration /tmp/nappy-rig-sources \
  docs/evidence/comic-rig-2026-09-12/mother-atlas-generated.png \
  docs/evidence/comic-rig-2026-09-12/pram-atlas-background-corrected.png
```

Choose new output paths each time. The prop recipe is in
`docs/evidence/comic-props-2026-09-12/GENERATION.md`; the identity/export recipe is in
`docs/evidence/comic-identity-2026-09-12/GENERATION.md`. Inspect retained highlights and transparent
gaps; registration alone does not establish faithful interior geometry or sufficient gameplay detail.

## Integrate

Place reviewed derivatives at `art/illustrated/svg-transfer/<family>/<name>.png` for the
corresponding `art/<family>/<name>.svg`. Keep the native canvas dimensions and placement.
Do not change draw offsets, camera scale or animation to compensate for a misregistered transfer.
Nothing under `art/` has an `.import` sidecar — the folder carries a `.gdignore` — and the pages
are rebaked from the sources by every tool that starts the engine; do not copy a worktree's
`.godot/` cache.

## Verify the player's checkout

Read the verify skill, then run from the folder the player will use:

```sh
./tools/check.sh
./tools/test.sh visuals stroller crowd presentation_mode orientation
./tools/lint.sh
git diff --check
git status --short
```

Inspect every error, including resource import failures. The full suite runs in CI. To compare
the two bakes, bake one mode, run `tools/check.sh` so the import pass sees the new pages, capture,
then bake the other and do the same — `tools/test.sh` cannot run the SVG side, since it re-bakes
to PNG on its way in. Use the same seed, walk, capture time and window size for both.
Keep captures bounded to one or two windowed runs. Preserve whole telemetry folders and record
build, flags and coverage in `docs/DECISIONS.md` under the session-captures skill.

For comic redraws, preserve generated alpha within the native canvas and align functional
anchors. Do not reuse the older scripts' final SVG-alpha stamping step: it clips expressive
outlines back to the primitive source. Save the actual registration script with each family.
Opaque terrain retains full coverage and directional joins retain their functional alignment.

Review appearance at gameplay scale, frame consistency, silhouettes, transparent gaps and ground
contact. A still does not verify smooth motion or every facing. Keep unverified gates explicit,
and review each family before accepting its derivatives into the asset catalogue. Every PNG
asset needs a corresponding SVG authored and reviewed first; record that pairing and provenance.

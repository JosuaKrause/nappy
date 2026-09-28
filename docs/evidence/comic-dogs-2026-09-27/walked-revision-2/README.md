# Walked-dog gait correction

**This proposal is rejected.** The player identifies sliding leg attachments in
[coral-goose, fixed leg attachments](../../../playtests/2026-09-27-coral-goose.md).
[The current fixed-joint comparison](../walked-revision-3/README.md) preserves this pass's raw
outputs, candidates and manifests unchanged. Four paws and changed contact positions alone
do not demonstrate articulation from fixed hips and shoulders.

This preview-only correction answers the player's report that the normal dog's E/W and SE/SW
hind legs did not move and that NE/NW lost a leg. It supplies exactly three B-frame overrides:
`dog_b`, `dog_front_diagonal_b`, and `dog_back_diagonal_b`. Every walked A frame, both front/back
cardinal pairs, and every accepted charging-dog artifact remain the first-pass bytes. Nothing is
installed under `art/` and runtime behavior does not change.

## Retained rejected proposal

- [Current walked-dog A/B loop](review/current-walked-a-b.gif) shows all eight runtime facings;
  [its static sheet](review/current-walked-a-b-sheet.png) exposes both frames at once.
- [Affected-facing A/B loop](review/affected-a-b.gif) isolates E/W, SE/SW and NE/NW;
  [its static sheet](review/affected-a-b-sheet.png) is the anatomy check. Both GIFs are assembled
  pose comparisons, not gameplay captures.
- [Affected high-resolution figures](review/affected-high-resolution.png) place the preserved
  first-pass A crops above the selected B crops. The raw B-only generation used a different raster
  scale, so this sheet inspects anatomy and rendering rather than native registration.
- [Selected B-only raw output](raw/attempt-2-b-frames.png) contains the three overrides unchanged.
  [Attempt 1](raw/attempt-1.png) is preserved because it was shown; it remains rejected because its
  rear paws stayed clustered and its back-diagonal B still read as three legs.

The selected B frames show four visible paws in all three projections. Their near hind leg
advances under the body while the far hind leg extends back, producing a visible opposite contact
from A; the front pair uses the other diagonal. These contact changes do not prove anatomical
ownership or stable attachments. Head, torso and outer contour differences remain between the
preserved A art and generated B art, and independent silhouette fitting changes their body
registration. The sheets preserve these defects as rejected evidence.

## Generation authority

[PROMPT.md](PROMPT.md) preserves both exact built-in image-generation prompts and all reference
roles. `inputs/defective-target-grid.png` contains the six first-pass high-resolution crops. It is
an edit target for identity, body, color and rendering continuity; its legs are explicitly
defective and are not approved pose guidance. `inputs/authoritative-pose-grid.png` contains the six
matching SVG renders and controls projection, stride pairing, ground contact and leg articulation.
The two approved style references supply comic line and shading only.

The first call redrew all six figures and still failed the gait check. The second call requested
only the three B frames, with the near hind leg forward, far hind leg back, front pair on the
opposite diagonal, and four connected legs. The built-in tool exposes no model selector or model
version in this workflow. Generation is nondeterministic; the retained raw PNGs are immutable.

## Extraction and overrides

The selected raw is 2172×724 RGBA with SHA-256
`7c3b47eed75c9abc1f68300ffca67b7af44aec44ffac84064bbba3c57bb0d0d2`.
`assemble.py` uses inspected cell bounds recorded in [revision-manifest.json](revision-manifest.json).
Within each cell, alpha above 10 locates a two-pixel-padded framing box; all original alpha inside
that box is preserved. No mask, pixel painting, warping or leg compositing is applied.

Because the selected result is a B-only sheet at an arbitrary generator raster scale, each B crop
is proportionally fitted into the union of its A/B SVG source alpha bounds, then centered and
bottom-aligned on its native canvas. The preserved A candidate is never rescaled or rewritten.
The manifest names only the three B overrides and records their source hashes, crop bounds, native
sizes, registration boxes, scales, positions and derivative hashes.

[source-input-manifest.json](source-input-manifest.json) freezes the twelve first-pass crops and
SVG renders used to compose the two generation references. [input-manifest.json](input-manifest.json)
separately freezes the composed references, both raw outputs, registration sources, first-pass
walked candidates and crops, approved style references, comparison backgrounds and every accepted
charging raw/crop/candidate/review artifact. There is no command that refreshes either manifest.
Every deterministic command fails on a missing or changed frozen input before writing derivatives.

## Rebuild and verify

Run from the repository root:

```sh
uv run python docs/evidence/comic-dogs-2026-09-27/walked-revision-2/assemble.py inputs
uv run python docs/evidence/comic-dogs-2026-09-27/walked-revision-2/assemble.py candidates
uv run python docs/evidence/comic-dogs-2026-09-27/walked-revision-2/assemble.py verify
```

The retained deterministic recipe ran with Python 3.14.7 and Pillow 12.3.0. Verification checks
the two frozen input sets, exactly three native B overrides, real transparent and visible alpha,
the selected raw and derivative hashes, all walked A/cardinal hashes, every accepted charging
artifact hash, and the five current review outputs.

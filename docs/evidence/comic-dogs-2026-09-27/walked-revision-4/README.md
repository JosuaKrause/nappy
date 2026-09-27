# Authored leg geometry preview

This proposal changes only the side and diagonal B frames. The authored SVG B supplies each
pose; the frozen A crop supplies the body and character identity. This is evidence only;
visual acceptance remains open. No runtime asset, binding or behavior changes.

## Review

Clean all-facing A/B loops include western mirrors at [native size](review/all-facings-1x.gif),
[2×](review/all-facings-2x.gif) and [6×](review/all-facings-6x.gif); corresponding static sheets
use the same names with `.png`. Each phase lasts 450ms. The clean crop-resolution pairs and
separate color-free leg silhouettes expose changes that a light/dark shading swap cannot make:

| View | Clean A/B artwork | Color-free leg contours |
|---|---|---|
| Side, E/W | [Pair](review/dog-body-pair.png) | [Pair](review/dog-leg-silhouette-pair.png) |
| Front diagonal, SE/SW | [Pair](review/dog_front_diagonal-body-pair.png) | [Pair](review/dog_front_diagonal-leg-silhouette-pair.png) |
| Back diagonal, NE/NW | [Pair](review/dog_back_diagonal-body-pair.png) | [Pair](review/dog_back_diagonal-leg-silhouette-pair.png) |

Matching `-body-loop.gif` and `-leg-silhouette-loop.gif` files alternate the exact pair at 650ms.
The separate `-leg-silhouette-overlay.png` diagrams use cyan for A-only alpha, magenta for
B-only alpha and black for overlap. They threshold original alpha at 128 and contain no coat
color. The leg crops begin at A-plane y=145, 187 and 207 respectively. These are synthetic
comparisons, not gameplay captures, and their timing is chosen for inspection.

The side hind legs gather; its near foreleg retracts and far foreleg advances. The front
diagonal likewise brings the hind feet closer, retracts the near foreleg and exposes the
advancing far foreleg. The back diagonal bends the near hind leg forward beneath the original
haunch, retracts the far hind, and reverses front-leg reach while retaining four visible limbs.
Each description follows the same anatomical limb from its original attachment region; it
does not reassign near/far labels based on color or foot position.

The black silhouettes establish changed lower-leg contours and footprint positions independently
of shading. They do not establish hidden joint positions, exact source-coordinate matching,
smooth live animation or visual acceptance. Read them beside the clean full-body artwork to
judge continuous haunch/thigh and shoulder/foreleg connections.

## Appearance limits

The generated movement follows the authored directions without matching every requested
displacement. In the side A-crop plane, approximate paw centers move near hind x=61→75,
far hind 120→109, far fore 175→189 and near fore 268→227. The near foreleg therefore gathers
more than the source-scaled request. Side B paw extent is about eight crop pixels higher,
roughly 0.6 native pixel; it is not corrected by aligning the feet because that would move
the fixed torso. Back-diagonal hind reach is smaller than the source-scaled prompt.
Small head, tail, belly-outline and shading redraws remain in the pairs. Body features are
visually close, not pixel-identical outside the legs. Native downscaling also compresses the
gap between gathered hind legs. The back B muzzle's antialiased tip reaches the raw canvas's
right edge (last-column alpha reaches 140), so its edge has no transparent margin.
These limits remain for appearance review.

## Generation and registration

The exact generation prompts and input roles are in [PROMPTS.md](PROMPTS.md) and
[DIAGONAL-PROMPTS.md](DIAGONAL-PROMPTS.md). Built-in
`image_gen` supplies the artwork. Registration applies one uniform scale from the generated
canvas into A's original crop plane, then the frozen A native transform; it does not paint,
warp, composite limbs or apply SVG alpha. Body and paw differences remain visible in the pair.

All three exact unedited generation outputs are selected, one per view, and preserved under
`raw/`. The two input manifests freeze those outputs, prompts, the original source SVGs/renders,
style references and prior image artifacts. Both manifest hashes are pinned in `assemble.py`;
there is no refresh command. The native transforms inherit the first-pass A scale, fitted
dimensions and placement. Raw canvas proportions preserve A's composition plane, with no
additional translation: the original haunch crease, tail/body junction and collar remain in
approximately the same positions. Registration does not infer scale from moving paws.
`revision-manifest.json` records the raw dimensions/hashes, inherited transforms and outputs.
The recipe reuses the frozen revision-3 layout function only for all-facing sheets and loops.

## Rebuild and verification

Run from the repository root using the project environment (Python 3.14.7, Pillow 12.3.0).
Pillow's bundled font draws labels; no system font is required.

```sh
uv run python docs/evidence/comic-dogs-2026-09-27/walked-revision-4/assemble.py build
uv run python docs/evidence/comic-dogs-2026-09-27/walked-revision-4/assemble.py verify
uv run python docs/evidence/comic-dogs-2026-09-27/walked-revision-4/verify-rebuild.py
./tools/lint.sh
git diff --check
```

Verification checks frozen prior artifacts, A/cardinal/pursuing frames, native canvases, real
alpha and all derivative hashes. The isolated rebuild checks byte-identical outputs and that
each selected raw, when changed or missing, fails before any write. No runtime code or game
asset changes means no gameplay suite or windowed capture is needed for this preview.

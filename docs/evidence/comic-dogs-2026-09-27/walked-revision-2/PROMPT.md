# Walked-dog gait correction prompt

The built-in image generator received four local references for the first targeted correction.
Image 1, `inputs/defective-target-grid.png`, contains the six high-resolution first-pass crops and
is a defective edit target for identity, body, color and rendering continuity. Its leg positions
are not approved pose guidance. Image 2, `inputs/authoritative-pose-grid.png`, contains the six
matching SVG renders and is authoritative for projection, stride pairing, ground contact and leg
articulation. Images 3 and 4 are the approved style references
`docs/style-references/graphics-reference-urban-01.jpeg` and
`docs/style-references/graphics-reference-cardinal.jpeg`; they supply comic line and shading only.

## First targeted correction

```text
Edit the walked-dog sprite family in Image 1 to correct only the leg anatomy and gait in its six shown poses. Image 1 is the defective in-review target: preserve its friendly compact tan-and-cream dog identity, exact comic rendering language, blue collar, hanging dark ears, raised tail, body/head proportions, body placement, colors, contours, and internal shading, but do not treat its defective leg positions as approved pose guidance. Image 2 is authoritative for the three projections, A/B stride pairing, ground contact, and intended leg articulation; interpret its simple shapes as anatomy rather than tracing its primitive contours. Images 3 and 4 supply comic line and shading style only.

Output exactly six isolated full-body dog sprites in a strict 3-column by 2-row grid with generous transparent separation. Columns left to right: east-facing side, southeast/front diagonal, northeast/back diagonal. Top row is stride A and bottom row is stride B. No labels, borders, floor, scenery, checkerboard, leash, cast shadow, halo, text, or watermark. Use genuine alpha transparency.

Correct the gait with anatomically connected hip-to-knee-to-paw chains. SIDE A/B: both hind legs must be visible and must clearly exchange their forward/back relationship between A and B, with one rear leg advancing while the other trails; do not leave the hind silhouette static. FRONT-DIAGONAL A/B: both hind legs must be accounted for at their separate hips and visibly articulate between frames, with a clear alternate rear-paw position rather than the same two shapes. BACK-DIAGONAL A/B: show all four legs in both frames, each connected to its own shoulder or hip; preserve the far leg under the body so no leg vanishes, and alternate the stride without crossing ownership. Keep paws on a common ground baseline within each row.

Across each A/B pair, hold the torso, head, ears, muzzle, collar, tail, scale, and placement fixed as closely as possible; change the legs only. Keep the same dog across all six cells and preserve the high-resolution authored comic treatment from Image 1. Avoid extra limbs, fused legs, detached paws, hidden fourth legs, anatomy seams, body drift, head drift, and independent per-frame rescaling.
```

The built-in tool exposes no model selector or version in this workflow. The generation is
nondeterministic; `raw/attempt-1.png` preserves this shown attempt. Inspection found that its rear
paws remained clustered in both rows and its back-diagonal B still had only three readable limbs,
so no candidate uses it.

## B-frame correction

The second call received the same four references. It narrowed the output to the three defective
B frames and made the opposite contact explicit:

```text
Create only three corrected STRIDE B sprites for the walked dog, one per column: east-facing side, southeast/front diagonal, northeast/back diagonal. Image 1 is the defective in-review A/B target grid. Preserve its A-row dog as the identity, rendering, torso/head/tail/collar scale, and placement reference, but repair the B-frame leg anatomy; Image 1's existing B-row legs are explicitly defective and must not be copied. Image 2 is authoritative for projection, ground contact, and intended alternate stride. Images 3 and 4 supply comic line and shading style only.

Output exactly three isolated full-body dogs in one horizontal row, ordered side, front diagonal, back diagonal. Genuine transparent background, generous gaps, common ground baseline. No labels, borders, floor, scenery, checkerboard, leash, cast shadow, halo, text, or watermark.

For every corrected B sprite, draw exactly four readable legs, each continuously connected to its own shoulder or hip. This B contact must be the clear opposite of A: the NEAR HIND leg swings FORWARD from its hip to a separate paw under the mid-belly; the FAR HIND leg extends BACK from its own hip to a separate rear paw. Keep those two rear paws visibly separated in horizontal position, not clustered at the same x/y. Put the front-leg pair on the opposite diagonal: the near front leg trails while the far front leg advances, both connected and readable. Do not hide, fuse, omit, duplicate, or detach any leg.

For the back-diagonal sprite, foreshortening must still leave four countable connected limbs: two distinct hind legs and two distinct front legs. Preserve a readable far hind leg under/behind the body rather than letting it vanish into the silhouette.

Hold each torso, head, ears, muzzle, blue collar, tail, colors, proportions, scale, and ground registration stable to the corresponding A sprite in Image 1. Change the leg positions only. Avoid body drift, head drift, independent rescaling, crossed hip ownership, extra limbs, anatomy seams, or a friendly dog's body turning into a different projection.
```

`raw/attempt-2-b-frames.png` is the immutable output selected for three explicit B-frame
overrides. The corresponding A frames remain the first-pass candidates.

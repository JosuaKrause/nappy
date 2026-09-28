# Third-pose generation prompts

## Side front-leg ownership refinement

Inputs: `raw/dog-c-front-ownership-attempt.png` (first C edit target), then
`source-renders/art/events/dog_c@6.png` (reviewed pose authority).

```text
Correct only the FRONT LEGS in Image 1, leaving the new hind-leg pose and entire body/head/tail unchanged. One dog on true transparent background. Image 2 is the authoritative reviewed SVG C pose.
The current front legs still read as the wrong anatomical pair: the light foreground front leg reaches forward, but the desired C pose has the LIGHT FOREGROUND front leg reaching BACKWARD (toward screen left), and DARK BACKGROUND front leg reaching FORWARD (toward screen right).
Redraw their actual anatomical connection and silhouette from fixed shoulder roots, not merely their colors:
The golden near/frontmost foreleg begins at the lower torso shoulder (around x201,y118 in a320x218 plane) and angles BACK LEFT, with elbow around x186,y157 and paw around x177,y199. It passes IN FRONT at the overlap with the other foreleg and owns that backward foot.
The darker far foreleg begins BEHIND the chest at x218,y116 and angles FORWARD RIGHT, elbow around x244,y153 and paw around x270,y198. Its upper section disappears naturally behind the near leg/chest. It owns the forward foot.
Keep their roots at the original shoulder, retain four complete connected limbs and the new hind step. Preserve same image dimensions/proportions, original body, outline, ears, head, collar, tail and alpha. No added shadows, diagrams or labels. Match Image 2's foreground/backward and background/forward foreleg layering.
```

Built-in `image_gen` creates the artwork after independent review of the new SVG sources.
The approved urban and cardinal style references are inspected; frozen illustrated A is the
edit target and preserves the selected family rendering. Each new C SVG raster is pose authority.

## Side C

Inputs: `../crops/dog/dog.png` (identity/body edit target), then
`source-renders/art/events/dog_c@6.png` (reviewed new pose).

```text
Use case: precise-object-edit.
Create ONE missing opposite-step animation frame of this dog on genuine transparent background.
Image 1 is the frozen illustrated A EDIT TARGET: preserve exact dog identity, camera, framing, body, rounded haunch, head, muzzle, collar, tail, tan/cream coat and ink style. Image 2 is the independently reviewed new SVG C POSE AUTHORITY. Transfer its limb articulation into Image 1's drawing style; do not transfer its primitive vector style.
This is the opposite EXTENDED step, not a neutral stance. In A the near/light hind leg trails backward and near/light foreleg reaches forward. In C the SAME near/light hind leg must reach forward under the belly and SAME near/light foreleg must trail backward; dark far hind trails backward and dark far fore reaches forward.
Trace continuous anatomy from the SAME original roots: near hind hip around (82,123), far hind root (104,128), near fore shoulder (201,118), far fore root (218,116) in the 320x218 image-1 plane. Near hind thigh angles forward from its fixed haunch, knee forward around (112,157), hock beneath it around (104,180), paw forward around (120,200). Far hind angles backward from its original root to knee around (80,157), hock (54,177), paw around (57,198). Near fore goes backward through elbow (186,156) to paw around (177,200). Far fore reaches forward through elbow (245,156) to paw around (269,198). Preserve floor baseline heights.
Near/far identity and shading never change. Rebuild actual articulated leg contours rather than recoloring/relabeling the existing two footprints. Some overlap in projected silhouettes is natural, but each of the four legs must visibly connect to its own fixed root, with different knee/hock shape from A. Near hind flows continuously from original haunch; do not slide its attachment along the belly.
Keep the entire torso/head/tail/collar unchanged in placement and proportions. Only legs change. No bounding-box refit, no body bob, no ground/shadow, no labels or diagrams. Same full-dog composition as Image 1, true alpha. Output one dog only.
```

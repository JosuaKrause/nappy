# Diagonal opposite steps and cardinal neutral poses

## dog_front_diagonal C

Inputs in order: `../crops/dog/dog_front_diagonal.png` (frozen A identity/body edit target),
`source-renders/art/events/dog_front_diagonal_c@6.png` (independently reviewed new pose authority).

```text
Use case: precise-object-edit. One new opposite EXTENDED step of the front-diagonal dog, true transparent background.
Image1 is frozen A edit target and exact identity/body/style authority. Image2 is reviewed NEW SVG C pose authority; transfer its articulation into the existing comic rendering, not its primitive drawing.
Face southeast exactly as Image1. Preserve its body, original haunch crease, shoulders, head, muzzle, ears, tail, collar, camera and proportions. Change only legs.
Near LIGHT hind leg advances forward under belly from ORIGINAL hip (62,145) through forward knee roughly (100,183), hock (98,209), paw (113,230) in image1's326x263 plane. Far DARK hind leg trails backward from original root (82,150), knee (51,183), hock (28,202), paw (36,212). They must articulate through genuine new joint angles, not exchange colors of old leg silhouettes.
Crucial front pair: the LIGHT near foreleg angles BACKWARD/LEFT from original shoulder (177,157), through elbow (165,199) to paw (174,245). Its contour is foreground and overlaps the other upper leg. DARK far foreleg angles FORWARD/RIGHT from BEHIND original shoulder (205,150), through elbow (237,190) to paw (265,224). The far forward leg must remain dark and be behind the light backward near leg where they cross. This is the opposite reach to A.
Four connected limbs, fixed body attachment regions, continuous haunch-thigh connection. Do not slide a thigh along belly. Preserve standing ground heights and sourceC perspective. Some silhouette overlap with opposite step is normal but the SAME limb must visibly change its bend. Keep all non-leg artwork as close as possible to Image1. No torso bob, labels, guides, shadows, backdrop or extra objects. One complete dog only with real alpha.
```

## dog_back_diagonal C

Inputs in order: `../crops/dog/dog_back_diagonal.png` (frozen A identity/body edit target),
`source-renders/art/events/dog_back_diagonal_c@6.png` (independently reviewed new pose authority).

```text
Use case: precise-object-edit. One new opposite EXTENDED step of the back-diagonal dog on true transparent background.
Image1 is frozen A edit target, identity/body/rendering authority. Image2 is reviewed NEW SVG C pose authority. Dog faces northeast away/right, same camera.
Preserve exactly the original rounded haunch, torso contour/height, shoulder positions, head, collar, tail, ears, coat colors and framing. Change only articulated legs to the new C.
The LIGHT near hind leg swings FORWARD under belly from SAME original hip around(65,171) in333x275 image1 plane, through forward knee(106,211), hock(112,239), paw(130,261). Its connected thigh grows from the original haunch, never from a moved attachment.
The DARK far hind leg swings BACKWARD from fixed behind-root(99,175), through knee(69,211), paw(54,242). Keep its shin and foot separately visible to the left/behind the light forward hind leg.
The LIGHT near foreleg retracts BACKWARD/LEFT from fixed shoulder(226,151), elbow(203,193), paw(195,230). It is the foreground foreleg at crossing.
The DARK far foreleg reaches FORWARD/RIGHT from behind shoulder(242,140), elbow(268,180), paw(291,215); its upper leg is behind the light near foreleg. This front ordering is critical: light backward in FRONT, dark forward BEHIND.
Read Image2 for actual pose, with four continuously attached limbs and new joint shapes from the same roots. No mere recoloring or near/far relabeling. Preserve all original body features, standing paw heights and overall composition, no raised running paws. True alpha, no ground/shadow, diagrams, labels or added objects. Output only one complete dog.
```

## dog_front C

Inputs in order: `../crops/dog/dog_front.png` (frozen A identity/body edit target),
`source-renders/art/events/dog_front_c@6.png` (independently reviewed new pose authority).

```text
Use case: precise-object-edit. Create ONE NEUTRAL RESTING front-view dog frame on genuine transparent background.
Image1 is frozen illustrated A edit target and body/identity/rendering authority. Image2 is newly reviewed SVG C neutral pose authority.
Preserve EXACTLY the dog face, head, eyes, ears, muzzle, chest, collar, body, tail, camera, scale and framing. Change only the four legs to a symmetric square standing stance.
The two LIGHT nearer FRONT legs should stand side by side with their paws at equal ground height, both as low as the lowest current near/front paw. Same shoulder roots and lateral tracks. Neither front foot reaches farther toward the viewer than the other. Make both look relaxed and weight-bearing, not one lifted.
The two DARK farther HIND legs should likewise stand level as a pair behind the front legs, at a slightly higher projected floor line (Image2 defines this depth); move their feet to the middle height between their two existing alternating positions. Keep all four legs continuously attached; no new root placement.
Near foreground front legs remain tan, far background hind legs remain darker brown. It is a new square neutral pose between the existing two steps, not a mirror of Image1 and not a relabeling of foot colors. Preserve material shading and ink weight, genuine alpha, no body bob, no shadows/ground/labels. Output one full front-facing dog.
```

## dog_back C

Inputs in order: `../crops/dog/dog_back.png` (frozen A identity/body edit target),
`source-renders/art/events/dog_back_c@6.png` (independently reviewed new pose authority).

```text
Use case: precise-object-edit. Create ONE NEUTRAL RESTING rear-view dog frame on genuine transparent background.
Image1 is frozen illustrated A edit target and authoritative original rump/body/head/tail/collar/rendering. Image2 is independently reviewed new SVG C neutral pose authority.
Preserve EXACTLY the upper dog, tail curve, rump center line, haunches, head, ears, blue collar, original body scale and placement. Change ONLY legs to a symmetric square stance.
Both LIGHT nearer HIND legs stand on the same low ground baseline, as low as the current lowest near hind paw. Keep the same roots, thigh tracks and relaxed joint shape; neither hind foot should be ahead of the other in screen depth.
Both DARK farther FRONT legs stand at equal higher projected floor height behind the hind legs; their equal level is halfway between their current alternating positions. Retain four owned, attached legs and their existing lateral tracks; don't move roots or recolor them to fake a new phase.
This view looks straight away from the viewer, and the sourceC is neutral between the two existing steps. Same camera, composition, colors and original comic line/shadow style. True alpha, no labels, guides, ground, shadows or other objects. One complete dog only.
```


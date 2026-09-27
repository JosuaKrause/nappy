# Authored leg geometry correction

Built-in `image_gen`; nondeterministic generation. The source PNG is the rendered authored
B pose, not a style reference. The frozen A crop supplies identity and body registration.

## Side B

Inputs in order:

1. `../crops/dog/dog.png`: frozen A edit target and identity/body authority.
2. `../source-renders/art/events/dog_b@6.png`: authored gathered B pose authority.

```text
Use case: precise-object-edit.
Create ONE corrected animation frame of the dog on genuine transparent background.
Image 1 is the EDIT TARGET and authoritative dog identity, rendering, body, head, collar, tail and fixed hip/shoulder attachment positions. Image 2 is the AUTHORED B POSE AUTHORITY (simple original SVG render), NOT the desired drawing style.
The target currently has spread legs. Change ONLY its four articulated legs to the gathered-under-body B pose in Image 2. Do not swap near/far legs or swap their light/dark shading. Each leg remains attached to the same hip or shoulder; only the angles through knee/hock and paw change. Retain the first image's inked comic drawing style.
Precise movement in Image 1's 320 by 218 coordinate plane (scale proportionally if output enlarged):
Near/light hind leg: fixed hip (82,123), knee moves from (65,155) to (76,155); hock moves (53,177) to (71,177); paw moves (61,200) to (82,200). It becomes less backward-bent, visibly more vertical under the SAME original haunch.
Far/dark hind leg: fixed hip (104,128), knee moves (107,164) to (99,164); paw moves (120,198) to (110,198). Keep it behind the light thigh; keep two readable hind paws.
Near/light foreleg: fixed shoulder (201,118), elbow moves (229,155) to (220,155), paw moves (268,199) to (255,199); less forward-reaching.
Far/dark foreleg: fixed shoulder (218,116), elbow moves (190,153) to (203,153), paw moves (175,198) to (193,198); less backward-reaching.
These are actual contour and position changes, not recoloring existing leg silhouettes. The rear legs GATHER; the front legs GATHER. Four connected legs, with their near/far identities preserved. No limb reaches further outward than in A. No raised running paws. No attachment sliding forward/back on torso. Preserve exactly the back contour, belly height, original haunch crease, chest shape, head, ears, tail, facial expression, collar and body proportions of Image 1.
Output only the complete single dog, same camera, composition and framing as Image 1. No guide lines, labels, shadows, backdrop or extra objects. Preserve real alpha.
```

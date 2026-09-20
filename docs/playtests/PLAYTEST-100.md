# Playtest 100 — Match the whole picture's colors; preserve the pose

2026-09-19. Review of PR #234, M167, the father's legs read as legs.

> "okay match the color with the rest of the drawings -- the entire picture has off colors (too bright)"

> "but the legs and pose is good now"

The uncrossed diagonal legs and pose are accepted. Preserve their geometry, registration and
alpha exactly. Apply only a deterministic color and brightness transformation to the entire
new SE/SW B figure in pushing and carrying: skin, hair, jacket, shirt, trousers, shoes and
the carrying baby/blanket must match the existing drawings. A trouser-only recolor is not
sufficient. Keep the already accepted E/W and every other frame unchanged. Publish updated
PNG sheets and GIFs on PR #234. This verdict does not authorize installation or merging.

The player specifies the two opposite color errors:

> "wait, the pants are too dark and the jacket is too bright"

Lighten the trousers and darken the jacket independently to match the existing A/C material
colors. Do not apply uniform darkening to the whole picture. Match other materials as needed
without changing the approved geometry.

The player adds a specific jacket-edge correction:

> "also pull the jacket edge down to match the rest of the frames"

> "you can just move the pixels down and fill in the new empty space with copies of the jacket texture down there"

Lower only the jacket's bottom edge to the corresponding A/C height and fill the exposed gap
with copied neighboring jacket texture. Move the hem outline with the edge rather than leaving
a doubled dark line. This authorizes a local pixel edit to the jacket hem; keep the approved
legs, walking pose and all artwork outside the hem region unchanged apart from the requested
material colors. No image generation is needed for this correction.

The player specifies the texture and edge sources:

> "ie take the rest of the body texture from the other frame and just move the edge down"

> "take the edge from the new frame"

Use the corresponding existing frame's body texture with the new approved B frame's jacket
edge moved down. The matching-state diagonal C supplies the stable body texture; the new B
supplies the hem contour and approved legs. Keep the new legs below the extended hem and
lighten their colors to match. This supersedes recoloring the generated upper body or using
its texture as the jacket fill. Keep all unaffected animation frames byte-identical.

The player explains why the existing body texture matters:

> "because the carrying one also includes the baby which is now too short"

Restore the entire existing carrying upper body, including the full-size baby, arms and face,
at its original native scale. Do not resize the baby independently. The approved new legs
remain the lower-body source, with the new hem edge moved down between them and the old body.

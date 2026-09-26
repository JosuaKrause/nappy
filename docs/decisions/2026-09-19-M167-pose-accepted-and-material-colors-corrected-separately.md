## M167, pose accepted and material colors corrected separately — 2026-09-19

[PLAYTEST-100](../playtests/PLAYTEST-100.md) accepts the uncrossed legs and pose: "but the legs
and pose is good now". The player first describes the entire picture as too bright, then
specifies the opposing material errors: "the pants are too dark and the jacket is too bright".
The remaining correction is deterministic and color-only: lighten trousers, darken the jacket,
and compare other materials with the corresponding A/C drawings. Uniform darkening would
worsen the trousers. The approved pose, every alpha value and every other frame are protected.

The player then authorizes a specific pixel construction: "also pull the jacket edge down
to match the rest of the frames", "you can just move the pixels down and fill in the new
empty space with copies of the jacket texture down there", then "ie take the rest of the
body texture from the other frame and just move the edge down" and "take the edge from the
new frame". The body texture comes from the matching existing frame, while the hem contour
and approved legs come from the new B. The player explains the carrying requirement:
"because the carrying one also includes the baby which is now too short". Copying the
existing carrying upper at its native scale restores the baby's proportions along with
the father's texture. This local body/hem construction is an explicit exception to the
earlier color-only boundary; it does not authorize moving the approved legs or regenerating
the figure.

The implementation copies the corresponding existing C upper body at native scale and moves
only the new B jacket's two-row edge down two pixels. A first five-row selection included
trouser pixels and was narrowed before publication. The copied body supplies the existing
jacket texture and full-size baby; the moved edge receives a lower-jacket palette fit that
excludes the blanket. The retained new trousers are lightened separately against A/C samples.
All pixels below the extended hem retain the approved lower-body alpha, and the shoes keep
their original pixels. The comparison sheets show A, C, original B and the composite result
alongside the complete pushing/carrying PNG sheets and GIFs.
Fresh assembly reproduces every output byte. Checks confirm the restored upper matches C
outside the moved edge, alpha changes remain within the authorized upper/hem region, approved
leg geometry is unchanged, and all other authored frames remain byte-identical. Native sizes,
nearest-neighbor enlargement and 190ms phase timing pass, as do lint and whitespace checks.

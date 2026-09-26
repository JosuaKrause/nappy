## M109 — Muted plaza material and selected sidewalk source — 2026-09-12

PLAYTEST-65 asks for plaza paving with the quiet square's muted, low-contrast stone constraints.
The retained generator output uses a larger single slab with edge joints and a cool slate palette.
Direct LANCZOS registration makes an opaque 32×32 PNG; mean RGB brightness falls from 149.5589
to 93.6289. The raw image, exact prompt, source SVG, approved quiet-square input and neighboring
materials are retained in `docs/evidence/plaza-paving-2026-09-12/`. Its portable frozen-input
rebuild reproduces the complete bundle byte for byte. Root import/boot and focused visual checks
pass. The player's subsequent boundary-joint instruction applies to this material too.

The same playtest selects the sidewalk from PR #138, revision
62d1c344dccbf77e7cb8052ea09b337a76ce994e, as the shared floor. The source PNG blob is
af36579547f3f1795a7549c4f3227a2a9e9f58db and SHA-256 is
a86c9cdff2ca96f1d5016a7b997d506e0a1452174a06cadd9a51b50eafff0c28.
It is installed byte for byte in the normal sidewalk path and shared layer path; every overlay
remains separate. Frozen layer, quiet-square and plaza bundles rebuild byte for byte with these
neighbor inputs. Repeated layout review and the player's report then identify missing boundary
joints: center joints alone let adjacent rectangles merge. The follow-up preserves this selected
material while completing the paving family's boundary joints.

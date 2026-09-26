## Illustrated repair continuation — 2026-09-08

The player asked to continue from `feature/illustrated-registration`, following PLAYTEST-43's
connected-parts and original-SVG-size review. The existing draft PR is #49. The work remains
opt-in and does not authorize releasing or merging the full graphics overhaul.

Two built-in pram generation attempts are preserved under
`evidence/archive/rejected-graphics/pram-registration-2026-09-08/`, with exact prompts and input
roles in `GENERATION_RECORD.md`. The first requested eight views and four registered layers;
the second requested only actual background extraction. Both returned 1448×1086 RGB PNGs with
`sips -g hasAlpha` reporting `no`. Both visibly paint a checkerboard. The first also packs each
layer independently and duplicates the storage basket across chassis and seat. Neither was
registered or substituted into gameplay. These are rejected outputs, not art references.

Review rejected the initial walker code pass (`bc06307`): it supplied whole-sheet x coordinates
as crop-local pivots, reused one variant's unremapped table for both variants, and calibrated an
upper-body sheet as though it included the solver's separate legs. Its constant-readback tests
could pass while the actor moved sideways and remained oversized. This is why rendered painted
extents and transformed attachment points, rather than declared cell dimensions, gate the repair.

The graphics handoff also claimed that the modular actors were not bound to gameplay and that
the street study could be extended. It now points to the opt-in live bindings and the rejected
street gate recorded under M84. Source availability, registration validity and visual acceptance
are distinct checks; a manifest listing eight views does not establish eight valid drawings.

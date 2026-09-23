---
name: rejected-graphics
description: Guard the rejected graphics archive, and where rejected artwork goes. Load BEFORE moving artwork into this archive or citing it.
---

# Rejected graphics archive

Preserve artwork rejected by a human, and artwork suggested for human review. Keep drafts
rejected only internally by an assistant outside the repository. This retention rule applies
to both SVG authoring and PNG transfer; it does not call for deleting human rejection records.

**Where rejected artwork goes**, by the candidate's stage: a candidate rejected during its family's
review stays beside that family's evidence with its verdict; artwork removed from `art/` after it
shipped or was wired in moves to `docs/evidence/archive/rejected-graphics/`. *(2026-09-23: the
player chose this split between an in-review rejection, which stays with the family that produced
it, and an out-of-service removal, which moves to this archive.)*

Everything under `docs/evidence/archive/rejected-graphics/` is preserved for posterity only. These
are rejected experiments, not visual guidance, style references, prompt inputs, or implementation
targets. Use the approved references in `docs/evidence/` and the roles documented in
`docs/VISUALS.md` for active work. Do not copy archived assets into a new family or cite them as
approval evidence.

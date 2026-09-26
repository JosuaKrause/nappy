## M167, interrupted delivery checkpoint — 2026-09-19

The player first requested a complete reviewable PR with future conflicts deferred, then
stopped all work: "write everything down now!!!", "no more tests no more anything", and
"handoff now!!!!". Both implementation agents were interrupted. No additional tests or
implementation were performed after that stop; existing changes were checkpointed for handoff.

The PR branch is `feature/father-leg-refinement` in `.claude/worktrees/father-leg-refinement`.
Its preceding local tip is `c8af7e63`, following the reviewed main merge `4b9b21cb`, attempt
indexing, reusable toolbox and the M171 build-time atlas requirements. The latest confirmed
published head is `49bc5b0e`; its full CI was green. The handoff commit publishes the subsequent
documentation. PR #234 remains draft and is not merged or newly represented as ready.

Installation checkpoint `2a310abde1f7e55ed1ebf008e1a44d0428029fbe` is on
`feature/father-final-install`, worktree `.claude/worktrees/father-final-install`, based on
`4b9b21cb`. It installs six exact approved PNGs, preserves the other 24 father frames and
import sidecars, updates manifest overrides, and reconciles the existing pushing and carrying
diagonal SVG fallbacks with the approved uncrossed contact. It preserves the original registered
rasters and retargets the old normalized-crop carrying recipe to those immutable inputs.
Its README changes overlap the parent branch's normalized-crop cleanup and need manual review.

Before the stop, the installation agent reported: final-family fresh rebuild/diff passed;
pair/hash/import verification passed; normalized-crop carrying outputs reproduced byte-for-byte;
boot passed; focused PNG visuals, player-presentation, stroller, presentation-mode and orientation
suites passed with 2,246 assertions. Forced-SVG completion and final capture metadata require
inspection of the checkpoint rather than assuming the interrupted agent finished them.

Two runtime bursts are retained under `docs/evidence/archive/session-captures/2026-09-19/`:
`rig-200220-seed3-v0.13.0-62-g4b9b21cb-dirty` shows father pushing, while
`rig-200241-seed288043464-v0.13.0-62-g4b9b21cb-dirty` shows the mother carrying despite the
requested seed-3 city-escape scenario. The second burst is not father-carrying visual evidence.
Both have 36 frames; actual timing is in their burst sidecars. The parent inspected frames
and caught the incorrect carrying subject. No third windowed run was taken. Headless binding
checks and the approved complete PNG/GIF family are separate evidence, not a replacement claim
that this failed scenario photographed the father carrying.

Historical-recipe checkpoint `1c056b8c` is on `feature/father-recipe-preservation`, worktree
`.claude/worktrees/father-recipe-preservation`, also based on `4b9b21cb`. It touches only
straight-contact, woman-leg-trial, review and diagonal-carrying recipes and provenance. The agent
reported fresh output matches and lint/diff checks, but parent review found its SVG fix invalid:
`docs/graphics-creation/player/father_front_diagonal_b.svg` is an active creation copy changed
by the installation, not a frozen original. The source references in straight-contact and
woman-leg-trial must instead use preserved historical SVG bytes. Its PNG mappings to immutable
registered originals are the intended approach. Do not claim the combined tree reproduces until
that specific remaining issue is corrected and inspected under renewed authorization.

Neither checkpoint is cherry-picked into the PR. `/tmp/nappy-pr234-shipping-body.md` is only
an unpublished draft and contains an `INSTALLATION_CHECKS_PENDING` placeholder; do not publish
it unchanged. The accepted PNG/GIF embeds remain on the PR at their original immutable image
commit. PR #216 is owned elsewhere. No new main merge, release, branch deletion or further
testing is part of this handoff. The next session needs fresh agents if work resumes.

## Main update for illustrated registration — 2026-09-08

The user requested the merging-main skill to update the current branch. The original branch
tip and actual first parent were `24a85058dafc5765044ce38cf6b80c99b9b84dd9`; fetched main was
`33c45f936a0659c1f41e96e8dae515a4dddc4aea`; the sole merge base was
`10ec34b13f56b738729a80e0e3bc4c88f5dd2897`. The merge stopped before commit for review.

Both histories independently introduced playtests 36–38. Main kept those identities and their
contents unchanged. The branch records moved with identity-only edits and attributed reference
updates: 36 → 43 (actor calibration and connected anatomy), 37 → 44 (transparent v3 pram
approval), and 38 → 45 (missing texture, directional posture, natural reach and pram quality).
The allocation reserved the union of both tips, including branch playtests 39–42. Each renamed
record was compared with its original; wording, evidence, dates and finding order were preserved.
Main's references to its separate halo and junction reports were not renumbered. Milestone and
TODO additions were also compared: the branch added an unnumbered actor queue, while main added
M93; there was no independently assigned milestone collision. Repeated milestone headings in
the archive described existing continuations, not new branch identities.

The five textual conflicts were presented with Theirs, Ours and Base excerpts. The archive kept
both sets of separate additions above their shared history. TODO retained the illustrated work,
main's M93 queue and the completed-item removals for the halo, chalk mark, bollards and circle
fix. Main's playtest histories remained in the archive; current queue references distinguish
the illustrated and gameplay sessions. The stale crowd-halo deferral in the illustrated brief
was reconciled with the player's recorded M92 instruction to include the whole crowd.

Semantic review covered the automatically merged code as well as the documents. Main's
three-argument halo setup retained event, crowd and player wiring alongside the branch's burst
input. Baby attribution, WorldContext, City, event and crowd source lists and landed-point
tracking agreed. Main's resistance sight callback reused the rotation-aware screen check and
coexisted with the branch's opt-in camera experiment. Junction paint, precinct paving, bollard
props and out-of-bounds crowd blocking retained main's contracts; applied-displacement and
recycle/reset wiring continued to feed the branch's registered actor compositors. Source PNGs,
manifests, import identities and capture schemas were preserved. The separate supersampling
worktree was not integrated, and its unresolved rendering checks remained open.

The [merged arterial capture](../evidence/archive/session-captures/2026-09-08/illustrated-main-merge.png)
used the pending merge over the recorded branch tip, `--illustrated --seed 4242 --spawn arterial
--walk south`, and a two-second screenshot delay in a 1280×720 window. Its
[whole run](../evidence/archive/session-captures/2026-09-08/rig-225618-seed4242-v0.7.0-56-g24a8505-dirty/)
records movement from tile (113,80) to (113,86), a crowd contact and a crossing. The PNG showed
loaded illustrated actors, dotted main-road crossings and incoming halos. It also confirmed
the open integration limit: a walker halo traced the offset SVG comparison, not the animated
PNG assembly. The brief, queue and handoff retain that silhouette repair as an explicit gate;
this capture did not establish natural posture, smooth animation or visual acceptance.

Verification passed the merged checkout's `./tools/check.sh`, an explicit bounded headless
illustrated gameplay boot, `./tools/test.sh halo meters hud resistance crowd generator events`,
and focused actor/capture runs. The illustrated run selected visuals, limb_attachments,
mother_attachments, presentation_mode, stroller and burst_capture; the legacy run selected
visuals, presentation_mode, stroller and burst_capture. All assertions passed. The intentional
malformed-manifest and capture-write-failure probes emitted their expected diagnostics; there
were no script errors or leak warnings. Document lint, both-parent diff checks, primary-source
comparisons and asset/manifest/import hash checks passed. The local runs were explicitly partial;
the full suite remained the PR CI gate. The PR description's actor report references were updated
to PLAYTEST-45 and its open halo-to-PNG integration limit was made explicit.

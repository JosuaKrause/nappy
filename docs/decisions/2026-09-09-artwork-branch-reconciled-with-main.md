## Artwork branch reconciled with main · 2026-09-09

The player requested `$merging-main` after the artwork was finished. The recorded branch tip is
`2392ccd8fa4f9bdbb6f8bc9ffc2968deef42fedc`, fetched main is
`14dd4d4ae53f47913833d12ff2d61123cfc5c5f6`, and their single merge base is
`c596f5dff2e539f77abc83feadd12dcb5ff3245d`. The remote artwork branch was still at
`2b1ee38c296afa7cb43e32bc06a28c18ac58a74f`; no concurrent artwork was overwritten.

The three text conflicts were reviewed as theirs, ours and base. Main completed M93, the caret
chosen by expected impact, while the artwork branch completed M64, eight seal pictures. Both
were open in the base. TODO and HANDOFF therefore remove both from the work queue; DECISIONS
keeps both separate archive records and the branch's visual-review records. No independently
numbered identities collided: main added no playtest, and PLAYTEST-50 is byte-identical to the
artwork tip. No record was combined or renumbered.

Main's source changes select carets from projected motion and share the halo's points/horizon.
The branch changes seal art, its street-axis bindings and grounding. Their source and tests merge
cleanly: stationary seals retain zero approach impact, and drawing variants do not change the
contribution, motion or lethal-geometry calculations. Crash shadows stay out of halo redraws.
The merged event documentation keeps the new cue vocabulary alongside the specific seal pictures;
its contradictory stationary-fire caret example is corrected to match the implemented selector.

Main excludes `docs/` and `tools/` from Godot and writes an exclusion into web-export output.
All remaining documentation import sidecars added on the artwork branch are removed too, while
source evidence and every asset import are preserved. Every branch asset is byte-identical to
the reviewed artwork tip. The future asset notes stay in their owning milestones and do not
close their placement, traffic, detention or objective-integration work.

The reconciled tree passes `./tools/check.sh`, `./tools/test.sh events seals danger halo`,
`./tools/lint.sh` and whitespace checks. The focused run has no failures; full-suite validation
remains the PR's CI gate. Review found no source-level semantic blocker. Historical labels in
new source comments are replaced with their descriptive archive section names.

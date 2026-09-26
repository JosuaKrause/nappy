## Updating branches from main — 2026-09-08

The player requested a dedicated skill:

> create a skill for merging main into a PR / branch. conflicts must be shown with three ways (theirs ours base) and never just do --theirs or --ours . always check semantic alignment between the branches. a clean merge can still be semantically incorrect. also, never combine unrelated playtests or todo items. renumber the one on the branch to not have duplicate numbers or worse have playtests combined that were separate before

The merging-main skill is linked from CLAUDE and the committing skill so the procedure is loaded
before a branch update. It requires explicit user-facing theirs/ours/base conflict presentations,
semantic reconciliation for every merge, and provenance-aware renumbering of the
branch's colliding records. Main's identities remain intact; unrelated playtests and TODO items
remain separate. Reference updates must distinguish which record each occurrence means, rather
than globally replacing a number. The skill does not perform a main merge merely by being created.

The player clarified: "semantic check should always happen. not only on clean merges". The
mandatory whole-result review covers clean, conflicted and manually resolved merges, including
cross-file interactions outside the conflict set; presenting three-way resolutions cannot replace it.

The player also clarified: "renumbering also applies to milestones and todos not only playtest.
anything really that is numbered and could be numbered the same in different PRs". The collision
audit covers every independently numbered namespace and its references, including nested findings
and identifiers carried in code, rather than only playtest filenames.

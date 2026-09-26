## PR merges require permission in the current session — 2026-09-12

The player asked: "make a note where appropriate to not automatically merge PRs unless
explicitly allowed in that session". Standing automatic merge authorization is overturned:
creating and pushing PRs stays authorized, but merging, enabling auto-merge and delegating
a merge require explicit permission in the current session. The committing, orchestration
and cleanup skills and the handoff carry the same boundary. No merge is authorized in this
session.

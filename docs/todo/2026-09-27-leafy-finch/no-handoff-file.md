**No PR merges with a handoff file in it** (statement 11). A handoff file may be pushed to a
branch while the PR is being made, so that agents sharing a PR can pass work on, and is removed
before the PR is done. CI fails a PR whose diff against `main` adds one, so the check is green
only once it is gone.

**Proposed, not asked for:** what counts as a handoff file — one whose name contains `handoff` in
any case, among the files the PR adds. The existing records under `docs/decisions/` with the word
in their names are not added by a new PR and are untouched by the check.

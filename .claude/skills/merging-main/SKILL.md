---
name: merging-main
description: Merge main into an existing PR or branch with explicit theirs/ours/base conflict review, mandatory semantic reconciliation for every merge, independently authored records kept distinct, and the conversion of a branch still on the old single-file queue.
---

# Merge main into a branch

Use this skill before updating a PR branch with main, and read `committing` for the repository's
git workflow. This updates the branch; merging the PR into main follows **committing** (explicit
permission in this session). Keep design and final semantic review in the orchestrating session.

## Establish the three histories

Inspect `git status`, the current branch and worktrees. Preserve unrelated local work; do not
reset it, silently stash it or mix it into the merge. If needed, use an explicitly created clean
worktree. Fetch main from the intended remote, then record the branch tip, fetched main tip and
merge base(s) before any renaming or merging. Keep those exact revisions as provenance. If a
preparation commit renames branch records, also record the prepared branch tip: that is the
merge's actual first parent and stage-2 input; retain the original tip for identity comparisons.

Read the changes on **both** sides since the common ancestor, including their docs and tests.
Use `git diff --name-status` and targeted diffs from the base to each tip, plus the relevant commit
messages. Do not inspect only files Git predicts will conflict. Read the path-matched skills
before editing affected files.

For an ordinary merge **while checked out on the PR branch**:

| Label | Meaning | Unmerged index stage |
| --- | --- | --- |
| Theirs | The incoming, recorded main tip | 3 |
| Ours | The PR branch receiving main | 2 |
| Base | The common ancestor used by Git | 1 |

These labels depend on the operation. Do not carry them into a rebase, where their apparent roles
differ. With multiple merge bases, inspect the histories and Git's synthesized stage-1 content
where available; do not choose an arbitrary base and call it authoritative.

## Preserve the identity of records before merging

Compare additions on both sides by their **content and provenance**, not just filenames, headings
or similar words. Distinct records must remain distinct: a clean textual merge can still
concatenate unrelated findings under one heading. Do not combine items to clear a conflict,
deduplicate them by name, or mark one complete because the other is.

**Old numbers are never reused, and new names need no renumbering.** A queue entry, its items,
its decision, a review item and a playtest are each a file of their own, named
`<date>-<adjective>-<animal>` by `tools/new-name.sh` (the playtest-feedback skill), so two branches
never edit the same record's file, and all but never draw the same pair of words; when two do,
`tools/lint.sh` rejects the second use and that branch draws a new name. The milestone numbers and
`PLAYTEST-NN` files that already exist keep their numbers, and no new thing takes a number.

**One case still collides: a branch from before the queue was files** that filed a new entry
`M<n>` or a new `PLAYTEST-NN.md` the old way, when `main` has a different record under the same
number. Keep `main`'s record and number intact; give the branch's record a name from
`tools/new-name.sh` instead of the next number, preserve its content, provenance and the player's
words, and update every reference that means the branch's record — never a global replacement of
the shared number, which also rewrites references to `main`'s record. A playtest's identity
changes only in its identifying label; its text is a primary source. Ambiguous references need
historical inspection; do not guess which session they mean. A persisted or externally consumed
identifier needs its consumers checked, not only a textual rename.

## Show every conflict in three ways

Merge the recorded main tip with `git merge --no-ff --no-commit` so even an automatic clean merge
waits for semantic review. Use `git diff --name-only --diff-filter=U` and `git ls-files -u` to
enumerate unresolved paths, including add/add, delete/modify and rename conflicts.

**Before resolving each conflict, show the user labeled Theirs, Ours and Base excerpts**, with the
file and enough surrounding context to explain the competing intent. Tool output alone, a list
of filenames or a statement that the versions were inspected is not the required presentation.
Then show or describe the proposed resolved behavior and why it retains the intended changes.
This is a review requirement, not an automatic permission question for an otherwise authorized merge.

For a text path still in the unmerged index, these are the actual three inputs:

```sh
git show ':3:path/to/file'   # Theirs: incoming main
git show ':2:path/to/file'   # Ours: current branch
git show ':1:path/to/file'   # Base: Git's merge ancestor
```

Use the real stage paths from `git ls-files -u` for renames. A missing stage is meaningful: show
“absent” for that side, such as the base of an add/add conflict, rather than omitting it. For binary
art, inspect and present the available versions visually, with their provenance and manifests;
do not pretend conflict markers can explain a binary conflict.

**Never resolve by `--ours` or `--theirs`.** Do not use checkout/restore side-selection shortcuts,
`-X ours`, `-X theirs`, the `ours` merge strategy, or equivalent wholesale side replacement to
silence conflicts. Author and explain the resolution from the three inputs with reviewable edits.
A justified result can match one side, but only after the other side's intent and the base are
examined and the semantic decision is explicit. Use `diff3` conflict display if helpful, but still
explain the three versions; marker removal is not reconciliation.

**A branch still on the old single-file queue** — its `docs/DECISIONS.md`, `docs/TODO.md` or
`docs/REVIEW.md` edited where `main` has them as files — is converted, never hand-merged:
`tools/convert-queue-edits.py`, run mid-merge, reads what the branch did to the three old files
since the merge base and applies it as file operations on `main`'s side (a record added becomes a
decision file, a closed entry or item deletes its folder or file, a review bullet becomes a review
file, an edit inside an entry becomes the same edit to its file), stages them, and resolves the
three files to `main`'s text. It refuses, naming every path, and changes nothing on an edit it
cannot map; show that path three ways as below. Converting does not exempt the merge from the
semantic review below.

`tools/update-pr.sh <pr-number | branch>` runs the whole mechanical sequence for an ordinary PR
update — fetch, merge, `git diff --check`/`lint.sh`/`check.sh`, commit, push — and refuses, naming
the files, the moment the merge conflicts; it never substitutes for the semantic review below,
which stays the reviewer's on every merge it produces.

## Check semantic alignment for every merge

**Semantic review is mandatory for every merge: clean, conflicted, or manually resolved.**
Three-way conflict resolution does not replace the whole-result review. Run it after resolving
conflicts as well as after an automatic merge, including interactions outside conflicted files.

Compare the pending merged tree with **each** recorded tip. For every changed area, state what
main intends, what the branch intends, and how the result satisfies both. Follow dependencies
across files: a caller can merge cleanly while its callee changes its contract elsewhere.

Check the affected relationships, rather than running an unrelated checklist:

- APIs and callers, data/manifest schemas and consumers, asset bindings and imports.
- Units, coordinate frames, defaults, flags, input bindings and lifecycle/reset behavior.
- Gameplay guarantees, ordered telemetry and determinism where those systems change.
- Tests and the behaviors they assert: passing tests can encode mutually inconsistent assumptions.
- Documentation, playtest identity, independent TODO ownership and completion state.

Keep a concise review record for each relevant interaction, including cleanly merged ones. Search
for duplicate identifiers and examine neighboring headings in the resulting documents. Distinguish
a real continuation of one playtest from two separately authored sessions; similarity alone never
authorizes combining them. If intent genuinely conflicts, preserve both requests and ask the user
the specific design question, while completing independent resolutions. Do not silently discard
one requirement because its implementation is older or on the branch labeled “theirs”.

## Verify and finish

Confirm no unresolved index entries or conflict markers remain, and review staged and unstaged
diffs against both parents. **`git diff --check` is the confirmation, not the eye**: a
diff3/zdiff3 conflict writes a fourth `|||||||` marker that survives a hand-resolution deleting
the other three.

Recheck every renamed record against its original and search for stale references; inspect the
PR description too. Preserve `.import` sidecars and source assets.

Run `./tools/check.sh` in the actual merged checkout, focused tests for the affected interactions,
`./tools/lint.sh` and `git diff --check`. Add a focused regression test when a resolved semantic
conflict exposes an uncovered behavior. Follow `verify` for visual gates; the full suite is CI's
unless one of verify's two local-run cases applies. A clean merge or green CI is evidence,
not a substitute for the semantic review.

Commit the reviewed merge and update the authorized PR. Report the three-way resolutions, any
renaming map, the conversion's plan, semantic checks, verification and any unresolved decisions.
Put historical reasoning and mappings in the branch's decision record; keep the queue limited to
open work, and leave `HANDOFF.md` to the end of the session.

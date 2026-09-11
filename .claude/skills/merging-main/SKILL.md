---
name: merging-main
description: Merge main into an existing PR or branch with explicit theirs/ours/base conflict review, mandatory semantic reconciliation for every merge, and collision-safe renumbering of all independently numbered records.
---

# Merge main into a branch

Use this skill before updating a PR branch with main, and read `committing` for the repository's
git workflow. This updates the branch; it does not authorize merging the PR into main or releasing
it. Keep design and final semantic review in the orchestrating session.

## Establish the three histories

Inspect `git status`, the current branch and worktrees. Preserve unrelated local work; do not
reset it, silently stash it or mix it into the merge. If needed, use an explicitly created clean
worktree. Fetch main from the intended remote, then record the branch tip, fetched main tip and
merge base(s) before any renumbering or merging. Keep those exact revisions as provenance. If a
preparation commit renumbers branch records, also record the prepared branch tip: that is the
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

Compare additions on both sides by their **content and provenance**, not just filenames, heading
numbers or similar words. Distinct records must remain distinct. This applies to **anything
independently numbered across PRs**: milestones, TODO items, playtests, findings, design entries,
and other numbered identities. Do not limit the collision audit to a known filename pattern.
A clean textual
merge can silently concatenate unrelated findings under one heading or reuse an identifier.

When main and the branch independently introduce the same number within an identity namespace:

1. Keep main's record and number intact. Allocate an unused number for the branch's record from
   the union of identifiers on both tips, including other branch additions. Reserve the whole
   mapping first so one rename cannot collide with another.
2. Show the mapping with a short description of each record's original subject. Rename the branch
   file or item and its identifying title; preserve its content, provenance and distinct ownership.
   For playtests, preserve the player's words, date, finding order and evidence.
   Renumbering identity is not permission to rewrite a primary source or combine two sessions.
3. Search all tracked text for links and references to the old identity before moving it. Update
   the references that mean the branch's record, including TODO, HANDOFF, DECISIONS, design docs,
   skills, tests and relevant PR text. Leave references to main's different record pointing to
   main. A global replacement of the shared number is wrong.
4. Audit every independently numbered namespace, including TODO/milestone identifiers and
   nested finding IDs: keep unrelated items separate, renumber the branch's colliding identity
   and reconcile its references. Do not combine items to clear a conflict, deduplicate them by
   number, or mark one complete because the other is. A filename, anchor, test name or code
   reference can carry the identity too. For persisted or externally consumed identifiers, inspect
   consumers and migration requirements; a bare textual rename does not establish compatibility.

Prefer a separate, reviewable branch commit for the identity changes before merging. If the
collision is discovered during the merge, preserve both original versions from the recorded tips
and resolve them into two distinct records. In either case, compare each result to its original:
only identifying labels and correctly attributed cross-references may change in a playtest.
Ambiguous references need historical/context inspection; do not guess which session they mean.

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
diffs against both parents. **`git diff --check` is the confirmation, not the eye**: the repo's
`diff3` conflict style writes a fourth marker, the `|||||||` line that opens the base section,
and a resolution that deletes the other three by hand and leaves that one behind reads as a
clean file until the next merge parses it. Four such lines reached `main` in DECISIONS.md this
way, one per merge, before a merge that ran the check found them. Recheck every renumbered record against its original and search for
stale references; inspect the PR description too. Preserve `.import` sidecars and source assets.

Run `./tools/check.sh` in the actual merged checkout, focused tests for the affected interactions,
`./tools/lint.sh` and `git diff --check`. Add a focused regression test when a resolved semantic
conflict exposes an uncovered behavior. Follow `verify` for visual gates; full-suite validation
belongs in CI unless its documented exception applies. A clean merge or green CI is evidence,
not a substitute for the semantic review.

Commit the reviewed merge and update the authorized PR. Report the three-way resolutions,
renumbering map, semantic checks, verification and any unresolved decisions. Put historical
reasoning and mappings in DECISIONS; keep HANDOFF and TODO limited to their current responsibilities.

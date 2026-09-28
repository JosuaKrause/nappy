priority: now

# leafy-finch — Issues as the inbox, and CI takes the mechanical review · filed 2026-09-27

> "the important thing is that it ends up in a safe queue in issues and I can choose when we want
> to turn those into a doc update PR"

> "what I want is a CI check that does what the reviewer currently does automatically. we should
> get as close as possible to that. the reviewer still needs to verify the correctness of those
> changes anyway. the CI is only a help"

[bouncy-heron](../../playtests/2026-09-27-bouncy-heron.md), statements 1 to 18, holds every word
of it. **The queue, the review items, the playtest files and the decision records stay in the
repository**, because an entry is reviewed when it enters the queue and a misread statement is
cheaper caught there than built (statement 1). **GitHub Issues become the player's inbox and
nothing else**: a note there is safe the moment it is written, can be edited until it is filed,
and an agent turns a batch of notes into one filing PR when the player asks (statements 5, 6).
**CI takes every check a script can make**, a doc-only PR stops waiting on the Godot suite, and
the review of a filing spends its time on faithfulness, on Sonnet (statements 7 to 12). **Every
docs-only PR and every issue write goes out as a new identity, `claude-orchestrator`**
(statement 17).

The band `now` is the filer's reading of "once that PR merges you can start implementing"
(statement 15); the player named no band.

**What this changes that is already written down.** The pr-review skill's "A queue update is
reviewed narrowly and merged first" section says the narrow review is Haiku's and that "the
semantic questions at the top of this skill are not asked of it: whether a filing states the
player's ask faithfully is the filer's job" — both change (statement 8). Its checklist stays the
reviewer's to verify, with CI running it first (statement 9). The committing skill's rule that "a
work item never merges while its queue item is unresolved", meaning the item's file deleted and
its record written, stays as it is and gains a CI check (statement 10). The **playtest-feedback**
skill's "write it down before doing anything about it" gains the inbox as the first place words
are written. `.claude/hooks/github-write-guard.sh`, the hook that denies a GitHub write outside an
agent identity (the tall-egret record, "Each agent posts on GitHub as an app of its own"), changes
for issue writes (statement 14), and the Codex adapter `tools/codex-hooks.py` and its tests change
with it if the change needs a new tool name, payload field or hook event, as `CLAUDE.md` requires.

**The PR that closes this entry writes its decision record**, which also records that Issues were
weighed as the queue itself and rejected — no review when an entry enters, edits with no reviewed
history, no path-triggered rules — and adopted as the inbox only.

**How the CI checks tell PRs apart** is by the files a PR changes, never by its title, which the
agent writes and can get wrong. A first job lists the changed files against where the branch
started (`git diff --name-only origin/main...HEAD`) and sets flags the other jobs read. The
workflow always runs: a path filter on the workflow itself would leave the `test` check that
`main`'s ruleset requires waiting forever on a PR it skipped.

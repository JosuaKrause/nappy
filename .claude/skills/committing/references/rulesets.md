# The two rulesets that guard `main`

What stands behind the gates **committing**'s "Merging" lists. Read it when a merge is blocked and
the reason is not plain, or before changing how pull requests are landed.

**The `main` ruleset requires a pull request and the `test` check, run on the merge result** — every
consistency check and every test of the game, except on a docs-only pull request, where the game's
tests are skipped and every consistency check still runs (**verify** says what each kind of pull
request gets).

**The `main approvals` ruleset requires one approving review, from a reviewer bot or the player,
and dismisses it when a commit is pushed afterwards** (inbox #1068 in gentle-walrus; `gh api
repos/JosuaKrause/nappy/rules/branches/main` shows it as `dismiss_stale_reviews_on_push`). A
reviewer bot's own APPROVE (posted as `claude-reviewer`/`codex-reviewer`, under **pr-review**)
counts the same as the player's. Repository admins (the player) may bypass the ruleset on *any* PR
they merge, not only their own. Resolving the review threads is not required: a review thread is
resolved only by whoever opened it, and that is a convention, not a gate (**pr-review** says who and
why), so an open thread never blocks an approval or a merge on its own.

So green CI alone is not the gate, and a push after an approval blocks the merge until a new
approval: auto-merge left on is safe against a later push, since it cannot merge what nobody
approved.

**Whether a merge of `main` that is Git's own** (**pr-review**'s exception, which needs no review of
new content) **keeps the approval is GitHub's to say**: where it dismisses the approval, the PR
needs a re-approval against the new head, not a review of new content, and the reviewer posts it
after the one check that `git show --remerge-diff <merge>` prints nothing. The exception is about
what is reviewed, not about whether the ruleset sees an approval.

**Neither ruleset requires a branch to be up to date with `main`**
(`strict_required_status_checks_policy` is off), so several PRs can merge in a row without
re-greening each one: an approved PR whose `test` check is green merges after `main` has moved
under it as long as the merge is still clean; a conflict still blocks it and is resolved on the
branch. **What that trades away is real**: the check ran on that branch's merge result, not on the
one it actually gets, so a semantic conflict between two PRs that touch different files passes both
gates and lands broken. Watch `main`'s own CI run after a batch rather than assuming the last green
PR spoke for it; `tools/await-merge.sh` names the run on the last merge commit once every PR has
merged, and `.github/workflows/ci.yml` never cancels a run on `main`, so every merge commit gets
one.

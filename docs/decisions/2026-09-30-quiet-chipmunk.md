# quiet-chipmunk — A cloud session's review posts under the player's account, as a comment · 2026-09-30 · not from an entry

*(2026-09-30, [feathery-egret](../playtests/2026-09-30-feathery-egret.md): "post under my account
if apps don't work here" · asked whether to write that into the skill: "you fix it".)*

**What was decided.** A review made in a Claude Code cloud session, where no agent identity can
work, posts under the player's own account through the session's GitHub tools instead of
stopping. Every comment and the summary say they were written by Claude Code, and the summary
says why the reviewer app was not used. The review's event is COMMENT, whatever the verdict.

**What it replaces.** [tall-egret](2026-09-27-tall-egret.md) recorded "Stop and tell me" for
every write when an identity is unusable, and "a cloud session still stops rather than posting
as the player". For a review in a cloud session, that no longer holds. Everywhere else it still
does: a review on the player's machine with an unusable role, and every commit, push and pull
request.

**Why COMMENT.** An APPROVE from the player's account is the player's own approval, which
satisfies the `main approvals` ruleset. So an agent would be approving on the player's behalf.
REQUEST_CHANGES from the player's account would read as the player's own objection. The verdict
is still written into the review's text, so the review is still a verdict under **pr-review**.
This event choice is the assistant's proposal, open to overturn.

**Rejected.** Widening the fallback to commits, pushes and pull requests: the player's answer was
about posting a review, and nobody asked for the rest.

**Found on the way.** `tools/new-name.sh` drew `teal-marmot` for this record although a playtest
already had that name. Its uniqueness check piped the folder listing into `grep -q` under `set -o
pipefail`. `grep -q` exits at its first match, the listing dies of SIGPIPE, and the pipeline's
status 141 read as "not taken". Whether a used pair was caught depended on where it fell in
the listing and on timing: a measurement on `main` caught `teal-marmot` in 2 of 10 tries and the
first name in the listing in none of 5, so the lint's duplicate-name check was the real guard.
The check now reads the whole listing (`grep` into `/dev/null`).

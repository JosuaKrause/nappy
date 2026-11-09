---
name: committing
description: The git workflow for this repo — one branch per work item, one commit per queue item, what a commit message must explain, what a PR files in the queue and the records, when to merge and delete, and how a release is cut. Load this BEFORE committing, branching, merging, cutting a release or writing a commit message.
---

# Git workflow

**Manage local branches and commits autonomously.** The rules nobody may miss, one line each; the
sections below hold the detail and the reasons.

- **Every GitHub write goes out as an agent identity**, as `uv run python tools/agent-identity.py
  run <role> -- <command>`: `claude-coder` on a pull request that changes code,
  `claude-orchestrator` on a docs-only one and for every issue write, `claude-reviewer` for a
  review. A write the guard denies is a stop, never tried another way.
- **Text handed to a write goes through a file in a fresh directory**, in three calls.
- **One branch per work item, named `feature-<thing>`**, pushed and with its pull request before
  the session ends.
- **A pull request carries its queue move, its record and every doc it makes false** before it
  merges.
- **A pull request merges only after a review posted *ready* against its head**, with one approval
  and a green `test`. Merging is the orchestrating session's: squashed, by auto-merge, confirmed
  at no cost in tokens, by a timer or by `tools/await-merge.sh` in the background.
- **A merged branch is retired at once** with the wrapped `tools/prune-merged.sh` line.
- **A picture in a description is linked by commit hash and embedded as an image.**
- **A release needs the player's own go-ahead in the current session.**
- **Before committing, run verify's checks**, and `./tools/lint.sh` for a governed doc.

## Who a commit and a pull request are from

**Every GitHub write goes out as an agent identity, and only that identity — never as the player on
an agent's own say-so** (tall-egret). The one exception is a write the player approves themself at
the guard's prompt, below.

**Which identity a write goes out as follows what the write does, not which session makes it**
(bouncy-heron 17). In Claude Code:

- **`claude-orchestrator`** makes every issue write — capturing a note into the inbox with its
  labels, asking a question on one, closing a filed batch and reopening it, each through
  `tools/inbox.py` (**inbox**), never a direct `gh issue` or `gh api` command; the script changes
  no label on a note once it is open, and a label to change is asked about on the note instead —
  and every write on a pull request with no code changes: its commits, its push, the pull request
  itself, its comments, merging `main` into it, its merge under the standing permission
  ("Merging"), and retiring its branch.
- **`claude-coder`** makes every write on a pull request that changes code — a queue move or a
  decision record committed inside it included, merging `main` into it, fixing its CI, its merge
  and retiring its branch — and cuts a release. The orchestrator identity never writes on such a
  pull request.
- **`claude-reviewer`** posts every review and its findings, on either kind of pull request
  (**pr-review**), and **is the only Claude Code identity that approves one** (busy-ibis 9): GitHub
  stops only a pull request's own author from approving it, so without the rule the coder and the
  orchestrator could approve each other's pull requests toward the approval `main` requires. A
  COMMENT or REQUEST_CHANGES review stays open to every identity.

A pull request has no code changes when CI calls it docs-only: `tools/ci_classify.py` decides that
from the files it changes, and **verify**'s "What `test` means on each kind of pull request" says
which files those are. The identity is chosen when the pull request is opened, from what it is going
to contain. So the orchestrating session writes as `claude-coder` when it merges a code pull
request, and a spawned agent writes as `claude-orchestrator` when it opens a docs-only one. **It is
a convention, not a hard rule** (bouncy-heron 18): a pull request that starts docs-only and later
gains code keeps the orchestrator's earlier writes and takes the coder's from then on, and nothing —
no hook, no CI check — compares a pull request's authors with what it contains. Codex has no
orchestrator identity: its issue writes and its docs-only pull requests stay `codex-coder`'s, and
its reviews `codex-reviewer`'s.

**The wrapper.** `uv run python tools/agent-identity.py status <role>` says whether the role is
usable; every command that **writes** to GitHub for that piece of work — a commit, a push, a `gh`
post — then runs as `uv run python tools/agent-identity.py run <role> -- <command>`, so the commit,
the push and the pull request all show as `<role>[bot]` and not as the player talking to themself.
An issue write is the one exception: it runs through `tools/inbox.py`, which takes the role from
`--role` or `NAPPY_AGENT_ROLE` and wraps each of its own writes itself. A read (`git status`, `gh pr
view`, ...) runs unwrapped; minting a token for one is wasted work. **Inside an agent worktree,
Claude Code's permission check can refuse the `uv run` form; the same wrapper run by the worktree's
own interpreter, `.venv/bin/python tools/agent-identity.py run <role> -- <command>`, is the
fallback** (round-moose 3): the same script, token and identity, which the guard accepts as
wrapped, in a `.venv` that `uv sync` makes. **When `status` reports the role not usable** (not
created yet, not installed on the repository, or a cloud session) **or the fallback is refused too,
the session stops and reports; it never runs the write bare under the player's account.**

**The guard.** `.claude/hooks/github-write-guard.sh`, a `PreToolUse` hook on every shell call,
denies a GitHub write that is not wrapped in `run <role> --`, so the rule holds when a session
forgets it; its header comment holds the exact, current list of what counts as a write, and its
denial names the way out. What a session needs beyond that:

- **A denial is a stop.** The session tells the player and tries no other command shape, and Codex
  stops on every one of them. The one exception is a direct `gh issue` write, denied wrapped or
  not, which is made again through `tools/inbox.py`: the player wants an agent's issue writes to go
  through a script (bouncy-heron 14), and the script never writes as the player, so where no
  identity can work an issue write is not made at all.
- **An approving review is denied under every identity but a reviewer's**, and a review whose event
  the guard cannot read counts as one. So a coder's or the orchestrator's review names its event
  inline (`-f event=COMMENT`, `gh pr review --comment`) and sends its body from a file.
- **Where no identity can work at all** (a Claude Code cloud session, a machine with no identity
  directory) **the guard can ask the player about one ordinary write at a time instead of denying
  it** (frosty-pelican): a local commit, a push of a branch, a pull-request write. A tag push, a
  merge, a release and an issue write are never asked about, only denied. **The asking is off
  unless the player switches it on** with `NAPPY_ASK_FOR_PLAYER_WRITES=1` in the environment a
  session starts with (frosty-pelican); a session never sets or clears it for itself.
  `references/write-guard.md` has the whole list of what is asked and what is denied.
- **An admin action no bot identity can perform** — changing a repository ruleset, a GitHub App's
  own permissions — **is the player's to do directly, in GitHub's own settings, never something to
  wrap and retry.**

**The commit still carries the session's own attribution trailer.** `run` changes who git says
authored and committed the change (the bot's name and noreply address), not what the message says:
the `Co-Authored-By` line the session's own instructions ask for is added as always.

## Text handed to a write goes through a file

**A commit message, a pull request's body, a review, a comment, a note for the inbox: each is
written to a file in a directory made for it, and the file is passed by name.** Never a fixed name
such as `/tmp/pr_body.md`: `/tmp` outlives a session, so a fixed name can already hold another
run's text, and a write of one's own that did not land then publishes theirs. Three calls, each a
command of its own:

1. `mktemp -d`, which prints the new directory.
2. `cat > <that literal path>/<name> <<'EOF'`, the text, `EOF`, and nothing else in the command:
   the path pasted as printed, no variable, no quotes around it, no second command.
3. The write, passing the file: `git commit -F <file>`, `gh pr create --body-file <file>`, `gh api
   -F body=@<file>` (capital `-F`; lowercase `-f` sends the literal text `@<file>`),
   `tools/inbox.py capture --body-file <file>`. Read the file back before passing it on.

The second call stands alone because of the guard: **a write's words in text deny like a call** —
in an echo, a commit message, a body, a heredoc — **except in three shapes, each the whole command
and nothing else in it** (plaid-tapir 4):

- `cat > FILE <<'EOF'` (or `cat <<'EOF' > FILE`, `>>`), the delimiter quoted, whose body is text;
- a coder's or the orchestrator's wrapped `git commit -F - <<'EOF'`, whose body is text and which
  is judged as the wrapped commit;
- `rg` or `grep` with one quoted pattern, plain options and paths, whose pattern is text.

Anything else — `d=$(mktemp -d)` or `mkdir -p … &&` in front, a second command after the body, an
unquoted delimiter, `<<-`, a `$` in a double-quoted pattern, a pipe — is read as the guard reads
every command, and a body that names a write then denies.

## Pushing

**Always push branch work and create or update its pull request before ending the session**
(woolly-finch 12). Work is not left only on a local branch, nor a remote work branch without a pull
request, unless there is a specific good reason, documented in the final report. The pull request's
link goes in the final report, always. This is standing authorization; no separate request to push
or open it is needed.

**Finished work opens a ready pull request, never a draft**: it carries the completed work and its
verification (see "Before committing"). **A draft is for unfinished work only**, pushed so that it
is not lost, with its failing or outstanding checks stated in it; backing work up does not claim it
is ready to merge. Unfinished work stays out of `main`, which is the tree a fresh clone receives.

## Merging

**The orchestrating Claude Code session holds the player's standing permission to merge a PR**
(`CLAUDE.md`, inbox #1063 in gentle-walrus), once the gates below hold. Merging includes enabling
auto-merge, merging by hand, and asking an agent or monitor to merge. Every other session (an
implementation agent, a Codex session) merges only a PR the orchestrating session hands it, an agent
or monitor running its merge (`tools/land-prs.sh` for one) under the orchestrating session's
standing permission (inbox #1063 in gentle-walrus), or one the player authorizes in that session; a
permission given in another session does not carry over to it. A review agent never merges
(**pr-review**). Finishing implementation, opening a PR and green CI do not by themselves make a PR
mergeable. Leave the PR open and report its link when the session has no permission to merge it.

**A standing permission reaches Claude Code's auto-mode classifier reliably only through the
player's own Claude Code settings** (`~/.claude/settings.json`: `permissions.allow` rules for a
command, `autoMode.environment` or `autoMode.allow` lines for anything else; a reviewer spawn only
by an `autoMode` line, since auto mode drops `Agent` allow rules). The classifier reads `CLAUDE.md`
and still refuses writes its standing permission covers when the player's settings do not carry it,
so `CLAUDE.md` and the skills are not relied on as the player's consent. The
player's own approval of one action (their next message, or the `/permissions` recently-blocked
list) is a different thing and is fine. When the classifier refuses a write the standing permission
covers, report the refusal to the player naming their settings; never work around it: no other
command shape, no `gh api` substitute, no player-write prompt, no allow rule added to the
repository's own settings files, to get the same write through.

**A PR merges only after its review**
(how-the-spent-park-was-rebuilt-against-the-players-words-and-the-review-rules-it). A review under
**pr-review** has posted the verdict *ready* on the PR against its current head, or against a head
whose later pushes were reviewed too; a merge of `main` whose result is Git's own needs no second
review (**pr-review**). The standing permission and green CI do not replace it.

**Two rulesets guard `main`**, and `references/rulesets.md` explains them once. What they come to:

- **A merge needs a green `test` check and one approving review**, from a reviewer bot or the
  player; green CI alone is not the gate.
- **A push after an approval dismisses it** (inbox #1068 in gentle-walrus), so auto-merge left on
  cannot merge what nobody approved. A merge of `main` that is Git's own may lose the approval too,
  and then needs a re-approval, not a review of new content.
- **An open review thread blocks nothing**: resolving one is a convention, not a gate
  (**pr-review**).
- **No branch has to be up to date with `main`**, so an approved, green PR merges after `main` has
  moved under it while the merge is clean. Two PRs that are wrong only together pass both gates:
  `main`'s own CI run on the last merge commit of a batch is the check for that.

**PRs land without waiting for each other or for `main`'s CI, and when `main` breaks after a
merge, a fix for it is landed on `main`** (freckled-moose #914). Nothing requires landing one at a
time; the player asks for tests that are isolated and not flaky instead.

**How a merge goes**, once the review is ready:

1. Check mergeability. A conflict is resolved on the PR's branch under **merging-main**, and the
   resolution is reviewed under **pr-review** before anything merges.
2. **Squash-merge, by auto-merge** (inbox #1068 in gentle-walrus): `gh pr merge <n> --squash --auto`,
   or `tools/land-prs.sh <n>...`, which does that for a list and merges directly a PR GitHub
   already calls clean. It handles every PR it is given as the one role it runs under, so docs-only
   PRs go in a call under `run claude-orchestrator --` and code PRs in one under `run claude-coder
   --`. Then move on: **no polling monitor and no background wait just to trigger the merge**
   (inbox #1068 in gentle-walrus), since GitHub merges the PR when its checks are green and its
   approval is in.
3. **Confirm that it went through, by a timer or a script, the orchestrator's choice, as long as
   neither the wait nor reading its result costs tokens** (inbox #1072 in gentle-walrus). The wait
   is sized to what is left of the PR's CI, undershot a little, and the tail is polled by a script,
   not an agent (inbox #1070 in gentle-walrus). `tools/await-merge.sh <the PRs>`, run right after
   step 2 with the Bash tool's `run_in_background`, does both and re-invokes the session when it
   exits; its output is short because reading it costs tokens. One call confirms a whole batch. No
   agent holds the wait.
4. **Act on what the check shows.** A PR that shows MERGED is retired ("Branches"; the main checkout
   pulls `main` first). A red check or a conflict it names is fixed on the branch (a conflict
   under **merging-main**) and the fix reviewed under **pr-review**: the push dismisses the approval, so auto-merge left on waits for the new one and
   cannot land the fix unseen, and `tools/land-prs.sh` turns auto-merge off on a stop so that the
   new approval does not fire a merge before it is chosen. A PR with auto-merge off or not approved
   is reported at once. One still unmerged when the script's cap runs out is the orchestrator's to
   look at, not to loop on.
5. **Watch `main`'s CI run on the last merge commit**, which the script prints once every PR has
   merged.

## Releasing

**A push is a check and a tag is a release**: `https://nappy.josuakrause.com/` serves whatever the
newest `v*` tag points at, so **a fix on `main` is not a fix on the site**. **Publishing needs its
own go-ahead from the player in the current session**; the standing merge permission is not release
permission. A release is cut with `tools/release.sh <major|minor|patch>`, which prints its plan and
acts only with a trailing `push`; an agent runs that form as `uv run python tools/agent-identity.py
run claude-coder -- tools/release.sh <part> push`. `major` is reserved for a change that breaks or
fundamentally alters the game. `references/releasing.md` holds what CI and the deploy check, how
the notes are generated, what the script refuses and why a browser fetches a release whole: read it
before cutting a release or answering whether a commit is live.

## The squash commit is the pull request's title and description

**Every pull request reaches `main` as one squashed commit whose message is the PR's title and
description**; the repository's squash defaults (pull-requests-are-squash-merged) are set to exactly
that. So `git log` and `git blame` on `main` show one reviewed text per work item, and a branch's
own commits — the WIP ones and the merges of `main` among them — are scratch that never lands.

**Re-read the description immediately before merging, because it is about to become permanent.**
It says what the PR carries as it now stands, the verification with its outcomes, and every
choice left open to overturn; a description written when the PR opened and not since is a
commit message about a different diff. Nothing may live only in a branch commit message: the
reasoning a later reader needs is in the decision record, and the description summarises it.

## A pull request is self-contained

**A pull request is a completed work item, and a broken one is fixed on its own branch, never by a
second PR** (woolly-finch 20). When review, a playtest or the player finds that a PR built the wrong
thing or built it wrong, the correction is committed on that PR's branch and the PR's description is
updated to say what it now carries. A follow-up PR for the fix would either merge the broken work
first or leave two PRs that only make sense together, and neither is a completed item.

**And the unit is the work item, not the queue entry** (woolly-finch 21). One question splits into
several queue entries as it is worked — a probe, the thing the probe found, the fix for it — and
each entry is still the same item until the player has what they asked for. The fix for what a PR's
probe found goes on that PR, whatever name or number the queue gave it; a new PR is for a new
question.

**A pull request carries every consequence of its own changes, documents first** (minty-lemur #763).
Not a follow-up, not a cleanup pass afterwards, not a note for the next session, and not left for
whoever later merges `main` into another branch: the edit is part of the change and lands in the
same PR. A doc the change makes false is the commonest case, but a picture it makes stale, a test it
makes wrong and the text of another open PR it makes untrue (a sentence, a strip picture, a side
view) are fixed the same way, by the change that made them; the reconciliation when `main` is
merged into the other PR is not where the omission is meant to be found. That covers the queue — the entry's
folder under `docs/todo/`, which goes stale fastest because it holds the work the PR just did — and
every other governed doc the change touches: `CITY`, `EVENTS`, `MECHANICS`, `TELEMETRY`,
`ARCHITECTURE`, `NARRATIVE`, `README`, `CLAUDE.md`, the skills, and the docstrings on anything
edited.

**A PR that finishes an item deletes the item's file and files what it built as a decision**,
`docs/decisions/<entry name>.md`, made with `tools/new-name.sh decision --entry <name> "<title>"`,
which names a further record of an entry `<entry name>-<adjective>-<animal>`, never `-2` (inbox #937
in plaid-penguin, inbox #941 in breezy-alpaca). **When that was the entry's last item, the entry's
folder goes in the same PR, after the record is drawn** (`new-name.sh --entry` finds the entry by
its folder, so a record drawn once the folder is deleted fails), because the queue holds open work
only and the entry stops being open the moment the PR merges. Another entry's `after:` line naming
it stays as it is: the record is what makes the wait count as over (`tools/queue.sh` prints it as
`<name>, closed`, and the lint accepts it), so closing an entry never edits a second one, and the
end-of-session pass (**session-cleanup**) deletes the line.

**The queue's order is each entry's band line**, the first lines of its `README.md`
(`priority: bug|now|next|later|parked`, then any `after:` lines), and `tools/queue.sh` prints it.
Setting or moving a band is the orchestrator's (**orchestrating**) and edits that one file, so it
meets another PR only when both change the same entry; there is no shared order list for a PR to
edit.

**Why:** a PR is reviewed once, against a tree where the reason for each doc edit is visible in the
same diff. Deferred, the reason is gone and only somebody who already knows what changed can tell
which sentence went stale — which is nobody, a week later. Several PRs merged in a row each leaving
their own doc debt is how three files come to carry three different answers to one question, and
the pass that untangles it is a milestone rather than a review comment.

**The test is the same one the docs rule uses:** if `main` at the squashed commit would hand a fresh
reader a sentence that is no longer true, or a picture, a test or another PR's text that no longer
matches what the change did, the PR is not finished. Read the entry's own folder before proposing,
not after.

**And every doc the change owes is in the PR before it merges. This is a hard requirement**
(woolly-finch 13). The entry's files, the decision record, the review item and every other doc the
change touches are committed on the branch by the time the merge button is pressed. Pushing them
onto an open PR is fine; filing them in the next PR, or in a cleanup afterwards, is not — once the
squashed commit exists, `main` has handed every reader a false sentence until something else lands.
Before merging, re-read the branch's own diff against the list above and ask what it left stale.

**A work item never merges while its queue item is unresolved** (woolly-finch 14). Resolved means
the item's file is gone from its entry's folder and its record — what was built, the measurement,
the rejected options — is filed under `docs/decisions/`, both on the branch. A PR whose own item
still sits open in the queue is not finished, however green its checks are; if the item is only
partly built, the PR either finishes it or rewrites the item's file on the branch to hold exactly
what is still open, with the built half filed as a decision. CI holds a pull request that changes
`src/` or `tests/` to this (`tools/ci_code_pr_queue.py`, which also accepts a description line `No
queue item: <reason>`).

**And work that only a person can judge adds its review item in the same PR**: a file
`docs/review/<entry name>.md`, made with `tools/new-name.sh review --entry <name> "<title>"`, which
names a second item from the same entry `<entry name>-<adjective>-<animal>`, never a number
(woolly-finch 18, inbox #941 in breezy-alpaca). The item says what to do, where to look, and the
question a run answers, its steps written as prose and not numbered; the record of what was built
stays in the decision. The review items are the list a playtest is asked against, so an item missing
from them is an item no run will ever be asked to look at.

The **session-cleanup** skill still runs at the end of a session: it catches drift that no single
change is responsible for, reassesses long-open items and re-reads the numbers. It is not where a
PR's own doc work goes.

## A PR description never links a file by branch name

**An image or file in a PR description is linked by commit hash, never by branch**
(tooling-audit-python-3-14-ruff-mypy-and-links-that-outlive-a-branch). A URL of the shape
`.../blob/feature-<thing>/docs/evidence/x.png?raw=true` or
`raw.githubusercontent.com/<owner>/<repo>/feature-<thing>/...` works while the branch exists and
returns a 404 the moment the branch is deleted — and this workflow deletes every branch as soon as
it is merged. The description is the one place the before-and-after pictures live once the PR is
closed, so a dead link there is the evidence gone.

Link the commit instead, and **embed a picture with image syntax, never as a bare URL**
(woolly-finch 28):

```
![what the picture shows](https://raw.githubusercontent.com/<owner>/<repo>/<full-commit-sha>/docs/evidence/x.png)
```

GitHub renders a bare URL in a description as a link, so the player has to open every picture to see
it, which is exactly what a visual review is meant to spare them.

**A pull request that went through several visual passes opens with the current proposal**, its
pictures embedded, and lists the superseded passes last as plain links (woolly-finch 29). A
description that grows a section per pass reads as a history, and the reviewer has to work out which
picture is the one being asked about.

A branch commit's URL survives both the squash and the branch's deletion
(pull-requests-are-squash-merged) because GitHub keeps every pull request's commits reachable under
`refs/pull/<n>/head`. **The hash has to be the one the file was committed in or a later commit on
the branch**, so write the description after the evidence commit exists — `git rev-parse HEAD` — and
if the evidence is amended, update the link.

GitHub-hosted attachments are an alternative to committed media; `references/attachments.md` says
which routes work for the bots' tokens, and is read before relying on one.

## Reviewing a pull request

**Every pull request is reviewed adversarially before it is ready to merge**, and the findings go
on the PR as comments. How is the **pr-review** skill's.

## Branches

**Before merging main into an existing PR or branch, read
[merging-main](../merging-main/SKILL.md).** It requires showing theirs, ours and base for each
conflict, reviewing semantic alignment for every merge (clean or conflicted), and keeping
independently authored records distinct. Side-selection shortcuts such as `--ours` and `--theirs`
do not satisfy that review.

**One branch per work item** (which may span several queue entries), named `feature-<thing>`;
`main` receives it as one squashed commit.

**Delete a branch as soon as its pull request is merged, always, without being asked.** The
squashed commit is what the project keeps; the branch pointer is scaffolding. Left alone they
accumulate one per work item, and the cost is not clutter — it is that `git branch` stops being
able to answer the only question it is good for: **is there work that is not on `main`?**

**Git cannot see a squash as a merge, so the PR's state is the check, not `git branch -d`**, which
refuses every squash-merged branch and so says nothing. **`tools/prune-merged.sh <branch>...` is
that check, executable, and the way a merged branch is retired**: GitHub must confirm MERGED and
git must prove the local tip equals or is an ancestor of the merged head (a different tip alone
does not prove unpushed work; a stale ancestor contains no work outside that PR). It then deletes
the remote with an exact-tip lease, removes the clean worktree without force, deletes the local ref
and the agent's released brief, and a failed stage keeps what is left and reports it. Its `--help`
lists what keeps a branch (an open PR, unpushed or dirty work, a lock, an unreleased brief) and its
read-only modes. A brief is released by its owner, with `cleanup: ready` in its header, only after
the agent has stopped and its useful ignored artifacts are kept (**orchestrating**).

**Run it from the main checkout, as the pull request's own identity**: `uv run python
tools/agent-identity.py run claude-coder -- tools/prune-merged.sh <branch>...` for a pull request
that changed code and `uv run python tools/agent-identity.py run claude-orchestrator --
tools/prune-merged.sh <branch>...` for a docs-only one (Codex runs the same line as `codex-coder`
for both). Its remote delete is a write, so the guard denies the script bare in every shape, the
read-only `--all` inventory and `--dry-run` included. **Use it, never the bare commands**: Claude
Code's auto-mode classifier refuses `git worktree remove` and `git branch -D` as destructive
however the check came out, and `.claude/settings.json` allows the wrapped line for each of the two
roles, because the script cannot delete anything the check did not clear. The allow rules are a
prefix match on the command's text, so the line has to be spelled as above: `./tools/…`, another
role, or anything else in front of `tools/prune-merged.sh` is not covered and goes to the
classifier. There is no `codex-coder` rule: Codex does not read that file (its approvals are its
own sandbox's), and Claude Code never runs as `codex-coder`. **A review agent's detached checkout
has no branch for the script to take, and is removed with `tools/agent-setup.sh --remove <name>`.**

**A PR stacked on another is retargeted to `main` before its base branch goes.** The repository
deletes a merged head branch on GitHub by itself; for a branch deleted by hand (`git push
--delete`, or `--delete-branch` on the merge), run `gh pr edit <upper> --base main` first, since
GitHub closes a pull request whose base branch is deleted. Either way, the upper branch still
carries the lower one's original commits after the squash, so merge `main` into it under the
**merging-main** skill before it is reviewed again; its diff against `main` is then its own work
only.

## Commits

**One commit per queue item, inside that one branch.** A milestone is a list of things that were
decided separately and are each true or false on their own, so each one gets a commit a reviewer
can read by itself on the pull request. The commits are for the review and for the branch while it
is open: `main` receives the squash, so nothing on `main` is reverted or bisected finer than a pull
request, and an item that must be revertible alone is a pull request of its own.

**But a branch is yours, and a messy commit inside one is fine** (woolly-finch 2). `main`'s ruleset
means nothing lands except through a pull request with the `test` check green on the merge result,
so **the branch cannot hurt anybody** — the thing that has to be clean is what reaches `main`, and
the squashed commit is what the project keeps. A half-finished item, a commit that does not build, a
"wip" while you go and check something, several small commits where the rule above wants one: all
fine, none of it needs asking about.

So read the one-per-item rule as **what the branch should look like by the time it is proposed**,
not as a gate on each `git commit`. Tidy at the end if it is worth tidying; an interactive rebase is
not available in this environment, so in practice that means writing the good message on the commit
that finishes an item rather than reshaping history afterwards.

**Commit before stopping, and prefer a scruffy commit to a dirty tree.** Uncommitted work is the only
state that can actually be lost. An unfinished milestone is a branch with commits on it — say in the
message that an item is incomplete and where you stopped, and move on.

**And that includes a session that only writes docs.** A long design conversation produces the most
valuable and least recoverable thing in this repo — a brief in the player's own words, and the
reasoning around it — and it is exactly the work that feels too unfinished to commit, because the
design is still moving. **Commit each piece as it is settled.** A decision that is only in the
working tree is a decision that is only in the session.

**Commit the docs in the same commit as the code.** `docs/` is not a report written afterwards, it
is the design. If an implementation contradicts a doc, **the doc is wrong and gets fixed in that
commit.**

## Commit messages

**Explain why, and say what was tried and rejected.** When something was discovered
mid-implementation — "the first version parked every route against the city wall" — say so. That is
the part that is **not recoverable from the diff**, which is the whole test for whether a sentence
belongs in a commit message.

**And it is never the only place that sentence is written.** A branch commit message does not
reach `main`; what it says that matters later is also in the decision record, and in the PR
description that becomes the squashed commit.

A message that restates the diff is worth nothing; the diff is right there.

## Before committing

Run the verification loop — see the **verify** skill, which owns it: `./tools/check.sh`, the
suites your change touches, and a screenshot if you touched anything visual. The full suite is CI's
on the pull request, not a local gate.

Run `./tools/lint.sh` too if the commit touches a governed doc (`CLAUDE.md`, a skill, `README.md`,
a top-level `docs/*.md` besides `DECISIONS.md`, a queue file under `docs/todo/` or a review item),
or files anything under a new name. A hit is a stop:
fix the sentence or commit nothing. And `./tools/pycheck.sh` if it touches `tools/*.py`,
`pyproject.toml` or `uv.lock` — see the **python-tooling** skill.

## Never commit

- **`.godot/`.** It is gitignored, which means a fresh clone has no `class_name` registry and every
  typed reference fails to parse until `check.sh` runs the import pass.
- **A doc that contradicts the code it ships with.**

## Proposed, not asked for

The rules in this file that are the filer's proposal or reading, not the player's words, each open
to the player's correction:

- **What is done when the classifier refuses a write the standing permission covers** ("Merging":
  report it naming the player's settings, never work around it). The player asked only for the
  standing permission in their own settings (curly-rabbit #1094).
- **The numbers `tools/await-merge.sh` waits by**, which its `--help` gives: how the end of CI is
  estimated, the undershoot, the time between polls and the cap. The player asked for a better
  estimate, undershot a little, with the rest polled by a script (inbox #1070 in gentle-walrus).
- **Why a further record of an entry is named with a pair of words and never `-2`**: read as, two
  branches building at once draw the same next number. That is the filer's reading of the player's
  remark that the reason is known (inbox #937 in plaid-penguin, inbox #941 in breezy-alpaca).

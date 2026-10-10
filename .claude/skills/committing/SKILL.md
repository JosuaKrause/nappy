---
name: committing
description: The git workflow for this repo — one branch per work item, one commit per queue item, what a commit message must explain, what a PR files in the queue and the records, when to merge and delete, and how a release is cut. Load this BEFORE committing, branching, merging, cutting a release or writing a commit message.
---

# Git workflow

**Manage local branches and commits autonomously. Merging a PR requires explicit permission in
the current session** — see "Merging".

## Who a commit and a pull request are from

**Every GitHub write goes out as an agent identity, and only that identity — never as the player
on an agent's own say-so.** The one exception is a write the player approves themself at the
guard's prompt, below.
*(2026-09-26, once the first four identities existed: "I want to make it mandatory for each agent
to use their respective identity when interacting with github", enforced on writes; asked what an
agent does when its identity is unusable, the player chose "Stop and tell me" — it never posts as
the player on its own say-so instead.)*

**Which identity a write goes out as follows what the write does, not which session makes it.**
*(2026-09-27: "orchestrator/coder session and orchestrator/coder identity are not the same thing.
for the purposes of github what matters is what they do. that is independent who actually
triggered it".)* In Claude Code:

- **`claude-orchestrator`** makes every issue write — capturing a note into the inbox with its
  labels, asking a question on one, closing a filed batch and reopening it, each through
  `tools/inbox.py` (**inbox**), never a direct `gh issue` or `gh api` command; the script changes
  no label on a note once it is open, and a label to change is asked about on the note instead —
  and every write on a pull request
  with no code changes: its commits, its push, the pull request itself, its comments, merging
  `main` into it, its merge once the player has said go, and retiring its branch.
- **`claude-coder`** makes every write on a pull request that changes code — a queue move or a
  decision record committed inside it included, merging `main` into it, fixing its CI, its merge
  and retiring its branch — and cuts a release. The orchestrator identity never writes on such a
  pull request.
- **`claude-reviewer`** posts every review and its findings, on either kind of pull request
  (**pr-review**).

A pull request has no code changes when CI calls it docs-only: `tools/ci_classify.py` decides that
from the files it changes, and **verify**'s "What `test` means on each kind of pull request" says
which files those are. The identity is chosen when the pull request is opened, from what it is
going to contain. So the orchestrating session writes as `claude-coder` when it merges a code pull
request, and a spawned agent writes as `claude-orchestrator` when it opens a docs-only one. **It
is a convention, not a hard rule**
*(2026-09-27: "if a PR starts out as doc only and later code becomes part of it then identities
will mix")*: a pull request that starts docs-only and later gains code keeps the orchestrator's
earlier writes and takes the coder's from then on, and nothing — no hook, no CI check — compares a
pull request's authors with what it contains. Codex has no orchestrator identity: its issue writes
and its docs-only pull requests stay `codex-coder`'s, and its reviews `codex-reviewer`'s.

`uv run python tools/agent-identity.py status <role>` (**using-tools**) says whether the role is
usable; every command that **writes** to GitHub for that piece of work — a commit, a push, a `gh`
post — then runs through `uv run python tools/agent-identity.py run <role> -- <command>` instead of
running it directly, so the commit, the push and the pull request all show as `<role>[bot]` rather
than as the player talking to themself. An issue write is the one exception: it runs through
`tools/inbox.py`, which takes the role from `--role` or `NAPPY_AGENT_ROLE` and runs each of its own
writes through that wrapper itself, and never as a wrapped `gh issue` command. A read (`git
status`, `gh pr view`, ...) runs unwrapped; minting a token for one is wasted work the player
never asked for. **When `status` reports the
role not usable (not created yet, not installed on the repository, or a cloud session — see
`tools/agent-identity.py`'s own module docstring), the session never runs the write under the
player's own account on its own say-so.** Where no identity can work at all — a Claude Code cloud
session, or a machine with no identity directory — the guard below can ask the player about an
ordinary write instead of denying it: a local commit or history step (`git commit`, `merge`,
`rebase`, `pull`, `cherry-pick`, `revert`, `am`), a push of a branch, or a pull-request write
(`gh pr create`, `comment`, `edit`, `ready`) goes to them as a permission prompt for that one
command, which only they can approve *(2026-10-02: "Let's do A and make the codex version always
refuse")*. Every other write is never asked about, only denied — among them a push of a tag, of
every branch or of a `*` pattern (a pushed `v*` tag publishes the site), a push naming a shell
expansion (`"$TAG"` can be a `v*` tag) or one the guard cannot read to its end, a forced,
deleting, mirroring or pruning push, a pull request's merge, a release and a `gh issue` write —
since a prompt is too easy to click through for any of them, and for the last because the player
wants an agent's issue writes to go through a script rather than a direct `gh issue` command
*(2026-09-27: "if it goes through a script it's safe we just need to get it working once -- an
agent shouldn't use gh issue directly")*; that script, `tools/inbox.py`, never writes as the
player, so where no identity can work an issue write is not made at all. **That asking is
off unless the player switches it on** with `NAPPY_ASK_FOR_PLAYER_WRITES=1` in the environment a
session starts with (a cloud environment's own variables, or the launching shell); unset, every
unwrapped write is denied *(2026-10-02: "Make it so it can be easily turned off and refuse again later";
"Yes default to refusing")*. A session never sets or clears it for itself. Anything the guard
denies the session stops on and tells the player about, and Codex stops on every one of them —
except a direct `gh issue` write, which is made again through `tools/inbox.py` instead. A
`PreToolUse` Bash hook (`.claude/hooks/github-write-guard.sh`) makes this mechanical: it denies a
`git push`, a commit-making git verb, a GitHub-writing `gh` call, or one of the `tools/` scripts
that pushes or posts internally, in command position, unless the same command is wrapped in `run
<role> --`, so the rule holds even when a session forgets it. **A `gh issue` write it denies
wrapped or not, and an issue write through `gh api` the same way** (all but a comment, which a
pull request's own conversation shares), since an agent writes an issue only through
`tools/inbox.py`, whose own writes run in a process of their own that the hook never sees. A
write named in a commit message or a PR body denies like the write itself, so a message is
written to a file and passed with `-F file` or `--body-file file`, or given to a wrapped `git
commit -F - <<'EOF'` that is the whole command, one of the three shapes whose text the hook
reads as text (**using-tools** lists them). A read stays unguarded — the hook's
own header comment carries the current, exact list, rather than a second copy of it here that can
drift from it. **An admin action no bot identity can perform** — changing a repository ruleset, a
GitHub App's own permissions — **is the player's to do directly, in GitHub's own settings, never
something to wrap and retry.**

**Inside an isolated agent worktree, Claude Code's permission check can refuse the `uv run`
form of the wrapper; the same wrapper run by the worktree's own interpreter,
`.venv/bin/python tools/agent-identity.py run <role> -- <command>`, is the fallback.**
*(2026-09-27: "Yes document the fallback".)* It is the same script with the same token and the
same identity, and `github-write-guard.sh` accepts it as wrapped. A worktree with no `.venv` yet
gets one from `uv sync`. The fallback changes only how the wrapper is started: when it is refused
too, or `status` reports the role not usable, the agent stops and reports, as above, and never
runs the command bare.

**The commit still carries the session's own attribution trailer.** `run` changes who git says
authored and committed the change (the bot's name and noreply address), not what the message
says: the `Co-Authored-By` line the session's own instructions ask for is added exactly as it
always was.

## Pushing

**Always push branch work and create or update its pull request before ending the session.**
*(2026-09-09: "always create prs don't leave branches locally only"; "or have branches on the
remote without pr without good reason".)*
Do not leave work only on a local branch or leave a remote work branch without a PR unless there
is a specific good reason, documented in the final report. Use a draft PR when the work is
unfinished, and include the PR link in the final report. This is standing authorization; no
separate request to push or open the PR is needed.

**A ready-for-review PR carries the completed work and its verification** (see "Before
committing"). An unfinished draft may be pushed with failing or outstanding checks, stated in the
PR; backing it up does not claim that it is ready to merge. Unfinished work stays out of `main`,
which is the tree a fresh clone receives.

## Merging

**Merging a PR requires explicit permission in the current session.** This includes enabling
auto-merge, manually merging, and asking an agent or monitor to merge. Permission from another
session does not carry over. Finishing implementation, opening a PR and green CI do not imply
merge permission. Leave the PR open and report its link when permission has not been given.

**A PR merges only after its review.** A review under **pr-review** has posted the verdict
*ready* on the PR against its current head, or against a head whose later pushes were reviewed
too; a merge of `main` whose result is Git's own needs no second review (**pr-review**).
*(2026-09-26: "all PRs must go through a (adversarial) review before ready to be merged.")*
Merge permission and green CI do not replace it.

**Merging needs one approving review, from a reviewer bot or the player, in addition to the green
`test` check** — the live `main approvals` ruleset exempts the player (a repository admin) from the
approval rule on *any* PR they merge, not only their own. A reviewer bot's own APPROVE (posted as
`claude-reviewer`/`codex-reviewer`, under **pr-review**) counts the same as the player's.

**A review thread is resolved only by whoever opened it, and that is a convention, not a gate**
(**pr-review** says who and why): an open thread never blocks an approval or a merge on its own.

When merging is explicitly authorized, check mergeability and let CI gate the merge. Resolve
conflicts under the **merging-main** skill before enabling auto-merge. **Squash-merge**
(`gh pr merge <n> --squash`) and retire the branch (see "Branches"). A dependent wait belongs to
a background agent, not a polling loop in the orchestrating session.

**Several PRs can merge in a row without re-greening each one.** Two rulesets guard `main`. The
`main` ruleset requires a pull request and the `test` check, run on the merge result — every
consistency check and every test of the game, except on a docs-only pull request, where the game's
tests are skipped and every consistency check still runs (**verify** says what each kind of pull
request gets). The `main approvals` ruleset requires one approving review, from a reviewer bot or
the player; repository admins (the player) may bypass it on any pull request they merge, not only
their own, and resolving the review threads is not required (a convention, not a gate — see
above). So green CI alone is not the gate.
Neither ruleset requires a branch to be up to date with `main`
(`strict_required_status_checks_policy` is off), so an approved PR whose `test` check is green
merges after `main` has moved under it as long as the merge is still clean; a conflict still blocks
it and is resolved on the branch. **What that trades away is real**: the check ran on that branch's
merge result, not on the one it actually gets, so a semantic conflict between two PRs that touch
different files passes both gates and lands broken. Watch `main`'s own CI run after a batch rather
than assuming the last green PR spoke for it; `tools/land-prs.sh` names that run when it finishes,
and `.github/workflows/ci.yml` never cancels a run on `main`, so every merge commit gets one.

## Releasing

**A push is a check and a tag is a release.** `https://nappy.josuakrause.com/` serves the game.
`.github/workflows/ci.yml` runs lint, check, the full suite, sharded, and the browser check — the
release Web export, built and played in Chrome exactly as the deploy builds and plays it — on
every push to `main` and every pull request but a docs-only one, which gets the consistency checks
alone (**verify**)
— a new push to a pull request cancels that pull request's older runs, and a run on `main` is never
cancelled. A push to `main` is never docs-only, so the commit a tag points at has had every check.
`.github/workflows/deploy.yml` fires on a `v*` tag and nothing else: verify, boot check, export,
upload, publish, then the GitHub release, in that order. **The deploy does not run the suite
again.** The `version tags` ruleset requires the `test` check on the commit a tag points at, so a
tag on a red or untested commit cannot be pushed, and the deploy's first job asks the API for that
check's outcome and refuses to build without it — the same read `tools/release.sh` waits on before
it tags. So a commit that fails in the browser cannot be tagged at all; the deploy's own browser
check, on the very files it publishes, is the second look rather than the first.

**The release's notes are generated, not written.** The deploy's last job runs `tools/release-notes.py
<tag>` — deterministic from git alone, no model and no network call to compute — and publishes its
Markdown as the tag's GitHub Release (`gh release create --notes-file`, or `gh release edit` when a
release for that tag already exists, so a re-run of the deploy is idempotent). One bullet per
commit's own subject line on `main`'s first-parent history, grouped into a Game and a Tooling and
docs section by what each commit changed. A patch tag (`vX.Y.Z`, `Z>0`) covers everything since the
previous tag; a minor tag (`vX.Y.0`) covers everything since the previous `.0` tag, folding in every
patch between them, and a major tag is treated the same way. `tools/release.sh`'s dry run previews
the same notes before anything is tagged.

**Publishing is a separate, deliberate act, and it needs its own go-ahead from the player in the
current session**; merge permission is not release permission. Completed work may be pushed
without asking, since pushing `main` publishes nothing.

**Cut a release with `tools/release.sh <major|minor|patch>`**, which reads the latest version tag
and prints what it would do. It acts only when given a second literal `push` argument, and it
refuses a dirty tree, any branch but `main`, a `main` that is not level with `origin/main`, a
commit that already carries the newest `v*` tag, and a machine with no `gh` — every refusal fires
in the dry run too, so the dry run tells the truth about whether the real thing would work. **It
tags nothing until it has read the `test` check on `main`'s commit as green.** That check is CI's
last job (it needs the classify, gates, cost-table, game, shards and browser jobs), so it reads `none` for
the first minutes after a merge and the `push` form waits, polling every 20 seconds. A read that
fails is retried with `gh`'s own error printed, never taken as a pass; a failed check refuses, and
so does a check still not green after 30 minutes, a bound that exists so an unattended run cannot
hang forever and that a normal run never reaches. Ctrl-C while it waits is safe, since nothing is
tagged yet. Semver, and **`major` is reserved for a change that breaks or fundamentally alters the
game**. An agent's own `push` run goes through
`uv run python tools/agent-identity.py run claude-coder -- tools/release.sh <part> push` (Codex the
same as `codex-coder`) — "Who a commit and a pull request are from" is why, and
`.claude/hooks/github-write-guard.sh` denies the bare form. The player's own run at their own
terminal is unwrapped either way (`tools/lib_agent_role.sh`'s `agent_run` only wraps when
`NAPPY_AGENT_ROLE` is set); the player's own go-ahead above is what release still needs regardless
of who types the command.

**A fix on `main` is not a fix on the site**, and that is the sentence to keep in mind before
telling anybody the page is well. The site serves whatever the newest tag points at, so `git tag
--list 'v*'` and `tools/release.sh`'s own dry run are what say whether a given commit is out there.
A release has carried a game-ending bug before (`tools/decisions.sh M73`).

**A browser fetches a new release whole.** The export publishes `index.js`, `index.wasm` and
`index.pck` under a directory named for the release tag, because GitHub Pages sends
`Cache-Control: max-age=600` on everything with no header surface to change it, and under fixed
names each file's ten minutes would run independently, pairing a fresh `index.html` with the
previous release's `index.pck` (`tools/decisions.sh M80`). So a report of a stale build is worth
believing rather than explaining away.

## The squash commit is the pull request's title and description

**Every pull request reaches `main` as one squashed commit whose message is the PR's title and
description**; the repository's squash defaults are set to exactly that. *(2026-09-19: "commit
messages shouldn't really contain information that isn't written elsewhere as well"; on the
message a squash carries: "I prefer \"Pull request title and description\"".)* So `git log` and
`git blame` on `main` show one reviewed text per work item, and a branch's own commits — the
WIP ones and the merges of `main` among them — are scratch that never lands.

**Re-read the description immediately before merging, because it is about to become permanent.**
It says what the PR carries as it now stands, the verification with its outcomes, and every
choice left open to overturn; a description written when the PR opened and not since is a
commit message about a different diff. Nothing may live only in a branch commit message: the
reasoning a later reader needs is in the decision record, and the description summarises it.

## A pull request is self-contained

**A pull request is a completed work item, and a broken one is fixed on its own branch, never
by a second PR.** *(2026-09-14: "we're not merging broken things -- fixes go in the same PR
*always*"; "a PR is a *completed* workitem"; "we don't merge PRs that are broken, we fix PRs, not
by creating new PRs".)* When review, a playtest or the player finds that a PR built the wrong
thing or built it wrong, the correction is committed on that PR's branch and the PR's description
is updated to say what it now carries. A follow-up PR for the fix would either merge the broken
work first or leave two PRs that only make sense together, and neither is a completed item.

**And the unit is the work item, not the queue entry.** *(2026-09-14: "why do you keep
creating new PRs for things that should go in the same PR?")* One question splits into several
queue entries as it is worked — a probe, the thing the probe found, the fix for it — and each
entry is still the same item until the player has what they asked for. The fix for what a PR's
probe found goes on that PR, whatever name or number the queue gave it; a new PR is for a new question.

**A pull request carries every document its own changes make false.** Not a follow-up, not a
cleanup pass afterwards, not a note for the next session: the doc edit is part of the change and
lands in the same PR. That covers the queue — the entry's folder under `docs/todo/`, which goes
stale fastest because it holds the work the PR just did — and every other governed doc the change
touches: `CITY`, `EVENTS`, `MECHANICS`, `TELEMETRY`, `ARCHITECTURE`, `NARRATIVE`, `README`,
`CLAUDE.md`, the skills, and the docstrings on anything edited. **A PR that finishes an item deletes
the item's file and files what it built as a decision**, `docs/decisions/<entry name>.md` (made with
`tools/new-name.sh decision --entry <name> "<title>"`, which takes `-2` and on when the entry
already has one); **when that was the entry's last item, the entry's folder goes in the same PR**,
because the queue holds open work only and the entry stops being open the moment the PR merges.
Another entry's `after:` line naming it stays as it is: the record is what makes the wait count
as over (`tools/queue.sh` prints it as `<name>, closed`, and the lint accepts it), so closing an
entry never edits a second one, and the end-of-session pass (**session-cleanup**) deletes the
line.

**The queue's order is each entry's band line**, the first lines of its `README.md`
(`priority: now|next|later|parked`, then any `after:` lines), and `tools/queue.sh` prints it.
Setting or moving a band is the orchestrator's (**orchestrating**) and edits that one file, so it
meets another PR only when both change the same entry; there is no shared order list for a PR to
edit.

**Why:** a PR is reviewed once, against a tree where the reason for each doc edit is visible in the
same diff. Deferred, the reason is gone and only somebody who already knows what changed can tell
which sentence went stale — which is nobody, a week later. Several PRs merged in a row each leaving
their own doc debt is how three files come to carry three different answers to one question, and
the pass that untangles it is a milestone rather than a review comment.

**The test is the same one the docs rule uses:** if `main` at the squashed commit would hand a fresh
reader a sentence that is no longer true, the PR is not finished. Read the entry's own folder
before proposing, not after.

**And every doc the change owes is in the PR before it merges. This is a hard requirement.**
*(2026-09-09: "why do you keep updating handoffs and todos *after* a PR has landed? the updates
*must* go in the PR … that's a hard requirement" — and, on the shape of it: "the requirement is not
for docs to be updated before the PR opens. it's for the docs to be updated *before* it
**merges**".)* The entry's files, the decision record, the review item and every other doc the
change touches are committed on the branch by the time the merge button is pressed. Pushing them onto an open PR is
fine; filing them in the next PR, or in a cleanup afterwards, is not — once the squashed commit
exists, `main` has handed every reader a false sentence until something else lands. Before merging,
re-read the branch's own diff against the list above and ask what it left stale. The end-of-session
cleanup pass is for drift no single PR caused, not for finishing a PR's own doc work.

**A work item never merges while its queue item is unresolved.** *(2026-09-09: "a workitem may
never merge if it's corresponding TODO item hasn't been resolved".)* Resolved means the item's
file is gone from its entry's folder and its record — what was built, the measurement, the
rejected options — is filed under `docs/decisions/`, both on the branch. A PR whose own item still
sits open in the queue is not finished, however green its checks are; if the item is only partly
built, the PR either finishes it or rewrites the item's file on the branch to hold exactly what is
still open, with the built half filed as a decision.

**And work that only a person can judge adds its review item in the same PR**: a file
`docs/review/<entry name>.md`, made with `tools/new-name.sh review --entry <name> "<title>"`, which
takes `-2` and on for a second item from the same entry. *(2026-09-11: "keep a document with items
that need human review / test runs. That way you can keep working without having to stop. And test
runs can capture multiple items at once.")* The item says what to do, where to look, and the
question a run answers, its steps written as prose rather than numbered; the record of what was
built stays in the decision. The review items are the list a playtest is asked against, so an item
missing from them is an item no run will ever be asked to look at.

The **session-cleanup** skill still runs at the end of a session — it catches drift that no single
change is responsible for, reassesses long-open items and re-reads the numbers. It is not where a
PR's own doc work goes.

## A PR description never links a file by branch name

**An image or file in a PR description is linked by commit hash, never by branch.** *(2026-09-09:
"using branch names in pr descriptions will lead to stale links (eg for images etc)".)* A URL of
the shape `.../blob/feature/<thing>/docs/evidence/x.png?raw=true` or
`raw.githubusercontent.com/<owner>/<repo>/feature/<thing>/...` works while the branch exists and
returns a 404 the moment the branch is deleted — and this workflow deletes every branch as soon as
it is merged, so every such link in every merged PR is dead. The description is the one place the
before-and-after pictures live once the PR is closed, so a dead link there is the evidence gone.

Link the commit instead, and **embed a picture with image syntax, never as a bare URL**:

```
![what the picture shows](https://raw.githubusercontent.com/<owner>/<repo>/<full-commit-sha>/docs/evidence/x.png)
```

*(2026-09-23: "the images don't show up inline"; "while they do show up inline for the other
prs".)* GitHub renders a bare URL in a description as a link, so the player has to open every
picture to see it, which is exactly what a visual review is meant to spare them.

**A pull request that went through several visual passes opens with the current proposal**, its
pictures embedded, and lists the superseded passes last as plain links. *(2026-09-23: "it's not
clear what the current proposal is".)* A description that grows a section per pass reads as a
history, and the reviewer has to work out which picture is the one being asked about.

A branch commit's URL survives both the squash and the branch's deletion because GitHub keeps
every pull request's commits reachable under `refs/pull/<n>/head`. **The hash has to be the one
the file was committed in or a later commit on the branch**, so write the description after the
evidence commit exists — `git rev-parse HEAD` — and if the evidence is amended, update the link.
*(2026-09-19: "images will survive if you use the commit hash"; "only branch names disappear".)*

GitHub-hosted attachments are an alternative to committed media: dragging an image or video into
the PR text box uploads it and supplies its URL. GitHub also documents `--attach` for PR creation,
editing and comments in [Attaching files with GitHub CLI](https://docs.github.com/en/github-cli/github-cli/attaching-files-with-github-cli).
Check that the installed CLI and the required agent identity support that route before using it.
The [CLI upload token allowlist](https://github.com/cli/cli/blob/2c7ec97fddb8da331803e18e8c33395a3b6537ee/internal/attachments/client.go#L65-L79)
excludes, at that pinned commit, the GitHub App installation tokens this repository's bots use,
so changing the apps' permissions does not enable that CLI route; check the current allowlist
before relying on it either way. The player can upload through the browser. Attachment uploads
follow the same identity and publication authorization rules as other PR writes, and issue writes
still use `tools/inbox.py`.

## Reviewing a pull request

**Every pull request is reviewed adversarially before it is ready to merge**, and the findings go
on the PR as comments. How is the **pr-review** skill's.

## Branches

**Before merging main into an existing PR or branch, read
[merging-main](../merging-main/SKILL.md).** It requires showing theirs, ours and base for each
conflict, reviewing semantic alignment for every merge (clean or conflicted), keeping
independently authored records distinct, and converting a branch still on the old single-file
queue with `tools/convert-queue-edits.py`. Side-selection shortcuts such as `--ours` and
`--theirs` do not satisfy that review.

**One branch per work item** (which may span several queue entries), named
`feature/<thing>`; `main` receives it as one squashed commit.

**Delete a branch as soon as its pull request is merged, always, without being asked.** The
squashed commit is what the project keeps; the branch pointer is scaffolding. Left alone they
accumulate one per work item, and the cost is not clutter — it is that `git branch` stops being
able to answer the only question it is good for: **is there work that is not on `main`?**

**Git cannot see a squash as a merge, so the PR's state is the check, not `git branch -d`.**
`-d` refuses every squash-merged branch, which makes its refusal say nothing. Use the retirement
script below: GitHub must confirm MERGED and git must prove the local tip equals or is an
ancestor of the merged head. A different tip alone does not prove unpushed work; a stale ancestor
contains no work outside that PR. Missing commit objects are kept for explicit inspection and
fetching, never fetched by the dry run. A harness
`worktree-agent-*` branch has no PR and points at its worktree's base, so `-d` still answers
for it.

**`tools/prune-merged.sh <branch>...` is that check, executable, and the way a merged branch is
retired.** `--all` inventories candidates and allocated KiB without mutations; `--all --apply`
retires eligible candidates, and `--dry-run <branch>...` previews named branches. Applying checks
state again before removal. An open PR, remote tip outside the merged head, dirty/untracked work,
an ignored file outside the regenerable caches (the script's own `REGENERABLE_IGNORED` list,
which `--help` prints), worktree lock or unreleased agent brief keeps the branch. After confirming the agent has stopped
and useful ignored artifacts are retained, its owner adds `cleanup: ready` to the brief's opening
header in the main and target checkout wherever a copy exists. A lock still vetoes removal and
is never cleared automatically. The script deletes the remote with an exact-tip lease, removes
the clean worktree without force, then compares and deletes the local ref. A failed stage keeps
remaining local work and reports the incomplete cleanup. It also sweeps the harness's
`worktree-agent-*` branches whose worktree is gone. Run it from the main checkout, through `uv run python
tools/agent-identity.py run claude-coder -- tools/prune-merged.sh <branch>...` for a pull request
that changed code and `uv run python tools/agent-identity.py run claude-orchestrator --
tools/prune-merged.sh <branch>...` for a docs-only one ("Who a commit and a pull request are
from") — its own remote delete is a write, so `github-write-guard.sh` denies it bare in every
shape, and the read-only `--all` inventory and `--dry-run` run through the same wrapped line as
the apply (Codex runs the same line with `codex-coder` for both). **Use it rather than the bare commands**: Claude
Code's auto-mode classifier refuses `git worktree remove` and `git branch -D` as destructive
however the check came out, and `.claude/settings.json` allows exactly those two wrapped lines, one
per role, because the script cannot delete anything the check did not clear. The allow rules are a
prefix match on the command's text, so the line has to be spelled as above: `./tools/…`, another
role, or anything else in front of `tools/prune-merged.sh` is not covered and goes to the
classifier. There is no `codex-coder` rule: Codex does not read this file (its approvals are its
own sandbox's), and Claude Code never runs as `codex-coder`.

**`tools/land-prs.sh` lands every pull request it is given as the one role it runs under**, since
it merges and retires each branch through that role. So a batch of docs-only pull requests and a
batch of code pull requests are two calls, one as `claude-orchestrator` and one as `claude-coder`,
rather than one mixed call.

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

**But a branch is yours, and a messy commit inside one is fine.** *(2026-09-05: "unclean commits are
fine inside a branch since main is protected".)* `main`'s ruleset means nothing lands except through
a pull request with the `test` check green on the merge result, so **the branch cannot hurt anybody**
— the thing that has to be clean is what reaches `main`, and the squashed commit is what the
project keeps. A half-finished item, a commit that does not build, a "wip" while you go and check something,
several small commits where the rule above wants one: all fine, none of it needs asking about.

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

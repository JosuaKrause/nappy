---
name: orchestrating
description: How implementation work is delegated to sub-agents — delegating is the default, isolated worktrees, one work item per agent, what a task description must contain for the result to be mergeable, and the design principles every brief and change keeps. Loaded at session start because who does the work is decided before the first tool call.
---

# Orchestrating sub-agents

**When delegating a milestone, give the implementation agent an isolated git worktree;
the orchestrating session designs, specifies, reviews integration and maintains the queue.**
The split gives implementation fresh context and a fenced scope while orchestration retains
the whole queue and the player's words.

Use Sonnet in Claude Code for implementation, Haiku for a wait — polling a check, retargeting a PR,
removing a worktree, pulling `main` — and a stronger model when a milestone's geometry or contracts
warrant it, by judgement (woolly-finch 15). **In Claude Code, drawing is Opus's** (PLAYTEST-123 8):
an agent that makes or revises artwork — SVG, PNG, a review sheet — runs on Opus, since the result
is judged by eye and a weaker first pass costs the player a review round; Codex has its own model
hierarchy and keeps its own tiering for art (woolly-finch 27). In Codex, pick the subagent tier by
the task's remaining difficulty: see `references/codex-models.md`. **Generating a raster is Codex's
alone**: Claude Code has no image generator (**illustrated-png**, "Asset contract"), so a brief
whose work includes generating an illustrated PNG, a comic transfer included, goes to a Codex agent
(which writes as `codex-coder`); the drawing rule above covers SVG and the review sheets. While
Codex support is frozen (inbox #901 in freckled-moose), such a brief waits for Codex to come back, and the player is
told.
Installing, registering, rebaking and checking PNGs that already exist stays open to either host.
**The orchestrator grades every finished agent with `tools/agent-stats.py add`** (kind, model, PR,
rounds, grade; `--redone` when it redid the agent's own conclusion), and the SubagentStop hook
(`.claude/hooks/agent-stats.py`) records the tokens and tool calls beside it; `summary` shows what each
kind and model cost and how it went. The data lives outside the repository, in
`~/.claude/nappy-agent-stats/` (inbox #900 in freckled-moose): a shared log in git would conflict between parallel pull
requests and need a PR per entry, so the code is checked in and the data is not.

*Proposed, not asked for, open to the player's correction, to be revised once the counter holds
enough entries (inbox #900 in freckled-moose):*

| Task kind | Model |
|---|---|
| Build at test parity | Sonnet |
| Build that changes play or designs a seam | Opus |
| Investigate an unexplained result | Opus |
| Measure: run a named probe batch into a fixed table, no conclusion | Haiku |
| Measure with interpretation: what is noise, what is real, what a picture shows | Sonnet |
| Capture named moments for a PR | Haiku, the pictures judged by the measurer or the reviewer |
| Review fixes | the builder, while warm and not near the limit |
| Review of a play-changing or design PR | Opus |
| Review of queue, docs, skill wording or a small delta | Sonnet |
| Waiting, merging, polling | no agent (a background shell) |

The measuring rows follow one comparison (inbox #900 in freckled-moose): Haiku and Sonnet ran C2b's measurements,
pictures and conclusion on one brief. Their numbers matched exactly; Sonnet called a borderline rise
unresolved where Haiku called it flat, and saw the change in three picture pairs where Haiku saw one,
at about 10% more tokens. No further side-by-side runs are made for now: the counter's statistics
decide, and a row still ambiguous after a week of them, from 2026-11-01, may be tested by running one
task on both models again (inbox #900 in freckled-moose).

The contract is the same on either host: fresh context, a bounded scope and an isolated checkout for
implementation. Create the worktree explicitly if the tool does not create one. Read-only review can
share a checkout. If delegation is unavailable, do the bounded work locally and retain the same
verification gate.

**A usage or quota limit is already over by the time the orchestrator hears of it**, in Claude Code
and in Codex alike. Nothing about delegation changes because of one: no fewer agents, no cheaper
models, no implementing locally to save quota. Do not carry a limit message
(codex-delegation-after-visible-usage-limit-messages) from an earlier agent or turn forward as a
reason to do anything differently (woolly-finch 25). What an interruption does change is which
agents can continue — see "Recovering from an interruption".

## Delegating is the default, and implementing by hand is the decision

**Before writing code in `src/` or `tests/`, the question is not "can I do this" but "is this
specified enough to hand over".** If it is, hand it over.

The three cases where the orchestrating session implements directly, and they are narrow:

- **The design is still moving.** An open fork, a "draft and put back" item, or anything where the
  next decision is the player's — an agent cannot hold a conversation with them.
- **The change is a sentence.** A stale line in a doc, a constant, a one-line fix. Specifying it
  costs more than doing it, and a prompt long enough to be unambiguous is longer than the diff.

  **This one drifts, and it drifts while the work is going well.** It is claimed for a change that
  turns out to touch four files, want a test, and need a decision about where a new helper lives —
  by which point the prompt would have been shorter than the diff, and the argument for doing it by
  hand was made before any of that was known. Two checks, either of which fails it: **is it more
  than one file**, and **does it need a test**. A fix that needs a test is a fix somebody has to
  verify, and verification is exactly what an agent's report is for.

  The tell is the phrase *"while I'm in here"*. The cost is not the diff — it is that the
  orchestrator's context fills with implementation detail that an agent would have held instead,
  and the next design decision is taken with less room to take it in.
- **It is the queue or the archive.** `TODO.md` and the entries under `docs/todo/`, the review
  items, the records under `docs/decisions/` and the playtests are the orchestrator's, always —
  see "What the orchestrator keeps".

**Everything else is an agent's**, and a milestone that is not ready for one is a milestone whose
queue entry is not finished yet. That is the same test the **playtest-feedback** rules already impose:
*somebody opening the repo cold could build the thing that was asked for.* Writing the brief until
an agent can take it is not overhead on top of the work — it **is** the orchestrating half of it.

**A milestone with an open design question is not ready for one.** The question goes to the player
first, and "draft and put back" items never go to an agent at all.

## Code is designed by layer

**Every design, brief and change keeps to the player's principles** (minty-lemur #785, #796):
separation of concerns, composability, cohesion, low coupling and a layered architecture, with
**dependency injection** for modular, testable code (minty-lemur #794). A layer depends only on the
layers below it, through their interfaces, and tells a higher one what happened by an event or a
callback it was handed, never by calling it; a component is handed what it depends on rather than
fetching it from an autoload, a group or a static, so a test hands it fakes. A mode, the escape
included, is a configuration of the shared code, never a parallel copy of it (minty-lemur #785).

*Proposed by the filer, open to overturn (plush-kestrel):* the target layers are minty-quail's (data
and configuration; the domain model; the world; simulation; run flow; observers); a fix lands in the
shared mechanism rather than a branch keyed on one row's id or picture; new code follows the target
shape and adds nothing to the divergence the open refactor entry lists; a brief names the layer its
work belongs to. **The one exception to this whole section** is a minimal fix the queue orders
before the refactor, which names itself as the exception in its entry, and **it holds only until the
refactor**: the refactor replaces the code the fix touched, and the PR that closes the refactor entry
removes the exception from this section, so it never outlives that PR (minty-lemur #799).

**Every pull request that changes code answers the architecture questions** in
**pr-review**'s `references/architecture-questions.md`, so the layering does not drift once the
refactor is done (plush-egret #892): its layer, its dependencies, what it is handed and what it
fetches, what it reuses, where a fix lands, how a test builds it, and the docs that say where it
lives. A brief asks for them; the builder answers them in its report and under the description's
`## Architecture questions`; CI checks they are there and the reviewer that they are true.
**Which folder and file is in which layer is `tools/layer_map.py`**, which `tools/check_layers.py`
holds the code to in CI; the list of breaks standing there only shrinks. *Proposed by its builder,
open to overturn:* the composition root (`main.gd` and the developer's rigs) above everything, and
each thing's own drawing on the layer of the thing it draws. *Two departures from minty-quail's
filed layering, decided by the player* (inbox #904 in freckled-moose): the view (the HUD, the screens, the badges, the controls) and the observers are **siblings at one level**,
neither above the other and neither naming the other, where minty-quail's README puts the UI inside
the observers; and the map lookup (`WorldMap` and its records) stays **with the city maps in the
domain model**, a correction to minty-quail's item 3, which puts one map interface in the world. A
record the map holds is placed on the map's layer as it appears.

## The task description is the contract

A vague prompt returns work that cannot be merged.

**A brief, a PR title and a record title name every part of a step, and never number or letter
it** (inbox #937 in plaid-penguin, inbox #941): "the route rig walking the building", not "part
B3", "slice 4" or "2a/4". A number is a lookup the reader performs.

**Before spawning, the orchestrator writes the brief verbatim to `.claude/briefs/<branch with
"/" replaced by "-">.md`.** `tools/agent-setup.sh <name> <branch>` makes the worktree and writes
the header; the task goes under it. The file opens with a header of `key: value` lines that
`tools/agent-status.sh` parses:

```
branch: feature/<thing>
worktree: /abs/path/to/worktree   (added once known)
agent: <agent id>                 (added after spawning; one line per agent, the newest last)
spawned: <ISO date>
```

Then a blank line, then the brief. **The shared half of a brief is a file, not a paste**:
`references/agent-contract.md` holds the read-first order, git and commit cadence, the identity by
PR kind and its fallback, the scope fence over the queue and the archive, verify's gate, headless
first, `--no-save` and the dev flags, the visual-attempts rule, disk, forks, no merge and the
report. A brief carries its task, its task-specific read-first items, the layer its work belongs to
(proposed in "Code is designed by layer"), for a pull request that changes code the ask for the
architecture questions' answers (**pr-review**'s `references/architecture-questions.md`) in the
report and the description, **the GitHub role the agent
acts as**, its fence, whether the evidence is a still or a burst, whether the capture may be
invincible, whether this is a local-full-run case, and a paragraph on the other live agents and the
files they own (written by hand from the briefs' fences; they are prose, so nothing generates it).
The spawn prompt `agent-setup.sh` prints names the brief and the contract. Every later
`SendMessage` that changes the agent's scope or task is appended under `## Amendment <ISO
date>`, so the file on disk stays what the agent was actually told rather than what it was told at
spawn time.

**Any agent started into an existing worktree gets its `agent:` line appended the moment its id
is known** (`tools/agent-setup.sh --agent <branch> <id>`) — a fresh spawn and a replacement into a
dead agent's worktree alike; see "An agent that died mid-task is replaced in its own worktree" for
the replacement case.

Every agent prompt contains, explicitly — in the brief or, for the items the contract covers
(commit cadence, the standing fence, verify's gate, headless first and `--no-save`, the
visual-attempts rule, disk, forks, no merge, the report), by naming
`references/agent-contract.md`; the role is always the brief's own line, since an agent with no
role named has nothing to check `status` against:

- **A read-first list, in order**: `CLAUDE.md`, the entry's folder under `docs/todo/` (its
  `README.md` and every item file), the records under `docs/decisions/` that carry its design (by
  path; `tools/decisions.sh` finds them), and the specific docs and source files it will
  touch. The agent starts cold; everything it needs must be named, not assumed.
- **The branch name** (`feature/<thing>`), and the committing rules restated: one commit per item,
  messages that explain why, docs move in the same commit as the code.
- **Which GitHub identity the agent commits, pushes and opens its pull request as**, chosen by
  what the pull request will contain, not by which agent writes it (**committing**, "Who a commit
  and a pull request are from"): in Claude Code, `claude-coder` for a pull request that changes
  code, `claude-orchestrator` for a docs-only one and for any issue write, `claude-reviewer` for a
  review agent; in Codex, `codex-coder` for both kinds and `codex-reviewer` for a review —
  since **committing** and **pr-review** make this mandatory and an agent with no role named has
  nothing to check `status` against. If
  `status` reports the role not usable, the brief's own instruction is to stop and report back
  rather than falling back to a direct call. The brief names **committing**'s `.venv/bin/python`
  form of the wrapper as the fallback for a worktree whose permission check refuses `uv run`.
- **Commit and push after each item, and before starting any run that takes longer than a few
  minutes.** A WIP message is fine — **committing** already says a messy branch commit is fine.
  A usage limit or an API error kills the agent without warning, and the committed-and-pushed
  state is what survives it: `git log` on the branch shows where the agent stopped, and another
  session can see that and pick it up, rather than the state living only as uncommitted edits in
  a worktree that somebody has to find and diff by hand.
- **A scope fence**: the files it may touch, and the files it must not — always including
  `docs/TODO.md`, `docs/todo/`, `docs/review/`, `docs/decisions/` and the
  playtests (queue maintenance and
  archiving belong to the orchestrator), plus anything another live agent owns. Two agents editing
  one file is a merge conflict scheduled in advance; when a shared file is unavoidable, tell each
  agent exactly which lines are theirs.
- **The verification gate is verify's**: `./tools/check.sh`, `./tools/pycheck.sh` and
  `./tools/lint.sh` where they apply, and the suites the change touches; the full suite is CI's,
  on the merge result, and a `PARTIAL RUN` marker is expected. **Say in the brief whether this is
  one of verify's two local-full-run cases** — an agent left to judge it will run the whole thing
  to be safe. Only those two count: a change that is large or touches many files is not one by its
  size, since CI runs the same suite on a better tree, and a local full run is a wait long enough
  to go to the background, which notifies this session and the player (inbox #870 in minty-dolphin). A brief copied from an earlier one is checked for this
  line, not inherited. A red PR goes back to the agent with the failing output.
- **Headless first.** Verification lives in the test rigs, not in watching the game. Windowed runs
  (`tools/run.sh`, repeated `tools/shot.sh`) open on the player's own screen; at most one or two
  `shot.sh` calls at the end for evidence. A windowed run is also the least reliable thing an agent
  can lean on — the **verify** skill carries the rig traps that make one look like it worked when
  it did not. **Say in the brief whether the evidence is a still or a burst**: anything about
  motion — a turn, a gait, a wing beat, a shadow rotating — is a burst
  (`--press snapshot_burst <seconds>` on the same `shot.sh` call, see **verify** and
  **session-captures**), and an agent told to take a screenshot of motion will spend its budget
  on stills that land beside the moment. **And say whether the capture may be invincible**:
  `--invincible` keeps the day running while a rig waits for a junction, a chase or a crossing
  to happen in front of it, where a rig left to itself dies to the meter or the clock before the
  moment arrives; an agent not told about it will burn runs landing on the summary screen. Leave
  it off only for a capture whose subject is a cost or a loss.
- **An agent's run carries a dev flag or `--no-save`** (see **verify**), because every worktree
  shares the player's save.
- **Visual attempts come back early.** The player welcomes repeated feedback and prefers seeing
  an attempt to waiting through a long internal revision loop. Ask the agent for a prompt preview
  in the player's requested format, naming the visual point that remains uncertain. Keep cheap
  integrity checks and provenance, but do not hold a useful attempt for polish or repeated
  generation. Let the player's response steer the next visual pass while independent work
  continues. The player's CLI cannot display images: push review artifacts first, then embed
  them in the PR description as images with commit-pinned URLs, as **committing** says.
  A local file link is not a delivered visual review. Showing an attempt does not authorize
  runtime installation. **A question the player answers by eye gets a picture of its own**, the
  options alone with the question above it in words; a full sheet is evidence, not a question
  (`references/agent-contract.md` has the player's words).
  **A delivered review file stays byte-for-byte unchanged.** Render into job-owned scratch,
  wait for its writer to finish, then copy the completed artifact to a new versioned delivery
  filename and record its hash. Once the player has a link, no render or copy overwrites that
  file: further attempts get new filenames. Independent work can continue while the player
  reviews it, but it cannot change the artifact being reviewed. Label an attempt's actual
  verification limits; an existing file and plausible stream metadata do not prove its audio
  or picture matches the requested result.
- **Forks come back, never guessed.** If the design is ambiguous, or two recorded instructions
  conflict, the agent implements the unambiguous part and states the fork precisely in its report.
  Where the design is merely silent on a small detail, it chooses the smallest implementation
  consistent with the contracts **and says so in its report, which the PR description carries**,
  so the choice is visible and cheap to overturn. **A brief that contradicts a recorded
  decision is a fork too**, however explicit the brief is: when the brief asks for something a
  record under `docs/decisions/` or a doc's stated rule rules out, the agent builds nothing that overturns
  it and reports the clash, quoting both.
- **What the final report must contain**: per item, what was built and how it was verified; every
  choice made where the design was silent; every fork left open; and, for a pull request that
  changes code, the answers to the architecture questions. The report is the merge review's
  input — an outcome it does not mention is an outcome that did not happen.
- **Do not merge, do not delete the branch.** After the report, the orchestrator commits the
  queue's move on the PR branch — the finished items' files deleted, the entry's folder too when
  its last item went, the decision record written under the entry's name and any review item
  filed (**committing** says how), the agent's silent choices recorded as open to overturn, not
  narrated as settled; then the PR goes to a review agent under **pr-review**, which checks that
  move with everything else; then the orchestrator merges only under **committing**'s permission
  rule and retires the branch with `uv run python tools/agent-identity.py run <role> --
  tools/prune-merged.sh <branch>`. Each of those writes goes out as the pull request's own
  identity, not the orchestrating session's: on a pull request that changes code the queue move,
  the merge and the retirement are `claude-coder`'s, and on a docs-only one they are
  `claude-orchestrator`'s.

## Running agents in parallel

**Create sparse worktrees before materializing files, with `tools/agent-setup.sh`** (busy-ibis 3).
It runs the disk preflight, `git worktree add --no-checkout --no-track` onto a new branch from
`origin/main` (so the branch inherits no upstream), enables non-cone sparse checkout and only then
materializes HEAD. The patterns are the `gates` job's sparse checkout in `.github/workflows/ci.yml`
— the one list, which keeps back what the repository's own checks read from `docs/evidence/` (the
SVGs `lint.sh` validates and the experiment scripts `pycheck.sh` runs) — followed by
`!/docs/reference/` and `!/docs/style-references/`; `--include <path>` adds a folder back for a task
that needs it (evidence, references or style references are the point of some tasks). A tools-only
task may omit runtime art/assets too. **Claude Code's worktree isolation makes a full checkout
here**, since `.claude/settings.json` sets neither its `worktree.sparsePaths` (which can only
include whole folders) nor a `WorktreeCreate` hook. So the orchestrator runs the tool, which creates
the worktree under `.claude/worktrees/<name>` (the path-triggered rules hook loads only for paths
inside the project, so a worktree under `$TMPDIR` gets no rules), and starts the agent in it without
isolation; the brief carries the `worktree:` line and the agent's `agent:` line the moment its id is
known, as for any agent started into an existing worktree. A review agent's scratch checkout is made
sparse with `tools/agent-setup.sh --detach <ref> <name>`: the same patterns, detached at `<ref>`,
with no branch and no brief, so `agent-status.sh` never counts it as an agent. Worktrees share
history, so clone depth does not avoid repeated working files. Before checkout, import, build or
capture batches, check free space on the destination volume against the estimated peak working set
plus explicit headroom (`tools/lib_disk_headroom.sh` holds the measured estimates, worktrees'
included); an unknown peak or inadequate room means measure or reduce the batch before starting. **A
low-disk warning from a tool, or a check that leaves less than the reserve, stops new work**
(quiet-yak #496). It is guidance, not a hard hook. The orchestrator starts no new agent or worktree
and an agent starts no new task or batch until the space is sorted out by **session-cleanup**'s
storage steps; work already running may finish, and an agent reports the warning in its report
rather than leaving it in a log. Record scratch paths and cleanup ownership in the brief, and follow
**session-cleanup**'s job-owned storage rules. Release a finished agent's brief only after its
processes stop and useful artifacts are retained (`tools/agent-setup.sh --release <branch>` adds
`cleanup: ready`); retirement refuses an unreleased brief.

**One repo takes several agents at once when each works in its own git worktree** (each gets a
checkout under `.claude/worktrees/` and its own branch: a sparse one the orchestrator made, as
above, or the harness's full one through worktree isolation when the task needs the excluded
folders; the path-triggered rules hook works in either unchanged). What makes it safe is not the
worktrees — merging is what collides — so parallelism is planned at the file level, before spawning:

- **Partition by files, not by topic.** List what each milestone will touch and spawn together
  only sets that are disjoint. Docs count: two agents "on different features" that both rewrite
  `docs/MECHANICS.md` are one merge conflict split across two reports.
- **A shared file gets line-level ownership or a sequence.** Tell each agent exactly which
  lines or blocks are its own; when that carve-up cannot be stated, run those milestones
  sequentially instead.
- **Overlapping the event catalogue, `tuning.gd` or a shared test file means sequential.** Those
  are the repo's convergence points; two agents adding rows or checks to the same file will not
  auto-merge.
- **Merging follows committing** (explicit permission in this session). As each agent lands,
  push and open its PR. Once merging is authorized, issue the merges in turn, without waiting for `main`'s CI between them; a second PR merges as it
  stands unless the new `main` now conflicts with it, in which case the conflict is resolved on
  its own branch under **merging-main** and the resolution is reviewed under **pr-review** before
  it lands — the ruleset's checks are not strict, so a PR merely
  behind `main` needs nothing. The semantic gate is `main`'s own CI run after the batch, which the
  orchestrator watches: a conflict between two PRs that touch different files passes both PRs'
  own gates and only shows up there. Then retire the branch with `uv run python
  tools/agent-identity.py run claude-coder -- tools/prune-merged.sh <branch>` from the main
  checkout, or `run claude-orchestrator --` for a docs-only PR (see **committing**, which also says
  why it is spelled exactly so), which removes the worktree and deletes the branch only once GitHub
  vouches for it. `uv run python tools/agent-identity.py run claude-coder -- tools/land-prs.sh
  <pr-number>...` is that sequence for several already-authorized, reviewed PRs in one call: merge
  or auto-merge, wait, then fast-forward `main` and prune, one PR at a time, printing `main`'s own
  CI run at the end as the check to watch. It runs every PR it is given as one role, so docs-only
  PRs go in a call of their own under `run claude-orchestrator --`. A PR that an earlier merge
  left conflicting stops the run, since its resolution needs a review before it lands.
- **The harness's own branches go with the same script.** Each spawn also leaves a
  `worktree-agent-*` branch pointing at the worktree's base. `tools/prune-merged.sh` deletes the
  ones whose worktree is gone, with `git branch -d`, and keeps a live agent's: that worktree has
  a feature branch checked out, so "is it checked out" says nothing about whether it is in use.
- **An agent branches from `main`, never from an open docs branch.** When a milestone's entry
  is still in an unmerged docs pull request, wait for it to merge before spawning rather than
  telling the agent to branch from the docs branch. That pull request reaches `main` as one
  squashed commit, so the agent's branch keeps the docs commits as ancestors `main` never had.
  When `main` is merged back, every file those commits added meets `main`'s squashed copy: an
  identical one merges silently, one amended since conflicts on a file the agent never edited, and
  an item file the branch has since deleted comes back from `main`'s side without any conflict,
  reopening finished work. Each is still a three-way review, and the last is found only by
  looking.
- **Spawn from the main checkout, never from a worktree that has just been removed.** The
  harness resolves `HEAD` in the shell's current directory before it creates an agent's
  worktree, so a shell still standing in a deleted worktree fails every spawn; `cd` back to
  the repository's own folder after removing one.
- **A push that starts no CI run is diagnosed, not waited on.** When `gh pr checks` answers
  "no checks reported" minutes after a push, inspect the workflow runs and the PR's mergeability.
  GitHub cannot run a pull-request merge check while the branch conflicts with main: fetch
  current main, reconcile it under **merging-main**, and review the result before proceeding.
  If the PR is mergeable but no run exists, an empty commit on the branch re-triggers CI.
  Waiting or repeatedly pushing empty commits does not resolve a merge conflict.
- **Tell each agent who else is alive** and which files those agents own, so a scope fence is a
  sentence in the prompt rather than a discovery in the diff.

## What the orchestrator keeps

- **The queue and the archive.** Agents never edit the queue or the archive; two writers on one
  entry is how a queue lies.
- **The queue as it stands on `origin/main`, not as it stood when the session started.** More
  than one session works this repository at once, and a design entry can be rewritten and merged
  while a brief is being written from the older text. Before briefing a milestone, `git fetch` and
  read its entry's folder on `origin/main`; a brief built from a stale entry produces work that
  contradicts a decision the player has already recorded, and the contradiction is only found at
  review. If `main` has moved, merge it into the branch before the next agent commit rather than
  after the last one. **What is next is `tools/queue.sh` run on that checkout**: it prints the
  queue from each entry's band line (`priority:` and `after:`, the first lines of its
  `README.md`), and setting or moving a band is the orchestrator's one-line edit to that entry. The queue move that
  starts an entry's work drops its `upnext:` line, which puts it back in its band.
- **The merge order** when agents run in parallel — overlapping areas run sequentially instead;
  disjoint file sets are what makes parallel safe in a single repo.
- **The player's questions.** An agent's fork, silent choice, or measurement lands back with the
  player through the orchestrator, in the entry where the next reader will look for it.
- **An agent stays on one task, and no agent grows huge** (inbox #874 in minty-dolphin). An agent re-reads its
  whole context on every turn, so the cost of a long-lived one grows with every step it is kept
  for; a fresh agent instead rebuilds its context from scratch, so too many fresh agents cost too.
- **A task is scoped to stay under the limit by construction, never policed** (inbox #896 in plaid-raven). A brief
  carries no size line asking the agent to count its turns or tokens, and the orchestrator does not
  watch an agent's count while it runs, since either spends tokens on bookkeeping instead of the
  work; the orchestrator sizes every task before spawning it so that it finishes well under the
  limit.
- **A warm agent is reused while rebriefing would cost more** (inbox #896 in plaid-raven). Briefing a fresh agent
  costs tokens too, so follow-up work on a pull request (review fixes, the next step of the same
  change) goes back to its agent while it is warm (the cold-resume rule below) and not huge, which
  saves the rebriefing. What the orchestrator is told for free, such as the token count in an agent's
  finishing notification, is used: it says whether the agent is far enough under the limit to
  reuse, and how the next brief should be sized.
- Where the limit and the sizing fall is *proposed, not asked for, open to the player's correction*:
  - The limit is about 150 turns or 300k tokens of context. Re-reading grows with the square of the
    turns, so two agents of 150 turns cost well under one of 300.
  - One kind of work per agent: building, measuring (long probe runs, many-seed statistics) and
    capturing pictures are separate agents on the one pull request, each briefed from the brief
    file, the review threads and what the one before it left. A measurement
    or a capture is what makes an agent huge, since every run's output stays in its context.
  - One mechanism per build: a change that reaches several mechanisms, or whose reading list runs
    past a handful of files, is split into pull requests, or into agents on one pull request.
  - The brief names every probe, suite and evidence rig the work needs, with its command, so no
    turns go on finding them.
  - A cold or near-limit agent's follow-up goes to a fresh agent briefed from the brief file, the
    review threads and what the one before it left.
  - A builder stays with its pull request through merges of `main` while it is warm (the
    cold-resume rule below), since that work reuses the context it built.
  - A plan split across several pull requests is built by a fresh agent per pull request, each
    briefed with its part, not by the agent that wrote the plan.
  - A brief names the files and the records to read rather than asking for the whole history,
    so a fresh agent's start stays small.
  - A reviewer is fresh per pull request and is resumed, while warm, for that pull request's
    delta reviews; a review aims at about 30–60 turns.
- **A finished agent is not resumed after it has gone cold.** Sending a follow-up to an agent that
  reported an hour ago replays its whole transcript at full price, because the prompt cache behind
  it has expired (woolly-finch 5). Resume only while the cache is live, and the windows are exact:
  **Claude Code's cache lasts one hour, Codex's twenty minutes** (woolly-finch 6), counted from the
  agent's last request. **Resume only with five minutes to spare** — 55 minutes in Claude Code, 15
  in Codex — since the clock is the provider's and not observable from here (woolly-finch 7). Past
  that, spawn a fresh agent with a self-contained brief that names the branch and the report to read
  first.
- **An agent that died mid-task is replaced in its own worktree.** A usage limit or an API error
  kills the agent and leaves every edit it made, usually uncommitted. Past the cache window
  (woolly-finch 22), start the fresh agent without worktree isolation, pointed at the dead agent's
  worktree path. The brief it needs comes from `.claude/briefs/<branch-slug>.md` — the file the
  orchestrator wrote before spawning, kept current by every amendment sent since; the previous
  session's transcript under `~/.claude/projects/` is only the fallback when no such file exists.
  Its replacement agent's prompt is "read `.claude/briefs/<file>`, then what changed: …", plus what
  the orchestrator verified on disk: which files are modified, what was never run, and where the
  dead agent stopped, read from its own transcript's last tool calls. Its first two steps are to
  commit the inherited work as it stands and to merge `origin/main`. Say plainly that nothing
  inherited has been reviewed, and that it may not even compile.

  **Starting the replacement includes updating ownership.** Right after spawning it, run
  `tools/agent-setup.sh --agent <branch> <new id>` to append `agent: <new id>` to the worktree's
  brief, and write the `worktree:` line if it is missing. If no brief exists, create one with the
  header and a pointer to where the original brief is.
  `agent-status.sh` reads the last `agent:` line, and a non-isolated agent's meta names no
  worktree, so skipping this step leaves the worktree credited to the dead agent.

  **Before inheriting anything, compare the worktree with its own branch on the remote.** Another
  session can pick the same branch up while the agent is dead: the remote then carries pushed
  commits the worktree never saw, and committing the inherited edits on top of the stale head
  forks the branch. Fetch, and count `git rev-list HEAD..@{u}`. If it is not zero, diff the
  inherited edits against what was pushed; where the pushed commits already do the same work,
  save the inherited diff under `$TMPDIR`, discard it, fast-forward, and brief the fresh agent
  from the pushed state instead.
- **Nothing is committed into a worktree an agent is working in.** Queue docs, a merge of
  `main`, a fix the player wants urgently: wait for the agent's report, or do the work on a
  branch of its own from `main` and tell the agent what it will touch, so the later merge is
  small.
- **No agent runs `git stash`.** `refs/stash` is one stack shared by every worktree of the
  repository, so a `git stash pop` applies whichever stash is on top, which may be a sibling
  agent's. To test another head, add a temporary worktree under `.claude/worktrees/` (`git
  worktree add --detach <path> <sha>`, made sparse with the same patterns: `tools/agent-setup.sh
  --detach <sha> <name>`) and remove it afterwards. To set work aside, `git add -A` (so untracked
  files are kept) and make a WIP commit on the branch, kept local and unpushed; undo it with
  `git reset HEAD~1`, which leaves the changes unstaged as a pop would. Once it is pushed it is
  not undone: a follow-up commit continues from it. A brief for an agent says so.
- **The main checkout is the player's test bed.** Whatever the player is asked to try out is checked
  out in the repository's own folder before they are told it is ready — never left in an agent's
  worktree under `.claude/worktrees/` (woolly-finch 8). That means freeing the agent's worktree
  first if it holds the branch (`git worktree remove`), then `git checkout` in the main folder, and
  saying so; and while the player is testing there, nothing touches that checkout but docs commits
  on the same branch.

## Recovering from an interruption

**A limit or an outage stops every agent at once, and the pause's length decides what happens
next.** The player usually tries to hand the session off before a limit hits, so the next one starts
fresh at the reset, but not every limit is seen coming (woolly-finch 26).

1. **Run `tools/agent-status.sh` before touching anything.** It covers every worktree's branch,
   uncommitted files, how far it is ahead of and behind its own upstream (another session may have
   pushed to it), its PR's CI state, its brief file, and its credited agent's warm/cold verdict in
   one pass — across this checkout and any other local clone of the repo it is told about or finds
   from Codex's own session history, each block naming which one it is in, with a warning when the
   same branch is checked out in more than one. What it cannot show is where an agent stopped
   inside an item — for that, read its transcript's last tool calls, the file `agent-status.sh`
   named.
2. **Take the pause's kind from the player.** If they have not said, it is long when the
   agent's last request is older than the cache window less five minutes (see "A finished agent
   is not resumed after it has gone cold"), and brief otherwise.
3. **Brief pause: nudge each agent with `SendMessage`**: the limit is over, what its worktree
   and branch now hold if that moved, and continue. The cache is warm, so the agent's own
   context is the cheapest brief there is. **This changes no ownership** — the agent named on the
   brief is still the one working, so append nothing. **In Codex, check the live agent status:**
   `send_message` only queues a message and does not start an idle or interrupted agent's turn.
   Resume a warm idle or interrupted agent with `followup_task`; use `send_message` for a running
   agent. A queued reply is not evidence that work resumed.
4. **Long pause: replace each agent** in its own worktree, as "An agent that died mid-task is
   replaced in its own worktree" says, with a brief updated to what step 1 found, and its
   ownership updated the moment the replacement's id is known. Never resume a cold one.
5. **Tell the player what was found per agent and which way each went**, before waiting on any
   of them.

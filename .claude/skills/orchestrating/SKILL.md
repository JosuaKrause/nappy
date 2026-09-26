---
name: orchestrating
description: How implementation work is delegated to sub-agents — delegating is the default, isolated worktrees, one work item per agent, and what a task description must contain for the result to be mergeable. Loaded at session start because who does the work is decided before the first tool call.
---

# Orchestrating sub-agents

**When delegating a milestone, give the implementation agent an isolated git worktree;
the orchestrating session designs, specifies, reviews integration and maintains the queue.**
The split gives implementation fresh context and a fenced scope while orchestration retains
the whole queue and the player's words.

Use Sonnet in Claude Code for implementation, Haiku for a wait — polling a check, retargeting a PR,
removing a worktree, pulling `main` — and a stronger model when a milestone's geometry or contracts
warrant it, by judgement *(2026-09-11: "for wait tasks like this haiku makes more sense -- use your
judgement")*. **In Claude Code, drawing is Opus's**: an agent that makes or revises artwork — SVG,
PNG, a review sheet — runs on Opus, since the result is judged by eye and a weaker first pass costs
the player a review round *(2026-09-23: "what is the model making those images? use opus 5.5")*;
Codex has its own model hierarchy and keeps its own tiering for art *(2026-09-23: "make the opus
guidance claude only -- codex has a different model hierarchy here")*. In Codex, pick the subagent
tier by the task's remaining difficulty: see `references/codex-models.md`. The contract is the same
on either host: fresh context, a bounded scope and an isolated checkout for implementation. Create
the worktree explicitly if the tool does not create one. Read-only review can share a checkout. If
delegation is unavailable, do the bounded work locally and retain the same verification gate.

**A usage or quota limit is already over by the time the orchestrator hears of it**, in Claude
Code and in Codex alike. Nothing about delegation changes because of one: no fewer agents, no
cheaper models, no implementing locally to save quota. Do not carry a limit message from an
earlier agent or turn forward as a reason to do anything differently. *(2026-09-12: "when you see
usage limit errors that means they are already resolved. if the usage limit was reached you
wouldn't see anything."; 2026-09-22: "by the time _you_ hear of it the quota or usage is fully
restored so there is no need to change behavior due to it (ie no reducing agent usage or things
like that). quota limits happen from time to time.")* What an interruption does change is which
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
- **It is the queue or the archive.** `TODO.md`, `HANDOFF.md`, `DECISIONS.md` and the playtests are
  the orchestrator's, always — see "What the orchestrator keeps".

**Everything else is an agent's**, and a milestone that is not ready for one is a milestone whose
`TODO.md` entry is not finished yet. That is the same test the **playtest-feedback** rules already impose:
*somebody opening the repo cold could build the thing that was asked for.* Writing the brief until
an agent can take it is not overhead on top of the work — it **is** the orchestrating half of it.

**A milestone with an open design question is not ready for one.** The question goes to the player
first, and "draft and put back" items never go to an agent at all.

## The task description is the contract

A vague prompt returns work that cannot be merged.

**Before spawning, the orchestrator writes the brief verbatim to `.claude/briefs/<branch with
"/" replaced by "-">.md`.** The file opens with a header of `key: value` lines that
`tools/agent-status.sh` parses:

```
branch: feature/<thing>
worktree: /abs/path/to/worktree   (added once known)
agent: <agent id>                 (added after spawning; one line per agent, the newest last)
spawned: <ISO date>
```

Then a blank line, then the brief. Every later `SendMessage` that changes the agent's scope or
task is appended under `## Amendment <ISO date>`, so the file on disk stays what the agent was
actually told rather than what it was told at spawn time.

**Any agent started into an existing worktree gets its `agent:` line appended the moment its id
is known** — a fresh spawn and a replacement into a dead agent's worktree alike; see "An agent
that died mid-task is replaced in its own worktree" for the replacement case.

Every agent prompt contains, explicitly:

- **A read-first list, in order**: `CLAUDE.md`, the milestone's `TODO.md` section, the
  `DECISIONS.md` sections that carry its design, and the specific docs and source files it will
  touch. The agent starts cold; everything it needs must be named, not assumed.
- **The branch name** (`feature/<thing>`), and the committing rules restated: one commit per item,
  messages that explain why, docs move in the same commit as the code.
- **Commit and push after each item, and before starting any run that takes longer than a few
  minutes.** A WIP message is fine — **committing** already says a messy branch commit is fine.
  A usage limit or an API error kills the agent without warning, and the committed-and-pushed
  state is what survives it: `git log` on the branch shows where the agent stopped, and another
  session can see that and pick it up, rather than the state living only as uncommitted edits in
  a worktree that somebody has to find and diff by hand.
- **A scope fence**: the files it may touch, and the files it must not — always including
  `docs/TODO.md`, `docs/HANDOFF.md`, `docs/DECISIONS.md` and the playtests (queue maintenance and
  archiving belong to the orchestrator), plus anything another live agent owns. Two agents editing
  one file is a merge conflict scheduled in advance; when a shared file is unavoidable, tell each
  agent exactly which lines are theirs.
- **The verification gate is verify's**: `./tools/check.sh`, `./tools/pycheck.sh` and
  `./tools/lint.sh` where they apply, and the suites the change touches; the full suite is CI's,
  on the merge result, and a `PARTIAL RUN` marker is expected. **Say in the brief whether this is
  one of verify's two local-full-run cases** — an agent left to judge it will run the whole thing
  to be safe. A red PR goes back to the agent with the failing output.
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
  runtime installation.
- **Forks come back, never guessed.** If the design is ambiguous, or two recorded instructions
  conflict, the agent implements the unambiguous part and states the fork precisely in its report.
  Where the design is merely silent on a small detail, it chooses the smallest implementation
  consistent with the contracts **and says so in its report, which the PR description carries**,
  so the choice is visible and cheap to overturn. **A brief that contradicts a recorded
  decision is a fork too**, however explicit the brief is: when the brief asks for something a
  `DECISIONS.md` record or a doc's stated rule rules out, the agent builds nothing that overturns
  it and reports the clash, quoting both. *(2026-09-26: a brief asked for a used park to be fenced;
  M24's "It spoils with events, not by taking the ground away" said otherwise, and the agent
  rewrote that sentence instead of reporting it.)*
- **What the final report must contain**: per item, what was built and how it was verified; every
  choice made where the design was silent; every fork left open. The report is the merge review's
  input — an outcome it does not mention is an outcome that did not happen.
- **Do not merge, do not delete the branch.** After the report, the orchestrator commits the
  queue move on the PR branch (below), and then the PR goes to a review agent under **pr-review**,
  which checks that move with everything else. The move is the orchestrator's: it commits the
  `TODO.md` → `DECISIONS.md` move on the PR branch (the agent's silent choices recorded as open to
  overturn, not narrated as settled), merges only under **committing**'s permission rule, and
  retires the branch with `tools/prune-merged.sh`.

## Running agents in parallel

**One repo takes several agents at once when each works in its own git worktree** (spawn with
worktree isolation; each gets a full checkout under `.claude/worktrees/` and its own branch, and
the path-triggered rules hook works there unchanged). What makes it safe is not the worktrees —
merging is what collides — so parallelism is planned at the file level, before spawning:

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
  push and open its PR. Once merging is authorized, merge one at a time; a second PR merges as it
  stands unless the new `main` now conflicts with it, in which case the conflict is resolved on
  its own branch under **merging-main** — the ruleset's checks are not strict, so a PR merely
  behind `main` needs nothing. The semantic gate is `main`'s own CI run after the batch, which the
  orchestrator watches: a conflict between two PRs that touch different files passes both PRs'
  own gates and only shows up there. Then retire the branch with `tools/prune-merged.sh <branch>`
  from the main checkout (see **committing**), which removes the worktree and deletes the branch
  only once GitHub vouches for it. `tools/land-prs.sh <pr-number>...` is that sequence for several
  already-authorized PRs in one call: auto-merge, wait, bring a conflicting one up to date, then
  fast-forward `main` and prune, one PR at a time, printing `main`'s own CI run at the end as the
  check to watch.
- **The harness's own branches go with the same script.** Each spawn also leaves a
  `worktree-agent-*` branch pointing at the worktree's base. `tools/prune-merged.sh` deletes the
  ones whose worktree is gone, with `git branch -d`, and keeps a live agent's: that worktree has
  a feature branch checked out, so "is it checked out" says nothing about whether it is in use.
- **An agent branches from `main`, never from an open docs branch.** When a milestone's entry
  is still in an unmerged docs pull request, wait for it to merge before spawning rather than
  telling the agent to branch from the docs branch. That pull request reaches `main` as one
  squashed commit, so the agent's branch keeps the docs commits as ancestors `main` never had,
  and every docs file they touched conflicts when `main` is merged back — add/add for a new
  playtest file, content conflicts for `TODO.md` and `HANDOFF.md` — on files the agent never
  edited. The resolution is always `main`'s text, and it is still a three-way review each time.
- **Spawn from the main checkout, never from a worktree that has just been removed.** The
  harness resolves `HEAD` in the shell's current directory before it creates an agent's
  worktree, so a shell still standing in a deleted worktree fails every spawn; `cd` back to
  the repository's own folder after removing one.
- **A push that starts no CI run is re-triggered, not waited on.** `gh pr checks` answering
  "no checks reported" minutes after a push means no run exists, and auto-merge then waits
  forever on a check nobody is running; an empty commit on the branch starts one.
- **Tell each agent who else is alive** and which files those agents own, so a scope fence is a
  sentence in the prompt rather than a discovery in the diff.

## What the orchestrator keeps

- **The queue and the archive.** Agents never edit the queue or the archive; two writers on `TODO.md` is
  how a queue lies.
- **The queue as it stands on `origin/main`, not as it stood when the session started.** More
  than one session works this repository at once, and a design entry can be rewritten and merged
  while a brief is being written from the older text. Before briefing a milestone, `git fetch` and
  read its `TODO.md` entry on `origin/main`; a brief built from a stale entry produces work that
  contradicts a decision the player has already recorded, and the contradiction is only found at
  review. If `main` has moved, merge it into the branch before the next agent commit rather than
  after the last one.
- **The merge order** when agents run in parallel — overlapping areas run sequentially instead;
  disjoint file sets are what makes parallel safe in a single repo.
- **The player's questions.** An agent's fork, silent choice, or measurement lands back with the
  player through the orchestrator, in the entry where the next reader will look for it.
- **A finished agent is not resumed after it has gone cold.** Sending a follow-up to an agent
  that reported an hour ago replays its whole transcript at full price, because the prompt cache
  behind it has expired. *(2026-09-08: "resuming after an hour will be a huge token hit because
  the cache expires. at that point it's better to just start a new one.")* Resume only while the
  cache is live, and the windows are exact: **Claude Code's cache lasts one hour, Codex's twenty
  minutes** *(2026-09-08: "claude cache is 1h", "caching for codex is 20min only")*, counted from
  the agent's last request. **Resume only with five minutes to spare** — 55 minutes in Claude
  Code, 15 in Codex — since the clock is the provider's and not observable from here *(2026-09-08:
  "I would give like a 5min safety buffer")*. Past that, spawn a fresh agent with a
  self-contained brief that names the branch and the report to read first.
- **An agent that died mid-task is replaced in its own worktree.** A usage limit or an API
  error kills the agent and leaves every edit it made, usually uncommitted. Past the cache
  window *(2026-09-20: "don't let them continue because their cache is expired")*, start the
  fresh agent without worktree isolation, pointed at the dead agent's worktree path. The brief it
  needs comes from `.claude/briefs/<branch-slug>.md` — the file the orchestrator wrote before
  spawning, kept current by every amendment sent since; the previous session's transcript under
  `~/.claude/projects/` is only the fallback when no such file exists. Its replacement agent's
  prompt is "read `.claude/briefs/<file>`, then what changed: …", plus what the orchestrator
  verified on disk: which files are modified, what was never run, and where the dead agent
  stopped, read from its own transcript's last tool calls. Its first two steps are to commit the
  inherited work as it stands and to merge `origin/main`. Say plainly that nothing inherited has
  been reviewed, and that it may not even compile.

  **Starting the replacement includes updating ownership.** Right after spawning it, append
  `agent: <new id>` to the worktree's brief, and write the `worktree:` line if it is missing. If
  no brief exists, create one with the header and a pointer to where the original brief is.
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
- **The main checkout is the player's test bed.** Whatever the player is asked to try out is
  checked out in the repository's own folder before they are told it is ready — never left in an
  agent's worktree under `.claude/worktrees/`. *(2026-09-08: "always check out what you want me to
  test.")* That means freeing the agent's worktree first if it holds the branch (`git worktree
  remove`), then `git checkout` in the main folder, and saying so; and while the player is testing
  there, nothing touches that checkout but docs commits on the same branch.

## Recovering from an interruption

**A limit or an outage stops every agent at once, and the pause's length decides what happens
next.** The player usually tries to hand the session off before a limit hits, so the next one
starts fresh at the reset, but not every limit is seen coming. *(2026-09-22: "long pauses let the
cache expire which means we probably shouldn't let existing agents continue and start a new agent
with a precise updated prompt instead. if the pause was brief nudging the existing agents is
enough since the cache is still warm and they can just continue. usually, I'll tell you which kind
of interruption it was.")*

1. **Run `tools/agent-status.sh` before touching anything.** It covers every worktree's branch,
   uncommitted files, how far it is ahead of and behind its own upstream (another session may have
   pushed to it), its PR's CI state, its brief file, and its agent's warm/cold verdict in one pass.
   What it cannot show is where an agent stopped inside an item — for that, read its transcript's
   last tool calls, the file `agent-status.sh` named.
2. **Take the pause's kind from the player.** If they have not said, it is long when the
   agent's last request is older than the cache window less five minutes (see "A finished agent
   is not resumed after it has gone cold"), and brief otherwise.
3. **Brief pause: nudge each agent with `SendMessage`**: the limit is over, what its worktree
   and branch now hold if that moved, and continue. The cache is warm, so the agent's own
   context is the cheapest brief there is. **This changes no ownership** — the agent named on the
   brief is still the one working, so append nothing.
4. **Long pause: replace each agent** in its own worktree, as "An agent that died mid-task is
   replaced in its own worktree" says, with a brief updated to what step 1 found, and its
   ownership updated the moment the replacement's id is known. Never resume a cold one.
5. **Tell the player what was found per agent and which way each went**, before waiting on any
   of them.

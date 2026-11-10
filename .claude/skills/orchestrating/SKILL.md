---
name: orchestrating
description: How implementation work is delegated to sub-agents — delegating is the default, isolated worktrees, one work item per agent, what a task description must contain for the result to be mergeable, and that every brief and change keeps to designing-classes. Loaded at session start because who does the work is decided before the first tool call.
---

# Orchestrating sub-agents

The rules the orchestrating session must not miss, one line each; the sections below hold the detail.

- **Delegating is the default.** Code under `src/` or `tests/` is an agent's unless the design is
  still moving or the change is one sentence in one file with no test.
- **A design question that blocks goes to the player first**, before any agent.
- **The work keeps moving until none is left**: every startable item is briefed and spawned, which
  while the player has put one entry first means that entry's items only (inbox #1210 in
  gentle-owl), and a running agent is looked at at least every 45 minutes.
- **The queue is read from `origin/main`, after a fetch, before a brief is written.**
- **The model is the table's.**
- **One task per agent, in its own sparse worktree** from `tools/agent-setup.sh`, with its brief
  written to `.claude/briefs/` before it is spawned and its GitHub role named in it.
- **Parallel agents are split by files**, never by topic.
- **The queue and the archive are the orchestrator's**; nothing is committed into a worktree an
  agent works in, and no agent runs `git stash`.
- **An agent is resumed only while its cache is warm** (55 minutes in Claude Code); after that a
  fresh one is briefed. **A hook refuses, once, the resume of an agent that has grown too large**
  (inbox #1298 in merry-badger): a follow-up on its own pull request is sent again, new work goes to a fresh agent.
- **After a report**: the queue move, a review under **pr-review**, the merge and the retirement
  under **committing**, and a grade in `tools/agent-stats.py`.
- **A usage limit changes nothing about delegation.**

**When delegating a milestone, give the implementation agent an isolated git worktree;
the orchestrating session designs, specifies, reviews integration and maintains the queue.**
The split gives implementation fresh context and a fenced scope while orchestration retains
the whole queue and the player's words. It is the same on either host: fresh context, a bounded
scope and an isolated checkout for implementation. Read-only review can share a checkout. If
delegation is unavailable, do the bounded work locally and retain the same verification gate.

## The model table: which model does what

**The model for each kind of task is the table below**, and which model a task gets is chosen by
judgement (woolly-finch 15). The rows that cite the player's words hold where another row differs.
A stronger model than a row's takes a milestone whose geometry or contracts warrant it.

| Task kind | Model |
|---|---|
| A task that needs planning or complex reasoning | Fable is considered (inbox #1264 in olive-ferret) |
| A pull request labelled `fable-only`, a label put only on work the player names | Fable designs its code and reviews it; writing the code may go to another model (inbox #1293) |
| The review of anything Fable designed | Fable (inbox #1299) |
| Drawing: making or revising artwork, SVG, PNG or a review sheet | Opus (PLAYTEST-123 8) |
| Waiting on a merge or a check, polling | no agent: a timer or a script in a background shell, which costs no tokens (inbox #1070 in gentle-walrus, inbox #1072 in gentle-walrus) |
| Merging | the orchestrating session, with no agent spawned for it; an agent or a monitor may run a merge the session hands it (**committing**, "Merging") |
| Build at test parity | Sonnet |
| Build that changes play, or builds a seam from its design | Opus |
| Investigate an unexplained result | Opus |
| Measure: run a named probe batch into a fixed table, no conclusion | Haiku |
| Measure with interpretation: what is noise, what is real, what a picture shows | Sonnet |
| Capture named moments for a PR | Haiku, the pictures judged by the measurer or the reviewer |
| Review fixes | the builder, while warm and not near the limit |
| Review of a play-changing or design PR, of one that carries a drawing, or of a change to what a rule says | Opus |
| Review of queue, docs, a skill's wording alone or a small delta | Sonnet |

**In Claude Code, drawing is Opus's** (PLAYTEST-123 8), since the result is judged by eye and a
weaker first pass costs the player a review round; Codex has its own model hierarchy and keeps its
own tiering for art (woolly-finch 27). In Codex, pick the subagent tier by the task's remaining
difficulty: see `references/codex-models.md`. **Generating a raster is Codex's alone**: Claude Code
has no image generator (**illustrated-png**, its opening rules), so a brief whose work includes
generating an illustrated PNG, a comic transfer included, goes to a Codex agent (which writes as
`codex-coder`); the drawing rule above covers SVG and the review sheets. While Codex support is
frozen (inbox #901 in freckled-moose), such a brief waits for Codex to come back, and the player is
told. Installing, registering, rebaking and checking PNGs that already exist stays open to either
host.

**The two measuring rows differ by whether the task ends in a conclusion** (inbox #900 in
freckled-moose): Haiku fills a fixed table with the numbers Sonnet gets, and Sonnet reads more out
of a borderline result and out of a picture, so interpretation is Sonnet's. No side-by-side runs
are made as a routine: the counter's statistics decide, and a row they leave ambiguous may be
tested by running one task on both models (inbox #900 in freckled-moose).

**The orchestrator grades every finished agent with `tools/agent-stats.py add`** (kind, model, PR,
rounds, grade; `--redone` when it redid the agent's own conclusion), and the SubagentStop hook
(`.claude/hooks/agent-stats.py`) records the tokens and tool calls beside it; `summary` shows what
each kind and model cost and how it went. The data lives outside the repository, in
`~/.claude/nappy-agent-stats/` (inbox #900 in freckled-moose): a shared log in git would conflict
between parallel pull requests and need a PR per entry, so the code is checked in and the data is
not.

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

**A milestone with an open design question that blocks is not ready for one**: one where changing
course after the answer would be very costly (**board**, "Blocking, and no dialogs"; inbox #1194 in gentle-owl).
That question goes to the player first. An open question that does not block goes on the board and
the work goes to an agent at once, built on My pick, with the brief naming the pick as open to the
player's answer; a pick that would overturn something the player asked for is never built ahead of
their answer (**playtest-feedback**, "Never silently overturn a decision the player took"). "Draft and put back" items never go to an agent at all.

## Code is designed by layer

Every design, brief and change keeps to **designing-classes** — the player's principles, the
layering, dependency injection, a mode as configuration and derived state held by one object — and
a brief names the layer its work belongs to. The orchestrator reads **designing-classes** before
writing a brief for code work, and **writing-tests** before one that writes or changes tests (the
invoke table in `CLAUDE.md`).

## The task description is the contract

A vague prompt returns work that cannot be merged.

**A brief, a PR title and a record title name every part of a step, and never number or letter
it** (inbox #937 in plaid-penguin, inbox #941 in breezy-alpaca): "the route rig walking the building", not "part
B3", "slice 4" or "2a/4". A number is a lookup the reader performs.

**Before spawning, the orchestrator writes the brief verbatim to `.claude/briefs/<branch>.md`.**
`tools/agent-setup.sh <name> <branch>` makes the worktree, writes the file's header (`branch`,
`worktree`, `spawned`, which `tools/agent-status.sh` parses) and prints the spawn prompt; the task
goes under the header. **The shared half of a brief is a file, not a paste**:
`references/agent-contract.md` holds what does not change from one task to the next (the read-first
order, git and commit cadence, the identity, the scope fence over the queue and the archive, the
verification gate, headless first, forks, the report). **A brief carries what the contract cannot
know**: its task, its own read-first items, the layer its work belongs to, for work under `src/`,
`tests/` or `tools/` the ask for the architecture questions' answers, **the GitHub role the agent
acts as** (always, since an agent with no role named has nothing to check `status` against; which
role is **committing**'s), its fence, whether the evidence is a still or a burst, whether the
capture may be invincible, whether this is a local-full-run case, and a paragraph on the other live
agents and the files they own. `references/writing-a-brief.md` says what each of those must say
and how a task is sized so that it finishes well under an agent's limit: read it before writing a
brief.

Every later `SendMessage` that changes the agent's scope or task is appended to the brief under
`## Amendment <ISO date>`, so the file on disk stays what the agent was actually told. **Any agent
started into an existing worktree gets its `agent:` line appended the moment its id is known**
(`tools/agent-setup.sh --agent <branch> <id>`), a fresh spawn and a replacement alike.

**After the report**, the agent has not merged and has not deleted its branch. A red PR goes back
to it with the failing output. Then the orchestrator commits the queue's move on the PR branch — the
finished items' files deleted, the entry's folder too when its last item went, the decision record
written under the entry's name and any review item filed (**committing** says how), the agent's
silent choices recorded as open to overturn, not narrated as settled; the PR goes to a review agent
under **pr-review**, which checks that move with everything else; the orchestrator merges it and
retires its branch as **committing** says ("Merging", "Branches"), each write going out as the pull
request's own identity and not the session's. The brief is released first, once the agent's
processes have stopped and its useful artifacts are kept (`tools/agent-setup.sh --release
<branch>`); retirement refuses an unreleased brief.

## Running agents in parallel

**Each implementation agent works in a sparse worktree made with `tools/agent-setup.sh <name>
<branch>`** (busy-ibis 3): under `.claude/worktrees/<name>`, on a new branch from `origin/main`,
without the evidence archive, the reference photos and the style references unless `--include`
adds a folder back. The agent is started in it. **The Agent tool's own worktree isolation is not
used**, unless a task needs the folders the sparse checkout leaves out: it makes a full checkout.
A review agent's scratch checkout is `tools/agent-setup.sh --detach <ref> <name>`.
**A low-disk warning from a tool, or a check that leaves less than the reserve, stops new work**
(quiet-yak #496): the orchestrator starts no new agent or worktree until the space is sorted out by
**session-cleanup**'s storage steps. `references/worktrees-and-disk.md` holds how the worktree is
made, the disk check and what an agent does on a warning: read it before making a worktree by any
other route, before a batch of several checkouts, imports, builds or captures (each tool checks
only its own call, so the batch as a whole is checked by whoever starts it), and on any disk
warning.

**One repo takes several agents at once when each works in its own worktree.** What makes it safe
is not the worktrees — merging is what collides — so parallelism is planned at the file level,
before spawning:

- **Partition by files, not by topic.** List what each milestone will touch and spawn together
  only sets that are disjoint. Docs count: two agents "on different features" that both rewrite
  `docs/MECHANICS.md` are one merge conflict split across two reports.
- **A shared file gets line-level ownership or a sequence.** Tell each agent exactly which
  lines or blocks are its own; when that carve-up cannot be stated, run those milestones
  sequentially instead.
- **Overlapping the event catalogue, `tuning.gd` or a shared test file means sequential.** Those
  are the repo's convergence points; two agents adding rows or checks to the same file will not
  auto-merge.
- **Merging follows committing** ("Merging": the gates, the auto-merge flow and the wait that
  confirms it). As each agent lands, its PR is reviewed and merged in turn, without waiting for
  `main`'s CI between merges; `main`'s CI run on the last merge commit of the batch is the
  orchestrator's to watch.
- **An agent branches from `main`, never from an open docs branch.** When a milestone's entry
  is still in an unmerged docs pull request, wait for it to merge before spawning: that pull
  request reaches `main` as one squashed commit, so a branch made from the docs branch meets
  `main`'s copy of every docs file when `main` is merged back, and an item file it deleted comes
  back without a conflict (`references/worktrees-and-disk.md`, "Branching from a docs branch").
- **Spawn from the main checkout, never from a worktree that has just been removed**: `cd` back
  to the repository's own folder after removing one, since a shell still standing in a deleted
  worktree fails every spawn (`references/worktrees-and-disk.md`, "The worktree").
- **The orchestrating session never moves its own workspace while a sub-agent runs**: no
  `EnterWorktree`, nor any other call that switches the session into a worktree, since the switch
  reaches every agent of the session and the harness then refuses each one's commands in its own
  worktree, reads included. It writes on a branch from the main checkout, by absolute paths
  (`references/worktrees-and-disk.md`, "The session stays in the main checkout").
- **A push that starts no CI run is diagnosed, not waited on**: `references/recovery.md` says how.
- **Tell each agent who else is alive** and which files those agents own, so a scope fence is a
  sentence in the prompt and not a discovery in the diff.

## What the orchestrator keeps

- **The work moving, until there is none left** (inbox #1196 in gentle-owl). The orchestrating session ends only
  when no task is left to start or advance. While agents run, it briefs and spawns every queue item
  it can start whose files the running agents do not own; holding startable work back, to limit
  the reviews to come or for any other reason, is stopping early. **While the player has put one
  entry first, startable means that entry's items only** (inbox #1210 in gentle-owl), until that entry closes:
  its `README.md` says so, and work on another entry before it is done is work done twice, on code
  about to change. The up-next marker (`docs/TODO.md`) orders the queue and fences nothing, and the
  end-of-session pass drops it from an entry open pull requests are building, so the fence is the
  README's sentence. **Once everything startable is
  running, it ends its turn to wait for the agents** (inbox #1196 in gentle-owl): their reports wake it, and
  waiting that way is not ending the session. A report to the player goes out along the way, never
  as a stopping point. A running agent or a
  pull request still to review or land is a task to advance, so the session stays open while one
  is left. A task that waits only on the player, a blocking board question or a review item, does
  not keep the session open, since nothing this side can advance it.
- **A wait is checked at least every 45 minutes** (gentle-owl #1255). While a sub-agent runs,
  the orchestrator looks at it at least every 45 minutes (its output, its worktree and its
  pushes) for signs it is stuck: no new commits, a loop that has stopped improving, a wait with
  no end. The completion notice alone is not enough, since an agent that is stuck never sends
  it. No wait of the orchestrator's own runs past 45 minutes without such a check. The check is a
  recurring job about every 30 minutes, since a scheduler can fire up to half its period late, and
  the job is deleted when no agent is left running. It is not a tick in the sense of the agent
  contract's one-notification rule, which keeps a wait from ending a turn on every minute.
- **The queue and the archive.** Agents never edit the queue or the archive; two writers on one
  entry is how a queue lies.
- **The queue as it stands on `origin/main`, not as it stood when the session started.** More
  than one session works this repository at once, and a design entry can be rewritten and merged
  while a brief is being written from the older text. Before briefing a milestone, `git fetch` and
  read its entry's folder on `origin/main`; a brief built from a stale entry produces work that
  contradicts a decision the player has already recorded, and the contradiction is only found at
  review. If `main` has moved, merge it into the branch before the next agent commit, not after the
  last one. **What is next is `tools/queue.sh` run on that checkout**: it prints the
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
  **A hook holds this at the resume** (inbox #1291): `.claude/hooks/resume-guard.py` refuses, once,
  a `SendMessage` to a sub-agent whose context is past the size `references/writing-a-brief.md`
  gives for a resume, or whose context the harness has compacted on its own, naming which. That
  size is above the limit a task is scoped to, since an agent may go a bit over now and then
  (inbox #1291), and it comes earlier than the reassessment of an agent, since it is about resuming;
  neither it nor the limit counts turns (inbox #1298 in merry-badger). **The refusal asks one question: is the
  message a follow-up on the agent's own pull request, or new work** (inbox #1298 in merry-badger)? A follow-up (a
  delta review, review or CI fixes, a merge of `main`, an instruction to stop or wrap up) is sent
  again and the same message passes, since a job that short costs less on the agent that knows the
  pull request than on a fresh one. New work (the next step, the next pull request, another task)
  goes to a fresh agent briefed from the brief file and what this one left. The reassessment of an
  agent near 500k tokens applies on top (inbox #1298 in merry-badger).
- **A task is scoped to stay under the limit by construction, never policed** (inbox #896 in plaid-raven). A brief
  carries no size line asking the agent to count its turns or tokens, and the orchestrator does not
  watch an agent's count while it runs, since either spends tokens on bookkeeping instead of the
  work (the hook above reads the agent's size only when a message is sent, and spends none); the
  orchestrator sizes every task before spawning it so that it finishes well under the limit.
  `references/writing-a-brief.md` says where the limit falls and how a task is cut to it (one kind
  of work per agent, one mechanism per build, a fresh agent per pull request of a split plan).
- **A warm agent is reused while rebriefing would cost more** (inbox #896 in plaid-raven). Briefing a fresh agent
  costs tokens too, so follow-up work on a pull request (review fixes, the next step of the same
  change) goes back to its agent while it is warm (the cold-resume rule below) and not huge, which
  saves the rebriefing; past the size a resume is refused at, only a follow-up on the agent's own
  pull request still saves it, which is the question the hook's refusal asks. What the orchestrator is told for free, such as the token count in
  an agent's finishing notification, is used: it says whether the agent is far enough under the
  limit to reuse, and how the next brief should be sized.
- **A finished agent is not resumed after it has gone cold.** Sending a follow-up to an agent that
  reported an hour ago replays its whole transcript at full price, because the prompt cache behind
  it has expired (woolly-finch 5). Resume only while the cache is live, and the windows are exact:
  **Claude Code's cache lasts one hour, Codex's twenty minutes** (woolly-finch 6), counted from the
  agent's last request. **Resume only with five minutes to spare** — 55 minutes in Claude Code, 15
  in Codex — since the clock is the provider's and not observable from here (woolly-finch 7). Past
  that, spawn a fresh agent with a self-contained brief that names the branch and the report to read
  first.
- **An agent that died mid-task is replaced in its own worktree**, past the cache window
  (woolly-finch 22): a fresh agent, briefed from the brief file and what is on disk, whose first
  steps are to commit the inherited work and merge `origin/main`. `references/recovery.md` holds the
  steps, and is read before replacing one.
- **Nothing is committed into a worktree an agent is working in.** Queue docs, a merge of
  `main`, a fix the player wants urgently: wait for the agent's report, or do the work on a
  branch of its own from `main` and tell the agent what it will touch, so the later merge is
  small.
- **No agent runs `git stash`**, the orchestrator included: `refs/stash` is one stack shared by
  every worktree of the repository, and the agent contract ("Git") says what is done instead.
- **The main checkout is the player's test bed.** Whatever the player is asked to try out is checked
  out in the repository's own folder before they are told it is ready — never left in an agent's
  worktree under `.claude/worktrees/` (woolly-finch 8). That means freeing the agent's worktree
  first if it holds the branch (`git worktree remove`), then `git checkout` in the main folder, and
  saying so; and while the player is testing there, nothing touches that checkout but docs commits
  on the same branch.

## Recovering from an interruption

**In-flight state is kept where a fresh session finds it** (inbox #986 in brisk-pelican): the
repository, the pull requests and issues, the board, the briefs, and the local
`.claude/restart-prompt.md` for the orchestrator's own working state (which pull request waits on
what, which review is next, what a builder was told). That file is written during the session
whenever it is cheap, not only at the handover (**session-cleanup**, step 8); the board is the
player's information and answer channel, updated in batches (**board**). A session cleared,
compacted or cut off must be able to carry on from these alone.

**A limit or an outage stops every agent at once, and the pause's length decides what happens
next** (woolly-finch 26): after a brief pause each agent is nudged, since its cache is warm; after a
long one each is replaced by a fresh agent in its own worktree. The player usually says which kind
it was, and usually hands the session off before a limit hits, though not every limit is seen
coming. **Run `tools/agent-status.sh` before touching anything**, then follow
`references/recovery.md`, which holds the steps for both kinds of pause and for a single dead agent.

## Proposed, not asked for

The rules in this file that are the filer's proposal or reading, not the player's words, each open
to the player's correction:

- **Every row of the model table that carries no citation**, the merging row and the two build
  rows among them, to be revised once the agent counter holds enough entries (inbox #900 in
  freckled-moose). The player asked for a granular table revised after experiments or statistics,
  and for Haiku to be tried on captures and measuring.
- **That a stronger model than a row's takes a milestone whose geometry or contracts warrant it**
  ("The model table"); the player's words are that the model is chosen by judgement
  (woolly-finch 15).
- **That a review of a change to what a rule says goes to Opus** and a skill's wording alone to
  Sonnet ("The model table").
- **That a pull request that carries a drawing is reviewed by Opus** ("The model table"); the
  player's words are about the model that makes the drawing (PLAYTEST-123 8), not the one that
  reviews it.
- **That a brief names the layer its work belongs to** ("Code is designed by layer"), made in
  **designing-classes** (plush-kestrel).
- **That a task waiting only on the player does not keep the session open** ("What the
  orchestrator keeps"; the rule it qualifies is inbox #1196 in gentle-owl).
- **That the orchestrating session never moves its own workspace while a sub-agent runs**
  ("Running agents in parallel"), with the way it writes on a branch instead and the way back
  from a switch (`references/worktrees-and-disk.md`): the filer's fix of a gap in this skill.
- **That the 45-minute check is a recurring job about every 30 minutes**, and the reading that it
  is not a tick under the contract's one-notification rule (the rule is gentle-owl #1255).
- **How the resume hook remembers and words its refusal** ("What the orchestrator keeps"): the
  filer's design. The player's are the hook itself, refusing the resume of an agent that has
  compacted automatically or grown too large (inbox #1291), the size it refuses at, that nothing
  counts turns, and the question the refusal asks, with a follow-up sent again and new work given
  to a fresh agent (inbox #1298 in merry-badger). Proposed: that a refusal is remembered for one sender, one target
  and one message text, so that only the very same message passes when sent again; which jobs the
  refusal lists as a follow-up and as new work; and that the hook refuses at the first token past
  the number.
- **How the player's other words on agent size bear on the refusal** ("What the orchestrator
  keeps"): the orchestrator's reading. Read as: the room to go a bit over now and then
  (inbox #1291) is the distance between the limit a task is scoped to and the size a resume is
  refused at, and a resend to an agent near 500k tokens waits for its reassessment (inbox #1298 in merry-badger).

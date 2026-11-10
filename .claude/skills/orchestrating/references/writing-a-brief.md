# Writing a brief

What a brief's file looks like, what each thing it adds to the agent contract must say, and how a
task is sized. **orchestrating** keeps the rules (the brief is written to its file before spawning,
the shared half is `agent-contract.md`, the role is always named, one task per agent sized under
the limit); read this before writing a brief.

## The file

`tools/agent-setup.sh <name> <branch>` makes the worktree and writes the header of
`.claude/briefs/<branch>.md` (a `/` in a branch name becomes `-` in the file's); the task goes
under it. The header is `key: value` lines that `tools/agent-status.sh` parses:

```
branch: feature-<thing>
worktree: /abs/path/to/worktree   (added once known)
agent: <agent id>                 (added after spawning; one line per agent, the newest last)
spawned: <ISO date>
```

Then a blank line, then the brief. The spawn prompt `agent-setup.sh` prints names the brief and the
contract. Every later `SendMessage` that changes the agent's scope or task is appended under
`## Amendment <ISO date>`, so the file on disk stays what the agent was actually told and not what
it was told at spawn time.

## What a brief adds to the contract

- **The task, and its own read-first items**, by path: the entry's folder under `docs/todo/`, the
  records under `docs/decisions/` that carry its design (`tools/decisions.sh` finds them), and the
  specific docs and source files it will touch. The agent starts cold; everything it needs must be
  named, not assumed.
- **The GitHub role the agent acts as**, always: an agent with no role named has nothing to check
  `status` against. Which role follows what the pull request will contain, and is **committing**'s
  to say ("Who a commit and a pull request are from").
- **A scope fence**: the files it may touch, and the files it must not. The queue and the archive
  are fenced by the contract; the brief adds anything another live agent owns. Two agents editing
  one file is a merge conflict scheduled in advance; when a shared file is unavoidable, tell each
  agent exactly which lines are theirs.
- **A paragraph on the other live agents** and the files they own, written by hand from the
  briefs' fences (they are prose, so nothing generates it).
- **The layer its work belongs to**, and for a pull request that changes `src/`, `tests/` or
  `tools/` the ask for the architecture questions' answers (**pr-review**'s
  `references/architecture-questions.md`) in the report and the description.
- **Whether this is one of verify's two local-full-run cases.** An agent left to judge it will run
  the whole thing to be safe. Only those two count: a change that is large or touches many files is
  not one by its size, since CI runs the same suite on a better tree, and a local full run is a
  wait long enough to go to the background, which notifies the orchestrating session and the player
  (inbox #870 in minty-dolphin). A brief copied from an earlier one is checked for this line, not
  inherited.
- **Whether the evidence is a still or a burst.** Anything about motion — a turn, a gait, a wing
  beat, a shadow rotating — is a burst (`--press snapshot_burst <seconds>` on the same `shot.sh`
  call, see **verify** and **session-captures**), and an agent told to take a screenshot of motion
  will spend its budget on stills that land beside the moment.
- **Whether the capture may be invincible.** `--invincible` keeps the day running while a rig waits
  for a junction, a chase or a crossing to happen in front of it, where a rig left to itself dies
  to the meter or the clock before the moment arrives; an agent not told about it will burn runs
  landing on the summary screen. Leave it off only for a capture whose subject is a cost or a loss.
- **Scratch paths and who cleans them up**, for a task that writes outside the repository
  (**session-cleanup**'s job-owned storage rules).

## Sizing the task

The player's rules are **orchestrating**'s: an agent stays on one task and no agent grows huge
(inbox #874 in minty-dolphin), a task is scoped under the limit by construction and never policed,
and a warm agent is reused while rebriefing would cost more (inbox #896 in plaid-raven). Where the
limit falls and how a task is cut to it:

- The limit is about 300k tokens of context, and no limit counts turns (inbox #1298 in merry-badger). Every turn
  re-reads the whole context, so an agent's cost grows much faster than its length: two agents that
  each end at half the size cost well under one that ends at the whole.
- A resume is refused once past 400k tokens of context (inbox #1298 in merry-badger), the context being what the
  agent's latest turn read. It is a second, higher number on purpose: the limit above is where a
  task is scoped to finish, an agent that ran a bit over it is still resumed unasked, and a resume
  is refused earlier than an agent is reassessed (inbox #1298 in merry-badger). `.claude/hooks/resume-guard.py`
  reads the number out of this item's first sentence and reads no other, so it is written nowhere
  else and that sentence keeps its form (`tools/test_resume_guard.py` fails when the hook cannot
  read it).
- One kind of work per agent: building, measuring (long probe runs, many-seed statistics) and
  capturing pictures are separate agents on the one pull request, each briefed from the brief
  file, the review threads and what the one before it left. A measurement
  or a capture is what makes an agent huge, since every run's output stays in its context.
- One mechanism per build: a change that reaches several mechanisms, or whose reading list runs
  past a handful of files, is split into pull requests, or into agents on one pull request.
- The brief names every probe, suite and evidence rig the work needs, with its command, so no
  turns go on finding them.
- A cold agent's follow-up goes to a fresh agent briefed from the brief file, the review threads
  and what the one before it left, and so does new work for an agent past the size a resume is
  refused at (**orchestrating**, "What the orchestrator keeps").
- A builder stays with its pull request through merges of `main` while it is warm
  (**orchestrating**'s cold-resume rule), since that work reuses the context it built.
- A plan split across several pull requests is built by a fresh agent per pull request, each
  briefed with its part, not by the agent that wrote the plan.
- A brief names the files and the records to read and does not ask for the whole history,
  so a fresh agent's start stays small.
- A reviewer is fresh per pull request and is resumed, while warm, for that pull request's
  delta reviews.

## Proposed, not asked for

The rules in this file that are the filer's proposal, not the player's words, each open to the
player's correction:

- **Every line of "Sizing the task" that carries no citation**: the player asked that a task stay
  under the limit by construction (inbox #896 in plaid-raven), and how a task is sized to it is
  proposed. Where the limit falls is the filer's number, which the player's answer on the resume
  leaves standing; that no limit counts turns, and the size a resume is refused at, are the
  player's (inbox #1298 in merry-badger).
- **That a brief names the layer its work belongs to**, made in **designing-classes**
  (plush-kestrel).

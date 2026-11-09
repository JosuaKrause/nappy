# sandy-alpaca — The orchestration skills after the rules review: the contract said once, committing owns identity and merging, a short tool catalogue, Fable in the model table · 2026-11-09 · not from an entry

**The ask.** The player had a review made of every rule file ("have another fable agent review all
skills/claude/rule files", inbox #1267), read its summary, and said "let's do all the suggested
changes for the hooks/skills/claudes etc", "four PRs is fine with me -- can we parallelize?" and
"for the rule/skill/claude changes I want fable to do it directly" (inbox #1267). The work was split
by files into four pull requests. This record is the one for the skills the orchestrating session
and every builder work under: orchestrating with its agent contract, committing, and using-tools,
the catalogue of what each entry point under `tools/` is for.

## What the review found in these skills

- **A builder was told to read about 280 KB of rules.** The agent contract sent every builder to
  the verify, committing and using-tools skills, which are written for the orchestrator (releases,
  merge rulesets, the whole catalogue); most builders did not read them.
- **The orchestrating skill restated the agent contract bullet by bullet**, and the two copies had
  drifted: on a choice where the design is silent, on who names the role, and on draft or ready.
- **The same rule in several files:** which GitHub identity writes what, what the write guard
  denies, and how a merge goes, each stated at length in two or three of these files and in
  others.
- **Four answers to "which model":** "Haiku for a wait" stood first, although the player's later
  word is that a wait is polled by a script and not an agent.
- **The tool catalogue restated each tool's help**, row by row, and its trigger ("before running
  a sequence of shell commands by hand") was always or never.
- **Sentences no longer true:** rules for a branch still on the single-file queue; branches named
  with a slash where nearly every real branch has a dash; the harness's own worktree isolation
  described as the normal case.

## What was built

- **The agent contract carries what a builder needs**: verify's commands, how a red CI shard is
  replayed, "run `tools/<name> --help`" for a tool the brief names, and what committing asks of a
  builder. It no longer sends a builder to three skills, and `CLAUDE.md` is off its read-first
  list, since the harness gives it to every sub-agent.
- **The contract is said once.** The orchestrating skill keeps what a brief adds to it, in a
  paragraph and in a reference file on writing a brief. The three drifts are settled: the later
  rule on silent choices stands (inbox #1232 in gentle-owl, inbox #1234 in gentle-owl); the orchestrator always names
  the role and an agent whose brief names none chooses by what the pull request will contain;
  finished work opens a ready pull request and a draft is for unfinished work.
- **committing owns identity, the write guard and merging**; every copy in these files is a
  sentence naming it. The merge is a numbered flow, and the two rulesets are explained once, in a
  reference file.
- **The model table owns "which model"**, in a section of its own. The player's words on Fable are
  in it (inbox #1264): Fable is considered for a task that needs planning or complex reasoning; the
  design that code is built from is Fable's, a seam's design included; code built from a Fable design is built by the model the orchestrator chooses;
  a change to a rule file is done by Fable directly. A wait is no agent's (inbox #1070 in gentle-walrus).
- **Text handed to a write goes through a file in a fresh directory**, never a fixed name under
  `/tmp`: committing has the three-call sequence and why each call stands alone.
- **Each catalogue row says what a tool is for, when to reach for it, and which skill holds the
  detail**; flags, numbers and refusal lists are the tool's help. A sentence a tool's help does not
  say stays in its row. The trigger is: a tool is needed for a job and its name is not known, or a
  manual sequence is about to be repeated.
- **Branches are `feature-<thing>`**; the old single-file queue's rules are gone; the harness's
  worktree isolation is named once as the exception.
- **Each skill opens with its must-see rules and ends with one list of what is the filer's
  proposal**; detail read only for one kind of moment is in reference files (writing a brief,
  worktrees and disk, recovery from an interruption, visual attempts; releasing, the rulesets, the
  write guard, attachments).

## Where the review was wrong

- It read the two sentences on who names the role as a drift. They bind different readers, so
  both stay.

## Choices made in the rewrite, open to the player's overturn

- **Who reviews a change to a rule, or a drawing:** a pull request that changes play or carries a
  design, one that carries a drawing, and a change to what a rule says are reviewed by Opus; a
  skill's wording alone by Sonnet. Listed in the skill as a proposal; it reconciles pr-review's "a
  stronger model" with the table's row for skill wording.
- **Merging has a row of its own**, uncited: the orchestrating session merges, with no agent
  spawned for it, and an agent or a monitor may run a merge the session hands it, as committing
  has it. The player's word that a wait is polled by a script covers waiting and polling only.
- **Code built from a Fable design is built "by the build rows below"**, the filer's reading of
  the orchestrator's choice the player left it.
- **"A rule file" takes in a hook's text**, marked as a reading: the player's words name rule,
  skill and `CLAUDE.md` changes.
- The catalogue rows for the two old-queue tools are cut to a line and kept, since the tools exist.
- Three sentences describe what the sibling pull request for the hooks adds (a review checkout's
  removal, a released brief going with its branch, a hook naming the skills that govern a file and refusing the first
  edit there until they are read),
  and one what the sibling pull request for the domain skills adds (the illustrated-png skill says
  in its opening rules that Claude Code has no image generator, which is where orchestrating now
  points for it).

## History taken out of the skills

Kept here word for word, each with the rule it stood beside.

**orchestrating, which model:**

> Use Sonnet in Claude Code for implementation, Haiku for a wait — polling a check, retargeting a PR, removing a worktree, pulling `main` — and a stronger model when a milestone's geometry or contracts warrant it, by judgement (woolly-finch 15).

What the player's words still carry stays with its citation: which model a task gets is chosen by
judgement. That a stronger model takes a milestone whose geometry or contracts warrant it is the
skill's own clause, kept without the citation and listed in the skill's closing list as the filer's
proposal. "Haiku for a wait" is overturned by the player's word that the
wait after a merge is polled by a script, not an agent (inbox #1070 in gentle-walrus).

**orchestrating, the measuring rows of the model table:**

> The measuring rows follow one comparison (inbox #900 in freckled-moose): Haiku and Sonnet ran C2b's measurements, pictures and conclusion on one brief. Their numbers matched exactly; Sonnet called a borderline rise unresolved where Haiku called it flat, and saw the change in three picture pairs where Haiku saw one, at about 10% more tokens. No further side-by-side runs are made for now: the counter's statistics decide, and a row still ambiguous after a week of them, from 2026-11-01, may be tested by running one task on both models again (inbox #900 in freckled-moose).

**orchestrating, the forks rule's older sentence:**

> Where the design is merely silent on a small detail, it chooses the smallest implementation consistent with the contracts **and says so in its report, which the PR description carries**, so the choice is visible and cheap to overturn.

**committing, auto-merge confirmed at no cost in tokens:**

> The player said to check back later that it went through and that a timer is enough (inbox #1068 in gentle-walrus); then that a fixed timer was overly safe, and to estimate better, undershoot a little and poll the rest with a script, not an agent (inbox #1070 in gentle-walrus). That overturns the player's earlier word that a timer needs no polling (inbox #1068 in gentle-walrus) for the tail after the estimate only; the player's word that no polling monitor is wanted just to trigger the merge (inbox #1068 in gentle-walrus) stands. The script meets the rule now:

**committing, who writes as `claude-orchestrator`:** "its merge once the player has said go".

**committing, the standing permission reaching the classifier:**

> The classifier reads `CLAUDE.md`, yet writes its standing permission covered were refused until the player's settings carried it, so `CLAUDE.md` and the skills are not relied on as the player's consent.

**committing, the ruleset dismissing stale approvals:** "(the player set it on 2026-11-04,
inbox #1068 in gentle-walrus;".

**committing, "a fix on `main` is not a fix on the site":** "A release has carried a game-ending bug
before (`tools/decisions.sh M73`)."

**committing, "Branches":** ", and converting a branch still on the old single-file queue with
`tools/convert-queue-edits.py`".

**The agent contract, the picture a by-eye question gets:** "*The form PR #750 used, open to the
player's correction:*".

**using-tools, the row for `convert-queue-edits.py`:**

> On an open PR from before the queue was files, after `git merge --no-ff --no-commit origin/main` meets the three files, whether it conflicts or not. `tools/update-pr.sh` and `tools/land-prs.sh` refuse such a branch before merging it, naming the files (`tools/lib_old_queue.sh`), since git can merge an old-format edit cleanly into the new short files; convert by hand in the PR's worktree — merge, this, the merging-main review, `lint.sh`, commit, push — then run `land-prs.sh` again.

**using-tools, the row for `migrate-queue.py`:**

> Only while a branch still meets a `main` in the old format: mid-merge, `--rev MERGE_HEAD --replace` takes `main`'s old files and re-runs it rather than merging them by hand.

**using-tools, the disk reserve:** "(3 GiB by default, about where the player's disk warnings
appeared)".

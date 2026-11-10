# leafy-dolphin — The rules are delivered: a hook names the skills for a file and the first edit waits, with the hook rows complete and the orchestrating session defined · 2026-11-09 · not from an entry

**The ask.** The player had a review made of every rule file ("have another fable agent review all
skills/claude/rule files", inbox #1267 in olive-ferret), read its summary, and said "let's do all the suggested
changes for the hooks/skills/claudes etc", "four PRs is fine with me -- can we parallelize?" and
"for the rule/skill/claude changes I want fable to do it directly" (inbox #1267 in olive-ferret). Shown the six
picks the summary ended with, the player took them with that go-ahead; three are built here: the
first edit in an area is refused until its skills are read; the orchestrating session is defined;
branches are named with a dash. The work was split by files into four pull requests. This record is
the one for the machinery: `CLAUDE.md`, the hooks that load the rules and lint the docs, and the
tools around them.

## What the review found

- **The rules did not load themselves.** The harness shows a hook's output inline only up to about
  ten thousand characters; anything larger is replaced by its first two thousand and a file path. Of
  the last 96 rule injections the review counted, 83 were replaced that way, the orchestrating
  skill's at every session start among them, and no edit of game code had ever had its rules inline.
- **Every sub-agent's first code edit pulled in the orchestrating skill**, which is about how to
  delegate: the session-start hook that marks it as delivered does not run for a sub-agent.
- **The post-edit doc lint did not fire in an agent's worktree**, where agents work, and the
  reference files under a skill were outside the lint.
- **Hook rows that could never fire** (a PNG, a WAV: the edit tools cannot write them), **files
  with rules and no row** (the files that draw the danger cues, the files that hold the balance
  numbers, the hooks themselves, the decision records, the CI workflow), and no test comparing
  `CLAUDE.md`'s table with the hook.
- **"The orchestrating session" was never defined**, though it holds the merge permission, the
  board and the restart prompt.
- **Nothing sanctioned removed a review agent's checkout or a finished agent's brief.**

## What was built

- **The rule hooks print an index, never a skill's text**: each governing skill's name, path, size
  and the opening clause of its description, one line each. The path hook refuses the first edit in
  an area with that index as the reason and lets the same edit through when it is made again. A
  sub-agent has its own markers; a second area is refused in its turn; after a compaction, a resume
  or a clear the main session's markers are cleared, so each of its areas is refused once more.
  Nothing watches whether the skills were read: making the edit again is the session's statement
  that they were. A path is matched as the file it reaches, with its `.` and `..` parts taken out,
  so `docs/../src/events/a.gd` is named what `src/events/a.gd` is.
- **A sub-agent is not handed the orchestrating skill** for an edit under `src/` or `tests/`.
- **The doc lint follows the edited file's own checkout**, and the lint governs every Markdown file
  under `.claude/skills/`.
- **The hook's rows are one table in `CLAUDE.md`'s notation, and a test compares the two row for
  row.** New rows: the four files that draw the cues, the six that hold the balance numbers, the
  reference tools, the atlas membership file, evidence folders to session-captures beside verify,
  Godot's scene, shader and project files, the settings file and the decision records to
  committing, the CI workflow to verify. The rows that could not fire are gone, and the tools that
  write such files print a one-line pointer to their skill.
- **`CLAUDE.md` defines the orchestrating session** (the top-level session the player started to
  run the queue; a sub-agent never is; a second top-level session only when the player says so),
  names the board in its pick-up list, and holds the rule about a picture pasted into the
  conversation, which no edit hook can deliver.
- **`tools/agent-setup.sh --remove <name>` removes a clean detached review checkout**, refusing
  anything else, and **`tools/prune-merged.sh` deletes a released brief** when it retires its
  branch. **`--remove` never takes the only copy of a commit**: a commit made in a detached
  checkout is on no branch, `git status` calls the checkout clean, and the worktree's own `HEAD`
  reflog, which goes with the worktree, is all that names it. So `--remove` refuses a checkout
  whose `HEAD` is at, or has been at, a commit no ref reaches, names each such commit and says that
  a branch at it keeps it. The commit the checkout was made at is exempt, so a stale review
  checkout of a pull request whose branch is deleted is still removed.

## What was not built

- **The allow line for `--remove` is not in `.claude/settings.json`.** The permission system
  refused the agent's edit of the settings file as a change to its own permissions. The line is the
  player's to add beside the two prune lines: `"Bash(tools/agent-setup.sh --remove:*)"`. Until then
  the command asks before it runs.
- **The backlog of old briefs is not swept**: a brief whose branch was already gone is never
  visited.
- **The hook scripts under `.claude/hooks/` have no row.** The builder gave them to committing,
  which covers the write guard and says nothing about the other hooks; the pull request's review
  found that an edit of one was refused until a long skill was read that does not mention it. A
  row naming a skill that does not cover its path costs a read and delivers no rule, so the row
  went (the orchestrator's ruling, open to the player's overturn). What a hook change owes, its
  cases in `tools/test_rules_hooks.sh` and the table in `CLAUDE.md` kept in step, is said in
  `CLAUDE.md`. `.claude/settings.json` keeps its row to committing, which holds what its allow
  lines must be.

## Known limits

- **Nothing watches whether the skills were read.** Once the window after a refusal is over, any
  edit of the area passes: the refused edit made again, or an edit of another file there, read or
  not. The refusal makes the read the next step; it cannot prove the step was taken.
- **A sub-agent that compacts is not refused again.** The markers are cleared by the session-start
  hook, and the hooks documentation gives a sub-agent `SubagentStart`, when it is spawned, and
  describes `SessionStart` as a session's. Wiring another event needs a line in
  `.claude/settings.json`, which is the player's file. So "refused once more after a compaction"
  holds for the main session only, and a long-running builder is where a skill read early is gone
  later.

## Choices made, open to the player's overturn

- **The Codex adapter still gets the skills' text.** Its tests call the real hooks and expect the
  text, and the adapter is frozen, so both hooks keep the old output for a Codex session.
- **An edit within two seconds of a refusal is refused too**, since the calls of one message run
  back to back and would otherwise land unread. The window is not extended, so there is no loop.
  It is a clock standing in for "the same message", and it is wrong both ways. A session that had
  read the skills already and makes the edit again at once lands inside it, so that refusal is
  worded to be true of both edits it can meet (one of the same message that nothing was read for,
  and one made again too soon) and says to make it again; the first refusal says the window is
  there. And an edit after the window passes unread, the first limit above. The builder's window
  was five seconds: the review measured, in this project's transcripts, that about one edit in
  five follows a tool result in under five seconds and under one in a hundred in under two, and
  that the hook answers in a fraction of a second, so two seconds still cover a message's calls.
  The harness has an event that fires once a batch of calls has resolved, which would need no
  clock; it needs a line in the settings file and was left for that reason.
- **A marker whose time is in the future counts as old**, which is what a refusal's marker is once
  the clock has stepped back: the edit passes. The marker is emptied, not given the current time,
  since a marker stamped now would refuse the next edit as a call of the same message.
- **Where the hook cannot write its markers it refuses nothing** and gives the index as context.
- A spawn is given the index as context and never refused.
- `CLAUDE.md`'s size was held by one move, and by tightening the new section's own prose: which
  number a statement has is said by the header of `tools/check_citations.py`, and `CLAUDE.md`
  points at it. The file is no larger than it was.
- **`--remove` reads the whole `HEAD` reflog, not `HEAD` alone.** The review asked for a refusal
  when `HEAD` is neither where the checkout was made nor reachable from a ref. A commit made in
  the checkout and then stepped away from is held by the same reflog and lost the same way, so
  every commit the log names is asked about. Git cannot tell a commit made in a checkout from one
  fetched, checked out and since left without a ref, so that one is refused as well; a branch at
  it, or git's own `git worktree remove`, is the way past.
- The sentence that any other session merges nothing says "on its own authority", so that it
  agrees with committing's rule that a session may merge a pull request the orchestrating session
  hands it or the player authorizes there.

## What the documentation did not say

The Claude Code hooks documentation gives the ten-thousand-character cap per hook, a
two-thousand-character preview, a deny's reason shown to the model with no stated cap, several
hooks run in parallel with a deny winning, and an `agent_id` on a sub-agent's tool events. It gives
a sub-agent `SubagentStart` and lists `SessionStart`'s sources as a session's, which is the second
known limit above. It does not say whether the calls of one message run one after another for the
edit tools, whether the harness normalizes a file's path before a hook sees it, whether the
compaction events carry a sub-agent's `agent_id`, or whether a hook's refusals count toward auto
mode's pause after repeated denials.

## What the pull request's review changed

The review of the pull request (not ready, against the builder's head) found two defects and six
smaller points, all fixed on the branch: `--remove` deleting commits nothing else held; the
five-second window and its false second refusal; a marker stamped in the future refusing its area
until the clock caught up; "this session" in the refusal, which a sub-agent could read as its
parent's reading (the refusal now says "unless you have read it whole in this context", a
sub-agent sharing its parent's session id and none of its reading); the hooks row; `CLAUDE.md`
larger than it was; a second citation in one pair of parentheses that the checker did not read,
being after a comma (it is after a semicolon now); and "No hook prints a skill's text", which is
true of a Claude Code session and not of the frozen Codex adapter. It also found the sub-agent
limit and the path that was not normalized. A case in `tools/test_rules_hooks.sh` that fed the
session-start hook an event carrying an `agent_id` is relabelled as an event the harness is not
documented to send.

## History taken out of `CLAUDE.md`

Kept here word for word.

**"Things deliberately not done", no quest log for the resistance:**

> *asked for no marker and no quest log (PLAYTEST-02 14) · overturned on 2026-08-31 to only the first encounter, the chalk mark, coming without a hint (PLAYTEST-16 7) · overturned again on 2026-09-23 to the first task being hinted at too (PLAYTEST-122 12).*

**Sentences shortened or left to their owner** (not history, kept for the record of what the file
said):

- On a manual sequence done a second time: "It follows cli-tools…, and its row goes into the
  using-tools catalogue in the same commit. This is a conversation rule rather than a hook…". The
  using-tools skill holds it.
- On the session-start rule: "an `Agent` spawn is that decision already going the right way and a
  first edit to `src/` or `tests/` is it already going the wrong one. The table's two orchestrating
  rows are backstops that share its marker, so a session gets it once however it is triggered, and
  again after compaction". The hook's comments hold the mechanism.
- "It lives here rather than in a skill because no file edit precedes it".
- The paragraph on which number a citation takes: "The number is `#N` in a file whose statements
  are `## #N` headings … the heading is meant."

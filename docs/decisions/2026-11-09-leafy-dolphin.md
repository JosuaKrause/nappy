# leafy-dolphin — The rules are delivered: a hook names the skills for a file and the first edit waits, with the hook rows complete and the orchestrating session defined · 2026-11-09 · not from an entry

**The ask.** The player had a review made of every rule file ("have another fable agent review all
skills/claude/rule files", inbox #1267), read its summary, and said "let's do all the suggested
changes for the hooks/skills/claudes etc", "four PRs is fine with me -- can we parallelize?" and
"for the rule/skill/claude changes I want fable to do it directly" (inbox #1267). Shown the six
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
  or a clear the markers are cleared, so each area is refused once more. Nothing watches whether
  the skills were read: making the edit again is the session's statement that they were.
- **A sub-agent is not handed the orchestrating skill** for an edit under `src/` or `tests/`.
- **The doc lint follows the edited file's own checkout**, and the lint governs every Markdown file
  under `.claude/skills/`.
- **The hook's rows are one table in `CLAUDE.md`'s notation, and a test compares the two row for
  row.** New rows: the four files that draw the cues, the six that hold the balance numbers, the
  reference tools, the atlas membership file, evidence folders to session-captures beside verify,
  Godot's scene, shader and project files, the hooks and the settings file and the decision records
  to committing, the CI workflow to verify. The rows that could not fire are gone, and the tools
  that write such files print a one-line pointer to their skill.
- **`CLAUDE.md` defines the orchestrating session** (the top-level session the player started to
  run the queue; a sub-agent never is; a second top-level session only when the player says so),
  names the board in its pick-up list, and holds the rule about a picture pasted into the
  conversation, which no edit hook can deliver.
- **`tools/agent-setup.sh --remove <name>` removes a clean detached review checkout**, refusing
  anything else, and **`tools/prune-merged.sh` deletes a released brief** when it retires its
  branch.

## What was not built

- **The allow line for `--remove` is not in `.claude/settings.json`.** The permission system
  refused the agent's edit of the settings file as a change to its own permissions. The line is the
  player's to add beside the two prune lines: `"Bash(tools/agent-setup.sh --remove:*)"`. Until then
  the command asks before it runs.
- **The backlog of old briefs is not swept**: a brief whose branch was already gone is never
  visited.

## Choices made, open to the player's overturn

- **The Codex adapter still gets the skills' text.** Its tests call the real hooks and expect the
  text, and the adapter is frozen, so both hooks keep the old output for a Codex session.
- **An edit within five seconds of a refusal is refused too**, since the calls of one message run
  back to back and would otherwise land unread. The window is not extended, so there is no loop.
- **Where the hook cannot write its markers it refuses nothing** and gives the index as context.
- A spawn is given the index as context and never refused.
- `CLAUDE.md`'s size was held by one move: which number a statement has is said by the header of
  `tools/check_citations.py`, and `CLAUDE.md` points at it.
- The sentence that any other session merges nothing says "on its own authority", so that it
  agrees with committing's rule that a session may merge a pull request the orchestrating session
  hands it or the player authorizes there.

## What the documentation did not say

The Claude Code hooks documentation gives the ten-thousand-character cap per hook, a
two-thousand-character preview, a deny's reason shown to the model with no stated cap, several
hooks run in parallel with a deny winning, and an `agent_id` on a sub-agent's tool events. It does
not say whether a sub-agent gets its own session-start event; if it does not, a sub-agent whose
context is compacted is not refused again.

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

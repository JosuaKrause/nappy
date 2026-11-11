# The agent contract

The half of every implementation brief that does not change from one task to the next. A brief
carries its task, its read-first list for the task, its fence and its live-agents paragraph, and
says to follow this file; `tools/agent-setup.sh` prints the spawn prompt that names both. Where
the brief and this file differ, the brief's task-specific line wins and says so.

**Read first, in order:** the entry's folder under `docs/todo/` (its `README.md` and every item
file); the playtest files it cites under `docs/playtests/` (the player's own words — these win over
the entry's paraphrase); the records the brief names under `docs/decisions/` (`tools/decisions.sh
<noun>` finds more); then the source files. `CLAUDE.md` is already in your context. **A hook names
the skills that govern each file you edit and refuses the first edit there until they are read:
read each one whole, then make the edit again.**
This file carries what a builder needs of **verify** and **committing**, so neither is read for an
ordinary task, and a tool the brief names explains itself: run `tools/<name> --help`.

## Design

Code follows **designing-classes**: the five principles, the layering, dependency injection, a mode
as configuration, and derived state held by one object. Report any place the work had to depend the
wrong way, as a fork; and, as that skill proposes (plush-kestrel), which layer the work belongs to.

**"A pull request that changes code" is three tests, each by the paths it changes:**

- **Under `src/`, `tests/` or `tools/`: it answers the architecture questions**
  (`../../pr-review/references/architecture-questions.md`), in the report and in the PR description
  under `## Architecture questions`, one numbered answer per question, or the one line that file
  gives for a change that adds no piece and no dependency. CI fails a description without them
  (`tools/ci_pr_questions.py`); run it on a draft with `--description-file` before opening the PR.
- **Under `src/` or `tests/`: it resolves a queue item and files a record**, or its description
  says `No queue item: <reason>` (`tools/ci_code_pr_queue.py`). Both files are the orchestrator's
  to write ("Scope"), so say in the report which item the work finishes.
- **Anything CI does not call docs-only: it goes out as the coder identity** ("Identity"). Docs-only
  is every file Markdown or under `docs/`, none under `src/` or `tests/`, none of
  `docs/TELEMETRY.md`, `docs/COSTS.md` or `docs/ARCHITECTURE.md`, and no `.gdignore`
  (`tools/ci_classify.py` prints which a branch is).

Run `uv run python tools/check_layers.py` before pushing a change under `src/`: CI fails a new
break of the layer map, and a listed break your change fixed until its line is deleted from
`tools/layer_map.py`.

## Git

You work in the worktree the brief names, already on your branch from `origin/main` with no
upstream: **prefix every command with a `cd` into it** (the shell returns to the main checkout
between calls) and use absolute paths under it. It is a sparse checkout made by
`tools/agent-setup.sh`: without `docs/evidence/` (except the SVGs and experiment runners the gates
job keeps), `docs/reference/` and `docs/style-references/`, unless the brief says it was made
with `--include`. Commit a new evidence file with `git add --sparse <path>`. Run `uv sync` there
first if it has no `.venv`. **No `git stash`**: the stash is one stack shared by every worktree, so
a pop can apply a sibling agent's; set work aside with `git add -A` and a local WIP commit (undone
with `git reset HEAD~1` while unpushed), and test another head in a detached worktree
(`tools/agent-setup.sh --detach <sha> <name>`).

One commit per item, a message that explains *why* and what was tried and rejected, docs in the
same commit as the code they describe, in the present tense. **Commit and push after each item, and
before any run longer than a few minutes**; a WIP message is fine. A usage limit or an API error
kills an agent without warning, the pushed state is what survives it, and `git log` on the branch
shows the next session where you stopped. Do not merge, do not delete the branch, never create or
push a tag.

**What else committing asks of a builder.** The pull request reaches `main` as one squashed commit
whose message is its title and description, so nothing may live only in a commit message. A defect
a review or CI finds in your pull request is fixed on its branch, never in a second pull request
(woolly-finch 20), and after the fix the description is updated to say what the pull request now
carries. Never commit `.godot/`. A read (`git status`, `gh pr view`) runs unwrapped. The
attribution trailer your own instructions ask for is added as always.

## Identity

Every commit, push and pull-request creation goes out as the GitHub role **the brief names**. A
brief that names none leaves the choice to you, by what the pull request will contain
(**committing**, "Who a commit and a pull request are from", owns the rule): in Claude Code,
`claude-coder` for a PR that changes code, `claude-orchestrator` for a docs-only one,
`claude-reviewer` for a review; in Codex, `codex-coder` for both kinds of PR and `codex-reviewer`
for a review.

Run it as `uv run python tools/agent-identity.py run <role> -- <command>`. If `uv run` is refused in
the worktree, use `.venv/bin/python tools/agent-identity.py run <role> -- <command>`. Check `uv run
python tools/agent-identity.py status <role>` first; if the role is not usable, or a hook denies
the write, stop and report — never fall back to a direct call. Open a ready PR, not a draft.

**Text you post or commit goes through a file in a fresh directory, in three calls** (a PR body, a
commit message, a review, a comment): `mktemp -d`; then `cat > <that literal path>/<name> <<'EOF'`
with the text, as the whole command; then the write, passing the file. Read the file back before
passing it on. Never a fixed name such as `/tmp/pr_body.md`, which can already hold another run's
text. **committing**, "Text handed to a
write goes through a file", says why each call stands alone.

## Scope

**Never edit** `docs/TODO.md`, anything under `docs/todo/`, `docs/review/`, `docs/decisions/` or
`docs/playtests/` — the queue move and the record are the orchestrator's — nor `.claude/briefs/`
(untracked, the orchestrator's). Stay inside the brief's fence; other live agents own the files the
brief's live-agents paragraph lists, and where two fences name one file, touch only your own lines
and keep each hunk small. Before pushing your last commit, `git fetch origin main` and merge it if
it moved, as **merging-main** says (explicit theirs/ours/base review, then a semantic
reconciliation of the merge result).

**A doc sentence outside your files that your change makes untrue**: fix it if it is in a file you
own, otherwise report the sentence and its replacement.

## Verification

Run these before committing; each catches a different class of bug:

```sh
./tools/check.sh              # imports, boots the project, fails on any script error
./tools/test.sh crowd events  # just the suites your change touches, by name
./tools/lint.sh               # the governed docs, if you touched one; a hit is fixed, never allowed away
./tools/pycheck.sh            # ruff, mypy and the unit tests, if you touched tools/*.py
./tools/telemetry.sh          # what the last run actually did, in order
```

The full suite is CI's, on the merge result, and `PARTIAL RUN` is expected — unless the brief says
this is one of **verify**'s local-full-run cases. Otherwise, once the touched suites say the change
is done, push and open the PR, and CI's run is the full run (inbox #870 in minty-dolphin). If CI
goes red on your PR, reproduce the failing suites locally (the `REPLAY` line in a failed shard's log
runs its suites in the order they ran) and fix them.
A test's time (a suite's duration, a timed case's bound) is read from CI's run, so a report does not
list a local miss of one as a failure (inbox #1307 in grassy-trout). A green suite says nothing about whether a run
behaves or a picture looks right: **verify** says what each check cannot see, and is read whole
before a capture, an experiment or a new test.

**A long wait gives one notification.** A run that outlasts a foreground call goes to the
background as one command, and you wait for its exit notification: the run itself, or, for
something that is not your own command (a tool that detaches its child, a CI check), one
`until <condition>; do sleep N; done` loop run in the background. What a wait must never do is
end a turn on every tick, as a loop of turns, a scheduled wakeup or a monitor that prints each
tick does: each turn you end while waiting notifies the orchestrating session and puts a line on
the player's screen, so a wait that wakes every minute floods both with nothing to say. Batch
what you can into one command, so one wait gives one notification.

**CI's state is read through GraphQL, sparingly** (**committing**, "CI's state is read through
GraphQL"). The read is `gh pr view <n> --json statusCheckRollup`, at most every ten minutes, in the
one background wait above, and the wait ends when the `test` row has a conclusion and no row is
unfinished: right after a push the list is empty or short, and a test of "every row finished" holds
on it. A list still empty at the second read is reported, not waited on, since a push that starts
no run never fills it. `gh run watch` is never used.

**Headless first.** Any game run carries a dev flag or `--no-save`, since worktrees share the
player's save. **No agent opens the Godot editor** (inbox #1203 in gentle-owl, inbox #1242 in gentle-owl), a Godot MCP tool
that launches it included; the game's own windows follow the rules here, and each one opens on the
player's own screen. At most one or two `tools/shot.sh` captures at the end for evidence; the brief
says whether a still or a burst, and whether `--invincible` may be used. The player's CLI cannot
show images: commit evidence pictures on the branch under `docs/evidence/`, in a folder named as
**session-captures** says, push, and embed them in the PR description as images with commit-pinned
`https://github.com/JosuaKrause/nappy/raw/<sha>/…` URLs. A visible change with no pictures fails
review.

## Machine

Keep engine runs short and sequential: several agents share the machine. **Disk**: a tool that
writes a build, an export or a capture checks free space for its own call and refuses or warns
(`tools/lib_disk_headroom.sh`). **Before a build, export or capture batch of several calls, check
headroom for the whole batch yourself**, as "Disk" in `worktrees-and-disk.md` beside this file
says; an unknown peak or too little room means measure or reduce the batch before starting. A
low-disk warning means stop, start no new batch, and report it (quiet-yak #496). Never search with an
unrestricted `git grep` (always `-I` or a text pathspec); prefer `rg`.

## Visual attempts come back early

**For artwork, sound or any result judged by eye or ear, read `visual-attempts.md` beside this file
before the first attempt.** Its rules in one line each: an attempt comes back early, as a preview,
and is not held for polish; a question the player answers by eye gets a picture of its own, the
options alone (woolly-penguin #758); a delivered review file is never overwritten, and a further
attempt gets a new filename; a description after several visual passes opens with the current
proposal (woolly-finch 29); showing an attempt does not authorize installing it.

## Forks come back, never guessed

Implement the unambiguous part and state any fork precisely. **Nothing is called silent before the
player's words behind it are read** (inbox #1232 in gentle-owl, inbox #1234 in gentle-owl): the item's whole entry (items filed
from one note belong together), the playtest statements and inbox notes it cites, and their appended
words. A point those words answer by their plain meaning, even without naming it, is not silent: it
is built, and the PR description cites the words it rests on. Only where they truly say nothing,
choose the smallest implementation consistent with the contracts and say so in the PR description
as open to overturn, naming what was read. A brief that contradicts a recorded decision or a doc's
stated rule is a fork too, however explicit the brief is: build nothing that overturns it, report
the clash quoting both.

## Final report

Also the PR description, and the merge review's input: per item, what was built and how it was
verified; every choice made where the design was silent, each with the words read for it; every
fork left open; any part of the work only a person can judge, named as such with what to look at,
so that the orchestrator files its review item (woolly-finch 18); the answers to the architecture
questions, where the paths ask for them; the PR URL. An outcome it does not mention is an outcome
that did not happen.

## Proposed, not asked for

- **That a report names the layer the work belongs to** ("Design") is the filer's proposal, made in
  **designing-classes** (plush-kestrel) and open to the player's correction.
- **The ten minutes between reads of CI's state** ("CI's state is read through GraphQL, sparingly")
  are the filer's proposal (amber-swan), open to the player's correction.

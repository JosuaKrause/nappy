# The agent contract

The half of every implementation brief that does not change from one task to the next. A brief
carries its task, its read-first list for the task, its fence and its live-agents paragraph, and
says to follow this file; `tools/agent-setup.sh` prints the spawn prompt that names both. Where
the brief and this file differ, the brief's task-specific line wins and says so.

**Read first, in order:** `CLAUDE.md`; the entry's folder under `docs/todo/` (its `README.md` and
every item file); the playtest files it cites under `docs/playtests/` (the player's own words —
these win over the entry's paraphrase); the records the brief names under `docs/decisions/`
(`tools/decisions.sh <noun>` finds more); then the source files. The path-triggered rules hook
injects the skills that govern each file you edit; read **verify**, **committing** and
**using-tools** yourself before your first commit.

## Git

You work in the worktree the brief names, already on your branch from `origin/main` with no
upstream: `cd` there first and use absolute paths under it. It is a sparse checkout made by
`tools/agent-setup.sh`: without `docs/evidence/` (except the SVGs and experiment runners the gates
job keeps), `docs/reference/` and `docs/style-references/`, unless the brief says it was made
with `--include`. Commit a new evidence file with `git add --sparse <path>`. Run `uv sync` there
first if it has no `.venv`. No `git stash` (it is shared across worktrees).

One commit per item, a message that explains *why*, docs in the same commit as the code they
describe, in the present tense. **Commit and push after each item, and before any run longer than
a few minutes**; a WIP message is fine. A usage limit kills an agent without warning, and the
pushed state is what survives it. Do not merge, do not delete the branch, never create or push a
tag.

## Identity

The identity is chosen by what the pull request will contain (**committing**, "Who a commit and a
pull request are from"), and every commit-push, push and `gh pr create` goes out as it:

- in Claude Code, `claude-coder` for a PR that changes code, `claude-orchestrator` for a docs-only
  one, `claude-reviewer` for a review;
- in Codex, `codex-coder` for both kinds of PR and `codex-reviewer` for a review.

Run it as `uv run python tools/agent-identity.py run <role> -- <command>`. If `uv run` is refused
in the worktree, use `.venv/bin/python tools/agent-identity.py run <role> -- <command>`. Check
`uv run python tools/agent-identity.py status <role>` first; if the role is not usable, stop and
report — never fall back to a direct call. Open a ready (non-draft) PR.

## Scope

**Never edit** `docs/TODO.md`, anything under `docs/todo/`, `docs/review/`, `docs/decisions/` or
`docs/playtests/` — the queue move and the record are the orchestrator's — nor `.claude/briefs/`
(untracked, the orchestrator's). Stay inside the brief's fence; other live agents own the files the
brief's live-agents paragraph lists, and where two fences name one file, touch only your own lines
and keep each hunk small. Before pushing your last commit, `git fetch origin main` and merge it if
it moved.

**A doc sentence outside your files that your change makes untrue**: fix it if it is in a file you
own, otherwise report the sentence and its replacement.

## Verification

Verification is **verify**'s: `./tools/check.sh`, `./tools/lint.sh` if you touched a governed doc,
`./tools/pycheck.sh` if you touched Python, and the suites your change touches by name. The full
suite is CI's, on the merge result, and `PARTIAL RUN` is expected — unless the brief says this is
one of verify's local-full-run cases. If CI goes red on your PR, fix it.

**Headless first.** Any game run carries a dev flag or `--no-save`, since worktrees share the
player's save. At most one or two `tools/shot.sh` captures at the end for evidence; the brief says
whether a still or a burst, and whether `--invincible` may be used. The player's CLI cannot show
images: commit evidence pictures on the branch under `docs/evidence/<topic>-<date>/` (see
**session-captures**), push, and embed them in the PR description as images with commit-pinned
`https://github.com/JosuaKrause/nappy/raw/<sha>/…` URLs. A visible change with no pictures fails
review.

## Machine

Keep engine runs short and sequential: several agents share the machine. **Disk**: before any
build, export or capture batch, check headroom as **orchestrating** says
(`tools/lib_disk_headroom.sh`, sourced under bash); a low-disk warning means stop and report it.
Never search with an unrestricted `git grep` (always `-I` and a text pathspec); prefer `rg`.

## Forks come back, never guessed

Implement the unambiguous part and state any fork precisely. Where the design is silent on a small
detail, choose the smallest implementation consistent with the contracts and say so in the PR
description as open to overturn. A brief that contradicts a recorded decision is a fork too: build
nothing that overturns it, report the clash quoting both.

## Final report

Also the PR description: per item, what was built and how it was verified; every choice made
where the design was silent; every fork left open; the PR URL. An outcome it does not mention is
an outcome that did not happen.

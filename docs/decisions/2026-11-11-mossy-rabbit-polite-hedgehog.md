# mossy-rabbit — Old briefs and review checkouts are swept · 2026-11-11

**The ask.** The rules review found several hundred briefs under `.claude/briefs/` whose branches
were retired before a retired branch's brief was deleted with it, and detached review checkouts under
`.claude/worktrees/` whose review was long posted (amber-ibis's item, moved to this entry when the
player answered "split it", inbox #1348 in grassy-trout). Not the player's request: a defect the
review named, filed by the orchestrator. The item asked for a sweep that lists first and removes only
on a second, explicit run, modelled on the retirement script's `--all` inventory.

## What was built

- **`tools/sweep-agent-leftovers.py`** lists, one line each, every branch brief and every detached
  checkout under `.claude/worktrees/`, marked `sweep` or `keep` with the reason; `--apply` removes
  what is marked `sweep`, after reading the disk again and inspecting each thing again, and keeps
  anything that changed in between.
- **A brief is a branch brief** when its header has a `branch:` line and its file name is that branch
  with `/` as `-`, the lookup the retirement script and `tools/agent-status.sh` use. Any other file
  there (drafts, plans, review briefs) is counted in the summary, given no line and never touched,
  so a new kind of file needs no new rule.
- **A brief is swept** only when its branch exists nowhere (no local branch, none on `origin`, no
  open pull request, no directory at its `worktree:` line), a pull request of that branch merged, and
  neither the brief nor any credited agent's transcript was written in the last 24 hours.
- **A detached checkout is swept** only when it holds no commit of its own (the rule of
  `tools/agent-setup.sh --remove`), has no changed, untracked or non-cache ignored file, is not
  locked, the caller is not in it, no rebase, merge or bisect is under way in it, and nothing in it
  changed in the last 24 hours. Its removal is `tools/agent-setup.sh --remove`, never forced; a
  refusal keeps it and fails the run. A checkout holding a commit no ref reaches is listed with each
  commit and the `git branch` that keeps it.
- **GitHub is only read**: a failed or possibly cut-off read ends the run before anything is listed.
- Its row in the using-tools catalogue, and step 6b of **session-cleanup** names it.

## Choices open to overturn

- **`cleanup: ready` is not required** of a swept brief, which widens the item's "a released
  brief": every condition the line releases (the branch and its worktree gone, no agent running)
  is checked directly. On the first listing most briefs marked to sweep carried the line; of
  those that did not, most were written in September, before the line existed. The alternative
  keeps the briefs without the line until each is released by hand (the builder's).
- **A merged pull request is required**: a brief of dropped work may be its task's only record
  (the builder's).
- **24 hours of quiet** (`QUIET_HOURS`), one constant for briefs, transcripts and checkouts, so that
  a review still reading a checkout is not swept under it (the builder's).

## Left, each with its reason

- **The checkouts holding commits of their own** are never removed by the sweep. The listing on the
  real checkout found ten, mostly worktrees of squash-merged branches; whether each commit is in
  `main` is a judgement for the orchestrator.
- **`tools/agent-setup.sh --remove` has no listing form**, so the sweep restates its rule for a
  commit no ref reaches. A drift can only make the listing wrong, since the removal still goes
  through `--remove`; giving the rule one home was outside this item's files.
- **Whether Claude Code's auto mode lets `--apply` run** without a line in `.claude/settings.json`
  is untried; no line was added.

## Verified

The listing ran on the real checkout and removed nothing; the removing form ran only on scratch
repositories, in `tools/test_sweep_agent_leftovers.py`, which `tools/pycheck.sh` runs and which
failed on each of the one-line mutations of the script's rules. `./tools/pycheck.sh`,
`./tools/lint.sh` and `./tools/check.sh` pass.

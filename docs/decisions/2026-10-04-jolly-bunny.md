# jolly-bunny — One script sets up an agent, and the brief's shared half is checked in · 2026-10-11


[jolly-pelican](../playtests/2026-10-04-jolly-pelican.md), #518: "do you feel the need to streamline
subagent setups? are there steps that need repeating? are there common prefixes of the brief?
etc?" The player read the orchestrator's answer and proposal and filed it ("file it as now first we
can pick it up later"); CLAUDE.md's rule that a manual sequence done a second time becomes a script
is the reason.

**Built, as the filed proposal said.** `tools/agent-setup.sh <name> <branch> [--include <path>...]`
runs the disk preflight, makes the sparse worktree under `.claude/worktrees/<name>` from
`origin/main` with no upstream, its exclusions read from the `gates` job's sparse checkout in
`.github/workflows/ci.yml` (so there is one list) plus `docs/reference/` and
`docs/style-references/`, writes the brief's header and prints the spawn prompt; `--agent` and
`--release` make the two later header edits. It refuses an existing worktree, branch or brief
before writing anything. The shared half of a brief is
`.claude/skills/orchestrating/references/agent-contract.md`, and **orchestrating** and the
**using-tools** catalogue name both. `tools/test_agent_setup.sh` runs the script against a scratch
clone, in CI's `gates` job.

**The skill fix.** **orchestrating** asked for sparse worktrees, the brief's header, the `agent:`
line and `cleanup: ready` with no tool to make them, so the exclusion list was copied by hand
beside CI's and could drift from it; it now names the tool for each.

*Open to overturn, chosen by the implementer:* the live-agents paragraph stays hand-written in each
brief, since the briefs' fences are free prose and generating it would not be reliable (the
proposal's own condition); `--include` switches the preflight to the full worktree's estimate; the
test was wired into CI, outside the brief's file list.

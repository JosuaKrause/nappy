# jolly-bunny — One script sets up an agent, and the brief's shared half is checked in · 2026-10-11


[jolly-pelican](../playtests/2026-10-04-jolly-pelican.md), #518: "do you feel the need to streamline
subagent setups? are there steps that need repeating? are there common prefixes of the brief?
etc?" The player read the orchestrator's answer and proposal and filed it ("file it as now first we
can pick it up later"); CLAUDE.md's rule that a manual sequence done a second time becomes a script
is the reason.

**Built, of the filed proposal, all but the generated live-agents paragraph.** `tools/agent-setup.sh <name> <branch> [--include <path>...]`
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

**Not built: the live-agents paragraph generated from the briefs' scope fences**, which the filed
proposal included. The briefs state their fences in free prose, so nothing can read a file list out
of them reliably; the orchestrator's brief allowed it to be left if it was not small and reliable,
a condition the player's filing did not set. The paragraph stays hand-written in each brief, and the
contract says so.

*Open to overturn, chosen by the implementer:* `--include` switches the preflight to the full
worktree's estimate; the new branch is made with `--no-track`, and a worktree whose branch still
has an upstream is removed again rather than kept; the brief the tool writes is the header alone,
the task appended under it by the orchestrator; `--detach <ref> <name>` makes a review agent's
scratch checkout with no branch and no brief; the test was wired into CI, outside the brief's file
list.

priority: now

# jolly-bunny — One script sets up an agent, and the brief's shared half is checked in · filed 2026-10-04

[jolly-pelican](../../playtests/2026-10-04-jolly-pelican.md) files it from #518. The player asked
"do you feel the need to streamline subagent setups? are there steps that need repeating? are
there common prefixes of the brief? etc?", read the orchestrator's answer and proposal, and said
"file it as now first we can pick it up later -- currently too many things in flight in
parallel". CLAUDE.md's rule is the reason: a manual sequence done a second time becomes a script.

**What is repeated by hand today**, each time an agent is started:

- **The sparse worktree.** `git worktree add --no-checkout`, dropping the `origin/main` upstream the
  new branch inherits, sparse init, the exclusion list copied from the `gates` job's sparse checkout
  in `.github/workflows/ci.yml` (orchestrating, "Create sparse worktrees before materializing
  files"), then checkout. No tool does it, so the pattern list is kept by hand beside CI's.
- **The brief's header** (`branch:`, `worktree:`, `spawned:`, and `agent:` once the id is known),
  which `tools/agent-status.sh` parses.
- **The brief's shared half**: the identity and its `.venv/bin/python` fallback, commit-and-push
  cadence, the scope fence over the queue and the archive, verify's gate, the disk preflight,
  forks coming back, no merge, the final report's contents (orchestrating, "The task description
  is the contract").
- **Who else is alive**: each brief lists the other live agents and the files they own.
- **The spawn prompt**, the same few lines naming the worktree and the brief.
- **Retiring a merged agent**: `cleanup: ready` added to its brief before the prune script will
  remove the worktree (the landing script reports "agent ownership is not released" until then).

**Proposed, not asked for** (the orchestrator's proposal the player filed):

- `tools/agent-setup.sh <name> <branch> [--include <path>...]`: the disk preflight, the sparse
  worktree with its exclusions read from `ci.yml` so there is one list, the upstream dropped, the
  brief's header written, and the spawn prompt printed; `--agent <branch> <id>` and
  `--release <branch>` make the two later header edits.
- A checked-in agent contract, `.claude/skills/orchestrating/references/agent-contract.md`, holding
  the shared half, so a brief carries only its task and says to follow the contract; the live-agents
  paragraph generated from the briefs' scope fences.
- The orchestrating skill and the using-tools catalogue updated with it, and the gap (the skill asks
  for sparse worktrees with no tool to make them) flagged to the player as a skill fix.
- Inbox captures keep their separate context and body files, since the write guard reads text passed
  any other way as commands.

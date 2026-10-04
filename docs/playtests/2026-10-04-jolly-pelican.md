# Playtest jolly-pelican — Streamline how a subagent is set up

2026-10-04. One note from the inbox, #518, copied word for word after what its words answered.

## #518 — Streamline subagent setup: one script for the worktree and brief, a checked-in agent contract

Asked on 2026-10-04: "do you feel the need to streamline subagent setups? are there steps that need repeating? are there common prefixes of the brief? etc?" The assistant listed what it repeated by hand this session: (1) the sparse worktree (git worktree add --no-checkout, dropping the origin/main upstream it inherits, sparse init, a pattern list copied by eye from the gates job of .github/workflows/ci.yml, checkout) — done nine times, twice wrong; (2) the brief's header and the agent: line written after spawning, with an ad-hoc script each time; (3) the shared half of every brief — identity and its fallback, commit-and-push cadence, the scope fence, the verification gate, the disk preflight, forks come back, do not merge, the final report; (4) the "who else is alive" paragraph, written by hand though the briefs hold it; (5) the identical spawn prompt; (6) retiring a merged agent (cleanup: ready, remove the worktree, prune-merged.sh — land-prs.sh stops at "agent ownership is not released"); (7) inbox captures needing three calls because of the write guard. Proposed, as one PR: tools/agent-setup.sh <name> <branch> [--include <path>...] (disk preflight, sparse worktree with the exclusions read from ci.yml, upstream dropped, brief header written, spawn prompt printed), with --agent <branch> <id> and --release <branch> for the header edits; a checked-in agent contract (.claude/skills/orchestrating/references/agent-contract.md) holding the shared half, so a brief carries only the task and says "follow the contract", with the live-agents paragraph generated from the briefs; the orchestrating skill and the using-tools catalogue updated, and the skill gap flagged to the player. Item 7 left as is. Asked whether to send an agent on it now.

> file it as now first we can pick it up later -- currently too many things in flight in parallel

## Routing

1. **#518** → the new queue entry jolly-bunny, "One script sets up an agent, and the brief's shared
   half is checked in", band `now` as the player said ("file it as now first we can pick it up
   later").

**Run from Codex, `tools/agent-status.sh` gives the warm-or-cold verdict from Codex's own session
logs under `~/.codex/sessions/`**, with Codex's cache window (twenty minutes, per orchestrating)
rather than Claude's hour. The orchestrator's proposal, not asked for; drop it if a Codex session
has no use for the verdict.

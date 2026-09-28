**Claude Code's orchestrator gets a GitHub identity of its own, `claude-orchestrator`, and every
docs-only PR and every issue write goes through it** (statement 17: "just a single one /
claude-orchestrator" · "all doc only PRs and issue writes go through orchestrator"). A docs-only PR
is one whose every changed file the CI classification of `skip-godot-on-docs.md` calls docs-only —
a filing, a queue move, a review item, a skill or `CLAUDE.md` change — and its commits, its push
and the PR itself are the orchestrator's. Every issue write is too: the inbox capture of
`capture.md`, and the closing of notes by a filing PR. A PR that changes code stays
`claude-coder`'s, as the committing skill says today.

It is one more row in the role table of `tools/agent-identity.py`, the script that creates each bot
app and runs a command as it, with the app name `nappy-claude-orchestrator`; the player creates it
on their own machine with `uv run python tools/agent-identity.py create claude-orchestrator`, since
the app-creation flow needs their logged-in browser. There is no Codex counterpart: Codex's
docs-only PRs and issue writes stay `codex-coder`'s.

The role is known everywhere a role is listed: the write guard `.claude/hooks/github-write-guard.sh`
accepts it as a wrapping role, `tools/lib_agent_role.sh` (the helper the pushing scripts use to
run under a role) accepts it, and their tests (`tools/test_rules_hooks.sh`,
`tools/test_lib_agent_role.sh`, `tools/test_agent_identity.py`) cover it. The committing skill's
"Who a commit and a pull request are from" and the orchestrating skill say which role a PR is
opened as. Like the other four identities, it does not work in a cloud session, where the session
proxy serves only repository-scoped endpoints.

**Proposed, not asked for:** its permissions — the coder app's set without `workflows: write`,
since a docs-only PR never changes a CI file; the alternative is the coder app's set unchanged.

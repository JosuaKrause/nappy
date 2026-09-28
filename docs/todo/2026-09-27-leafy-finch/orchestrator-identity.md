**Claude Code gets a GitHub identity for everything that is not code, `claude-orchestrator`, and
a write's identity follows what the write does, not which session triggers it** (statement 17:
"just a single one / claude-orchestrator" · "all doc only PRs and issue writes go through
orchestrator" · "orchestrator should not concern itself with coding prs at all" · "for the
purposes of github what matters is what they do. that is independent who actually triggered it").

- **`claude-orchestrator`** makes every issue write — the inbox capture of `capture.md`, the
  closing of notes by a filing PR — and every write on a PR that contains no code changes: its
  commits, its push, the PR itself, its comments, its merge once the player has said go, and
  retiring its branch with `tools/prune-merged.sh`.
- **`claude-coder`** makes every write on a PR that changes code, including a queue move or a
  decision record committed inside it, merging `main` into it, fixing its CI, merging it and
  retiring its branch. The orchestrator identity never writes on such a PR.
- **`claude-reviewer`** posts every review and its findings, on either kind of PR, as it does
  today.

Whether a PR contains code changes is the CI classification of `skip-godot-on-docs.md` applied to
its changed files: a docs-only PR is the orchestrator's, any other the coder's. The identity is
chosen when the PR is opened, from what it is going to contain ("if a PR is going to not contain
code changes it probably would go through orchestrator"). The session is not the identity: the
orchestrating session writes as `claude-coder` when it merges a code PR, and a spawned agent
writes as `claude-orchestrator` when it opens a docs-only PR.

**It is a convention, not a hard rule** (statement 18: "if a PR starts out as doc only and later
code becomes part of it then identities will mix"). A PR that starts docs-only and later gains
code keeps the orchestrator's earlier writes, and its later writes are the coder's. Nothing — no
CI check, no hook — compares a PR's authors with its classification.

It is one more row in the role table of `tools/agent-identity.py`, the script that creates each bot
app and runs a command as it, with the app name `nappy-claude-orchestrator`; the player creates it
on their own machine with `uv run python tools/agent-identity.py create claude-orchestrator`, since
the app-creation flow needs their logged-in browser. There is no Codex counterpart: Codex's
docs-only PRs and issue writes stay `codex-coder`'s.

The role is known everywhere a role is listed: the write guard `.claude/hooks/github-write-guard.sh`
accepts it as a wrapping role, `tools/lib_agent_role.sh` (the helper the pushing scripts use to
run under a role) accepts it, and their tests (`tools/test_rules_hooks.sh`,
`tools/test_lib_agent_role.sh`, `tools/test_agent_identity.py`) cover it. **This replaces a
recorded decision:** the tall-egret record ("Each agent posts on GitHub as an app of its own")
says "Claude Code's orchestrator and its implementation agents commit as `claude-coder`", and the
committing skill's "Who a commit and a pull request are from" says "Claude Code's orchestrator and
every implementation agent it spawns commit as `claude-coder`" — four apps in all, chosen by which
session writes. The committing and orchestrating skills are rewritten to say which role a write
goes out as, by what it does, and the decision record that closes this entry names tall-egret as
the record it supersedes on this point. Like the other four identities, it does not work in a
cloud session, where the session proxy serves only repository-scoped endpoints.

**Proposed, not asked for:** its permissions — the coder app's set without `workflows: write`,
since a docs-only PR never changes a CI file; the alternative is the coder app's set unchanged.

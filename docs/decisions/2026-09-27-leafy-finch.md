# leafy-finch — Claude Code's orchestrator identity · 2026-09-27

*([bouncy-heron](../playtests/2026-09-27-bouncy-heron.md), statement 17: "orchestrator/coder
session and orchestrator/coder identity are not the same thing. for the purposes of github what
matters is what they do. that is independent who actually triggered it" · statement 18: "this is
also not a hard rule. if a PR starts out as doc only and later code becomes part of it then
identities will mix" · statement 24: "we need to figure out the exact required settings before
creating that account" · [speckled-puffin](../playtests/2026-09-27-speckled-puffin.md): "yes")*

**Built (PR #424).** A fifth GitHub identity, `claude-orchestrator` (app
`nappy-claude-orchestrator`), for Claude Code only. A write's identity follows what the write does:
issue writes and every write on a docs-only PR go out as `claude-orchestrator`, writes on a code PR
as `claude-coder`, reviews as `claude-reviewer`. It is a convention nothing checks, so a PR that
starts docs-only and gains code carries both. Codex has no counterpart; its docs-only writes stay
`codex-coder`'s. The role is a row in `tools/agent-identity.py`'s `ROLES`; the write guard,
`tools/lib_agent_role.sh` and the land, prune and release scripts already accepted any wrapping
role that is not a reviewer, so only their messages and tests changed. The committing,
orchestrating, pr-review and using-tools skills say which role a write goes out as.

**This supersedes [tall-egret](2026-09-27-tall-egret.md) on one point**: tall-egret has Claude
Code's orchestrator and its implementation agents commit as `claude-coder`, chosen by which
session writes. Everything else in tall-egret stands.

**The app's settings were settled before it was created**, and the player confirmed them: the
coder app's permission set, `workflows: write` included. The item proposed dropping it, since a
docs-only PR's own diff never touches CI; kept, because merging `main` into a docs-only branch
after `main` changed a workflow is refused to an app without it (argued, not tested: that needs an
app without the permission). `actions: write` is there to re-run a check after a filing PR's
description is corrected. No ruleset names the app: `main approvals` is satisfied by
`claude-reviewer`.

**Open to overturn:** merging `main` into a docs-only PR is the orchestrator's write; a release
stays `claude-coder`'s; the committing skill states the docs-only rule itself (Markdown or under
`docs/`, except `docs/TELEMETRY.md`, `docs/COSTS.md` and `docs/ARCHITECTURE.md`) rather than
pointing at CI's classification, which is still being built.

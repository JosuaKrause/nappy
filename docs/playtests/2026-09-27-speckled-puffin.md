# Playtest speckled-puffin — The orchestrator app's settings are confirmed

2026-09-27. Said in conversation, answering the settings list for the `claude-orchestrator` GitHub
app that leafy-finch's `orchestrator-identity.md` item asks to be worked out before the app is
created (bouncy-heron, statement 24).

## Statements

The assistant put the list to the player: a private app `nappy-claude-orchestrator`, webhook off,
no account permissions, installed on this repository only; repository permissions `contents`,
`pull_requests`, `issues`, `workflows` and `actions` at write and `checks` and `metadata` at read,
which is the coder app's set, each with the write that needs it; no ruleset naming the app. It
recommended keeping `workflows: write`, against the item's proposal to drop it, because merging
`main` into a docs-only branch after `main` changed a workflow is refused to an app without it. It
also asked the player to add, or allow the edit of, the `.claude/settings.json` allow rule for
retiring a branch as `claude-orchestrator`, which Claude Code's auto-mode classifier refused as
self-modification. The player answered:

> "yes"

1. **The settings list is confirmed as put, `workflows: write` included**, and the player creates
   the app from it. → leafy-finch.

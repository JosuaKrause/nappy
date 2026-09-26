priority: later
after: 2026-09-26-M223

## M228 — Editing a hook loads the rule that keeps the Codex adapter current · asked for 2026-09-26

> "okay, yes this is important to keep up to date" · "good"

[2026-09-26-brisk-heron](../../playtests/2026-09-26-brisk-heron.md), statements 6–7. PR #377 writes the
rule down: a change to a hook script or to the hooks in `.claude/settings.json` updates
`tools/codex-hooks.py` and its tests in the same PR. Built after M223, which rewrites
`.claude/hooks/project-rules.sh`.

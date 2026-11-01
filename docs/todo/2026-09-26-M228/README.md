priority: parked

## M228 — Editing a hook loads the rule that keeps the Codex adapter current · asked for 2026-09-26

> "okay, yes this is important to keep up to date" · "good"

[2026-09-26-brisk-heron](../../playtests/2026-09-26-brisk-heron.md), statements 6–7. PR #377 writes the
rule down: a change to a hook script or to the hooks in `.claude/settings.json` updates
`tools/codex-hooks.py` and its tests in the same PR. Built after M223, which rewrites
`.claude/hooks/project-rules.sh`.

**Parked while Codex support is frozen** ([amber-penguin](../../decisions/2026-10-31-amber-penguin.md),
which lifted the rule that a hook change updates `tools/codex-hooks.py`).
[tiny-lark](../../playtests/2026-11-01-tiny-lark.md), #924: "yes, park those items. we're not going to pick them up while codex is on freeze", and #930: "to parked". Its second item, the sound lab's paths loading the sound-effects skill, has nothing to do with Codex and is its own entry.

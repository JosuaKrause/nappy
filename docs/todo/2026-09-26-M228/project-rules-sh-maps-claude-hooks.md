**`project-rules.sh` maps `.claude/hooks/**`, `.claude/settings.json` and `.codex/**` to the
skill that carries the rule** (python-tooling), with a row in `CLAUDE.md`'s path table and a
test in `tools/test_rules_hooks.sh`; `tools/codex-hooks.py` loads it for the same paths.

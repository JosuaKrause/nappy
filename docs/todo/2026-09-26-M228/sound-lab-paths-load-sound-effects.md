**Editing `tools/sound-lab.sh` or `tools/sound-lab/passes.json` loads the sound-effects skill**, as
editing `tools/synthesize-sfx.py` already does: a case in `.claude/hooks/project-rules.sh`, a row in
`CLAUDE.md`'s path table and a test in `tools/test_rules_hooks.sh`. Found by PR #384's review
(https://github.com/JosuaKrause/nappy/pull/384#pullrequestreview-5327778826), not blocking; it sits
here because it is the same file and the same kind of mapping.

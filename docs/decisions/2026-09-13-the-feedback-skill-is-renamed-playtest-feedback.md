## The feedback skill is renamed playtest-feedback · 2026-09-13

*(2026-09-13, on typing `/feedback` and getting the repository's skill: "oh, then we need to rename
the feedback skill maybe?", then "make sure all references are updated properly, too".)* Claude
Code has a built-in `/feedback` command that sends product feedback, and a repository skill of the
same name shadows it, so the skill that governs playtest reports and design instructions is now
`.claude/skills/playtest-feedback/`. Nothing in it changed but its name. Every reference that
meant the skill was moved with it — `CLAUDE.md`'s two tables and its loading sentence, the
path-to-skill hook, the **orchestrating**, **reference-photos** and **svg-art** skills, the
evidence folder's README and the handoff — and the ordinary noun *feedback* stays wherever it is a
noun. Older records below that name the skill by its old name are left as they were written.

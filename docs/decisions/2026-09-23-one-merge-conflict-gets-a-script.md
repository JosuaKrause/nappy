## One merge conflict gets a script · 2026-09-23

Merging `main` into a PR branch conflicted in `docs/DECISIONS.md` the same way four times in one
session (PRs 289, 298, 297 and 300): both sides had inserted a section under `# Decisions` from an
empty base, and each was resolved by hand by keeping both, the branch's above main's. Under
CLAUDE.md's "a manual sequence done a second time becomes a script", `tools/resolve-decisions-top.sh`
does exactly that and refuses every other shape, which stays the **merging-main** skill's
three-way review; the semantic review of the merge is not skipped because the conflict was
mechanical.

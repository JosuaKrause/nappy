# tiny-sparrow — The rule that an edit fails loudly is removed · 2026-10-30 · not from an entry


`CLAUDE.md`'s section "Editing files" held the rule "An edit fails loudly or it is not an edit":
whatever tool makes a change, a replacement that matches nothing says so, and a script or one-liner
that rewrites a file asserts its anchors before writing (`str.index` rather than a silent
`replace`, a `grep -c` that must return the expected count) and verifies after. The player's own
global `~/.claude/CLAUDE.md` held a short copy. Both are removed on the player's word (inbox #872):
the rule was written to override assistant instructions that steered file changes towards scripts
rather than the dedicated edit tool, and the player judged it no longer needed.

**What was said against removing it**, in the conversation before the player decided: the dedicated
edit tool already fails loudly on a miss, but an edit made through `sed`, a heredoc or
`str.replace` still succeeds silently, and the assistant's instructions still permit such edits for
small mechanical changes. On 2026-10-30 a builder's scratch replacement script added 48 stray blank
lines across PR #864 (minty-quail, main-and-state 4b); lint and `git diff --check` do not flag a
blank line, and the PR's adversarial review caught them.

**What stays:** the section's separate sentence, to grep for what pointed at a file before moving
it, is kept under the heading "Moving files". The comments in `tools/ci-costs.sh` and
`tools/lib_queue.py` that cited the rule keep their own reasons and no longer name it; the checks
they describe are unchanged.

**What would make it worth discussing again:** a silent edit reaching a merged commit, a doc
change that quietly did nothing or a script that mangled what it matched, which no review caught.

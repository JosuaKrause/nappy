# tiny-sparrow — The rule that an edit fails loudly is removed · 2026-10-30 · not from an entry


`CLAUDE.md`'s section "Editing files" is removed, and the short copy in the player's own global
`~/.claude/CLAUDE.md` with it, on the player's word (inbox #872 in minty-dolphin): the rule was written to override
assistant instructions that steered file changes towards scripts rather than the dedicated edit
tool, and the player judged it no longer needed. The section read, in full:

> **An edit fails loudly or it is not an edit.** Whatever tool makes a change — a dedicated edit
> tool, `sed`, a heredoc, a script — the change is either visibly correct or visibly rejected: a
> replacement that matches nothing must say so rather than look like a success. In a repo where the
> docs *are* the design and get committed alongside the code, a doc edit that quietly did nothing is
> a lie in the commit rather than a missing change.
>
> So a script or a one-liner that rewrites a file **asserts the anchors before writing** —
> `str.index` rather than a silent `replace`, a `grep -c` that must return the count you expect —
> and **verifies after**, with line counts and a `grep` for something that must have survived. That
> holds for a small change as much as for the large-scale and structural work a script is the right
> tool for: moving a file whole, splitting a document, deleting a whole section, renaming an
> identifier across the tree, applying the same change to thirty files.
>
> **And grep for what pointed at it before you move anything**, since a reference is not visible
> from the file being moved.

**What the orchestrating session said against removing it**, in the conversation before the player
decided, recommending the repo rule be kept: the dedicated edit tool already fails loudly on a miss,
but an edit made through `sed`, a heredoc or `str.replace` still succeeds silently, and the
assistant's instructions still permit such edits for small mechanical changes. On 2026-10-30 a
builder's scratch replacement script added 48 stray blank lines across PR #864 (minty-quail,
main-and-state 4b); lint and `git diff --check` do not flag a blank line, and the PR's adversarial
review caught them.

**What stays**, the orchestrating session's reading of "remove it", open to the player's correction:
the section's last sentence, to grep for what pointed at a file before moving it, is kept under the
heading "Moving files", since it is a separate rule about references rather than about edits failing
loudly. The comments in `tools/ci-costs.sh`, `tools/lib_queue.py` and `tools/shot.sh` and the
sentence in the reference-photos skill that cited or repeated the rule keep their own reasons and no
longer name it; the checks they describe are unchanged.

**What would make it worth discussing again:** a silent edit reaching a merged commit, a doc
change that quietly did nothing or a script that mangled what it matched, which no review caught.

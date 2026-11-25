# tawny-hedgehog — `tools/inbox.py cite` reads a citation wrapped across a line as one run, and writes only with `--write` · 2026-11-13

**The ask.** "schedule a bug fix. remember those get highest priority" (amber-goose #1442), said of `cite` doubling a
citation wrapped across a line and editing files when an agent ran it to look a note up. Band `bug`, as the player
named it.

## What was built

- **Both wrapped shapes are read as one run**: `cite_text()` hands `cite_line()` the lines beside it. A run broken
  after "and" or a comma gets no ` in <name>` when its end names the playtest, and one after its last number when it
  names none; a citation whose ` in` ends the line, the name opening the next, counts as cited, and a different name
  there is listed for a hand fix.
- **`cite` writes only with `--write`**; with no flag or `--dry-run` it prints the diff and the hand-fix list, and
  `--write` with `--dry-run` is rejected before any work. `filing-a-batch.md`, the tool's `--help` and its docstring
  say `--write` where a filer edits.
- **Tests** in `tools/test_inbox.py` hold each shape, the one-edit case, a second run changing nothing, the real
  sentences of the records minty-quail-quiet-swan, -curly-hawk and -fluffy-newt and of the orchestrating skill, and
  the flag rules; the builder ran them against the old tool first and they failed.

## Choices open to overturn

- **`--write`**, the filer's proposal (the item's "Proposed, not asked for"). Over: `cite` writing by default with a
  warning in the inbox skill, which leaves a lookup able to edit the tree.

The entry's other item, `bugs-go-first.md`, stays open: it waits on the player's answer to the board question
bug-passes-the-fence.

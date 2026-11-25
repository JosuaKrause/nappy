priority: bug

# brisk-quail — A roadblock catch in the escape city shows the fallback loss text · filed 2026-11-24

**What this is.** Found by the review of minty-quail's end pictures while rerunning a route in the
escape city (a bug found by the end remeasure, filed `bug`, inbox #1519 in breezy-magpie): a catch by the
escape city's roadblock ended the day with "It went wrong." (`Texts.DAY_LOST_DEFAULT`). The loss-text
table `Texts.HARD_FAIL_TEXT` has no `roadblock` line, so `DayController` falls back to the default. It
predates the refactor: v0.29.2 has the same gap.

**Read as:** a missing line of text, not a design change; the roadblock needs a line in the table's
voice. Whether other lethal events lack one is for the builder to check against the table.

**Items**, one file each:

- `roadblock-loss-line.md`: the line for a catch by the roadblock.

# minty-quail — The comments and system map items close · 2026-11-24

**The ask.** Two items of the entry's list were open: `comments.md`, which asked that every file a
refactor pull request touches have its comments brought to the present tense in that pull request, and
`system-map.md`, which asked that the board's System map tab (an entity diagram of the whole system,
inbox #1167 in gray-dolphin) be drawn again from the code once the redesign is complete.

## Why each is done

- **`comments.md` is done**: every code item of the entry has merged, so no refactor pull request is left to
  carry it. The rule itself lives on in **godot**'s "Comments are written in the present tense", which
  governs every `.gd` edit from now on. A sweep of comments in files no refactor pull request touched
  (a rough search finds about 140 candidate lines, many of them ordinary English) is outside the item's
  ask and would be an entry of its own after minty-quail, the orchestrator's call.
- **`system-map.md` is done**: the orchestrator redrew the board's System map tab from `main` at
  `f98443b5b` on 2026-11-25 (two mermaid diagrams and the table of the entities). Only the orchestrating
  session reaches the board, so the tab is not in the repository.

## What changed

Both files are deleted. The sentence of amber-ibis's "Five sentences that say something the code does not
do" that pointed at `comments.md` points at **godot**'s rule; the entry's README names only the remeasure
(its step 1; the module-by-module step is removed because every module is done) and the pull request that closes the entry, and silver-ferret's pointer at the remeasure's
step says "the remeasure". Nothing was measured.

# spotted-trout — A defect a refactor step finds is filed to be fixed, never only noted · 2026-11-17

**The ask.** The dawn phases' second pull request (#1449) found the code and the docs disagreeing
about day 6's loudspeaker masts, and the orchestrator asked whether to investigate, adding "If it
turns out to be a bug, it goes in the bug lane. Otherwise I'll leave it noted." The player: "yes,
refactor surfacing bugs is a positive outcome", then "we need to fix those" (silky-lemur #1450).

**What was built.** The rule is written into **orchestrating** ("What the orchestrator keeps", the
bullet on a defect a refactor step finds): a defect a refactor step finds, where the code does
something the player's decisions say it should not, is filed at once as an entry of its own and
fixed to the player's decision for the thing, found in the records and playtests that built it,
never left only as a line in a record, a report or a pull request. It covers code a refactor step carries over unchanged; a
defect the step introduces, or one a review finds in its open pull request, is fixed inside that
pull request. **pr-review**'s question "Is every defect already found in this change fixed inside
it?" points to it for such a carried-over defect, and a review names one it finds so the
orchestrator files it (marked there as the filer's addition). It sits with minty-quail's frozen-list paragraph as written: the
entry filed for such a defect waits after the refactor like anything else found (inbox #1210 in
gentle-owl), and is fixed then.

**Proposed, not asked for, open to the player:**

- **The band**, `now`, the player moving one to `bug` when they want it ahead of everything: the
  orchestrator's pick on the board question `refactor-bug-band`. The other answer put to the board is
  `bug` for every such bug, the orchestrator's first reading of the player's "yes" to a sentence that
  named the bug lane, which collides with **playtest-feedback**'s rule that `bug` is filed only
  where the player names it (mossy-ferret #710).
- **Where the records and playtests say nothing** about the thing, the question goes to the board
  before either the code or the doc is changed to match the other.
- **Where the rule lives**, **orchestrating**, the filer's proposal in the item.

**Already settled before this entry:** the case that prompted it was no bug. The player kept day
6's stacked broadcast, "it felt fine during play so let's keep and change the wording instead"
(silky-lemur #1450), and #1451 changed the two sentences that said otherwise (the record M180).

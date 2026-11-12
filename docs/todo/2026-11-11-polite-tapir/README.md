priority: now
fable-only: true

# polite-tapir — The refactor's design review: placement drawn as she walks, the event scheduler broken up, one start for every kind of day, the standing layer breaks, the baseline measurements · filed 2026-11-11

**The ask.** The player had the refactor's design reviewed, the refactor being minty-quail (one
engine: the codebase refactored by layer): "have a fable agent review the design of the refactor"
(inbox #1265 in olive-ferret). Shown the review's findings, the player answered them point by point,
then "let's apply the suggestions", "agree on all design review points. let's do it", and, of the
mechanisms the review worked out, "I saw the review and approved it" (inbox #1268 in olive-ferret).
The five items in this folder are that review's work; each opens with the finding it answers and the
player's words on it.

**Read as:** the work is the refactor's own, as minty-quail's is: minty-quail's "the refactor is the
one thing to complete right now" (inbox #1210 in gentle-owl) holds for it, an entry that waits for the
refactor waits for both entries, and the two are worked side by side. Neither waits for the other to
start, so this entry has no `after:` line; where an item here waits on a particular item of
minty-quail's, or one of minty-quail's on an item here, the item says so.

**Whose the label is.** The player: "there were two reviews run by fable and the resulting items from
that were the only ones that were approved to get fable-only", "nothing else", and, told that the
line marks a whole entry while the review's items stood inside minty-quail beside thirteen that no
review gave, "if the mechanism doesn't support it then let' smove those items out and put the label
then" (inbox #1387 in mossy-bunny). **Read as:** this entry carries `fable-only: true`, so every pull
request that builds one of its items carries the `fable-only` label: Fable designs its code and
reviews it, and writing the code may go to another model (`docs/TODO.md`). minty-quail carries no
line. The other review of that day, of the rule files (inbox #1267 in olive-ferret), gave the entries
amber-ibis and gentle-finch, which carry the line too.

**An entry of its own.** "don't keep stacking more work on existing items -- you have enough tools to
control exactly the work order" (inbox #1387 in mossy-bunny): the order against minty-quail is set
below and in each item, and the entries that wait for the refactor name this entry in an `after:`
line beside minty-quail.

## Order

The review's tracks run beside minty-quail's, module by module (inbox #1268 in olive-ferret: "yeah
module by module makes sense and can be parallelized"). The tracks are the review's worked-out
detail, which the player approved.

- **Placement:** `placement-by-construction.md`'s steps with `scheduler-breakup.md` interleaved.
  Nothing else changes where events go until it is done (inbox #1185 in gentle-owl). Where it meets
  minty-quail: the scheduler's dawn context comes after the event manager's own city, the first
  part of the third hand-ins pull request (minty-quail's `city-hand-ins.md`); the first steps of minty-quail's
  `event-interface.md` (the callers outside the events folder, the live event's behaviours and
  looks) run beside placement, and its dawn, the event manager's parts, the resistance and the
  scene recipes follow placement and the scheduler's breakup; minty-quail's `re-derived-cases.md`
  closes with the breakup's `RowGround`; a probe minty-quail's `typed-everywhere.md` lists is typed
  or deleted by placement's step 4.
- **Run flow:** who builds the events and the crowd (`one-start-for-every-spec.md`), together with
  the last part of the third hand-ins pull request (minty-quail's `city-hand-ins.md`), landing
  between two placement pull requests.
- **The standing layer breaks** (`standing-layer-breaks.md`): one pull request per group, each in
  its module's turn of minty-quail's order (within a module, its dead code, then its standing
  breaks, then its interface and field reads, then its suites). Dawn planning's reads move with the
  scheduler's breakup and are settled by row 3a of minty-quail's `event-interface.md`; the city
  scene as builder goes with the run flow above; the building's pass in minty-quail's order
  (`src/interior/`, `src/finale/`) takes its one read of `WorldMap.world` with the map interface's
  world half.
- **The baseline** (`baseline-measurements.md`): a reading when placement closes and one after the
  events' field-read conversion (row 4b of minty-quail's `event-interface.md`), for the remeasure
  that closes minty-quail.

**The "before" is captured while the old tree can still be measured** (inbox #1268 in olive-ferret).
The design review found that no baseline commit is named, that no winnability or route-cost numbers
from before the refactor are stored, and that a probe asks only what every tree has, so once the
events' fields are behind methods no probe runs on both the old tree and the new; the player, shown
that capturing them blocks nothing: "sure". *Read as, with the specifics proposed by the
orchestrator and open to the player's correction:* the baseline is `v0.29.0`, the tree minty-quail's
first review read. `baseline-measurements.md` captures the before-numbers into `docs/evidence/`, and
takes one background reading of winnability and frame time when placement closes and one after the
events' field-read conversion, so the end remeasure can say which half moved a number. None of it
blocks a step or changes the player's "remeasuring at the very end" (inbox #813 in curly-moose): a
reading is recorded, not judged.

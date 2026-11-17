# A bug the refactor surfaces is filed to be fixed, and the rules say so

**The ask:** "we need to fix those", of bugs the refactor surfaces (silky-lemur #1450), said to the
orchestrator's "If it turns out to be a bug, it goes in the bug lane. Otherwise I'll leave it
noted."

**Read as:** when a refactor step (minty-quail or polite-tapir) finds that the code does something
the player's decisions say it should not, the defect is filed as an entry of its own to be fixed,
never left as a line in a record or a pull request. It is fixed to the player's decision for the
thing, found in the records and playtests that built it; where those say nothing, the question goes
to the board before either the code or the doc is changed to match the other.

**Where it is written:** no skill says yet what is done with a defect a pull request finds outside
its own work (**pr-review**'s "Is every defect already found in this change fixed inside it?" covers
only defects in the change itself), and minty-quail's `README.md` holds the frozen-list paragraph
("anything else found from here on is filed as an entry of its own after this one"). The pull
request that builds this item writes the rule into the skill it chooses, **orchestrating** being the
filer's proposal, cited to silky-lemur #1450, and reconciles minty-quail's sentence with it.

**Open, for the board before it is built:** the band such an entry gets.

- **`bug`, with no `after:` on the refactor entries:** the orchestrator's reading of the player's
  "yes" to "it goes in the bug lane". It is started at once, beside the refactor. It collides with
  **playtest-feedback**'s rule that `bug` is filed only where the player names it (mossy-ferret
  #710): the player said "yes" to a sentence that named the lane, which may or may not count as
  naming it for every later bug.
- **The band the player gives each bug as it comes:** the orchestrator asks on the board for each
  one, and it is filed `now` with `after:` the refactor entries until the player names `bug`. Safer
  against mossy-ferret #710, slower to fix.

*Proposed, not asked for:* the first, since "we need to fix those" answered a message that named
the bug lane; the board question decides it.

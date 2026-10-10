# calm-pelican — Defects found re-reviewing the PRs since v0.25.0 · 2026-10-10

The player asked, inbox #632 in [dotted-wombat](../playtests/2026-10-10-dotted-wombat.md): "Check
all PRs since the last minor release and review them again (note all defects as work items)."
v0.25.0 is read as that release; its own commit is PR #539, so the 33 PRs merged after it were
reviewed again (#547 to #629).

**How.** Six review agents split the PRs by area — the queue filings, the tooling and skills, the
controls and pursuits, the task scenes and route events, the performance and telemetry work, and the
trailer and drawings — each reading the player's words and the records first, then the code, and
checking every finding against `main` at be97976b. Each PR has one review by `claude-reviewer`
naming its head and merge commits and the verdict it would have had; a merged PR's review is a
comment, since nothing on it can change. Twelve would not have been ready (#552, #564, #565,
#567, #570, #580, #585, #588, #590, #592, #597 and #603), three of them (#564, #585 and #590) for
doc or comment wording alone.

**Where the findings went.** Defects still on `main` that need code or a test are the items under
`docs/todo/2026-10-10-calm-pelican/`, each naming its PR; the ones that need the player's answer
first are marked open there. Findings that were only text were corrected in the filing PR (#636):
sandy-ferret brought in line with the M226 that was built, jolly-hare naming grassy-alpaca,
sunny-finch naming M100, tall-walrus and sunny-finch marking their questions as the player's,
olive-badger's forced cases made conditional, M204 retitled to its one remaining item and moved to
`later`, the breezy-wombat review item naming the first sheet that escapes by design, a sentence
each in the busy-hedgehog and tiny-beaver records, and the pelican evidence README. Two skills were
corrected and flagged to the player: **committing** stated as permanent that the bots' tokens cannot
upload attachments, which holds only at the pinned upstream commit; **using-tools** pointed the
scene-recipe and scene-draft rows at **verify**, which says nothing about drafting. The findings on
#603 inside [leafy-marten](2026-10-10-leafy-marten.md)'s files are an item of that
entry, since its agent is rewriting those files.

**Not filed, open to overturn:**
- #573 asked for a hook that denies `git stash`, or for the reason prose is enough. Prose is judged
  enough here: the rule's harm is popping a sibling's stash, which only an agent told about stashing
  would reach, and every brief carries the rule. A recurrence is what would make the hook worth it.
- #573's note that a pushed WIP commit stays in branch history: a squash merge keeps it off `main`,
  and **committing** already allows a messy branch.
- #596's `MAX_QUERY_BYTES` (30,000) is one measurement of GoatCounter's limit; nothing changes
  unless it is hit.
- #629's two links to one video and its thumbnail URL went with frosty-egret (#635).

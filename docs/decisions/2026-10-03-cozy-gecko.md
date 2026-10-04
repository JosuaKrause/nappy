# cozy-gecko — The checkpoint is a gatehouse, and the van lines read right · built 2026-10-03

*([minty-hedgehog](../playtests/2026-10-03-minty-hedgehog.md), statement 7, note #436: "We should
us "gatehouse" instead of "hut". The "van...before it's light" doesn't read right"; asked which line
reads wrong: "the former but the latter needs improvement, too, light is ambiguous"; "keep
identifiers but change texts")*

**Built (PR #473).** Everything a player or a reader of the docs reads says gatehouse. Day 9's
brief (`src/ui/day_summary.gd`) is "They have closed the districts off from each other. There are
gatehouses at the crossings." The reader-facing prose in `docs/MECHANICS.md`, `docs/CITY.md`,
`docs/EVENTS.md`, `docs/SCENE_RECIPES.md` and `docs/NARRATIVE.md` says gatehouse too. The
identifier `checkpoint_hut`, its `EventDef.display_name`, the docs that name identifiers
(`docs/ARCHITECTURE.md`, `docs/GRAPHICS.md`) and the player's quoted words keep "hut".

**Day 7's mark** (`src/resistance/resistance_steps.gd`) is "A van is waiting on the sidewalk.
Don't come home empty-handed." Asked on 2026-10-03 to choose between that and "A van is waiting on
the sidewalk. It has something for you to bring home.", the player chose the first (inbox #470 in [quiet-yak](../playtests/2026-10-03-quiet-yak.md):
"Empty-handed (Recommended)").

**Day 8's brief** is "A van took someone from the next street before dawn.", the filer's proposal,
not the player's words, and open to overturn: [the review item](../review/2026-10-03-cozy-gecko.md)
asks the player to read it.

**Verified.** `tools/check.sh` and `tools/lint.sh`; no test pins these strings. The stills in
`docs/evidence/gatehouse-2026-10-03/` show days 8 and 9's briefs on the day summary, rendered from
a throwaway scene because `tools/shot.sh` with `--day-length 2` did not reach the summary (the
builder saw the clock stop at two seconds; not investigated). Day 7's mark has no still: it shows
only after walking to the chalk mark, which no dev-flag start reaches.

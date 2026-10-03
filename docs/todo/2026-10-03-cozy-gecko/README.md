priority: now

# cozy-gecko — The checkpoint is a gatehouse, and the van line reads right · filed 2026-10-03

> "We should us "gatehouse" instead of "hut". The "van...before it's light" doesn't read right"

[minty-hedgehog](../../playtests/2026-10-03-minty-hedgehog.md), statement 7 (note #436). **The player reads "gatehouse", never "hut"**, and the identifiers
stay ("keep identifiers but change texts"): the only "hut" a player reads is day 9's brief, "There
are huts at the crossings." (`src/ui/day_summary.gd`), and the docs that describe it to a reader
(`docs/MECHANICS.md`, `docs/CITY.md`) say gatehouse too; `checkpoint_hut` and its
`EventDef.display_name` stay as names. "gatehouse" is already the trailer's word (PLAYTEST-139).

**And both van lines are rewritten**, day 8's brief first (`src/ui/day_summary.gd`): asked which
line reads wrong, the player answered "the former but the latter needs improvement, too, light is
ambiguous". Day 8's brief is "A van took someone from the next street before it was light."; day 7's
mark is "A van is waiting on the sidewalk. Don't come home light." (`src/resistance/resistance_steps.gd`),
whose "light" can be read as daylight or as carrying nothing.

**Proposed, not asked for:** the new wording, the filer's, offered in the PR for the player to
change: day 8, "A van took someone from the next street before dawn."; day 7, "A van is waiting on
the sidewalk. Come home with the parcel."

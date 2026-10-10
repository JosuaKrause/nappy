# Whether a pursuer notices and lunges through a building

**Medium, a question for the player · from the re-review of PR #552 (polite-rabbit, a pursuer
catches her only by touching her).** Since #552 the catch needs her touched, but the 140px notice
range (`pursues_within`, the distance at which he turns to face her) and the lunge still work
through buildings: the alley robber notices her through a building and lunges across it, close to
what the player described in #544, "He couldn't reach me. But it was instant". The question is open
only in [polite-rabbit](../../decisions/2026-10-04-polite-rabbit.md) and
[polite-rabbit-2](../../decisions/2026-10-04-polite-rabbit-2.md); nobody asked the player.

**Answered in part by the player** (inbox #648 in [leafy-puffin](../../playtests/2026-10-10-leafy-puffin.md)), asked whether noticing and the lunge
should need a clear line: "yes noticing needs a clear line". A pursuer notices her (turns to
face her within `pursues_within`) only along a clear line. **Still open, for the player:** the
lunge, which the answer does not name. If it needs a clear line too, the events skill's rule
holds: a lunge held back by a wall starts from the full stand-off when she walks.

**Low, same area:** the comment on `EventInstance.will_be_lethal()` (it decides whether the doubled
red caret shows) says it asks "the same geometry `is_lethal_at()` tests", but the real catch now
also needs a clear line; the caret staying straight-line was #552's choice 4, open to overturn.
Make the comment say the caret projects the straight-line reach without the clear-line test. And
`will_be_lethal()` measures against `def.inner_radius` rather than `def.lethal_reach()`, which
gives the hunting roadblock a caret radius larger than its catch (older than #552).

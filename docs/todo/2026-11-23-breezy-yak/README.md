priority: later

# breezy-yak — minty-quail: stale lines in its entries and record nits · filed 2026-11-23

**What this is.** What the minty-quail planner's list gave, each checked against the tree on 2026-11-23: lines
in minty-quail's entry that are no longer true, and nits in three records. A filing from the session's reviews, not from the player's words; the band,
`later`, is the filer's proposal. A builder re-checks each against the tree first, since lines move. Each stale
line is rewritten in the present tense where it stands; the nits are fixed in a docs-only pull request.

**Stale lines.**

- minty-quail's `typed-everywhere.md`, "Build", says every file under `tests/` "carries no file-level ignore
  but the two below", and nothing below names two; its "Done when" holds for the files under `tests/` (what is
  left of it is the two `PROBE` scripts' strings and the files under `src/`). Both lines say what is true.

**Record nits.** `docs/decisions/2026-10-18-minty-quail-speckled-hare.md` and
`2026-10-18-minty-quail-jolly-ibis.md` end without a final newline; line 14 of
`2026-10-18-minty-quail-merry-osprey.md` is 155 columns (a trailing space was reported there and a check on
2026-11-23 found none: the line is rewrapped to the width its neighbours keep).

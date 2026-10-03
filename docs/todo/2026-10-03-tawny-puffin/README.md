priority: next

# tawny-puffin — Safari keeps the game when its tab is left · filed 2026-10-03

> "it seems like navigating to a different tab on safari unloads the page. this is not great since
> it basically costs a live to interrupt a game. on chrome this works correctly (the page stays
> loaded)."

[minty-hedgehog](../../playtests/2026-10-03-minty-hedgehog.md), statement 6 (note #435). **Find out why Safari unloads the game's tab when the player leaves
it, and keep it loaded if it can be.** `src/main.gd` pauses when focus is lost, but a page Safari
discards reloads, and a day under way resumes at dawn with a nerve charged. Adjacent work is built:
the rosy-chipmunk record (web saves wait for IndexedDB and retry after Safari drops its connection),
with its iPhone check still open in `docs/review/2026-10-02-rosy-chipmunk.md`.

**Only if Safari cannot be fixed**, the note's fallback — "saving the full state of the game on every
blur (and in regular intervals) and allowing to reload from the last location without penalty" —
comes back as a question to the player (the player: "yes", asked to investigate first). It is the
exact snapshot PLAYTEST-82 parked ("We don't want to be able to cheat by closing the window and
restarting from a safer position"), which named this very symptom as what would make it worth
discussing again; the question quotes PLAYTEST-82.

**Proposed, not asked for:** the investigation's result is a record of what Safari does (page
lifecycle events, bfcache) and what keeps the page, tried on an iPhone by the player.

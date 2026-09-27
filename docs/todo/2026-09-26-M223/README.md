priority: now

## M223 — One file per queue entry and per decision, named by date and two words · asked for 2026-09-26

> "Split every file where appropriate. Even the review file. We overhaul all items that are
> currently relevant."

[PLAYTEST-144](../../playtests/PLAYTEST-144.md), statement 14. The layout itself is built: its
record is [2026-09-26-M223](../../decisions/2026-09-26-M223.md). What is open is the overhaul the
player asked for with it. The split moved every open entry and review item as it was written; none
of them has yet been re-read against its playtest.

The player's order puts M223 before the open pull requests' conversion
([2026-09-26-brisk-heron](../../playtests/2026-09-26-brisk-heron.md), statement 1: "get the hook in.
then the new planning rules. then we need to update all open PRs to follow the new planning
rules"). That the overhaul comes after the conversions, and before M225, is the orchestrator's
ordering: a conversion replays a PR's queue edits onto `main`'s entry files, and refuses where the
PR closes an item or entry whose file `main` has changed, or edits lines `main` rewrote, so an
overhaul first would make the conversion of every PR that closes or edits an entry refuse. The
player agreed to it (brisk-heron, statements 11 and 12: "sounds good" · "once all is updated let's
do the telemetry finally"). The overhaul reads the queue the conversions leave.

**Scope** ([PLAYTEST-144](../../playtests/PLAYTEST-144.md), statements 13 and 14): every queue
entry and review item still relevant is rewritten in full in the new layout, checked against the
player's own words; one that no longer applies is put to the player, never dropped silently.

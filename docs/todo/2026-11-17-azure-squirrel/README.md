priority: now
after: 2026-11-11-polite-tapir

# azure-squirrel — A posted roadblock guard charges a straight walker and misses her on some streets · filed 2026-11-17

**Where it comes from.** No words of the player's: the builder of polite-tapir's step 5 switch found
it on 2026-11-17. The entry, its band and its reading are the filer's proposal. Read as a defect a
refactor step finds in code it carries over (**orchestrating**, the bullet on such a defect,
silky-lemur #1450): it waits for the refactor (inbox #1210 in gentle-owl).

**What was found.** `docs/EVENTS.md` and `docs/MECHANICS.md` say that walking straight past a
posted roadblock's guard meets his charge. The player: "it should be in a way that luring away the
guard is enough" (inbox #771 in minty-lemur). **Read as** (the filer's reading): luring is the way
past, so a straight walk past a posted guard is the one that fails. On some
streets the guard charges and misses her: seed 77's street (7,0,1) walked forward and seed
4216201080's street (2,0,1) walked back each print `charged: 1`, `caught: false`, the first with the
band on the street's last tile. `tests/probes/escape_roadblock_cost.gd` shows it at main too, on 3
walks of 32 over 8 seeds, every one on a vertical street walked forward. The finale rig's check that
a straight walk past a posted guard is caught passed at main only because its seeds had none; the
step 5 switch, which moves which streets stand a band, holds it to a floor of half the walks caught
and names this entry.

**Items:** `why-the-charge-misses.md`.

priority: now

# dotted-hawk — In Hard Mode a won day gives no nerve back · filed 2026-10-11

[mossy-ferret](../../playtests/2026-10-11-mossy-ferret.md), #709:

> can we make hard mode not regenerate nerves as well?

Asked whether that means no regain at all, or regain only in some cases:

> (a) this doesn't affect *gameplay* it still only affects restart pacing

and what "gameplay" means:

> by gameplay I mean -- enemies are not harder. or excitement or sleepiness doesn't move in on different values

> or distribution of events doesn't change

> anything that happens *during* a day is gameplay

The player named it among what is picked up next (#710), so it is filed `now`.

**What it changes.** Today a day she wins gives one nerve back, up to five, in both modes
(`GameState.regain_a_nerve()`; `docs/MECHANICS.md`, "Nerves"). In Hard Mode a won day gives none: a
hard run starts with five and only loses them. A normal run keeps its regain.

**What it keeps.** The rule Hard Mode was built under stays as it is: *"hard mode doesn't affect
gameplay -- only restart pacing"* (`docs/MECHANICS.md`, "Two modes"; gentle-osprey). Nerves are
restart pacing, since they decide only when a run ends. The player's definition belongs beside that
rule in `docs/MECHANICS.md`: anything that happens during a day is gameplay, such as how hard the
enemies are, the values excitement and sleepiness move by, and the distribution of events, and Hard
Mode changes none of it.

The work is [no-regain-in-hard-mode.md](no-regain-in-hard-mode.md).

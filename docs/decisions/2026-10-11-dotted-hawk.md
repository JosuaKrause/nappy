# dotted-hawk — In Hard Mode a won day gives no nerve back · 2026-10-11

[mossy-ferret](../playtests/2026-10-11-mossy-ferret.md), #709: "can we make hard mode not regenerate
nerves as well?"; "(a) this doesn't affect *gameplay* it still only affects restart pacing"; "by
gameplay I mean -- enemies are not harder. or excitement or sleepiness doesn't move in on different
values"; "or distribution of events doesn't change"; "anything that happens *during* a day is
gameplay". Then [mossy-kestrel](../playtests/2026-10-11-mossy-kestrel.md), #718: "No regain in
escape either. Also, nerves behave the same in escape for hard mode so the game can actually be
lost".

**What it overturns, with the player's word.** gentle-osprey built a hard run's escape so that
getting out of the building gave one nerve back (*"Section won gives one back"*); #718 takes that
away. "hard mode doesn't affect gameplay -- only restart pacing" stands, with the player's definition
of gameplay beside it in `docs/MECHANICS.md`.

**What is built.** `GameState.regain_a_nerve_for_a_won_day()` gives a nerve back only in a normal
run; `finish_day()` and day 14's hand-over to the escape go through it.
`main._regain_a_nerve_for_leaving_the_building()` is gone, so nothing gives a hard run a nerve back,
in a day or in the escape; a lost section still costs one and the last is the bad ending.
`tests/test_day_loop.gd` wins a day in each mode, and `tests/test_run_checkpoints.gd` walks out of
the building through `main.tscn` with the nerves unchanged. Nothing that runs during a day reads
`hard_mode`: its readers are the title screen, `main`'s mode choice and escape nerve spend, and
`GameState`'s checkpoint and nerve logic.

*Chosen by the implementer, open to overturn:* a separate won-day function rather than a guard
inside `regain_a_nerve()`.

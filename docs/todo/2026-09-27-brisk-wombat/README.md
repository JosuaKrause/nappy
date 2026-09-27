priority: now

# brisk-wombat — The mark and its robber never appear in front of her · filed 2026-09-27

> "the mark is quite bugged. I just had one appear out of nowhere while I was walking through an
> alley and then a robber also appeared out of nowhere and instakilled me."

[olive-koala](../../playtests/2026-09-27-olive-koala.md), statement 7. A chalk mark and the `alley_robbery` guarding it (`ResistanceDirector`, `_begin_step()` and
`_maybe_set_a_trap()`) are placed when a step begins; nothing in the record says they are kept out
of her sight when they appear. The robber's catch is `hard_fail`, so a robber that appears within
reach of her ends the day with no warning, against the events skill's telegraph contract.

# plaid-goose — Can a player with a saved run choose Hard Mode · 2026-10-17

**Decide whether a player with a saved run can choose Hard Mode.** The Hard Mode box shows only on a
title with nothing to resume ([plaid-goose](../decisions/2026-10-17-plaid-goose.md)). The save is
written as day 1 starts, so every later boot of that run opens on a title without the box; the
held restart, or the run ending, is the way back to one with it, and nothing on screen says so. What
it must keep: the player's own "(if new game)" ([gentle-osprey](../playtests/2026-10-11-gentle-osprey.md)),
`docs/MECHANICS.md`'s "fixed for the run and carried in the save", and the title being "not a main
menu". The choices: (1) keep it new-game only, and the title says a held restart begins a new game
(the implementer's and the orchestrator's pick); (2) show it on the resume title, and ticking it
discards the save for a new hard run, so a tap on a setting throws a run away; (3) let it change
the resumed run's mode, which overturns "fixed for the run"; (4) add a "new game" control to the
resume title, the menu the title says it is not. Also asked in the session on 2026-10-17.

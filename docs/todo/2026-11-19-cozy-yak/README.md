priority: now

# cozy-yak — The crowd is handed a focus source, and set_focus goes · filed 2026-11-19

**The ask.** Asked on the Nappy board (question `crowd-focus-source`) whether the crowd may be handed a
focus source, what says where its patch of simulated streets stands, so that its tests stop needing
`Crowd.set_focus()`, a member only tests call (option A), or whether `set_focus()` stays public with
its reason written down (option B), the player: "A" (grassy-bison #1561).

**Read as** (the orchestrator's): the crowd is handed a focus source that says where its simulated
patch stands; `main` hands one that answers with her position, a test hands a fixed point, and
`Crowd.set_focus()` is deleted.

**What it stands on.** The player's rule that a public member only tests use is a loophole, so it gets
the underscore and tests go through what the game exposes (curly-rabbit #1098). minty-quail's
`tests-unseen-reads.md` listed `set_focus` among the members only tests read that stay, with this
change as its open question; the record minty-quail-lilac-walrus holds why it stayed: the crowd moves
its patch to follow her only in the player half of its live tick, which also shoves, warns and
strikes her, while the test rigs tick with `step()`, which has none, so a stroller handed in moves no
patch there and real frames would add bumps and strikes to every check.

**Item:** `crowd-focus-source.md`.

The band `now` is the filer's proposal; the note carried no band label. It is the refactor's own work
(minty-quail's tests-public-seams rule), so it has no `after:` line.

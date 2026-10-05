# Playtest grassy-goose — A touched target sends the robber from off screen

2026-10-04, playing the busy-raven scene for day 8. One note captured in the session, #556. The
player's words are copied word for word, after what they answered.

## #556 — Task targets: the robber arrives off screen already pursuing when she touches the goal

Said on 2026-10-04 while playing the busy-raven task scene for day 8, the burnt building
(`scene-recipes/task-08-burnt-shell.json`, a scene recipe on main after v0.25.2), where the docs say
"The guard robbers stand where the day puts them".

> okay, so I'm doing the burnt building task and the robber just stands there next to the building -- this is *not* how those tasks should work -- the robber should spawn in off-screen already pursuing when I touch the goal

Asked on 2026-10-04: `docs/NARRATIVE.md` says only the man shouting's note and the van's package send
someone after her from off screen; "every other task that rides on something in the street or sits
on a bare point — the burnt shell, a roadblock, the district door, a mast's foot, the swing, the last
night's front door — keeps a robber waiting near it, as a mark does" (62–176px from the target).
"Which tasks should switch to a robber arriving off screen, already pursuing, the moment she touches
the goal?" Options: "Every guarded target (Recommended)" — burnt shell, district door, mast's foot,
swing, last night's door: no robber waits at any target; touching it sends one from off screen, as
the note and the package already do; the roadblock keeps its own guard (it is a guarded place by
nature); marks stay guarded by their two-thirds-in robber. "Every target, roadblock too". "Only the
burnt shell".

> Every guarded target (Recommended)

Asked afterwards where the waiting robber came from: it predates
[M137](../decisions/2026-09-13-M137.md), which added the off-screen robber for the two tasks the
player had named and, after a review found a wider first cut unasked for, kept the waiting guard at
the others as "the smallest reading" of the player's answer then.

## Routing

**#556** → built in the pull request that files it: the burnt shell, the district door, a mast's
foot, the swing and the last night's front door no longer keep a waiting robber; touching each sends
one from off screen, already pursuing, as M137's trap does for the note and the package. The
roadblock keeps its guard and the marks keep theirs.

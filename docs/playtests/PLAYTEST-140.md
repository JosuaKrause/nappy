# Playtest 140 — Warnings come too early, the yeller does nothing, and a spent park is closed

2026-09-25. Said in conversation, answering the orchestrator's open questions after playing the
released page (v0.18.0) on a phone.

## What the player said

On a spent park, asked whether a park she already used may cost a route (M129):

> "a spent park should not be accesible and no route should go through it"

On `robber_giving_chase`'s warning of about 12.9s (M137, on draft PR #362), chosen so that walking
away could not escape him:

> "12.9s is a *long* warning to the point where nothing really happens anymore. I feel the same
> with the biker. it gets warned too early so most of the time you're already gone when anything
> happens."

On the phone stutter (PLAYTEST-138, statement 1):

> "phone stutter on chrome on android pixel 8 pro it's pretty regular nothing stands out in
> particular"

On the man shouting, asked what felt weaker:

> "the yeller has no effect on the meter and its halo doesn't even turn on"

And a bug:

> "also there is a bug when you lose with game over the title screen is sideways"

The player also asked what the walls-and-seals question was about ("what is the problem? that it
doesn't seal perfectly or that it does seal something that shoudn't?") and what the neighbor
note meant; both were answered in conversation and are not decisions.

## The statements

1. **A spent park is closed**: she cannot enter it, and no route of the day goes through it.
2. **A warning comes shortly before its danger**, not so early that nothing happens by the time
   it does. `robber_giving_chase`'s 12.9s is too long, and the cyclist is warned too early: most of
   the time she has passed before anything happens. The M137 choice of about 12.9s is overturned.
3. **The phone stutter is on Chrome on a Pixel 8 Pro, steady rather than at particular moments.**
4. **The man shouting charges nothing and his halo never lights** in v0.18.0 — a bug: his row in
   `docs/COSTS.md` says walking beside him costs about 6.5 points a second.
5. **After a lost day's game over, the title screen is drawn sideways.** Seen on the phone; the
   player did not say whether the desktop does it too.

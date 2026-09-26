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
5. **After a lost day's game over, the title screen is drawn sideways.** Seen on the phone.

## Then, in the same conversation

On whether it is on the desktop too:

> "the bug is only on the phone I think"

On the walls and seals: a region wall body beside a seal or another wall body can reach onto a
route junction, so the day's route costs something there. Asked whether they should step back
from the junction or whether the route may pay:

> "it's okay if the route costs something"

6. **The sideways title screen is on the phone only**, as far as the player has seen.
7. **A region wall or a seal may cost a route where it stands at a junction.** Nothing moves them
   back from it.

## Then, on the first pictures of a spent park (PR #374), 2026-09-26

The pictures showed a used calm area fenced all round with a street closure's barrier panels and
"closed" signs, which PR #374 did to every calm area she had used in the act. The design came from
the queue entry's wording ("the park is shut the way a closure shuts ground"), not from the player.

> "where do you get this from? I never asked for this. a park that was used should be shut down,
> yes, but by placing events in it how it was before. where does this barrier thing come from?
> doing it for one park, sure, more towards the later stages of the game once but not for regular"

> "yes, the corners look wrong, too"

8. **A used park is shut by the events placed in it, as before**, not by barriers, and no route of
   the day goes through it. Statement 1 is read this way.
9. **The barrier fence is for one park, once, late in the game**, not for every used park.
10. **The fence's corners look wrong**: the rails overshoot each other at every corner.

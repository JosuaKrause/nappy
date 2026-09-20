# Playtest 116 — No second mark, gates that kill on the far side, and four rows by feel

2026-09-20. Played on the desktop build at the commit released as v0.15.0, seven days, ending
on five straight losses of day 7. The run is
`docs/evidence/m176-second-mark-and-gates-2026-09-20/run-182517-seed2609743060-v0.14.0-8-g13493987/`.

## What the player said

> "this is a recent run a few notes 1) I did the first mark then the yeller (there should be an
> indication that I did it correctly) but then there was no second mark I checked multiple
> alleys. it should follow the same rules as the first mark in that it can basically be any
> alley you come across 2) the gate checks were placed in a way that I would basically
> immediately die after crossing them 3) when doing the gate I go in (disappear) the camera
> moves to the hut but when I reappear I briefly spawn at my old location before teleporting
> to the new location. I should directly spawn at the new location"

Then, one message each, while the above was being read:

> "unleashed dog still has too little influence -- needs to be more intense"

> "but keep things in relation to each other"

> "also protesters have very little excitement?"

> "should be a bit more"

> "guard posts should emit less excitement by themselves, too"

> "since there can be other obstacles around"

> "but there should be a gap for events immediately surrounding the gates"

> "also since two gates can be adjacent to each other their influence shouldn't add up"

## What the run says

**1. The second mark was placed, pinned beside the home before she moved, and never found.**
Step 1, the chalk mark, was completed on day 4 at tile (65,83) and step 2, the man shouting,
on day 5 (`step 2 retargeted onto the nearest look-alike reached first`, `step 2 completed`).
On day 6 step 3, a chalk mark again, was on offer at (24,149); two seconds into the day it
`moved to (65,83): never seen at (24,149)` — the nearest alley to her doorstep at (80,84), and
the very alley step 1 was taken from — and 0.4 seconds later the log says `step 3 seen at
(65,83)`. *Seen* is `ResistanceDirector`'s sticky flag: once the mark's position has been on
screen it never moves again that day. It was on screen from the doorstep, so the rule that
lets a mark follow her to "any alley you come across" was switched off at 2.4 seconds, for an
alley fifteen tiles from where she stood. Day 7 shows the rule working when it is allowed to:
the mark moves to (94,90) and again to (83,65) as she moves. Nothing in the log acknowledges
step 2 beyond the telemetry entry.

**2. A gate lets her out into fields nothing could survive.** Day 7, first attempt: taken in
by `checkpoint_hut` at 5.2s with the meter at 10, `meter +25` for the hold, and the fields
around the door keep charging while she stands in it — she comes out at 7.3s with the meter at
72, on the north side, 57, 61 and 112px from three `roadblock`s and 66px from a
`police_patrol`, taking 54 a second from events. She is crying 0.4 seconds later. Attempts 3, 4
and 5 end the same way within two seconds of a release, the fourth beside a `dog_walker` at
70px. A `roadblock` emits 13 a second out to 86px and the patrol 10; a hut and a post 6 each,
which a walk cancels and a hold, where she stands still and earns no decay, does not.

**3. The reappearance.** The release is `body.teleport_to(released_at)` in
`EventManager`, after the camera has gone to the hut; the player sees her drawn at the place
she went in for a moment before she is at the place she comes out.

**4. The loose dog goes past her while it is still telegraphing.** Every `near` entry for
`loose_dog` in the run reads `(telegraph)`, down to 20px: `loose_dog (telegraph) at (27,90),
22px … events 5.7`. It runs at 132px a second through a 2.25 second telegraph, during which a
row emits `Tuning.TELEGRAPH_INTENSITY_FRACTION` (0.15) of its intensity, so it covers about
300px at 15% and is behind her before it is ever at 39. `docs/COSTS.md` says a pass nets +15.0:
the pass simulation starts its clock after the telegraph, which is not how this row is met.

**5. The protest** emits 15 a second over 269px on an eight-second pulse: walking beside it
nets +3.4 a second awake and nothing asleep (`docs/COSTS.md`), and it lost 2.5 a second to the
walking decay like every row tuned before 2026-09-12.

## What is asked for, as statements

1. **Completing a resistance step is acknowledged**, so that she knows she did it correctly.
2. **The second mark follows the first mark's rule**: it can be any alley she comes across.
3. **A gate never lets her out into something that kills her at once.**
4. **She reappears at the place she is let out**, never for a moment at the place she went in.
5. **The loose dog is more intense**, with the rows kept in relation to each other.
6. **The protest costs a bit more.**
7. **The guard posts emit less by themselves**, since other obstacles can stand around them.
8. **Events keep a gap around a gate**: nothing is placed immediately around one.
9. **Two gates next to each other do not add up**: what a door's parts put on the meter is
   one door's worth, however many of them stand together.

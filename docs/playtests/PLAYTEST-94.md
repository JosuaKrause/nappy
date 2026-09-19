# Playtest 94 — The save on a phone, the escape walked, and walls still on the route's side

**Date:** 2026-09-19

Played on the released page on a phone (v0.13.0) for the save, and on the desktop build for the
escape (`tools/run.sh --start-escape --seed 4242`). The desktop run's folder is
[`evidence/playtest-94-2026-09-19/`](../evidence/playtest-94-2026-09-19/); its log carries the
finale's plan line twice, which is the one section restart of the run, and every line in it is
stamped `0.0`, so it cannot say when anything happened. The phone session left no log, since a
release build writes none.

## What the player said

> "I confirmed saving working on a phone with the proper day briefing after reloading after a
> save. however, the save icon is basically a white square. also, I still get hard walls on the
> side of the sidewalk that is on the path -- how can this be so hard to do correctly? the escape
> is okay but there should be a fire on the left like it is right now but the top floor right side
> should be completely blocked off with rubble. then the pursuing guy should respawn forcing to
> switch the side again. the steam frequencies are too slow and there are only two steams and they
> are not blocking in any way they should go in the narrow hallways. I still spawn with flashing
> !!! in the city. restarting should still have the day brief for both the apartment escape and
> the city escape even if the nerves don't go down. also I just saw a barrier turn into a mask men
> (the barrier disappeared and the masked man appeared) and the pursuit ended way too early (I got
> caught when I was still very visibly away from him)"

## What is asked for, as statements

### The save

1. **Saving works on a phone.** Reloading after a save brings up the proper day brief. This
   closes the phone half of the `REVIEW.md` entry *Close the game in the middle of a day and open
   it again*; the desktop build and the laptop browser, the wording of the line, and whether a new
   release finds the old save are not spoken to and stay.
2. **"the save icon is basically a white square."** `assets/ui/save.svg` is three white shapes
   told apart only by opacity — the body at 0.85, the shutter at 1.0, the label at 0.35 — and
   `SaveIndicator` tints and fades the whole texture with one modulate, so at the size and
   opacity it is shown at the three merge into one square. The shutter and the label have to be
   told from the body by shape, as holes or as outline, rather than by opacity.

### Walls on the route's own sidewalk

3. **"I still get hard walls on the side of the sidewalk that is on the path -- how can this be so
   hard to do correctly?"** A re-report of M129, a path through the city never has to cost
   ([PLAYTEST-69](PLAYTEST-69.md), [PLAYTEST-71](PLAYTEST-71.md), [PLAYTEST-75](PLAYTEST-75.md),
   [PLAYTEST-76](PLAYTEST-76.md), [PLAYTEST-77](PLAYTEST-77.md)), and it answers the first of the
   three questions in the `REVIEW.md` entry *Walk day 1 along the tinted kerbs and look at both
   sides of every street*: the walked side does not read as a street with the things she cannot
   pass taken off it, because they are still there. The player did not say which body, on which
   seed or day. What is built refuses the route's own sidewalk to four rows only — the café
   tables, the market stall, the roadworks and the ice cream van — and only inside the
   scheduler's candidate loop; `TODO.md`'s open M129 item, *which placements the three rules never
   see*, already names the other paths a body reaches the day by (the seals, the calm-ground pass,
   the region walls and doors), and day 1's own side is recorded as carrying the parked van, whose
   gap to the frontage is narrower than the pram. The finding is filed there rather than as a
   second design.

### The escape, inside the building

*"the escape is okay"* — and then five changes.

4. **The fire stays on the left, as it is.**
5. **The top floor's right side is completely blocked off with rubble.** So from her own door the
   right stairwell cannot be entered at the top floor at all, and the first descent is forced down
   the left, past the fire's side.
6. **"then the pursuing guy should respawn forcing to switch the side again."** The masked man
   comes again after his first run, so that the side she switched to stops being safe and she has
   to switch back. Today he runs the height of one shaft once.
7. **"the steam frequencies are too slow"**: the vents' periods are 6.5, 8 and 9.5 seconds with a
   2 second blow (`Tuning.FINALE_STEAM_PERIODS`, `FINALE_STEAM_BLOWS_FOR`).
8. **"there are only two steams and they are not blocking in any way they should go in the narrow
   hallways."** Three vents are placed; two were met. A blow is one 32px cloud and the corridor
   where they stand is 64px wide, so she walks past one. The design of
   [PLAYTEST-85](PLAYTEST-85.md) stands — *"multiple fixed locations with steam that fully block
   the path"* — and what is added is where: in the narrow hallways, where one cloud is the whole
   width. This answers the `REVIEW.md` question *does it read as shutting the whole passage, or as
   something to squeeze past*: something to squeeze past.

### The escape, in the city

9. **"I still spawn with flashing !!! in the city."** She comes out of the service exit with the
   danger mark already up. The flashing mark is what `EventManager` raises for a live lethal row
   whose contract is about her; the finale puts trucks, vans, masked men and bursts on every open
   street, so the likely cause is one of them reaching the doorstep at the moment she appears;
   which row raises it on seed 4242 has not been traced.
   [PLAYTEST-85](PLAYTEST-85.md)'s rule for the spawn is the one that governs: *"the spawning
   shouldn't be a check. the pathing should start from the position. then obstacles can never
   happen"* — the ground she arrives on is free by construction, and that has to hold for a lethal
   reach as well as for a body.
10. **"restarting should still have the day brief for both the apartment escape and the city
    escape even if the nerves don't go down."** A section restart — capture, the meter, or the
    clock — shows the brief screen before the section starts again, for the building and for the
    city alike, with the nerves unchanged. Today it puts her straight back at the section's start.
    The no-cost restart itself (*"sounds good at that point you earned it"*, 2026-09-09) stands.
11. **"I just saw a barrier turn into a mask men (the barrier disappeared and the masked man
    appeared)."** This is the roadblock's hunting copy as built (`DECISIONS.md`, M56, the
    roadblock hunts): the finale's masked men on foot are roadblocks at full resistance progress,
    and the moment one notices her the barrier picture is swapped for a standing guard and the
    barrier's body is freed. It answers the `REVIEW.md` question *does a guard on foot read as the
    roadblock coming for her*: no, it reads as one thing turning into another.
12. **"the pursuit ended way too early (I got caught when I was still very visibly away from
    him)."** The roadblock's lethal `inner_radius` is 86px, raised from 24 so that the kill could
    fire from outside the 60px barrier plus her 14px body. Once the barrier is gone and a man is
    drawn, the same 86px — more than two and a half tiles — is measured from him, so she is caught
    at a distance that made sense for a barricade and not for a person.

## What was not spoken to

Whether a nerve lost to an accidental close reads as fair, whether the save symbol distracts, the
masked man's door margin, the one-tile basement stair, the choice at the service exit, the
millisecond clock and the epilogue. They stay in `REVIEW.md`.

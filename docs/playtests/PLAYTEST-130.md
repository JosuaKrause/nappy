# Playtest 130 — The mast is drawn near her, and the live page's ?debug=1 reaches the debug flags

2026-09-25. Said in conversation, answering two questions put after M181's late-day timing runs
(the last three late-day runs are timed).

## What was put to the player

1. **Day 11's loudspeaker mast.** The task's mast is drawn uniformly among the masts she can
   reach, so it can land in a corner of the map. On seed 1234567 it sits at the map's corner,
   reachable only through a gap between two moving vans (home at 156.0 s); on seed 4242 a late,
   far chalk mark is followed by a distant mast (home at 176.8 s, with 3.2 s to spare in a 180 s
   curfew day). Keep it random, or draw a mast nearer to her?
2. **`?day=N` on a phone.** Only on the debug build (served over Wi-Fi from a laptop), or also on
   the published site behind `?debug=1`, where anyone could skip ahead to any day?
3. **The release, v0.17.0.**

## What the player said

> "we need to tip the randomness to have the mast closeby"

> "on the published site behind debug=1 we'd want some of the debug flags (like day, invincible,
> etc.) so debugging the live build is easier"

> "if any changes are still necessary let's do them, then release"

## The statements

1. **Day 11's mast is drawn with the odds tipped toward the masts near her.** It stays a random
   draw among the reachable masts; a nearer mast is more likely than a farther one.
2. **The published site answers some of the debug flags behind `?debug=1`**, day and invincible
   among them, so the live build can be debugged. The player's "etc." leaves the rest of the set
   open.
3. **This overturns the 2026-09-06 rule "for release there should be no modifiers"**, which
   `DevFlags.enabled()` enforces, for the flags that `?debug=1` now opens. The player gave both
   instructions.
4. **Both changes go into v0.17.0**, and the release follows once they are in.

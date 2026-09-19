# Playtest 96 — The hallway windows flash too rarely

**Date:** 2026-09-19

Said in conversation after the escape walk of [PLAYTEST-94](PLAYTEST-94.md)
(`tools/run.sh --start-escape --seed 4242`). No further run attached.

## What the player said

> "the flashing lights in the window are too rare"

## What is asked for, as statements

1. **The hallway windows flash more often.** Today a window lights only when an off-screen
   explosion goes off inside the building section, one every 22 seconds
   (`Tuning.FINALE_EXPLOSION_INTERVAL`), held for 0.12 seconds
   (`Tuning.FINALE_WINDOW_FLASH_SECONDS`) — about four flashes over the 180 second clock when the
   whole clock is spent indoors, and one or two on a walk that gets out.
2. **What it collides with.** A flash and an explosion are one thing today, and an explosion is
   loud: it puts excitement on the baby for as long as it lasts. Shortening the 22 seconds makes
   the windows flash more often and makes the building cost more in the same stroke. The player
   asked for the light and said nothing of the noise.

## The rubble, seen while it was being built

On seeing the rubble that blocks the top floor's right side ([PLAYTEST-94](PLAYTEST-94.md),
finding 5; `assets/interior/hallway_rubble.svg` on the M168 branch), before its pull request was
open:

> "I like that rubble"

3. **The rubble's drawing is liked as it is.** Said of the picture; whether it reads as *this way
   is shut* in a walked escape is not spoken to.

## What was not spoken to

How often is right, whether every flash should be heard, and the length of a flash.

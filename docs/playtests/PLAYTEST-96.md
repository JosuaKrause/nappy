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

## What was not spoken to

How often is right, whether every flash should be heard, and the length of a flash.

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

## Every window flashes together

On seeing a capture in which the distant flashes lit some of the hallway's windows and not others
— which is what the orchestrator had asked the building agent for, *"a random subset so it reads
as something far off in one direction"*:

> "all windows always need to flash together. a single window cannot flash by itself"

4. **A flash lights every window at once, always.** Loud or distant, a flash is one event in the
   sky outside and every window shows it in the same frame. No window ever lights alone and none
   is ever left dark during a flash. *The random subset was the orchestrator's idea and was never
   the player's; it goes.*

## How often, in the player's numbers

> "do a biased random distribution between 100ms and 5s between flashes where the mean is 1.3s and
> the rest of the curve is smooth"

5. **The time between two flashes is random, between 0.1 and 5 seconds, with a mean of 1.3
   seconds, on a smooth curve** — biased toward the short end, no steps and no spike, and never
   outside the two bounds. This answers *how often is right* and replaces the orchestrator's
   first figure of 3 to 7 seconds.

## What was not spoken to

Whether every flash should be heard, and the length of a flash.

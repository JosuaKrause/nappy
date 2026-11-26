# Day 1's opening shot, an experiment

The player: "I'm not convinced of the opening shot yet but I can see how it could work. with a
closeby park. we could have the camera on the park for a brief moment then follow the desired path
back to the home then start. allow skipping", then "I think we can leave the opening shot to day 1
for now. but let's experiment" (curly-moose #819).

**Build, as an experiment:** on day 1 the camera rests briefly on the close park, follows the
intended path back to her door, and play starts; a tap skips it. It goes to the player as a burst
before it is kept.

**The experiment is the player's runs.** Asked whether "let's experiment" also means trying shots
on later days, the player: "it means I make a few test runs and see how it feels"
(minty-dolphin #834). **Read as:** the shot is built for day 1 only, and the player plays a few runs with it before
it is kept.

**Collides with** M151 (the first frame draws the doorstep: `docs/decisions/2026-09-15-M151-the-first-frame-draws-the-doorstep-built-the-hidden-city-overturned.md`)
and `tests/test_camera_start.gd`, which assert the first frame is on her; the shot changes that on
day 1, so the record that builds it says so.

**Owes the car-free start** (merged with its own item, record `grassy-beaver-woolly-goose`): the player
also said, of the title and the shot, "when showing the park, turn off car spawning so when the camera
comes back home no cars are around anymore" (minty-dolphin #867). The crowd's box is on her, so the
shot **moves the crowd's box with its camera** for its whole length, and **the hold starts on the
shot's first frame** (`Crowd.hold_new_cars()`, or the director's early hold), not when she is handed to
the crowd at play's start: otherwise the cars at her door are still there when the camera comes back.
The title keeps today's density.

*Proposed, not asked for:* a retry of day 1 skips it.

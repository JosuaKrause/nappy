# Day 1's opening shot, an experiment

The player: "I'm not convinced of the opening shot yet but I can see how it could work. with a
closeby park. we could have the camera on the park for a brief moment then follow the desired path
back to the home then start. allow skipping", then "I think we can leave the opening shot to day 1
for now. but let's experiment" (curly-moose #819).

**Build, as an experiment:** on day 1 the camera rests briefly on the close park, follows the
intended path back to her door, and play starts; a tap skips it. It goes to the player as a burst
before it is kept.

**Read as:** "but let's experiment" asks for the day-1 shot as an experiment; whether it also asks
to try a shot on later days is open.

**Collides with** M151 (the first frame draws the doorstep: `docs/decisions/2026-09-15-M151-the-first-frame-draws-the-doorstep-built-the-hidden-city-overturned.md`)
and `tests/test_camera_start.gd`, which assert the first frame is on her; the shot changes that on
day 1, so the record that builds it says so.

*Proposed, not asked for:* a retry of day 1 skips it.

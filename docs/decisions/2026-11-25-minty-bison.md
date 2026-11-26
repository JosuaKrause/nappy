# minty-bison — The browser check walks onto her front step, never into the street · 2026-11-25 · not from an entry

Three pull requests (#1790, #1752, #1791) and main's own run on a958615f2 failed the browser check
(`tools/web-template/browser-check.mjs`, CI's `browser` job) with "Timed out: summary to day 2".
Its screenshots showed why: in the day-one leg (seed 4242, a nearly settled baby) the scripted walk
held south for 1.5 s from the doorstep, straight off the sidewalk into the doorstep's own street,
and a crowd car hit her one to two seconds into day 1; day 1 restarted, so day 2 never came.

**The cause is the check, not the game.** The walk has stepped into that carriageway since the
check was written; whether a car happened to be passing depended on the city's day 1 and on the
frame rate the runner gave the page. The tutorial route (#1767) changed day 1 at seed 4242 (its
closure moved from roadworks at v(8,6) to h(8,6), and the seals added events), which moved the
crowd's cars so that one now meets her there. A crowd car on an open carriageway, horned, is the
painted-carriageway contract working (**crowd-traffic**), and the doorstep's carriageway mid-block
is not on day 1's route, so this is no breach of the tutorial's promise; a car near her door on day
1 is what the queued car-free start (grassy-beaver's item car-free-start) is to take away.

**Measured, locally** (a debug Web export, the check run in headless Chrome on a Mac, about 25 fps
against the CI runner's 4 to 13): the unchanged check failed 4 runs in 4 on main at a958615f2,
always a car strike at tile (80,37), road; the same check passed 3 in 3 on the tree before #1767
(89fbd3923); the changed check passed 5 in 5 on a958615f2, run alternately with the unchanged one.

**What changed.** Both walks hold north instead, onto her front step, the notch every city cuts
into the south edge of the home lot, which no car can reach: the day-one leg's baby falls asleep on
the step, which wins the day there (`DayController._on_baby_asleep()`), and the save leg's walk
stands at the door. A second "[Main] day 1 started" after the day-one leg's boot, the lost day's
retry, now fails the check at once with that reason instead of a two-minute timeout.

**Rejected:** walking a shorter way south (the sidewalk between the doorstep and the carriageway is
narrow, and a held key's length in game time depends on the frame rate, which is what made this
flaky); following day 1's route (it differs by seed and the check needs only a bounded win);
`--invincible` or a car-free query flag for the check (it would test a game nobody plays, and the
car-free start is a game rule still to be built, not a test switch).

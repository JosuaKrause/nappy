# frosty-marten — The screen-edge badge closes at the thing's own speed at any frame rate · 2026-11-25

**What was wrong.** `BadgeModel._measure()` divided the change of an event's position by each drawn
frame's delta. Events move on the 30 Hz physics tick, so on a tick frame a 3.7 px step was read over a
few milliseconds: 113 px/s on one run, 1949 px/s on another, for the masked man's own 110.

**Choice.** The measure, not the threshold. The model counts the seconds a point has held and reads a
move over all of them; a frame whose point has not moved inside `HOLD_WINDOW` (0.1 s) leaves the
measure as it was, and a stretch past it reads as standing (approach 0). A thing that has stood still
reads its first step over the physics ticks its frame carried (at least one, the shortest time a point can take to change; a display under 30 fps carries two). Rejected:
raising `CLOSING_SPEED` or clamping the approach, which would hide the inflated number and leave
the badge's arrival order wrong.

**Check.** `tests/test_badge_model.gd` steps a charging masked man whose point moves per 30 Hz tick at
30, 60, 144 and 500 fps and asks that his badge opens and peaks at his own 110 px/s; on main it read 220,
528 and 1833 at the last three. The three charger cases that moved him by a 60 Hz frame on his first
step move him by a tick's step, as the game does.

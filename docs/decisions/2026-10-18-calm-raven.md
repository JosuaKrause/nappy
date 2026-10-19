# calm-raven — The escape's stairs, the stairwell guard's radius, and doors under her · 2026-10-18 · not from an entry


The player (minty-lemur #783): "walking on the stairs should snap to 45 up or down angles -- if the
movement is towards the left it should automatically snap to the angle that is 45 towards the left (up
or down depending on which stair)", and when asked about landings, "if she is on a stair she goes
diagonally up or down depending on which stair outside of a stair she goes into the direction". On the
stairwell guard (minty-lemur #782): "should start charging when the player is at the end of the second
stair -- otherwise you can just walk to the door and never enter the stairs of the guard", then "make
the radius bigger to achieve the result -- don't place him higher up", "Accept off screen" for his
warning and "Accept it" for the one path a walker still gets through. On doors (minty-lemur #789):
"the escape doors should be in a way that the graphics is always under her".

**Built (PR #787):**
- **Her body walks a flight at 45 degrees.** The steering was already 45 degrees; her body zigzagged
  because the stair-side corners stood 22.6px apart across the slope against her 28px body. Each solid
  cell beside a flight is cut along the slope (`InteriorScene._blocker_outline()`), leaving edges
  25.5px either side of the flight's line (`FLIGHT_HALF_WIDTH` 1.125). On a stair she walks the
  stair's diagonal; off a stair she walks the way she presses.
- **The stairwell guard** (the masked man at the foot of the right shaft) keeps his post and charges
  within 426px (was 150px). Measured at the game's 30Hz: a runner gets through on every way down the
  second flight; a walker is caught on three of four lines, and one holding plain left from the
  landing tile between the two flights gets through 38px from him; the tightest runner is drawn 24.6px
  from him against his 28px catch and clears it on the tick at 28.6px; starting to run 0.3s late is
  caught. His warning is off screen in the stairwell.
- **Doors under her:** stairwell doors, thresholds and the emergency exit sat in her y-sorted layer;
  they now sit in a `Doors` layer under hers, as the lift door and entrance did.

PR #787 had three reviews of *not ready* over its published figures; the rethink and the measured
figures are on the PR.

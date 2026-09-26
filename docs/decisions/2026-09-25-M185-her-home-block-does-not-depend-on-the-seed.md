## M185 — Her home block does not depend on the seed · built 2026-09-25

*([PLAYTEST-134](../playtests/PLAYTEST-134.md): "the home building shouldn't depend on the seed. I
thought we fixed that?" · [PLAYTEST-136](../playtests/PLAYTEST-136.md): "so we keep the three floors
above the ground floor and keep the boarded up window on the top floor".)*

**What is built.** Her home block's three lots were already the same rects on every seed, carved
from `Tuning.BLOCK_SIZE`, `Tuning.HOME_SIZE_TILES` and the fixed middle block. What rolled was how
they were drawn: `City._variant_for()` now hashes a home-block lot's own position rather than the
seed, and `City._height_for()` gives her building `HOME_BUILDING_WALL_ROWS` (4: the ground floor
and three above it) and the two flanking ones `HOME_FLANKING_WALL_ROWS` (2). Window style, lit
windows and the rest follow from the variant; no home-block roof carries furniture at those
heights. Other blocks roll exactly as before. `tests/test_home_block.gd` holds it: the same
building on two seeds, four wall rows across a sweep of seeds, and a non-home building still
rolling.

**The neighbor's window is on her floor, the top one, wall row 3**, with no fallback since the
height is fixed. At the doorstep the normal camera shows only up to the second floor, and the
window comes into view when she faces her building, because the camera leads 46px the way she
faces (`Stroller.CAMERA_LOOK_AHEAD`); she starts each day facing south, away from it, so it is
seen walking home rather than leaving.

**The floors went back and forth before this**, all on 2026-09-25 and each in the player's words
in PLAYTEST-134 and PLAYTEST-136: the window moved to the second floor for the camera, the
building was shortened to three rows so she and the neighbor would share the top floor and the
start screen would show the whole front, the escape was to lose a floor to match ("two hallways
only"), and then both were kept at their floors, because on two floors the rubble on her own
floor leaves nothing to send her to the masked man's shaft. The escape keeps its three hallway
floors, and nothing in it marks the neighbor's door.

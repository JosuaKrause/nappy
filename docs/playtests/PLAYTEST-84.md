# Playtest 84 — The escape after the corrected stairs

**Date:** 2026-09-19

## What was checked

The escape sequence behind `--start-escape`, walked after M158, the staircase follows the
corrected tile grammar, had merged: the stairwells, the basement and its entry flight, and the
service exit onto the city.

## What the player said

> "there are more issues with the escape but the stairwell graphics are solved. other issues. the
> basement stairs are bad. the steam walks for some reason. the masked man is floating in the
> stairwell (the issue that you noticed as well). the spawn in the city from the basement can end
> up inside an obstacle. pathing is not done from the spawn but from the original door which is
> incorrect"

## The findings

1. **The stairwell graphics are solved.** A second acceptance of the main shafts' stair-side
   tiles, after [PLAYTEST-83](PLAYTEST-83.md).
2. **"the basement stairs are bad."** The basement's short entry flight is the one stair the
   corrected grammar did not reach: two `STAIR_FLIGHT_E` cells laid by
   `InteriorMap._build_basement()`, painted with the old `stair_flight_e.svg` tread and with both
   flanks of each diagonal step cleared of collision. The player did not say what is bad about
   it — the picture, the walk or both.
3. **"the steam walks for some reason."** `basement_steam` is `mobile` and `paces` at 18px/s
   between two points a couple of tiles either side of where it is placed. That was this side's
   choice, not the player's: the brief says *"maybe some steam in the basement"*, and the pacing
   was added so that a standing vent would not leave a four-pixel lane in a two-tile corridor
   (`DECISIONS.md`, M102, the finale built behind the flag). The player reads it as steam that
   walks.
4. **"the masked man is floating in the stairwell."** The same defect the review of M158 found:
   `InteriorEvents._place_the_masked_man()` runs him on a straight line from the lobby landing to
   the top landing, and those now sit in different columns, so the line crosses the shaft's solid
   cells. Filed under M165, the escape's events follow the corrected staircase.
5. **"the spawn in the city from the basement can end up inside an obstacle."**
   `FinalePlanner.service_exit_tile()` picks the pavement tile beside the home lot's middle row
   and checks only `CityMap.is_walkable()`, which knows tile types and nothing about what stands
   on the tile — street furniture, a parked or burnt car, a seal body, a crater.
6. **"pathing is not done from the spawn but from the original door which is incorrect."** The
   player did not say which pathing. The finale's two chains are grown by `FinalePlanner.plan()`
   from `service_exit_tile()`, the same tile she is put on, so the chains themselves start at
   the spawn as written; what still starts from the home's own doorstep has to be found before it
   is fixed.

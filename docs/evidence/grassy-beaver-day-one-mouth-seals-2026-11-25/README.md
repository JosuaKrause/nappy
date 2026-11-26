# Day 1's side streets sealed at their mouths on the tutorial route

**Claim.** On day 1 the side streets off the tutorial route past its first block are sealed at
their mouths, one tile in from the route's junction box, both sidewalks taken and the carriageway
open: here the east side street with a moving-van pair, the west one with a market-stall pair.

**Limits.** One still of one seed and one junction; it shows the placement, not that every side
street or alley is closed (`tests/test_seals.gd` holds that over its seeds), and nothing of the
lessons, which are not built yet.

**Source.** Commit e77c0ea10582640df89475d6229467d564a18e82 on `feature-grassy-beaver-tutorial-route`.

**Command.** `tools/shot.sh day1-junction-mouth-seals.png 13 --seed 72172 --walk 1s2w9s --invincible`:
seed 72172, day 1, out of the door, west to the route's first junction, then south down the first
lesson street to the second junction, (5, 7), where she stands in the frame. 1280x720.

**Retained.** The one frame at the second junction. Two other frames of the same build (an overview
of the city and a still at the first junction, an ordinary mid-street seal) were left out, since
neither shows a mouth seal.

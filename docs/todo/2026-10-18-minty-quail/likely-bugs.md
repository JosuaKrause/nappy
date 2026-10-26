# Bugs the review found by reading, to confirm and fix in the PR that touches the code

Not run; each is confirmed with a test before it is fixed, and closed with what the test showed if
it does not hold.
- **Day 12's tape goes up through a person not yet sent off:** a busker standing in a park's edge
  row has tape over him until his escort reaches him (seed 1's east edge row: about 12s), since only
  people already sent off hold a stretch (`ParkCordon._in_the_way()` through `_walkers()`, which lists
  `_leaving` and the escorts; the review of PR #840);
  the straight-walking cordon did the same.

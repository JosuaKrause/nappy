# Bugs the review found by reading, to confirm and fix in the PR that touches the code

Not run; each is confirmed with a test before it is fixed, and closed with what the test showed if
it does not hold.
- **Day 12's tape goes up through a person not yet sent off:** a busker standing in a park's edge
  row has tape over him until his escort reaches him (seed 1's east edge row: about 12s), since only
  people already leaving hold a stretch (`ParkCordon._still_stepped_on()`, the review of PR #840);
  the straight-walking cordon did the same.
- **An event car's re-run frame is not fully rolled back:** `_drive` (near 1928) and `_timed` (near
  2200) re-run `_process` and restore position, heading, travelled and gait, but not an emit or a
  spawn made inside it.

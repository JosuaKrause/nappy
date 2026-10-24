# Bugs the review found by reading, to confirm and fix in the PR that touches the code

Not run; each is confirmed with a test before it is fixed, and closed with what the test showed if
it does not hold.
- **An event car's re-run frame is not fully rolled back:** `_drive` (near 1928) and `_timed` (near
  2200) re-run `_process` and restore position, heading, travelled and gait, but not an emit or a
  spawn made inside it.

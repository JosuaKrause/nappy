# Bugs the review found by reading, to confirm and fix in the PR that touches the code

Not run; each is confirmed with a test before it is fixed, and closed with what the test showed if
it does not hold.
- **The chatting mother can detain twice.** `_has_chatted` is not carried through streaming
  (`Planned` in `event_scheduler.gd` near 13-87; `resume()` in `event_instance.gd` near 3416), and
  `chatting_mother` is map-placed and paces, so walking past the stream radius and back may let her
  stop her again.
- **An event car's re-run frame is not fully rolled back:** `_drive` (near 1928) and `_timed` (near
  2200) re-run `_process` and restore position, heading, travelled and gait, but not an emit or a
  spawn made inside it.
- **The cat's crossing path is unchecked** (`_cross_street_path`, `event_scheduler.gd` near 3941) and
  can end inside a lot: fixed by `world-passability.md`.

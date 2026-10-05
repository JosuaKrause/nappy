**A chalk mark counts as noticed only inside the visible area.** Today a mark is noticed once she
has held within `ResistanceDirector.SEEN_DISTANCE` (150 px) of it, and it on screen, continuously
for `SEEN_DWELL_SECONDS` (1 s); the on-screen half is `DangerEdge.is_on_screen()`, wired in through
`ResistanceDirector.set_sight()` by `main`. With the visible area, a mark under a covered corner in
the joystick mode is not on screen and its dwell does not run.

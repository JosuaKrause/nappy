## M189 — A still mother ends the run with a picture · built 2026-09-23

*(The player, 2026-09-23: "can we have a flag for automatically taking a screenshot and
terminating the game if the player doesn't move for a second or so?" · "also, it looks like the
walking rig is a good way to find bugs".)* `--quit-when-still [seconds]` (default one second):
once she has moved at all, if she then holds within `StillWatch.STILL_RADIUS` (4px, half the route
rig's own stuck distance, sampled every frame rather than every half second) of one spot for that
long while `DayController.is_running()` and the tree is not paused — which leaves out the brief,
summary and death screens without a third flag — the game saves `still/quit-when-still.png` into
the run's telemetry folder, notes a `still` line (her tile and the nearest live event or vehicle),
prints the path and quits. `StillWatch` is its own node rather than part of `AutoScreenshot`,
since a per-frame watch and a one-shot timed capture live differently, and it reuses
`AutoScreenshot`'s capture through `AutoScreenshot.immediate()`. It reads her position, not the
input or her velocity: on the route rig's day 6 wedge on seed 1234567 the HUD read a speed of 92
in the frame she was pinned against a moving van. **Open to overturn, chosen by the agent:** the
radius, the `still/` folder and fixed filename, and a `still` note kind rather than `shot`, whose
doc says a person asked for the picture.

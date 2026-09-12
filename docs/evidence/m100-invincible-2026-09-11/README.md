# M100, an invincible mode for playtesting — the flag holds a loss open

One `tools/shot.sh` capture on `feature/invincible-mode`, seed 2819529077, 1280×720.

- `invincible-crying.png` — `--invincible --meters 0 100 --after 3`, 3 seconds in. Seeding
  excitement at 100 drives `Baby.state` straight to `CRYING`, which without the flag ends the day
  the same frame. Here the status line reads `crying - day lost  (not settling: too excited)` —
  the ordinary crying message, unedited — while the clock keeps counting down (`2:56`, `walking
  177s left`) and the header carries `INVINCIBLE` beside `day 1 / 14`, `act 1` and `nerves`. No
  summary screen, no paused tree: `DayController._ignores_loss()` held `LOST_CRYING` back the same
  way it holds the other two losing results back, and everything else — the meters, the crowd, the
  traffic, the debug readout on the right — keeps running exactly as it would on a mortal day.

`tests/test_invincible.gd` is the actual verification, for all three losing paths and the won one;
this capture is what a person looking at the screen sees, which a headless assertion cannot show.

# M137 — the trap comes to her, 2026-09-25

One windowed rig run, kept whole under its original name:

```sh
tools/run.sh --day 6 --seed 4242 --route mark,task,task,task,calm --invincible --no-save \
    --no-title --frame-trace --after 19 --press snapshot_burst 12.3 --press snapshot_burst 15.5
```

**`--invincible`**, so the arrival could be photographed without the day ending first: the clock
and the meter stand still (the HUD reads `INVINCIBLE`, excitement 0), and his catch in the second
burst ends nothing. These frames show the arrival and the cues, not the cost or a loss.

**The build is marked `-dirty` because of a one-line local change made only for the capture and
reverted straight after**: `main.gd`'s `_input()` marks every event handled while a rig is locked
out, which also swallows the rig's own `--press` events, so no `--press snapshot_burst` could
start a burst. The capture let `InputEventAction` events through; nothing else in the run differs
from the committed branch.

What the run log (`run.log`) and the bursts show, in order:

- the rig touches day 6's mark, walks to a man shouting and hands the note over; the log's
  `task handed over: a robber sent after her from (84,116), 615px off (a clear run at her)` is
  the moment, and `edge badge: robber_giving_chase at 593px` follows within a few frames;
- `asked/burst-17232808-001` (and its `.mp4`): the badge at the bottom edge with his silhouette
  while he is off screen, then the badge gone as he comes into view with the doubled red caret
  over him and the exclamation mark over her;
- `asked/burst-20439605-002` (and its `.mp4`): him closing on her across the junction and
  reaching her.

`auto/001-attempt1-chase-robber_giving_chase.png` is the log's own still of the frame he was
spawned on, the handover itself, before the badge had risen.

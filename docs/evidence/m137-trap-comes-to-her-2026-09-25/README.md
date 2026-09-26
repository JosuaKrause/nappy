# M137 — the trap comes to her, 2026-09-25

Two windowed rig runs, each kept whole under its own name. Both walk day 6, seed 4242, the same
route to the man shouting (`mark,task,task,task,calm`), so the only thing that differs is
`--invincible`.

## The arrival and its cues — `rig-090219-seed4242-v0.18.0-18-g57f489ec`

```sh
tools/run.sh --day 6 --seed 4242 --route mark,task,task,task,calm --invincible --no-save \
    --no-title --no-focus-pause --frame-trace --after 14 --press snapshot_burst 10.0
```

**`--invincible`**, so the arrival could be photographed without the day ending first: the clock
and the meter stand still (the HUD reads `INVINCIBLE`), and his lunge does not end the run. This
run shows the arrival and the cues, not the cost or a loss — the loss is the other run below.

What the run log (`run.log`) and `asked/burst-14138051-001` (and its `.mp4`) show, in order:

- the rig hands the note to the man shouting; the log's `task handed over: a robber sent after her
  from (84,107), 315px off (a clear run at her)` is the moment — `Tuning.TRAP_ARRIVAL_DISTANCE`,
  down from the 615px this same evidence folder recorded before PLAYTEST-140 overturned the ~12.9s
  warning that distance bought;
- `frame-0007.png` is the handover itself, before he exists;
- `frame-0008.png`, taken 0.09s later, is the screen-edge badge: two yellow triangles at the
  bottom edge carrying his silhouette while he is still off screen — the log's `edge badge:
  robber_giving_chase at 290px, closing 78px/s`;
- `frame-0009.png`, another 0.08s on, is the badge gone (`edge badge gone: robber_giving_chase
  after 0.0s, now 185px away`) — he has closed the distance the badge announced;
- `frame-0013.png` is him on screen, at the bottom of the junction, with the doubled red caret
  over him;
- the rig's own route carries her on rather than standing still, and `robber_giving_chase gave up
  after 0.0s — closest 108px, she ran 0.6s of it` — the log's own record that walking on, not
  stopping, is what a warned player is given the room to do here.

`auto/001-attempt1-chase-robber_giving_chase.png` is the log's own still of the badge window.

The invincible day-clock reads 0.0s throughout `run.log`; the times above are the burst's own
`elapsed_seconds` (`asked/burst-14138051-001/burst.json`), real seconds from the first frame of
the 3-second, 36-frame burst.

## The catch — `rig-085744-seed4242-v0.18.0-18-g57f489ec`

```sh
tools/run.sh --day 6 --seed 4242 --route mark,task,task,task,calm --no-save --no-title \
    --no-focus-pause --frame-trace --after 20
```

No `--invincible`, so the day plays for real and the catch can end it — no screenshot, since a
window is not needed to read a log, and the point here is the timing rather than a picture.
`run.log`'s real timestamps (the day clock runs this time):

```
10.5  roll   task handed over: a robber sent after her from (84,107), 315px off (a clear run at her)
10.6  cue    edge badge: robber_giving_chase at 306px, closing 30px/s
11.1  cue    edge badge gone: robber_giving_chase after 0.6s, now 194px away
12.6  lost   lost_hard_fail after 12.6s — They were waiting for you.
```

The badge is up 0.1s after he appears and gone (on screen) 0.5s later; the catch, 2.1s after the
handover, is `day_controller.gd`'s new `robber_giving_chase` line, `"They were waiting for
you."` — the alley robber's `"They were waiting in the alley."` with the alley taken out, since
this one is never met in one. A second run of the same command can resolve differently (an
`excitement` meter cap racing the catch is real-time-dependent and not this row's own contract),
which is why the evidence above is the log rather than a single number to trust.

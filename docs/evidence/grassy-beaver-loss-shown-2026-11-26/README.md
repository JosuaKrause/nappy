# The loss shown: a burst of each kind of loss

Evidence for the item the-loss-shown of grassy-beaver (a day one that teaches): a lost day stops
the world on the frame of the loss, a camera of its own eases to frame her and the one thing that
caused it, holds, and then the day's summary comes up. There is one burst for each kind of loss the
beat frames a single cause for: a car strike, a hard fail by an event (a cyclist), and a crying loss
to an event row (the cafe tables).

## What the frames may be said to prove

- **The beat runs on each kind of loss.** The world holds still on the frame of the loss for about
  two seconds before the summary, and the summary then comes up on its own, with no press.
- **The camera barely moves.** In all three, the cause stands on her or right beside her when the
  day ends: the car is in the lane she walked into, the cyclist is 32 px from her, and the cafe
  tables are 44 px from her (the `near` field of each `lost` line below). So the framing of her
  and the cause together is almost her own view. The ease shifts the view by about a tile and
  shows no zoom that can be seen, and `frame-0001.png` and `frame-0012.png` in each folder differ
  by that much.
- **So the framing alone hardly marks the cause in these three.** Other things stand just as close
  in the same frame: a second car in her lane, the leaf blower beside the cafe tables. The existing
  rim on things charging her now traces several of them at once. Whether the framing alone reads
  is the design's first open pick (nothing is drawn on the cause), and these bursts are what the
  player judges it by. They show only causes that stood beside her. A cause farther off, which is
  the case where the framing zooms out, is not captured here.

What the frames do not prove: how the beat feels at full speed (the rig ran at 9 to 14 fps on the
cyclist's run; read speed from each `burst.json`'s frame times, never from the 12 fps target),
anything about a cause off her own screen, and whether the length of the hold is right.

## Why every burst starts just after the loss

**A burst cannot span the loss.** `Telemetry.end_day()` (`src/autoload/telemetry.gd`) cancels a
running burst when a day ends (`_bursts.cancel("day ended")`). A trial pressed before the strike
logged `burst cancelled: 10 frames | day ended`, and one pressed in the same frame logged
`burst cancelled: 0 frames | day ended`. So each burst below is pressed about 0.4 s after the loss.
The world is already frozen then, and the first frames fall inside the 0.7 s ease.

## The runs

Source revision `b25bb2a4479095b3d832ff7767395b2ff3eb9043` (branch
`feature-grassy-beaver-the-loss-shown`, reachable from a fresh clone as
`refs/pull/1797/head`), a clean worktree, macOS, Godot 4.7.2, a 1280x720 window
(`tools/shot.sh`'s default), the developer readout on as every rig draws it. Day 1, seed 4242.

| Folder | Command | The run log's `lost` line |
|---|---|---|
| `car/` | `tools/shot.sh /tmp/x.png 8 --seed 4242 --spawn arterial --walk 0.8e14p --press snapshot_burst 3.2` | `2.8 lost_hard_fail after 2.8s to car — It never slowed down. You were in the road. ... near: moving_van 285px (out of range)` |
| `event/` | `tools/shot.sh /tmp/x.png 9 --seed 4242 --force cyclist 2 --spawn arterial --walk south --press snapshot_burst 4.3` | `3.9 lost_hard_fail after 4.0s to cyclist — The bell, and then the bike. She is screaming. ... near: cyclist 32px` |
| `crying/` | `tools/shot.sh /tmp/x.png 8 --seed 4242 --spawn event:leaf_blower --meters 0 50 --press snapshot_burst 3.2` | `2.8 lost_crying after 2.8s to cafe-tables — She started crying. There is no settling her now. ... near: cafe_tables 44px` |

The `near` field names the nearest event, not the cause: on the car's run the striking car is a
crowd car, which that field does not list.

## What is kept, and why

Each folder holds the burst's `burst.json` (its frame times), `sheet.png` (every fourth frame
in a 3x3 grid, 640x360 each, the last row the summary), `frame-0001.png` (inside the ease) and
`frame-0012.png` (in the hold, after the ease). The other frames repeat the hold or the summary
and stay in scratch. The car burst has 35 frames, the cyclist's 25, the crying one's 36; the summary
comes up at frame 24, 19 and 24.

## Trials that did not give a crying loss to a row

Kept because the selection is not a clean first try: a crying loss lands on the row with the
largest landed share, and near most rows the crowd or the traffic out-lands it.

- `--spawn event:homeless_yeller --meters 0 85`: cried to the crowd.
- `--spawn event:playground`: the playground emitted nothing.
- `--spawn park --meters 0 85 --force busker 1 --walk east`: no loss in 10 s; the calm ground
  and her walking brought the meter down faster than the busker raised it.
- `--spawn event:busker --meters 0 90`: no street musician stands on day 1 (the row starts on
  day 2), and nothing charged her.
- `--spawn event:leaf_blower --meters 0 95`: cried after 1.7 s to the traffic. Starting at 50
  instead gave the events the time to out-land it, which is the `crying/` run.

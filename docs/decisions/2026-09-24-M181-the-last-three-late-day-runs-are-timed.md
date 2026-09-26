## M181 — The last three late-day runs are timed · built 2026-09-24

*([PLAYTEST-122](../playtests/PLAYTEST-122.md): time the late days before anything is cut. The rig
is fixed; nothing in the game or the city is.)*

**Every stall was the route rig's.** When `src/dev/route_rig.gd` could find no way that kept every
preference (off a body's side, out of a door's reach, on the sidewalk), it dropped that preference
for the whole leg, so one pinch anywhere sent the plan along every body's side and into doors'
reach. Day 12 on 90210: an alley mark reachable only past a barricade dropped clearance, the plan
ran her beside three roadblocks at (76,99..103), and the unstick pressed her back into the hut at
(75,97) whose latch had already let go; the rig counted holds only while following a plan. Day 12
on 1234567: confirmed as the swing's own park being taken, the calm tile read calm (sleepiness
x42) at 77.6 s and ordinary by 79.6 s, and she settled only at 161.8 s. Day 10's mark and day 11's
mast on 1234567: the same whole-leg drop, and on day 11 a second stall, the mast at tile (0,0)
reachable only between two moving vans at (10,1)/(10,4) that leave 48px of carriageway, which her
28px body fits only on the line between the lanes.

**What the rig does now.** Each preference is a price per tile rather than a rule for the leg:
`_cheapest()` adds 8 for a plain road tile, 64 beside a body, 128 in a door's reach, 16 on the
ground round what last caught her (kept off outright on a re-plan). A hut that has just let her
out blocks its body in every plan (`_latched_door_bodies()`); an unstick tries directions into a
door's circle last, and a hold during a wait or an unstick counts. A tile beside a body the plan
crosses is walked at its roomiest point (`_roomiest_point()`), never on the tile she stands on. A
target on ground no plan may end on is aimed at a free tile within 2 tiles (`_standable_near()`).
`calm` leaves out calm tiles in a lot the city no longer counts as calm (`_calm_tiles_left()`)
and looks again if the tile she paces on stops reading calm, so on day 12 she walks 776px to the
day's other calm area and settles at 91.0 s. Tests for each in `tests/test_route_rig.gd`.

**The table**, re-run whole on the fixed rig, alone on the machine, `--route
mark,task,calm,home --invincible --no-save`, left against 144 s and the 180 s curfew day (M192):

```
day  seed       mark    task    calm   settled   home  left144 left180
  6  4242        4.9s   10.0s   18.5s   25.1s   38.9s   105.1s  141.1s
  6  90210      15.2s   21.3s   29.1s   34.9s   58.4s    85.6s  121.6s
  6  1234567     7.3s   18.7s   35.8s   46.6s   79.5s    64.5s  100.5s
  7  4242        4.9s   48.4s   51.7s   57.3s   91.4s    52.6s   88.6s
  7  90210      16.4s   37.5s   59.6s   64.5s   84.9s    59.1s   95.1s
  7  1234567    14.0s   54.7s   67.2s   72.4s   92.8s    51.2s   87.2s
  8  4242        4.9s   42.4s   45.3s   50.5s   86.2s    57.8s   93.8s
  8  90210      16.4s   72.9s   79.6s   79.6s  107.4s    36.6s   72.6s
  8  1234567     9.5s   32.0s   36.3s   41.7s   64.6s    79.4s  115.4s
  9  4242        6.1s   11.8s   30.1s   35.9s   50.4s    93.6s  129.6s
  9  90210      27.7s  101.7s  107.9s  111.4s  169.2s   -25.2s   10.8s
  9  1234567    24.1s   54.3s   60.7s   66.3s   92.4s    51.6s   87.6s
 10  4242        4.9s   26.6s   29.4s   35.3s   52.9s    91.1s  127.1s
 10  90210      10.4s   56.7s   77.7s   82.4s  103.6s    40.4s   76.4s
 10  1234567    10.9s   39.9s   46.4s   52.1s   70.1s    73.9s  109.9s
 11  4242       35.2s   97.1s  140.7s  140.7s  176.8s   -32.8s    3.2s
 11  90210      11.1s   11.9s   31.5s   36.9s   65.3s    78.7s  114.7s
 11  1234567    35.6s   98.3s  112.7s  112.7s  156.0s   -12.0s   24.0s
 12  4242        4.9s   49.7s   64.7s   68.0s  102.5s    41.5s   77.5s
 12  90210      17.7s   44.3s   75.4s   77.4s  100.7s    43.3s   79.3s
 12  1234567    34.5s   76.7s   87.4s   91.0s  120.1s    23.9s   59.9s
 13  4242        4.9s   22.5s   34.9s   41.5s   59.0s    85.0s  121.0s
 13  90210      10.4s   15.0s   30.5s   36.0s   64.4s    79.6s  115.6s
 13  1234567    25.4s   44.5s   56.3s   61.4s   84.3s    59.7s   95.7s
 14  4242     unavail. unavail.   18.1s   30.0s   44.0s   100.0s  136.0s
 14  90210    unavail. unavail.   32.7s   38.2s   66.6s    77.4s  113.4s
 14  1234567  unavail. unavail.   21.8s   27.9s   45.7s    98.3s  134.3s
```

**27 of 27 get home inside 180 s, 0 legs stuck; 24 of 27 inside 144 s.** The tightest at 180 s is
day 11 on 4242 (3.2 s left), then day 9 on 90210 (10.8 s) and day 11 on 1234567 (24.0 s). Day 11
on 4242 moved from 70.4 s to 176.8 s by route choice, not a stall: an unseen mark jumps only to an
alley within 400px of her, the old plan went north past one at (92,90) because it had dropped its
preferences, and the new one goes south where none comes within 400px until 30.9 s, after which
the day draws a far mast at (158,0). Day 7 on 1234567 ran out of day in the fix's first sweep,
the waypoint moving on the tile she stood on; fixed, it gets home at 92.8 s.

**Open to overturn** (the agent's choices): the four prices (a street is crossed at a zebra up to
8 tiles along, and going round a kerbed van on the far lane beats one tile beside it); "the day's
second calm area" read as any calm tile in a lot still counted as calm; the settle watch firing
when the tile under her pacing stops reading calm; a latched hut's blocked ground as its solid
body plus her 14px radius; the roomiest-point search at ±15px in 2.5px steps; a blocked target's
2-tile search; door-circle directions ordered last rather than removed. **Left with the player**:
day 11's mast is a random reachable one and can be the map's corner (3917px from the mark on
1234567), which makes day 11 the day that misses 144 s on two seeds; and a rig change moves the
mark's jump and so the task, so any row can move by tens of seconds between rig versions with
nothing stuck.

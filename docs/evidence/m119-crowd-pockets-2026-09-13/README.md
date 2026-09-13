# A sealed-off junction, with and without the pocket rule

Two whole run folders, one command apart. Both are three-second bursts of the same crossing on the
same seed, day, spawn point and duration:

```sh
tools/shot.sh out.png 9 --seed 3265820891 --day 1 --spawn closure:0 --invincible \
        --press snapshot_burst 3
```

- `rig-065813-seed3265820891-v0.9.0/asked/burst-5542710-001/` — without the rule. Six walkers are
  penned into the junction west of the player and the pavements around it, two of them drawn on top
  of each other on the crossing's north-west corner (frame 30). None of them is anywhere different
  three seconds later.
- `rig-065740-seed3265820891-v0.9.0-3-g2e02e507/asked/burst-5739058-001/` — with it. The same
  crossing is empty; the only bodies left in frame are on the pavement east of the barriers, which
  is open street.

Both runs are `--invincible`, so the clock does not move and the excitement meter does not rise:
the frames say nothing about what a day costs, only about who is standing where. `burst.json` in
each folder carries the real capture times — about 83ms between frames, which is why neither burst
can show the per-frame reversal itself. That is measured in `tests/test_crowd.gd` instead.

The junction the playtest reported (seed 3265820891, day 1, tile 59,87) is a pocket on this seed
and day; it is 663px from the doorstep, which is too far for a burst to be aimed at without walking
there, so these two use the day's own closure as a spawn target instead.

# Walkers reaching a barrier and turning at it

One whole run folder: a three-second burst of the crossing beside day 1's fallen tree, taken with

```sh
tools/shot.sh out.png 8 --seed 4242 --day 1 --spawn closure --invincible \
        --press snapshot_burst 3
```

`rig-081611-seed4242-v0.11.1-9-g199c3981/asked/burst-6713653-001/` — 36 frames over 3.01s, with
`burst.json` carrying the real capture times (about 84ms apart, so the sequence shows where bodies
go rather than what a single stride looks like) and `burst-6713653-001.mp4` beside it for viewing.

The tree lies across the east-west street on the far side of the crossing, and the barrier line of
the closure runs north-south through the junction. What the sequence shows:

- **People walk up to the barrier.** In frame 1 the nearest walkers on the north pavement are a
  couple of tiles short of the barrier line; in frame 18 one of them is standing against it; in
  frame 36 three are on that pavement at and behind the line. Before this milestone that pavement
  was empty from the junction onward, because the street was held and a held street read as shut
  from seven tiles off. Which of them turned round is not a claim a burst can make about one body
  in a crowd of this size — the about-face itself is asserted in `tests/test_crowd_bodies.gd`.
- **The far side of the closed street carries people too.** The pavement east of the barriers, past
  the tree, has walkers on it throughout — ground nobody entered while a held segment read as shut
  from seven tiles off.
- **The traffic still refuses the street.** Cars run north-south past the junction in every frame
  and none of them enters the closed arm.

The run is `--invincible`, so the clock does not move and the excitement meter does not rise: the
frames say nothing about what a day costs, only about who is walking where. `run.log` is the run's
own ordered trace and `maps/` its day map.

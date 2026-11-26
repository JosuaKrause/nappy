# The thought bubbles in play, all eight

**Claim.** Each of the eight thought bubbles goes up over her in the game, on a real walk: the
way to the park at the start, the tutorial route when she walks off it, the zebra crossing when she
stands on the carriageway, turning back at a closed street (day 2), crossing the street when a body
closes her sidewalk, a noise to walk wide of, the chalk mark coming into view (day 6) and a
checkpoint hut she may walk through (day 9). Four frames of each burst (the 1st, 10th, 20th and
30th) and its `burst.json` are kept. The bubble is up in some of the four, not all: it goes up or
comes down inside the burst, and the frames and `burst.json`'s times say when.

**Limits.** These are a rig's walks under `--invincible`, so the run log's clock does not move
(every `cue` line reads 0.0) and the bubbles' timing is read from `burst.json`. The icons are the
simple set (`HintKind.ICON_SET_SUFFIX`). A bubble that is up gives way to a higher one: the way to
the park is replaced by the zebra bubble the moment she steps into the road, which is why
`use_zebra/` and `way_to_park/` start their bursts at different seconds. The crossing-the-street
capture's body is a parked delivery van that closes her sidewalk, not the forced hoarding the
`--force` fed the day; she stands against it. The walk-wide capture shows the bubble after she has
stopped at the leaf blower's noise, not while she walks up to it. A slow burst keeps fewer than 36
frames (way_to_park's has 31 or more); the four kept are all in it.

**Source.** `origin/main` at 3c73ed774 plus the branch's changes (60b73514c), windowed, seed 4242,
`--invincible`, one run at a time, 1280x720.

- `way_to_park/`: `tools/shot.sh out.png 10 --seed 4242 --invincible --walk 4@90@ --press snapshot_burst 1`, day 1
- `back_to_route/`: `tools/shot.sh out.png 16 --seed 4242 --invincible --walk 3@90@6@0@ --press snapshot_burst 8`, day 1, north off the route
- `use_zebra/`: `tools/shot.sh out.png 10 --seed 4242 --invincible --walk 1@180@ --press snapshot_burst 1`, day 1, south into the carriageway
- `turn_back/`: `tools/shot.sh out.png 14 --seed 4242 --day 2 --invincible --walk 6@180@6@270@ --press snapshot_burst 8`, west toward the closed street
- `cross_street/`: `tools/shot.sh out.png 16 --seed 4242 --day 3 --invincible --force construction 1 --walk 12@270@ --press snapshot_burst 5`
- `walk_wide/`: `tools/shot.sh out.png 17 --seed 4242 --day 2 --invincible --force construction 2 --walk 12@270@ --press snapshot_burst 12`
- `chalk_mark/`: `tools/shot.sh out.png 12 --seed 4242 --day 6 --invincible --walk 0.4@180@8p --press snapshot_burst 1`, the mark in the alley south of her
- `walk_through_hut/`: `tools/shot.sh out.png 14 --seed 4242 --day 9 --invincible --walk 10@90@ --press snapshot_burst 3`, the checkpoint hut ahead on the east walk

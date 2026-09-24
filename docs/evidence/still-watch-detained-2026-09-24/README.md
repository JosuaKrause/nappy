# A checkpoint's hold does not trigger `--quit-when-still`

Runtime evidence for [PLAYTEST-127](../../playtests/PLAYTEST-127.md): `Stroller.is_detained()` and
a checkpoint's own hold no longer read as standing still, and the hold restarts rather than resumes
once she is free again.

## What was recorded

```sh
tools/shot.sh out.png 10 --day 9 --spawn event:checkpoint_hut --seed 970135478 --walk 1n \
    --quit-when-still --invincible --no-save
```

Day 9 is `Tuning.REGION_WALL_FIRST_DAY`, the first day a checkpoint door stands at all. `--spawn
event:checkpoint_hut` puts her beside the first hut on the map; `--walk 1n` is the one step needed
to arm the flag (see `still_watch.gd`'s own note that standing at the spawn point without ever
having moved can never trigger it) and closes the last few pixels to the hut's own capture radius.

`--invincible` freezes the day clock, which is why every line in `run.log` reads `0.0`; the
sequence still orders correctly against itself.

- `fixed/` — with this branch's `src/dev/still_watch.gd`.
- `pre-fix/` — the same command against `origin/main`'s copy of the same file, for comparison.

## What the logs show

`fixed/run.log`:

```
   0.0  chat     checkpoint_hut at (20,57), 2.0s, baby awake, meter +25
   0.0  checkpoint checkpoint_hut at (20,57), 2.0s, released on the east side
   0.0  still    quit-when-still, 1.0s held | (22,57) | near: checkpoint_hut 63px
```

She is caught, held for the checkpoint's own 2.0s, and released. Only *after* `checkpoint …
released` does the flag start counting, and it fires a full 1.0s later, at (22,57) — 63px clear of
the hut, past its own `detain_distance()`. `fixed/quit-when-still.png` is the picture it saved: the
day clock reads `2:24` of a `2:24` (144s) day, so the whole sequence — capture, hold, release, the
fresh second — took a few hundred milliseconds of simulated time in all.

`pre-fix/run.log`:

```
   0.0  chat     checkpoint_hut at (20,57), 2.0s, baby awake, meter +25
   0.0  still    quit-when-still, 1.0s held | (19,57) | near: checkpoint_hut 46px
```

No `released` line before it: the flag fires *during* the hold, at (19,57) — 46px from the hut,
inside `detain_distance()` — which is the player's own report, *"a guard house triggers the stand
still flag -- it shouldn't"*. `pre-fix/quit-when-still.png` is that picture: she is still standing
at the hut, not yet let go.

## What this does and does not settle

It shows one real sequence on one seed: a checkpoint hold does not fire the flag while it runs, and
the flag correctly waits out a fresh hold once she is genuinely free. `tests/test_still_watch.gd`
covers the general contract — every `held` frame, however produced, and the red light — with
synthetic positions rather than one recorded run.

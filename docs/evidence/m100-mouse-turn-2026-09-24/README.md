# M100, the alley mouse faces where it runs

One `tools/shot.sh` burst on `feature/directional-guards-and-mouse`, taken from a worktree based
on `origin/main`'s tip at capture time, after binding `MOUSE_BY_VIEW`/`MOUSE_BY_VIEW_B` through
`EventInstance._draw_eight_view()` (PLAYTEST-128, statement 2).

```
tools/shot.sh out.png 10 --seed 4242 --day 1 --spawn alley --force alley_mouse 2 --walk south \
    --invincible --no-save --press snapshot_burst 6
```

Kept whole at `mouse-rig-085943-seed4242/` — `run.log`, `maps/day01-attempt1.png` and
`asked/burst-9485664-001/` with its 36 numbered frames and `burst.json`, plus the run's own final
still (`mouse-crossing.png`).

**A burst rather than a plain `--spawn event:alley_mouse` still, because the subject is the
turn and the first attempt at a still missed it entirely.** `--spawn event:alley_mouse` stands her
right beside the day's own first `alley_mouse` instance, and that row's whole telegraph-and-dash
life is under 2.5s (`telegraph_time` 1.4s, `duration` 1.0s) — shorter than the run's own startup
settle (city generation, ground composition, atlas warm-up), so the encounter had already run to
completion before a burst pressed at the ordinary start could ever catch it; three separate tries
that way came back with an empty street. `--force alley_mouse 2 --walk south` instead keeps
handing out fresh `alley_mouse` rows as she walks, so the burst catches one mid-crossing instead of
racing the very first one.

Frame 10 of the burst (`frame-0010.png`) shows the mouse at a clear three-quarter angle on a
crosswalk — tail trailing to the east, body and head turned toward the near corner — a
`front_diagonal`/`back_diagonal` view read out of `MOUSE_BY_VIEW` off its own crossing heading, not
the single east/west-mirrored side silhouette (`mouse.svg` alone) the row drew before this branch.
The run's own final still (`mouse-crossing.png`) catches the same turn a few tiles further into the
crossing, at the same angle.

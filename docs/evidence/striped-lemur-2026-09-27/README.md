# The game over screen shows the day you made it to

One `tools/shot.sh` still on `feature/coming-day-brief`, 1280×720, no `--invincible`.

- `bad-ending-day9.png` — `--ending bad --day 9`. The `GAME OVER` screen's body now carries `You
  made it to day 9.` under `Time played`, the last day played rather than the last day completed.

`tests/test_day_loop.gd`'s `_test_the_bad_ending_names_the_day_it_reached` is the actual
verification — that the line shows on the `BAD` ending (day 9, and day 1 rather than 0) and stays
off the neutral and good ones. This still is what the line looks like on screen, which a headless
assertion cannot show.

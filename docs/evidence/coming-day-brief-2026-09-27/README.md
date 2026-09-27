# The coming day's brief, and nerves as stars

Two `tools/shot.sh` stills on `feature/coming-day-brief`, 1280×720, no `--invincible` (neither
capture needs the day held open).

- `day7-brief.png` — `--day 7 --day-length 1`, 3 seconds in. The day runs out almost at once, so
  the screen between two days comes up on its own: the title is the one line about the day that
  just ended, *"Dusk. You are still out."*; everything under it is the coming day — `Day 7 of 14`,
  `Nerves left: ****`, `You try day 7 again.` — and the morning line breaks before its second
  sentence, *"There are more posters than yesterday."* on its own line above *"The same face is on
  most of them."*
- `pause-nerves.png` — `--day 5 --press pause 1`. The pause screen's own line reads `Day 5 of 14
  · Nerves left: *****`, the same stars the HUD's debug header draws at the top-left corner of the
  same picture.

`tests/test_day_loop.gd` and `tests/test_pause.gd` are the actual verification — that the day
number, the nerve line and the forced break are what a player reads on the label. These two
stills are what the layout looks like, which a headless assertion cannot show.

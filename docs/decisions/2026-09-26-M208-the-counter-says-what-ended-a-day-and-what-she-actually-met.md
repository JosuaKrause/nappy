## M208 — The counter says what ended a day and what she actually met · built 2026-09-26

*([PLAYTEST-141](../playtests/PLAYTEST-141.md): "the goatcounter telemetry should state what ended a
day"; "are the special/unique things actually getting encountered?")*

**What is built.** `VisitCounter` sends, beside the events it already sent:

- `nappy-day-N-instant-<what>` for a hard fail (`car` for `car_strike`, otherwise the striking
  row's id hyphenated), and `nappy-day-N-noise-<what>` for crying: the group that landed the most
  on her over the halo's 5-second window, by row id, `crowd`, `traffic`, or `self` for her own
  running and alley share, which the baby now keeps a sliding record of, read by nothing in
  gameplay. `main` emits `EventBus.day_lost_to(day, cause)` just before `day_ended`.
- `nappy-day-3-seen-fire` the first frame the burning building is on screen, whether or not the
  fire engine can be placed; `nappy-day-3-fire-unmet` when it is lit off her path at dusk;
  `nappy-day-14-blackout` on every blackout; `nappy-escape-city` when the building section is
  escaped.
- `nappy-day-N-dog-chased`, `-dog-shaken`, `-dog-outlasted` for `charging_dog`'s chase; a caught
  dog is `instant-charging-dog` and never also `dog-outlasted`.
- `nappy-day-N-mark-seen`, `-mark-read`, `-mark-missed` for the chalk mark, told apart from a
  task by the step's own `is_pickup`; `task-done` and `task-skipped` now count only tasks.
- `poster-torn`, `chat` and `checkpoint`, once per attempt at a day.

Every new `EventBus` signal only emits; nothing in gameplay listens to it. The baby adds running
and the alley to the meter in the same order as before, so the record kept for the counter moves
the meter by nothing.

**Verified** headless: `tools/check.sh`; `tests/test_visit_counter.gd`, the new
`tests/test_day_lost_to.gd` for the cause names, `tests/test_telemetry.gd` for determinism and
`tests/test_halo.gd`; and the suites of every edited file (event manager, chat, fire, pursuit,
scenery, solid, posters, day controller, resistance), all without failures. **Untested emit
sites**: the blackout, poster, detention, sighted and lit-unmet emits have no test asserting the
signal itself, and the crying cause's gathering from the live city has no unit test.

**Choices left open to overturn**: a tie, or an empty window, names the alphabetically first
group present, else `self`; `nappy-escape-city` is sent once per attempt at the building section,
never again for a retry of the city section alone; a step index the resistance does not know
counts as a task; the counter names only `burning_building` among sighted rows and only
`charging_dog` among pursuers, though the signals carry every such row.

**Left out**: the curfew announcement on day 6, because no moment says she was near enough to
hear it; the HUD's tips, shown every time their day begins; opening the pause screen.

## M217 — Nerves are stars on every screen · asked for 2026-09-26

> "why are nerves sometimes stars and sometimes numbers? it should be consistent throughout
> (stars)"

[PLAYTEST-143](../../playtests/PLAYTEST-143.md), statement 3. Today the day summary's "Nerves left:"
repeats `*`, while the day brief and the finale brief (`show_day_brief()` and
`show_finale_brief()` in `day_summary.gd`) and the pause screen (`_show_where_the_run_stands()`)
say "%d nerves left". It goes on one branch with M210, the brief between two days is the coming
day's, which already asks the brief to show the nerves "drawn the way the HUD draws them". Both
wait for M211 and M212's branch, which owns `day_summary.gd` and `pause_screen.gd`.

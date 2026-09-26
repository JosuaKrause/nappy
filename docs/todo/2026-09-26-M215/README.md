## M215 — The power station's chimneys stand in front of her · found 2026-09-26

> "the chimneys of the power plant render behind the player. they should be in front."

[PLAYTEST-143](../../playtests/PLAYTEST-143.md), statement 1. Buildings are drawn as one layer beneath
every entity (`city.gd`'s class doc: "nothing can ever legitimately stand behind one"). The power
station's stacks (`POWER_STATION_STACK`, drawn by `Building._draw_power_station()`) rise far above
the ordinary roof line, so she can walk where a stack should hide her.

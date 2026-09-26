## M218 — The burning building burns · found 2026-09-26

> "the fire of the burning building is on the street -- the building itself is not burning"

[PLAYTEST-143](../../playtests/PLAYTEST-143.md), statement 4. The row's body stands on the sidewalk
against a wall (`EventCatalogue._burning_building()`: `placement` SIDEWALK, `pavement_side`
AGAINST_THE_BUILDING). `EventInstance._draw_fire()` draws its flames at that ground spot, and the
facade behind them is drawn unharmed. The danger's footprint and its fairness contracts stay as
they are. This is about what is drawn.

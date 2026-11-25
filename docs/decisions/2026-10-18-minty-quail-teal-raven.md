# minty-quail — The day director's city term no game path reaches is deleted · 2026-11-19

The sweep's one find outside the events and the resistance (`dead-code-sweep.md`; the ask is
inbox #1180 in gray-dolphin): `DayDirector.finish_day()` lit the fire a won day never met only when
`_in_a_city`, a term a won walk home could reach as false only in a world with no city.

**Nothing reaches it.** A walk home is `DaySpec.Goal.HOME`, a day's default goal. Every world a
day is walked in is stood by `DayWorldSource`: a day and the escape's city section are in a city
(`DayWorld.in_the_city()`), an authored scene is handed the city whole, and the one world with no
city is the escape's building (`DayWorld.in_the_building()`), whose spec
(`DaySpec.for_section(BUILDING)`) has the goal `SERVICE_EXIT`. So a won `HOME` walk outside a city
is a state only a test could make. The term arrived with the pass that had the day director and the
run log take the city's parts rather than the whole city (#1482, 2026-11-16) and no game path has
reached its false side since.

**Deleted.** The term, so the fire is asked of a won day walked home with a player; and
`tests/test_day_director.gd`'s won day with a player and no city, which stood on the unreachable
world and held only that such a day ends (the suite's other won-day checks hold that). The suite's
rig no longer takes a player, which only that test passed. `DayDirector._in_a_city` stays: the
director still keys the city's dressing, its streets and the crowd on it.

**Mutations.** The walk-home fire case (a won walk home asks the fire lit; a lost day and the
escape's city section ask nothing) is unchanged. Dropping its `HOME` goal term fails it (the city
section is asked to light), and the other won-day checks read the same code as before.

**Remeasure:** nothing; no behavior changed.

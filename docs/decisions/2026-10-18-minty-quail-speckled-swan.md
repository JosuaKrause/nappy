# minty-quail — The scheduler's last test reads go through the run log, the corridor and what a day places (tests through public seams) · 2026-11-05

minty-quail's `tests-public-seams.md`: `tests/finale_rig.gd`, `tests/test_events_solid.gd` and
`tests/test_city_decay.gd`. The domain model: `src/events/event_scheduler.gd` and
`src/routes/corridor.gd`; run flow: `DayPlanner`.

**Built.** `build_day()` hands its trace to the escape's bag path, which notes how many marbles it
drew for how many rows, drawing nothing for the note; `DayPlanner.plan_the_escape_city()` takes the
trace its instance caller hands it from the world. The finale rig reads the count off a recording
trace and checks that a traced plan stands the same rows as an untraced one; the per-street cap and
the empty-bag and roadblock-bag checks go through `build_day()`. The walked sidewalk bands are
`Corridor.walked_sidewalks(map)`, cached per map, which the scheduler's guard that keeps a route's
sidewalk open asks; the bands a sidewalk splits into are `Corridor.sidewalk_bands`, which the walk
ground asks too. The city decay suite plans the last day over pinned maps and checks the alley mouse
lands beside a garbage-sack pile well above that ground's share of the candidates, by a bar reasoned
from the five copies the preference offers. Placement fingerprints over the same seeds are
unchanged.

**Choices, open to overturn.** The note is of kind `plan` and the rig reads its leading count; the
corridor caches per map; the sidewalk bands live on the corridor so the routes name nothing of the
events; the bag checks use the game's own bag seed (the builder's calls).

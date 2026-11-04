# minty-quail — The residency and blackout suites follow the roof drawer (tests through public seams: W5b) · 2026-11-04

minty-quail's `tests-public-seams.md`: the residency, blackout and city decay suites, the second
roof-art step on the drawer the pilot built (record sandy-raven). Tests only.

**Built.**
- `test_scenery_residency.gd` (private-read lines 12 to 0) hands every building a recording drawer
  through `Building.roof_drawer`, the member the city sets; the recorder can also stand each unit
  through the real `RoofDrawer`, so what a roof leaves standing in the city (eviction, ownership in
  the entity layer) is checked on real objects while the record says which building drew what.
  Windows are read through `window_texture()` and the roof through `roof_layout()`. The suite's
  subject building is the first whose roof places units, since the building it used drew none and
  its roof checks held nothing.
- `test_blackout.gd` (6 to 4) picks its spine cars through `travelling_vertically()` and
  `CrowdLanes.corridor_at()`, and checks the sample is not empty, which the old check never did.
- Checks 7938 and 36 to 7663 and 37 (the residency suite's view-dependent loops follow its new
  subject); eight mutation runs.

**Not done:** `Building._clerestory_texture()` and `_front_parapet_texture()` and
`TrafficLight._lamp()`, picture choices only their own class's drawing reads, which want the drawer
shape of the roof art (a front drawer, a lamp drawer), to be designed before it is built;
`test_city_decay.gd`'s `EventScheduler._prefer_beside_a_sack_pile`, in the scheduler's area. The
residency and blackout suites still share one city across their tests and fail run in reverse.

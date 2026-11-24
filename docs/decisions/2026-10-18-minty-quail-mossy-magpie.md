# minty-quail — The city map's nine fields are asked through its methods (C3) · 2026-11-23

CityMap's `network`, `main_road`, `calm_blocks`, `closed_tiles`, `power_station`,
`boundary_wall_at_a`, `playgrounds`, `home_rect` and `courtyard_rects` are private (`_network`
and so on). A reader asks the answer that already existed (`street_network()`,
`main_road_corridor()`, `calm_blocks_now()`, `closed_tile_set()`, `power_station_blocks()`,
`wall_stands_at_a()`, `playground_rects()`, `home_tile_rect()`, `courtyard_lots()`); a writer is
a method the game calls: `lay_main_road()`, `lay_home()` and `add_courtyard()` (new, called by
the generator), `recompute_calm()` and `close_streets()`.

The suites' 18 writes on hand-drawn maps go through those writers, with two typed fakes handed
in (`FakeCityState`, whose `calm_blocks()` answers the blocks a test names and whose
`purpose_of()` never answers a park, so a hand map gets no playground; `FakeClosure`, whose
`tiles()` and `mouth_rects()` both answer the tiles a test closes, so `close_streets()`'s flood
from the doorstep stops at each). The reads were rewritten by script: the seven `[kept]` lines
of `tools/test_only_members.txt` and the generator's two `tools/field_reads.txt` lines went with
them. No write became a write through an answer. Rejected: leaving the test writes as public
setters only tests call, which the test-only rule forbids.

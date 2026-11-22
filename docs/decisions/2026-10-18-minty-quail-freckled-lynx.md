# minty-quail — A route and a flock are parts (row 4b) · 2026-11-21

**What was asked.** Row 4b of minty-quail's `event-interface.md` (a row is written as its parts), designed by Opus;
this is its seventh pull request, "a route and a flock are parts", built as #1627 by Sonnet agents one part per turn.

**What was built.** Two values in `src/events/parts/` (data), each held by the row with `use_<part>()` and `<part>()`
and shared by its copies. `RouteSpec` says how a moving event goes: whether it moves, its speed, the kind of path (the
`Kind` that was `EventDef.PathMode`), how many tiles, whether it paces a beat and whether it parks where it arrives
(`none()`, `at(speed, kind)`, `up_to_tiles(n)`, `pacing()`, `parking_where_it_arrives()`); the reason a row parks where
it arrives (PLAYTEST-119 24) moved with the setting. `FlockSpec` holds a flock's count and spread (`none()`, `of(count,
spread)`). The composer hands the route walk, the car, the departure, the investigation and the notice run their route
part, and the flock and the notice run the flock part; the flock and the notice run no longer hold the row. The raid's
pacing patrol takes `row.route().pacing()`. `validate()` loses "parks where it arrives and does not move", which
`parking_where_it_arrives()` refuses to build, and keeps the rest. The catalogue's 41 writers are rewritten by
`convert_catalogue_route_flock.py`, kept with the design (`alley_mouse` by hand). Docs and skills name the parts'
answers.

**Measured.** The row fingerprint on main and the branch: every one of the eight removed settings shows the base's value
under its part on all 55 rows and 1,594 copies, and no other line changed. The look, excitement and placement
fingerprints, `placement_rows.gd`, `escape_density.gd` and `curly_stork_piece_layout.gd` print the same; no cost figure
moved; `m159_tick_sweep_events_cost.gd`'s chain hashes are equal, with the same three day-9 checks failing on both (a
known fault of that probe's own copy of the frame step).

**Open to overturn:** the design's forks; `up_to_tiles(n)` as the refinement beside the question `tiles()`; the
factories' asserts; `speed()` answering 0 for a row that does not move; the two test helpers, one per suite, that build a
row differing in speed alone. The row fingerprint probe prints a refinement (a method that returns its own class) as
`REFINES` instead of calling it, since a route refinement asserts on a row that does not move.

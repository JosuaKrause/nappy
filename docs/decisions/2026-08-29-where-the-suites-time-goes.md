## Where the suite's time goes

Per-suite timings are printed by `tools/test.sh`, and `tools/test.sh crowd events` runs a subset in
seconds. Since **M44** the whole run is ~96s for 74540 checks. `test_balance.gd` and `test_crowd.gd`
are ~26s each, `test_generator.gd` ~16s and `test_events.gd` ~13s; everything else together is ~11s.
Those four are the suites that generate cities and play days, and that weight is the cost that buys
the bugs a data-level test cannot see.

It was **8.4 minutes** before M44, and the thing to remember about that is that four plausible
explanations were all wrong: it was a rig that stepped the crowd without the frame around it (an
unbounded `TrafficIndex`), a filtered tile list recomputed four hundred times a day, a
`Vector2i`-keyed dictionary used as a flood fill, and `CityGenerator.validate` sweeping the map
twice before its cheap rejections. See `docs/TODO.md`, M44. No check was cut to get there — the
count went up by one.

One thing deliberately not swapped in, and still true: `test_generator.gd`'s route-redundancy sweep
closes each street segment in turn on the *tile* grid, where `StreetNetwork.route_count()` would
answer the same question by max flow on the junction graph far faster. The tile-level sweep checks
something the graph cannot — that the tiles agree with the lattice — so it stays.

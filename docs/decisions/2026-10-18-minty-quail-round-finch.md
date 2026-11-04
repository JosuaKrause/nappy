# minty-quail — The street lattice is a network each city map holds (hidden statics: StreetNetwork) · 2026-11-03

minty-quail's `hidden-statics.md`: the last hidden globals it named, `StreetNetwork`'s lattice
memos. The item stays open for `EventScheduler.judgements`, the counter it already lists as open.

**Built.**
- `StreetNetwork`'s `_segments`, `_by_key` and `_adjacency` are instance fields built in `_init()`
  (adjacency with the lattice rather than on the first route count). The methods that read the
  lattice are instance methods; the ones that are arithmetic on the constant block count
  (`junction_count`, `in_bounds`, `node_of`, `node_total`) stay static.
- Each `CityMap` builds its own network when it is made (`map.network`) and never replaces it;
  callers reach it through the map they are already handed. `RouteTree.network()` and a corridor's
  network serve the callers with a tree in hand; `FinalePlanner.Plan` is handed `map.network`;
  `CityGenerator._street_between()` takes the map; the recipe validators that run before any map
  exists check keys against a network of their own.
- `tests/shared_state.gd` loses its three `street_network.*` exemptions; `tools/layer_map.py` loses
  the static `StreetNetwork` exception and `resistance_steps.gd`'s `names StreetNetwork` break.
- Placement fingerprints (`director_placement_fingerprint.gd`, `placement_fingerprint.gd`) on seeds
  4242, 77 and 90210, days 1 to 14, are byte-identical on main and the head; frame cost (crowd and
  events) unchanged within noise.

**Rejected:** holding the network on the `Sitting`, which would have to travel through `main`,
`City`, `CityGenerator.generate()` and `RecipeCityContext.restore()` into every map and every test
that builds a city, for a lattice that depends only on a constant and costs a few hundred small
objects per city; and a static facade, since every caller already holds a map.

**Open to overturn** (the builder's choices where the brief was silent): the map building its own
network rather than being handed one; the name `network`; the validators' local lattice; keeping
`StreetTrees.Run.segments()`, which has no callers, with a network parameter rather than deleting
it. A segment belongs to the network that built it, so segments of two maps are not `==`; code
compares streets by `key()`, and nothing keeps a segment across days.

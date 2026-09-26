## Gotchas learned in M16

- **Check before accepting, not after placing.** The obvious shape for closures — place N,
  then drop them until the day is legal — has an order-dependent answer and a window in
  which the day is illegal. Testing each candidate against the invariant *before* accepting
  it costs the same and has neither problem. The reason it is affordable is the next point.
- **Counting distinct routes is a max flow, not a search for routes.** Two edge-disjoint
  paths is what "two distinct routes" means, and by Menger's theorem the count is also "how
  many streets it would take to cut this off". Two BFS augmentations over a 64-node junction
  graph — not a flood fill over ten thousand tiles — which is why it can run on every
  candidate closure of every day inside a test suite.
- **A doorway is not a route, and that has to be said out loud.** The first version of the
  brute-force cross-check closed every street in turn and asserted the area survived. It
  failed on three courtyards, correctly: a courtyard has one archway onto one street.
  Two routes has always meant two routes *to the door* — the same exemption the home has
  had since M3 — and the test now excludes access streets and carries a second test that
  states the consequence rather than leaving it implicit.
- **A cross-script enum is not the same type as itself.** `f(side: Side)` called from
  another script with a `StreetNetwork.Side` value fails to parse. Widen to `int`.
- **The crowd made the closure legible for free.** Agents divert at the junction rather than
  driving through a barrier, so the street with nobody on it is the street that is shut —
  which reads from a block away, further than the barrier does. That was a side effect of
  making the crowd respect closures, and it is better than the thing it fell out of.

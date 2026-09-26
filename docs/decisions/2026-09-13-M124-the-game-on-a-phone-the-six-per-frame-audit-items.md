## M124 — The game on a phone · the six per-frame audit items, built 2026-09-13

*(The audit's own findings, filed under M124 on 2026-09-13 from a per-frame read of the source;
the player's word to start them: "sure go ahead".)* Six agent commits on
`feature/m124-per-frame-audit`, reviewed on the PR.

**What changed, one item each.** The halo's `_process()` keeps one reused candidate array and
tests membership of the picked set through a dictionary keyed by the objects rather than a
linear `in` over up to eight picks for each of ~275 candidates. `EventInstance.contribution_at()`
caches its plain answer once per age and position, the shape `_caret_strength()` already
documents, so the baby's physics-rate sweep and the halo's frame-rate sweep share one evaluation
per event — and is invalidated the instant `_finish()` or the leaving branch sets its flag,
because `EventManager.retire()` and `silence_city_wide()` set those from outside the instance's
own tick, so age and position alone left the sabotage's mast answering its live value on the
frame it was silenced; two resistance checks caught it on CI and the case is pinned beside the
cache test. `DangerEdge._measure()` mutates its per-instance entries in place with a generation
stamp and erases the departed in one sweep instead of allocating a dictionary per instance per
frame. `DebugLayers` asks for a redraw only when a layer is on and collects collision nodes into
one caller-owned array rather than merging a fresh array up from every recursion level; the
public `collision_nodes_under()` keeps its signature. `DayController` emits the clock only when
the whole second changes, so the HUD's format runs once a second rather than sixty times; the
HUD itself is untouched. `ReachabilityGrid.flood()` stashes the dirty-cell set it built inside
the `reached` dictionary under a negative sentinel key and `reaches()` reads it back instead of
recomputing it; no caller iterates `reached`, so the sentinel is safe today and this sentence is
what a future caller that counts keys should find. `_cell_of_tile()` uses an arithmetic shift,
an exact floor for a negative coordinate where integer division truncates. Each item has a test
that the behaviour is unchanged; the clock's is a new small suite.

**The crowd half of the shared sweep is not built, on purpose.** A crowd agent's position and
startle are written from the crowd's own step — `Crowd._bump()` and `_horn()` call `startle()`
from outside the agent's `_process()` — so a per-frame cache on `CrowdAgent.contribution_at()`
answered with the pre-bump value on the tick a fresh startle is meant to show, and one crowd
test caught it. The cache was reverted and the reason is on the method. So only the ~41 events
are deduplicated and the ~234 agents, most of the candidates, still answer twice a frame; a
dirty flag set beside `startle()` is the shape a later pass would take, and the record's own
measurement says it is not worth taking yet.

**Measured, and inside the noise.** The record's own walk (`--seed 3265820891 --day 1 --walk
3s17e`, vsync off, three interleaved rounds each side), read off the `frame` entries from two
seconds in:

| | before | after |
|---|---|---|
| fps | 119.0 | 118.8 |
| worst frame | 18.8ms | 16.8ms |
| draw calls | 587 | 585 |
| objects | 1670 | 1668 |
| primitives | 3827 | 3816 |
| process | 13.16ms | 12.94ms |
| physics | 1.86ms | 1.85ms |

None of the six touches what is drawn, so the draw counts sitting still is the expected result;
process time and the worst frame moved a little in the right direction, and the worst frame
ranged wider between rounds on the same side than between sides, so nothing here is attributed
to one item. Two items cannot show in a walk at all: the grid's dirty set runs during planning,
and the debug layers' gate pays only when a layer is on.

**Open to overturn.** The sentinel-key stash rather than a changed signature (a dozen call
sites saved); no per-day cache of the collision-node list, since events add and remove
collision-bearing children mid-day and `child_entered_tree` does not reach a grandparent; the
halo's `select_sources()` still returns an array so its existing tests stand. What stays open
under M124 is the phone half of the measurement and the atlases it gates.

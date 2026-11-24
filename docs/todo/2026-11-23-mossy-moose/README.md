priority: later

# mossy-moose — Where she touches a roadblock from is worked out twice · filed 2026-11-23

**What is wrong.** Two functions answer "from which ground can she touch this roadblock plan": `RuledRoadblockGround._touched_from()` (`src/events/model/dawn_phases/ruled_roadblock_ground.gd`, a static function returning every walkable tile left open by `shut` within `plan.blocking_radius()` plus a tile and a half of the plan's body) and `ResistanceDirector._touched_from()` (`src/resistance/resistance_director.gd`, returning the one nearest reachable tile within the same radius along her paths, closer than `reach`). They share the radius arithmetic and the walk over the square of tiles round the body, and one change to what "touches" means has to be made in both. `designing-classes`: one answer, one owner. A filing from a review, not from the player's words; the band, `later`, is the filer's proposal.

**Found by** the design of pull request 1692 (`.claude/briefs/designs/minty-quail-blocking-reach.md`, untracked in the orchestrator's checkout).

**What a builder does.** Give the touch radius and the tiles within it one owner (the plan, or the ground class that already measures close by), and have the director choose its nearest reachable tile out of that owner's tiles. The two callers keep their different questions (every tile, the nearest reachable one); the radius and the walk are in one place.

**Shown fixed.** `rg -n '_touched_from' src` finds one definition of the radius and the tile walk, and the suites for the roadblock ground and the resistance director's sections pass with unchanged check counts.

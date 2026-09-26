## M184 — The rig waits before it forces, and aims beside a solid target · 2026-09-23

The route rig's open half ([PLAYTEST-122](../playtests/PLAYTEST-122.md): "a test-rig mode where she
just follows the edges of a path"). **Waiting before forcing:** a stall now first stands still for
`_STUCK_WAIT_SECONDS` (three seconds), since a crowd that would clear on its own and a wedge look
the same to the rig, and only a stall straight after waiting tries the eight-direction maneuver;
both spend one of a leg's three stuck episodes. Measured over the same 24 runs, it got none of the
twelve stuck legs through (14 of 24 stuck after, against 12), so the chokepoint item stays open in
`TODO.md` with what the first look found. The player chose to merge it as it stands and debug in
a new pull request.

**Aiming beside a solid target:** day 13's task on seed 4242 found no path because the rig aimed at
the roadblock's own centre, inside its body (`obstructs_radius` 60px), which no plan may end on.
`_reachable_point_near()` steps out to the nearest open tile first, well inside the 110px at which
the director counts the task done. Reproducing the director's own random side of approach was
rejected: the rig has no stream aligned with it and the completion check does not care which side.

**The other four legs with no path are the game's**, found by instrumenting the rig against the
running game: a mark placed inside a solid body, a mark sealed off by the day's obstructions, and
two contacts placed inside buildings, all in `src/resistance/resistance_director.gd`; queued as
M188, a resistance target can always be reached.

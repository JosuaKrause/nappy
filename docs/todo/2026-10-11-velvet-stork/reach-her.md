A guard set on her at the task's completion reaches her: he walks a path round buildings toward her
(the walkable grid the other pursuers on foot use, if one exists, or a path found once and refreshed
as she moves), instead of a straight line that a building stops. Restore the check in
`tests/test_day13_guard.gd` that the guard parked at another roadblock reaches her stand-off within
its time, on seed 4242 with the gatehouse-day closures, and add one with a building between them.
His notice, stand-off and clear-line lunge stay as they are: he closes along the path and lunges only
along a clear line.

**Proposed, not asked for** (open to the player's correction): pathing for this guard only, not for
every pursuer; whether other pursuers on foot need the same is a question for the player if a probe
shows them stuck the same way.

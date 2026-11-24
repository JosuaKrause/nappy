# The ground a hunting roadblock shuts, before and after (minty-quail, blocking reach)

**Claim.** A hunting roadblock (the roadblock row at heat 4, where its guard hunts) shuts the ground
its band covers (64px) instead of its field's 86px core: `EventPlan.blocking_radius()` is the
wider of the body and the ground the catch shuts (`EventDef.catch_shuts_within()`). The pictures
are one such roadblock on main and on the branch.

**Limits.** One plan of one seed each, the first hunting roadblock the probe meets (`shut_*`: the
first of days 7 to 12; `day13_*`: the first of day 13). The roadblock stands in the same place on
main and on the branch, since the placements agree in this probe. They show the shut tiles, not
play; whether the change reads right in a run is for a person to judge.

**Legend.** Dark: a building. Light grey: a sidewalk. Mid grey: a road. Red: the tiles the plan's
`blocking_radius()` shuts. Orange: the ring `core_within()` (86px) shuts and `blocking_radius()`
does not (empty on main, where the two are the same). Blue dot: a tile a route runs along. Green
dot: ground she touches the plan from (walkable, left open, within the disc and a tile and a half
of the body). Black cross: where the body stands. One tile is 12 pixels
in the drawing (a tile is 32px in the game), so the discs read at the right size against the
tiles.

**Source.** `*_main.png`: main at d3faeaf8c. `*_branch.png`: branch
feature-minty-quail-blocking-reach.
**Command.** `MQ_LABEL=main tools/test.sh probes/minty_quail_blocking_reach.gd` (or
`MQ_LABEL=branch`); the probe is `tests/probes/minty_quail_blocking_reach.gd`, 18 seeds from 90210 in
steps of 31, days 7 to 14, heat 4. Retained: the four crops. The probe's printed counts are in the
pull request.

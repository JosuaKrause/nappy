**`CrowdAgent` moves at frame rate; every rule about that movement is applied at physics
rate.** `src/crowd/crowd_agent.gd:751` is `_process(delta)` — frame rate — while everything
that governs it (`space_out_the_traffic()`, `_hold_walkers_at_doors()`,
`give_way_at_junctions()`, `_strike()`, `_horn()`, `_bump()`, `_make_way()`) is in
`src/crowd/crowd.gd:637`, `_physics_process(delta)` — the physics tick, thirty a second.
Speeds are frame-rate independent, so this is not a speed bug; what varies with the machine
is the **decision cadence relative to the motion** — how far a car travels between two
applications of "nothing enters a box it cannot leave." The verify skill records the
windowed build drawing ~110fps, so a desktop car covers roughly 3.7 movement steps per
right-of-way pass, against 1.0 at 30fps: a headway or junction-capacity number set against
`Crowd.step()` does not reproduce on the player's own machine at the ratio it was measured
at. **The audit's own recommendation**: move `CrowdAgent._process` to `_physics_process`,
which fixes the ratio at 1:1 everywhere, at the cost of re-measuring every crowd number and
giving up frame-rate-smooth motion for the agents — against leaving it as it is. That cost
is no longer frame-rate-smooth against a fixed sixty either: with the tick at thirty, moving
the agents onto it would draw the whole crowd at thirty frames a second, not merely decide
for it at that rate, which is a larger piece of the trade than it was. Docs/evidence/
audit-2026-09-13/AUDIT.md, finding 3.1, has the full reasoning.

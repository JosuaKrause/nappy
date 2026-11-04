# minty-quail — The crowd rigs read huts and door holds through what the crowd exposes (tests through public seams: W17) · 2026-11-04

minty-quail's `tests-public-seams.md`: the crowd rigs `tests/crowd_rig.gd` and
`tests/crowd_closures_rig.gd`. Tests only.

**Built.** Private-read lines 10 and 6 to 0. The bucket-edge hut test hands the city a region plan
with door bodies through `City.set_region_plan()`, the call a scene recipe makes, so
`Crowd.start_day()` builds the huts as every day does; a walker placed through `add_recipe_actor()`
on a sidewalk lane just below an edge and one just above it finds its hut as its `door_ahead` after
one real physics tick, in its own bucket, across the edge and on a tie both ways round. The two
cooldown checks stand a body across a footway with `obstruct_tiles()`, released with
`release_obstruction()`, as an event's body is stood, and read the hut's `WalkerDoorHold.inside`:
the walker is taken once when the body stands inside the cooldown radius past the hut and twice
when it stands beyond it; the walker comes toward the street's inside, since coming out toward the
mouth it turns at the junction rather than turning round. Five mutation runs.

**Not done:** the rigs' other cases still step the crowd through the public `Crowd.step()` rather
than real frames.

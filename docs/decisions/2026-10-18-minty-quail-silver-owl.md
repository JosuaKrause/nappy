# minty-quail — Where a still solid body stands is worked out once · 2026-11-08

minty-quail's `re-derived-cases.md`, the case filed as "the stand point of a moved body", in #1250.

**Found again in the code.** The case as filed (the move working out where a moved body stands and
the park cordon's standing search working it out again) does not hold: `EventManager.move_extra()`
is handed its point by the resistance director, and `ParkCordon._standing_point()` is a search for
open ground for officers, another question. What was worked out in several places is where a body
stands once built: a stationary solid row its `pavement_side` does not pin is moved to the middle of
its pavement band. Seven places did it (`EventInstance.setup()` and `move_to()`,
`EventScheduler._stands_at`, `WalkGround._stands_at` and `solids_of`,
`EventSpawner.obstructed_footprint`, `RouteRigPlanner._planned_position`), and `move_to()` did it
differently: it stood the body on the point handed while `move_extra()` recorded the footprint from
the centred one.

**Built.** `EventFootprints.stands_at(map, def, at)` is the one answer and all seven ask it;
`EventDef.stands_on_its_band_middle()` names the row's condition; the band-centring moved into
`EventFootprints`. A moved body now stands where its footprint is recorded. `tools/field_reads.txt`
loses two `pavement_side` reads.

**Measured.** The placement fingerprint is byte-identical to main's (15787 lines).

**Choices where the design was silent, open to overturn:** the real repeat was built rather than
the case as filed; the park cordon is left as it is; `move_to()` centres a moved body as setup does.

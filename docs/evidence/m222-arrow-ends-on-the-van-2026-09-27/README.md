# M222 — the red arrow for the van ends on the van, 2026-09-27

`seed4242-day7.png`: `tools/shot.sh seed4242-day7.png 23 --seed 4242 --day 7 --spawn contact
--walk 0.6w0.6n4e4s2s6e0.9w0.9n --invincible --no-title` — a scripted walk from day 7's own mark
(`--spawn contact` stands her beside it) that hands the package over at the van and then walks on
toward it, stopped short of actually touching it. The readout's own `nearest delivery_van active
age=22.8/1.3 115px` says she is 115px from the van and the HUD's own task line still reads
"somewhere out there: a van, waiting", so the task is not done and the arrow is still up.

The red arrow's tip sits on the van's own body, next to the driver's door, rather than on the
touch point beside it — where `_reachable_offset()` still keeps the actual contact, out of the
van's own solid footprint — which is `ResistanceDirector.red_arrow_target()` reading
`_rider.global_position` rather than `contact_position()` now that a task has a rider.

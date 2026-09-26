## M108 — Eight-direction entity graphics · the crowd car's turn, captured as a burst 2026-09-11

*(2026-09-11, playtest 56: "use burst mode for mid turn capture".)* Two branches had spent their
capture budget on stills that landed beside a two-second turn, and the queue had proposed a probe
that renders a car on a synthetic arc; the player chose the burst recorder instead. One agent
commit on `feature/crowd-car-turn-burst`, one `tools/shot.sh` run: `--seed 4242 --spawn closure:0
--layers 2,3 --press snapshot_burst 3`, standing at the mouth of the day's only closure, where
every car on that street is forced to turn, so a turn happened in view inside the first second —
the six earlier tries had stood at busy junctions waiting for ordinary traffic and been ended by the
meter. The whole run folder is kept under `docs/evidence/m108-crowd-car-turn-burst-2026-09-11/`
with its thirty-six frames, `burst.json` and the `tools/clip.sh` video. **What it shows**: frames 9
to 11, at 0.71s to 0.85s by the recorded times, the strike box, the shadow capsule and the car's
diagonal picture rotating together through an about-face, and frame 12 landing the car axis-aligned
in the opposite lane; no view jumps and the picture never leaves its shadow. **What it also
shows**: the half turn takes about four tenths of a second from frame 7's axis-aligned northbound
car to frame 12, so this car entered the arc near cruise speed rather than at `CAR_TURN_SPEED`
(60px/s) — the lookahead fork M111's own record lists, seen here rather than measured. The day-1
tutorial banner overlaps the car's lower half in several frames; cosmetic. The analytic per-sector
footprint test in `tests/test_car_views.gd` stays the pin; the burst is the evidence.

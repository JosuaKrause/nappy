## M100 — Water, smoke and steam move · built 2026-09-24

*([PLAYTEST-128](../playtests/PLAYTEST-128.md): "splashing water (from the main break) or puffs of
smoke (from the car crash) or steam (from the escape) should have (at least) a two frame
animation to convey what they are better".)* `burst_water_main`, `car_accident` and
`basement_steam` each have a second frame (`_b`), on the same canvas and anchor as the first, and
alternate on the existing `_idle_stepping()` clock the busker and the café use, offset per
instance: the water surges every 0.5s (`BURST_MAIN_SPLASH_PERIOD`), the steam billows every 0.7s
(`STEAM_BILLOW_PERIOD`) and the smoke rises every 1.2s (`CAR_ACCIDENT_SMOKE_PERIOD`). The crash had
no smoke, only one small white cloud, so its first frame was redrawn with grey puffs too; its two
frames share one shadow. `_picture_key()` carries the frame bit, since without it a still event
never redraws, and `tests/test_event_redraw.gd` checks that each row swaps frames and that each
swap changes the key. Review sheet and bursts: `evidence/m100-two-frame-effects-2026-09-24/`.

**Open to overturn, chosen by the agent:** grey smoke for the crash; the three periods, water
fastest and smoke slowest; the steam billowing through its 1.2s notice as well as its blow. **Left
open:** the crash's smoke is small at play scale, because it fits above the cars on the 200×50
canvas — larger smoke needs a taller canvas for both frames and both shadows; and whether the
steam should hold still during its notice, so that billowing means the passage is shut. Both are
in `REVIEW.md`.

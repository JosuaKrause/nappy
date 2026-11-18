# minty-quail — The scenery's, the lights' and the props' fields read through methods · 2026-11-18

**What it is.** A part of minty-quail's `field-reads.md` conversion: six classes in the city whose
fields were read from outside their files (sixteen lines): the scenery's ground, water and residency,
the traffic lights, the props and the building shadows. A Sonnet builder built it to the pattern the
record 2026-10-18-minty-quail-curly-elk settled. It changes nothing in play.

**What was built.** The ground takes its atlas through `use_atlas()` and answers `tile_set()` and
`elapsed()` (the city scene sets the exported tile set under `_tile_set`); the water takes its atlas
through `use_atlas()`; the residency takes `use_frame_timing()` and `use_view()` and answers
`view()`. The lights are switched by `use_power(on)`, which the blackout and the scripted scene
call, and answered by the existing `is_powered()`; the scripted scene sets their clock by
`restart_cycle()` and `advance(seconds)`, which give the same value. The props answer `kind()`,
`variant()`, `scale_factor()` and `shape()`, set by the existing `dress()`. The building shadows
take `stream_in_chunks()` and `use_falls_on()`, which the city and the shadow suite call, so they
leave the item's group of fields only a test reads. The crowd-traffic skill, `docs/CITY.md` and
`docs/GRAPHICS.md` name the lights' methods where they named `TrafficSignals.powered`.
`tools/field_reads.txt` lost fifteen lines and gained none.

**Left:** `SceneryResidency.frame_locked`, written by the city and read only by
`tests/test_run_config.gd`, joins the item's group of fields only a test reads.

**Proposed, not asked for, open to the player:** the names `use_power(on)` and `use_view()`; the
exported `_tile_set` rather than a hand-in; the building shadows converted as well.

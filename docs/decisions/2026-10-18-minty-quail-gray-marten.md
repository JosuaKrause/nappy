# minty-quail — The field of noise is a part (row 4b) · 2026-11-21

**What was asked.** Row 4b of minty-quail's `event-interface.md` (a row is written as its parts), designed by Opus;
this is its fourth pull request, "the field of noise is a part", built as #1616 by two Sonnet agents in turn (the first
stopped near its limit at a pushed commit).

**What was built.** `FieldSpec` (`src/events/parts/field_spec.gd`, data) holds the row's ten field settings and the
vehicle's "priced from its centre" flag, the field's maths, and the distance past which the field is silent, worked out
once when the value is made. The row holds one `field()` set by `use_field()`, and forwards the field's questions a
plan, a live event or a caller outside the folder asks, among them `core_rate()`, `core_reach()` and `falloff()` for
the cost table (the design's F5). The catalogue writes one field per row; the excitement source's cache key holds the
field by reference rather than copying six of its values; the flock and the cost table read through the row;
`VehicleSpec` keeps no setting; `validate()` loses "half a core", which `with_a_core(rate, reach)` makes unwritable.

**F7, overridden by the orchestrator.** The design dropped `test_prediction_reuse.gd`'s nine checks that changed a built
row in place, since a row can no longer change; a check is never dropped, so each is held by a second row differing in
that one setting (`FieldSpec.holding_to()` lets the inner radius alone differ), asked right after the row's own. Its
check count went from 6,608 on main to 8,105. With the key made to leave the field out, the falloff, inner- and
outer-radius variants fail; the core rate and reach (the test point lies outside any core), the peak and pulse (they ride
on the live intensity, in the key anyway) and the two speeds (they do not enter the number there) cannot fail under that
cache, as on main.

**Measured.** The row fingerprint (`tests/probes/row_fingerprint.gd`): every old field setting line (550, ten settings
on 55 rows) reappears under the part with the base's value, the vehicle flag on the field with the same values, and no
copy's full dump has an unexplained line. The excitement fingerprint's `XF` lines are identical, `docs/COSTS.md` is
unchanged, and the events' tick sweep (`m159_tick_sweep_events_cost.gd`) keeps the same state chains and is no slower.

**Open to overturn:** the design's forks but F7; the builders' `holding_to()`.

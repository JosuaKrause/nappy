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
that one setting, refined from the row's own field (`FieldSpec.holding_to()` lets the inner radius alone differ) and
asked right after the row's own; the core rate and reach are varied on a row that has a core, the leaf blower, and asked
inside it. The suite's check count rose from 6,608 on main to 7,463. With the cache key made to leave the field out, the
falloff, inner- and outer-radius, core rate and core reach variants fail; the peak and pulse fail once the key also loses
the live intensity, and the two speeds once it loses the velocity (the review's measurement).

**Measured.** The row fingerprint (`tests/probes/row_fingerprint.gd`): every old field setting line (550, ten settings
on 55 rows) reappears under the part with the base's value, the vehicle flag on the field with the same values, and no
copy's full dump has an unexplained line. The excitement fingerprint's `XF` lines are identical, `docs/COSTS.md` is
unchanged, and the events' tick sweep (`m159_tick_sweep_events_cost.gd`) keeps the same state chains and is no slower.

**Open to overturn:** the design's forks but F7; the builders' `holding_to()`.

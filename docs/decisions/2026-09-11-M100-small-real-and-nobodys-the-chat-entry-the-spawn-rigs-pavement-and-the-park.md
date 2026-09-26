## M100 — Small, real, and nobody's · the chat entry, the spawn rig's pavement and the park trees, built 2026-09-11

Three defects, three agent commits on `feature/three-small-defects`, reviewed here. **`chat` is
documented, and the two lists are held together**: `docs/TELEMETRY.md`'s table gains the row,
and `tests/test_telemetry.gd` scans every `Telemetry.note("<kind>"` call under `src/` — plus
the bare `note(` calls the telemetry autoload makes on itself, where the `shot` kind lives —
against the table's first column and asserts the sets agree both ways. A static list of kinds
was rejected because it would be a third thing to keep in sync; there is no enumeration in the
code, `note()` takes any string. Two traps in the scan itself, fixed before it landed: scanning
the file as one block let the pattern run from the one call with no comma into the doc comments
below it, so it scans line by line and skips comment lines; and Godot's `%` treats a bare array
as the argument list, so an empty match array threw until wrapped. **`--spawn event:<id>` stands
her on the pavement whatever the street's axis**: the fixed local-Y step became
`main._pavement_offset()`, which asks `EventInstance._spread_is_vertical()` — the same question
a spread asks to lie across the carriageway it blocks — and steps across the street's own axis.
The test drives two known corridor tiles on a bare `CityMap`, since the offset is arithmetic on
`Tuning.STREET_WIDTH`; a seed-driven test could pass by luck on the axis it never exercised.
**Park trees keep their distance**: `City.MIN_TREE_SPACING` (50px) is checked before a
candidate is accepted in the lot's rejection loop, never as a pass afterwards. The number is the
picture's: both tree pictures are 40px wide and scale up to 1.25×, so 50px is the widest a canopy
is ever drawn and two closer than that overlap into a clump. Deriving it from `Prop`'s shadow
footprint (about 11–14px) was rejected as a number for a different job. A throwaway probe over
sampled lots showed the forest's per-block target still reached under the extra rejections, so
the attempt cap is unchanged; the test groups a real day's trees by lot anchor over three seeds
and asserts every same-lot pair clears the spacing.

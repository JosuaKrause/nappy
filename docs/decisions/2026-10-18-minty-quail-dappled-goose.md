# minty-quail — The catalogue's whole list and the calm areas' unused list stop being read by tests · 2026-11-24

`EventCatalogue.all()` and `CalmAreas.unused()` were public members only their own file and tests read.

- **`unused()` is deleted.** Its one user, `unused_ground()`, reads the used list itself. A test that needed the
  unused blocks asks `blocks()` and `used()`, or `unused_ground()`; `FakeCalmAreas` overrides
  `unused_ground()`. The block-level check keeps its own place beside the ground check
  (`test_calm_areas.gd` counts as before).
- **Suites walk every row through `tests/catalogue_rows.gd`, `CatalogueRows.every()`**: the rows
  `EventCatalogue.available_on()` returns over days 0 to the run's length, each once. Measured once against
  `all()`: the same 55 rows, none missing, in another order (first availability, not catalogue order).
  Rejected: a `[kept]` line for `all()`, which would leave 27 suites reading a loophole.
- **`all()` stays public** because `tools/cost_table.gd` walks it for the table's fixed catalogue order, which
  no per-day question gives. No test reads it, so the check lists nothing, and a test that reads it again fails the check.
- **A row available on no day in 0 to the run's length** would be missed by `CatalogueRows.every()`;
  `tools/cost_table.gd` (`cost-table.sh --check`, in CI) fails naming such a row. Shown failing once with a
  temporary row from day 40.

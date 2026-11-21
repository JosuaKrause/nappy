priority: now
after: 2026-10-18-minty-quail

# jolly-gecko — A ground shape is a value: its four public fields are read through methods · filed 2026-11-21

**The finding.** The design of minty-quail's row 4b (a row written as its parts) found that `GroundShape`
(`src/ground_shape.gd`, the outline a body or a field stands on: a point, a band or a box) keeps four public fields,
`kind`, `radius`, `half_length` and `half_extents`, read by the car's driving, the row, the excitement source, the
live event and the walk's ground (the eleven lines `tools/field_reads.txt` lists under it), and written in place by one
test (`test_prediction_reuse.gd`'s shape change). It is a model value no entry converts, so the excitement source's
cache key copies its values rather than holding the shape. The refactor's rule is that a field is not an API and a
caller asks (minty-lemur #785, #794); the refactor's list is frozen (inbox #1268 in olive-ferret), so what it finds from
here is filed as an entry of its own after it.

**Item:** `shape-asked.md`.

**Proposed, not asked for:** the band `now` and `after: 2026-10-18-minty-quail` (the refactor's own kind of work,
started once the refactor is done), and the item's shape of the fix.

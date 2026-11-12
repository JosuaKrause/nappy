# The event strides sheet writes over its dated evidence with different pictures

`tests/probes/m108_event_strides_sheet.gd` draws every event family's five views with its two
stride frames side by side, straight from the drawings under `art/events/`, and saves the sheet at
native scale and at three times (`event-strides-native.png`, `event-strides-3x.png`) into
`docs/evidence/m108-event-strides-2026-09-12/`, the folder of M108's stride review.

**Its first failure:** run today, it writes those two pictures with content that differs from the
committed ones (the record 2026-10-18-minty-quail-breezy-ferret), so a run leaves the dated evidence
of that review changed in the working tree. The walker's stride sheet (`m108_walker_stride_sheet.gd`)
matches its committed pictures.

*Proposed, not asked for:* fixed, by writing to a scratch folder or to a new dated folder rather
than over the review's evidence, so the committed pictures stay what that review looked at; or
deleted, the review's pictures standing in their folder.

# Assembly metadata

The frozen PNG inputs are copied from runtime asset state at source revision
`d58233ab1e7d150d8e82b6941cbe082e4b1ea174`. The assembly script is SHA-256
`80130d4fc78e855f8e8ec6712ef50588899b4a9a3bf26cc32e8c17c6289fd846`, run with Pillow `12.3.0`.
`SHA256SUMS` records the eight frozen input PNGs.

The static sheet uses these screen offsets from the mother's feet (before → after):

| Facing | Before | After |
| --- | ---: | ---: |
| N | `(0, -11.900)` | `(0, -11.900)` |
| NE | `(16.971, -8.415)` | `(16.971, -6.415)` |
| NW | `(-16.971, -8.415)` | `(-16.971, -6.415)` |

The 2px value is a visual choice made against the hand and handle in all three P2 poses. This
record does not claim a separately measured hand-to-handle landmark distance; the test verifies
the geometric bound, symmetry and preservation contracts, while the sheet provides the visual
review of the chosen placement.

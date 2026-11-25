priority: bug

# frosty-marten — The screen-edge badge's closing speed grows with the frame rate · filed 2026-11-24

**What this is.** Found by minty-quail's end remeasure (a bug a refactor step's remeasure finds is filed
`bug`, inbox #1519 in breezy-magpie), not by a playtest. It is the interaction of events stepping on
the 30 Hz physics tick (minty-quail-21) with the charge rule in the badge's measure (inbox #788 in
minty-lemur).

**Read as:** a bug, not a design change; the badge's closing speed is meant to be the thing's own
approach speed (about 110 px/s for the masked man, `docs/TELEMETRY.md`).

**Items**, one file each:

- `badge-closing-speed-per-frame.md`: the evidence and the cause.

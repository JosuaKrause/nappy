## Graphics branch and gameplay integration — 2026-09-12

The graphics tip was `3b2ad2561c097cf103220f0f7441c258babdbc70`, incoming main was
`3fdcb50c2de1003cb4ce412cab63443769f03335`, and their base was
`28fe84596ab10b06ac7814de3114c0b193cb332b`. Preparation commit
`98faaaa` renumbered the graphics Playtest 63 to Playtest 64, preserving every quote and
the evidence paths; main independently used 63 for decay and crash-body feedback.
No milestone identity collided: repeated M109 headings describe distinct dated work.

The archive conflict retains both sets of records. The graphics inventory combines the new
event stride and idle frames with per-seat café facing. The café drawing chooses its idle
frame family once, then the correct view and mirror for each table-facing seat. Both the
musician's idle drawing and the café's facing helper survive. Alley-aware barrier selection
also survives; the solid-body footprint computation uses that same spread axis. Tree beds
remain ground decals, separate from upright tree drawings and their shadows; props have no
collision bodies. Fallen-tree visibility updates both layers. Return patrols and stationary
crowd obstructions retain main's implementations.
The queue keeps main's open decay/crash work and removes its finished stride, crowd and
return work while retaining the graphics branch's comic-transfer requirements.

The concurrent remote integration `62d1c34` was reconciled with local `f1ef463` before
pushing. Both independently integrated the same main tip, so the two merge bases were
`3fdcb50` and `3b2ad25`; Git synthesized an ancestor containing conflict text. The result
keeps the remote's matching Playtest 64 evidence-folder rename and café explanation, plus
this local review and the new Playtest 65 requests. The executable source is identical to
the remote integration; both preserve per-seat café facing and shared idle timing.

# spry-magpie — The frame record's download says it was saved · 2026-10-11

[azure-tapir](../playtests/2026-10-04-azure-tapir.md), inbox #530: "There is no feedback that the
files were saved so I downloaded multiple copies."

**What is built.** The `save frames` button the page draws over the canvas answers a tap: for six
seconds its label reads `sent to your browser: <file name>`, then returns to `save frames`, and a
second tap restarts the six seconds (`FrameRecorder._on_page_save()` in
`src/telemetry/frame_recorder.gd` calls the page script's `nappyFrameRecordSent` with the name
`save()` returns, and not at all when that name is empty). The words say the file was handed to the
browser, since the page cannot observe whether the download finished; that and the label on the
button rather than a readout line were the entry's proposals, built as proposed. The label wraps
within the viewport, so on a narrow phone it grows downward rather than past the screen's right
edge. `docs/TELEMETRY.md`, "Getting it off the device", says what the button shows. The stills
(before, after, and after at 360px wide) are in `docs/evidence/spry-magpie-2026-10-11/`.

*Chosen by the implementer, open to overturn:* the six seconds; the label set from the game's side
after `save()` returns, so a failed save leaves it unchanged; an 8px right margin, which at 360px
wraps the label onto several lines.

priority: now

# spry-magpie — The frame record's download says it was saved · filed 2026-10-04

[azure-tapir, the frame record's download](../../playtests/2026-10-04-azure-tapir.md) files inbox
#530. Recording on the phone with the released v0.24.0 page, the player saved the record through
the page's save button:

> There is no feedback that the files were saved so I downloaded multiple copies.

The two files from that run were one record saved twice, the later holding the earlier one's frames
as an exact prefix plus the frames played between the taps.

**The existing save.** On the web, a button the page itself draws over the canvas saves the record
through the browser's own download (`FrameRecorder.save()` in `src/telemetry/frame_recorder.gd`,
`JavaScriptBridge.download_buffer()`), the download starting inside the tap that asked for it, as
a phone's browser requires; `docs/TELEMETRY.md`, "Per-system frame records", describes it. Nothing
on the page or in the game answers the tap.

**Asked for:** feedback that the file was saved, so one tap is enough.

**Proposed, not asked for:**

- The button itself answers the tap: its label changes to say the record was saved, with the file
  name, for a few seconds, as a page element like the button rather than a game control. The
  plainer alternative is a line in the readout, which the filer reads as easier to miss on a phone
  than the button the player just tapped.
- Whether the browser actually finished the download is not observable from the page; the
  feedback says the download was handed to the browser, and says so in its words.

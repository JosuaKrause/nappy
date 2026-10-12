**The frame record and the readout say how many pixels the page draws, and the readout refreshes
its text a few times a second** ([velvet-marten](../../playtests/2026-10-11-velvet-marten.md),
#700: "We need to more resolution of the debug readout, yes", read back as both and answered "Both
(Recommended)").

- **The resolution.** The record's environment gains the window size, the device pixel ratio and
  the size actually drawn; the readout shows them. No record today says how many pixels the phone
  draws, which the pixel multiplier ([the-frame-goes-straight-to-the-screen-then-fewer-pixels.md](the-frame-goes-straight-to-the-screen-then-fewer-pixels.md))
  needs to be measured against.
- **The refresh.** The readout re-sets about thirty lines of text every frame, which adds draw
  calls and drawing work to every phone record taken with `?debug=1`. Updating it a few times a
  second, or only when a line changes, takes that out of what the record measures.
- **The analyser.** `docs/evidence/m159-phone-frame-record-2026-10-04/analyse.py` stops at its
  section 6 on a record without day 1, as both of velvet-marten's records are; it should report what
  it can and go on to the sections after it.

## M109 — Southern diagonal stroller wheel reuse — 2026-09-12

PLAYTEST-65 requests correcting the SE/SW wheel plane without changing its grounded height,
first trying pixel mirroring and then suggesting the NE/NW wheels as donors. The final SE
derivative copies the NE wheel and lower attachment pixels without mirroring; runtime supplies
the SW reflection. The three half-open donor bounds are (5,22,13,29), (13,23,23,30) and
(24,21,32,29). The body above those attachments, canopy, handle, canvas and occupied height stay
fixed. The direction assignment remains authoritative and must not be reversed again.

Review rejected the mirrored donor and a partial transplant that left old wheel pixels beneath
transparent donor pixels. Exact RGBA replacement, including donor transparency, clears those
remnants and includes the complete wheel edges. Frozen inputs, masks, hashes, native comparisons
and the paired SE/SW enlarged review are retained in the wheel reuse recipe. Its rebuild matches
the installed PNG byte-for-byte; the other four stroller PNGs retain their assignment hashes.

Fix the camera's initialization in PR #580 before further trailer improvements. It must begin
at the actual player position, not at world (0,0) followed by a fast smoothing move toward her.
Trace ordinary boot, saved-scene placement, current-camera handoff, smoothing and look-ahead
initialization to identify the cause; trimming away the bad frames alone is not this fix.
Preserve the decided city camera without limits and the interior's own limits.

Verify the first actual camera transform, then consecutive frames through the beginning of
movement. A later settled still cannot establish the initial state. Keep a positive moving
lead-in for recording: the player's "still not at 0 since we want to see movement" means a
correct snap must not expose an idle-to-walking start. Once initialization is correct, measure
the earliest stable moving entrance for each affected scene; reduce excluded time only where
the retained action remains complete. Preserve the current cut, caption/audio choices and the
two bird variants while diagnosing. Show a useful corrected opening promptly; no repeated full
render comparison (`--check` or `--check-load`) is requested.

Use focused initialization/transition regression coverage and a short rendered opening as
evidence. Keep generated video, frames and audio local under ignored `build/trailer/`; deliver
the preview path in the main checkout. This does not pick up the separate standalone escape
screenshot investigation or authorize further creative edits to the trailer.

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
chosen `current` westward bird sequence from [silky-egret](../../playtests/2026-10-07-silky-egret.md).
Show a useful corrected opening promptly, then render one complete local trailer for review;
the bird choice is answered and no alternative bird render is needed. No repeated full
render comparison (`--check` or `--check-load`) is requested.

Use focused initialization/transition regression coverage and a short rendered opening as
evidence. Keep generated video, frames and audio local under ignored `build/trailer/`; deliver
the preview path in the main checkout. Inspect and preserve the unfinished Claude workspace
before recovery. This does not pick up the separate standalone escape
screenshot investigation or authorize further creative edits to the trailer.

With the camera fixed, start recording each scene a little earlier without changing the scene
itself. Keep a positive moving lead-in. Add two seconds each to the intro slide, title card and
the final shot's hold after it is fully zoomed out; extending the zoom motion does not satisfy
that last request. Preserve existing action, captions, route and scene composition.

The circular-walk scene is the explicit exception to preserving scene composition: replace
its setting with a new saved scene made only of park tiles and trees, and keep the entire
circle inside the park. Preserve its close view, mother and sleeping baby, circular motion and
place in the cut. Frame and place the route so the pram stays clear of trees throughout.

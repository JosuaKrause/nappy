## Animation anatomy and camera experiment — 2026-09-08

PLAYTEST-42 preserved the complete run `run-204805-seed2468684785-v0.7.0-43-g1131bba`,
including both original bursts, timing records, sibling videos, maps and log. Inspection of
burst `15638553-002` frames 1, 12, 24 and 36 showed the overextended player reach, bent legs
retained after stopping, outward-facing walker knees and baby appearing over the seat. The PNGs
demonstrated that these were not introduced by MP4 compression. The burst contained 36 samples
over approximately three seconds; its timestamps, rather than an assumed fixed frame rate,
were the timing evidence.

Source inspection found that some mother upper-leg crops already included a painted knee and
part of the shin. Adding a separately solved knee and lower segment could therefore draw two
bends while the endpoint assertions still passed. `PlantedGait` solved knees with opposite bend
signs and retained unfinished steps through stops. `ModularPerson` placed the pram from the legacy
34-world-unit distance and stretched the source arms to its handle contacts. These were anatomy,
pose and reach issues, independent of camera resolution; no source or gait repair was claimed.

The project rendered with a 1280×720 authored viewport and a camera zoom of 2, exposing about
640×360 world units. The assistant interpreted the request as removing that magnification while
keeping the window.
The comparison isolated camera extent; zoom 1 exposed 1280×720 world units but did not add raster
pixels. Nearest texture filtering, extracted alpha coverage and source detail at small actor
sizes remained separate image-quality factors. Increasing the logical viewport with canvas-item
stretch alone was not treated as proven supersampling.

The debug `--illustrated-zoom` override was implemented with default 2 and a finite positive
range clamped to 0.5–4. Invalid values fell back to 2. The camera consumed it only for illustrated
mode; legacy framing and the 1280×720 window settings were retained. The clean integration was
reviewed against both branches: the flag parser and player camera agreed, the experiment docs
kept anatomy unaccepted, and the separate merge-skill refinements remained intact.

The [zoom-1 capture](../evidence/archive/session-captures/2026-09-08/illustrated-camera-zoom1.png)
showed the wider scene in a 1280×720 PNG, with smaller actors and unchanged HUD scale. It did not
demonstrate improved detail or animation. Its command was `tools/shot.sh /private/tmp/nappy-zoom1.png
0.8 --illustrated --illustrated-zoom 1 --seed 2468684785 --walk south`. The attempted
[baseline capture](../evidence/archive/session-captures/2026-09-08/illustrated-camera-zoom2-ended.png)
used the same seed with `--spawn arterial --walk 1s3e` at three seconds, but a traffic collision
put the ending overlay over the scene. These were not a matched route/time comparison. Baseline
build was b1f761f; the wider capture used df362ff with the pending 9032c1f camera integration.
The screenshot's startup FPS sample was not a sustained performance measurement.

The merged checkout passed the import/boot check, focused presentation-mode, stroller and visuals
suites with illustrated zoom 1, and the stroller suite in legacy mode with a non-default requested
zoom. The visual suite's deliberate malformed-registration diagnostics were expected; no script
errors were observed. Doc lint and diff checks passed. Source, gait, pram seating and sampling
quality remained open repairs rather than results inferred from the camera test.

The user corrected the interpretation: "I did not want to see more world -- I want higher
resolution for the current view". The wider-camera experiment did not satisfy the request.
The required experiment increases the actual rendered pixel count and downsamples into the same
window while retaining framing, actor size, HUD and input mapping. The camera option is removed
from the intended solution rather than presented as an accepted alternative.

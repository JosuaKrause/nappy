## Gameplay animation capture — 2026-09-08

PLAYTEST-46 requested video or a burst of screenshots so the player could communicate animation
defects. The player confirmed ffmpeg was installed and specified one sequence per subfolder in
the screenshot folder, with the video beside the sequence. They rejected F-key controls. The
selected control is Shift+P for a burst, leaving P for a single image; the rig uses the named
`snapshot_burst` action instead of a function key.

The capture contract is a three-second burst targeting twelve frames per second, capped at
thirty-six images, saved under the current run's `asked/burst-<id>/`. Sequential PNGs and
`burst.json` preserve actual monotonic capture times. `tools/clip.sh` converts the newest complete
burst, or an explicitly named folder, to a sibling `<burst-folder>.mp4` with ffmpeg. Conversion
preserves the original PNG sequence and refuses an existing destination. Separating recording
from encoding keeps encoder failures from losing source evidence or running an encoder while
the player is trying to demonstrate a movement defect.

Actual frame times, rather than the nominal capture frequency, determine playback timing.
Capture reads the viewport after drawing and performs bounded file writes; it does not alter
gameplay state or RNG. Readback and PNG encoding still cost time, so a capture does not establish
uncaptured performance. Overlapping requests are refused, and ending a day or run finalizes a
partial sequence in the originating run. Capturing while paused records the paused screen;
it does not unpause the game to manufacture animation.

The implementation uses a token-guarded deadline independent of the post-draw wait. Old callbacks
cannot finalize a newer burst. Metadata writes are checked through flush and failures terminate
capture without reporting success; an empty deadline is cancelled. The log records portable
`asked/<folder>` paths, while console output gives the absolute path for locating files.

Verification passed `./tools/check.sh`, `./tools/test.sh telemetry burst_capture`,
`uv run python tools/test_clip.py`, `./tools/lint.sh` and whitespace checks. The recorder tests
cover physical Shift+P, plain P, key repeat, the named rig action, refusal, unique folders,
metadata ordering, stale callbacks, cancellation and write failure. The converter tests decode
the MP4's colored frames to check order and compare every source file byte for byte.

A bounded rendered integration run exercised moving capture, an overlapping request, then a
paused capture. It produced 29 moving frames over 3.037515 seconds and 36 paused frames over
2.999814 seconds; the second overlapping request was refused. Both converted to 1280×720 H.264
`yuv420p` sibling MP4s with a reported duration of 3.04 seconds, with all PNGs retained. The timing
difference includes MP4 frame-time quantization; the PNG manifest retains the finer capture
times. The paused sequence retained the pause screen. This verifies capture and conversion,
not acceptance of the illustrated actor posture shown in the frames.

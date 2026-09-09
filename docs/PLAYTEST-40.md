# Playtest 40 — Convert pending bursts · 2026-09-08

> can't clip search for unfinished bursts? it's an easy check

> no I'm saying scan the telemetry folder for bursts that don't have an mp4

The plain `tools/clip.sh` command must scan the telemetry folder for burst folders whose sibling
MP4 is missing and convert them, rather than selecting only the newest completed burst. Keep the
PNG sequences and existing videos intact. A currently recording sequence is not ready to encode;
an ended partial sequence with frames is eligible. An explicit folder still selects one sequence.

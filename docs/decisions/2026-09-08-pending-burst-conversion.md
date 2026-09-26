## Pending burst conversion — 2026-09-08

PLAYTEST-40 clarified that `clip` should scan the telemetry folder for bursts without an MP4.
Selecting only the newest completed burst made repeat calls stop at an existing video and left
older sequences unconverted. The default command now scans across runs for missing sibling
`<burst-folder>.mp4` files, preserving existing videos and every source frame. Active recordings
are skipped; completed or ended partial sequences with frames can be converted. An explicit
folder still selects a single burst. An empty pending set is a successful no-op, and a failed
conversion does not prevent attempting the other pending sequences.

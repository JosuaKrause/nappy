# Playtest 41 — Capture control and ffmpeg compatibility · 2026-09-08

> shift interferes with running. Unrecognized option 'fps_mode'.
> Error splitting the argument list: Option not found

The supplied converter error identifies the sequence
`run-204805-seed2468684785-v0.7.0-43-g1131bba/asked/burst-15638553-002` and an ffmpeg invocation
using `-fps_mode vfr`, which exits with status 1 before encoding. Its remaining arguments are
the concat manifest input, odd-size padding, H.264, `yuv420p` and faststart output.

The capture shortcut must not require the gameplay run modifier. Use plain B for bursts, retaining
P for single screenshots and the named `snapshot_burst` action for scripted checks. B must also
work while Shift is already held to run. Use the older ffmpeg `-vsync vfr` spelling for timed
conversion so the installed encoder can accept the command, preserving the source PNG sequence.

# Playtest 39 — Animation capture · 2026-09-08

> we need a functionality of recording a video of the gameplay or at least a burst of screenshots so I can communicate animations to you

The player needs an in-game recording control that preserves animation as a sequence, extending
PLAYTEST-13's manual screenshot control. A screenshot burst satisfies the requested minimum.
The implementation brief uses Shift+P or Shift+F9 to start a bounded three-second burst targeting
twelve frames per second, leaving ordinary P/F9 as a single screenshot. Save numbered PNGs and
actual frame timestamps in a distinct folder beside the current run's telemetry, with context
in the run log and clear start/finish output. No video encoder is required for the initial feature.
This is developer capture tooling; it must not change movement, RNG or the game's rules.

## Video and folder layout

> ffmpeg is installed

> but keep the sequence and put it in a subfolder in the screenshot folder -- so one sequence is one folder and the video is besides the folder

Keep frames and timing metadata in one `asked/burst-<id>/` folder per sequence. Write its video
beside that folder as `asked/burst-<id>.mp4`. ffmpeg conversion must retain the PNG sequence.
F10 is also a direct burst shortcut so the existing scripted key-press rig can exercise capture.

## Keyboard correction

> don't use F-keys I cannot press them

The player rejects F-key controls for this feature. Use Shift+P for bursts and P for a single
screenshot. The scripted rig uses the named `snapshot_burst` input action, so testing needs no
F-key alias. This supersedes the F10 and Shift+F9 proposals above.

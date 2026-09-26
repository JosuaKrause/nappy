## M204 and M214 — The trailer and its recording tools · built 2026-09-26

*([PLAYTEST-139](../playtests/PLAYTEST-139.md): "the trailer will be a set of paths in pre determined
seeds with fixed events so we can reproduce it easily" · "the automated walking rig -- can we add an
option to record there, too?" · "no videos should be checked in of course".)*

**What is built.** `tools/trailer.sh` renders `tools/trailer/shots.json`'s shots through Godot's
movie writer, frame-locked at the game's resolution with its audio, then trims, fades, captions and
joins them with ffmpeg into gitignored `build/trailer/`, deleting the frames; `--check` renders a
shot twice and compares. `tools/record.sh` records any rig run the same way into `build/records/`.
The rig gained `--player-view`, `--parent mother|father`, `--zoom-out`, `--caption`, `--title-card`,
`--spawn door[:n]`, and `--walk` legs with decimal durations, pauses and runs.

**Two bugs a render found**, both invisible in the run log: the movie writer's window has no OS
focus, so without `--no-focus-pause` every frame was the pause screen; and physics interpolation
blends frames by real presentation time, which in a recording runs far slower than game time, so
every frame froze. `main.gd` turns physics interpolation off while recording.

**Open**: the cut itself (M204 in `TODO.md`), for the player's notes. `--spawn arterial` on day 13
renders differently each run, not root-caused; `tools/shot.sh --screenshot` seems to hang with
`--start-escape` and `--walk`.

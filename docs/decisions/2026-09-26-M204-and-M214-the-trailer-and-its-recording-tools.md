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

## Recipe source and editorial review · 2026-10-03

The original PLAYTEST-139 render had no visible truck, no clearly running carrying
mother, and two consecutive father shots. Its drafted captions were "Every walk is
a choice.", "Not every street is safe.", and "One family. A whole city.", with
"Nappy" as the title. These were drafts awaiting the player's review, not a finalized
edit. The earlier loaded-render experiment found differing second-pass frames in
choice, danger and title while two other Godot processes were busy; those shots
matched when rerun on a quieter machine. The original standalone escape screenshot
hang remained separate from the movie-writer path.

PR #457 replaces the shot sources with authored recipes and supplies stills plus
action checks. Its first authored cut split early danger into blower and dog, revised
shot lengths and omitted recipe caption overlays. Review identified that these editorial
changes were unmarked. M204's queue retains the editorial choices explicitly, with all
three drafted caption phrases retained for the player's choice. No final editorial
approval or loaded-render reproducibility is inferred from scene acceptance. The
queue describes the current recipe source; the earlier seed workflow stays in this
record as failure context rather than as the procedure to reproduce a new scene.

[Lilac-beaver](../playtests/2026-10-03-lilac-beaver.md) then replaces the blower scene
with a bird flock and accepts the trucks, gate, chase and whole-city compositions.
Those scene decisions do not select final movie durations, captions or ordering.

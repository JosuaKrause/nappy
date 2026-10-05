# grassy-goose: a touched target sends the robber from off screen

**Claim.** On day 8, reaching the burnt building's door sends `robber_giving_chase` from off
screen, from across the street (`ResistanceDirector._across_the_street()`, the front-door start):
the screen-edge badge is up before he is in view, he comes into view walking up from the block
opposite, crosses the street at her and lunges while she stands at the door.

**What the four stills are.** Four separate runs of one scripted scene recipe,
`task-08-trap-recipe.json` — `scene-recipes/task-08-burnt-shell.json` with its walk extended by a
4.5s stand at the door (`4.5p`) and its duration to 12.5s — each photographed at a different
`capture_at`: 9.0s (the badge at the bottom edge, nobody in view), 9.8s (he is in view on the
far sidewalk below her, her `!` and his red caret), 10.6s (the lunge, `!!`, as he crosses the
road), 10.75s (still lunging, onto her sidewalk). The scripted recipe replays the same setup and
input every run, so the four are frames of the same arrival, but they are four runs, not one
burst, and two runs of one seed differ by a few frames, so his position between them is close
rather than exact: a recipe owns its input, so `--press snapshot_burst` is refused
with `--recipe`, and a `--route` run cannot take `--screenshot`.

**Command** (from the worktree root, revision `db3ebb75`, Godot 4.7.2, macOS, 1280x720):

    tools/shot.sh out-9.0.png 9.0 --recipe docs/evidence/grassy-goose-target-trap-arrives-2026-10-04/task-08-trap-recipe.json \
        --recipe-mode scripted --player-view --invincible --no-save

and the same for 9.8, 10.6 and 10.75. `--invincible` keeps the catch from ending the day, so the
lunge frame is reachable; without it, `tools/scene-recipes.sh --recipe <the same file>` stops at
tick 333 with "gameplay paused before the authored action completed" — she is caught standing
there.

**Run log, for the same runs:** `task handed over: a robber sent after her from (84,66), 316px off
(a walk at her from across the street)`, then `edge badge: robber_giving_chase at 308px, closing
41px/s`, and `near` lines from 200px in.

**Limits.** One seed and one target. Where each target's robber starts across 30 cities is
`tests/probes/grassy_goose_target_traps.gd`'s table, not this folder.

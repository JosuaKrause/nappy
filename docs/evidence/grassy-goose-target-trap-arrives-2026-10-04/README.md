# grassy-goose: a touched target sends the robber from off screen

**Claim.** On day 8, reaching the burnt building's door sends `robber_giving_chase` from off
screen: the screen-edge badge is up before he is in view, he comes into view walking up from the
street below, and he closes on her and lunges while she stands at the door.

**What the four stills are.** Four separate runs of one scripted scene recipe,
`task-08-trap-recipe.json` — `scene-recipes/task-08-burnt-shell.json` with its walk extended by a
4.5s stand at the door (`4.5p`) and its duration to 12.5s — each photographed at a different
`capture_at`: 9.2s (the badge at the bottom edge, nobody in view), 9.7s (he is in view below
her), 10.1s (closing, her `!` and his red caret), 10.5s (the lunge, `!!`). The scripted recipe
replays the same setup and input every run, so the four are frames of the same arrival, but they
are four runs, not one burst: a recipe owns its input, so `--press snapshot_burst` is refused
with `--recipe`, and a `--route` run cannot take `--screenshot`.

**Command** (from the worktree root, revision `069ca554`, Godot 4.7.2, macOS, 1280x720):

    tools/shot.sh out-9.2.png 9.2 --recipe docs/evidence/grassy-goose-target-trap-arrives-2026-10-04/task-08-trap-recipe.json \
        --recipe-mode scripted --player-view --invincible --no-save

and the same for 9.7, 10.1 and 10.5. `--invincible` keeps the catch from ending the day, so the
lunge frame is reachable; without it, `tools/scene-recipes.sh --recipe <the same file>` stops at
tick 318 with "gameplay paused before the authored action completed" — she is caught standing
there.

**Run log, for the same runs:** `task handed over: a robber sent after her from (85,66), 311px off
(a clear run at her)`, then `edge badge: robber_giving_chase at 300px`, and `near` lines at 200,
110, 60, 33 and 18px.

**Limits.** One seed and one target. Where each target's robber starts across 30 cities is
`tests/probes/grassy_goose_target_traps.gd`'s table, not this folder.

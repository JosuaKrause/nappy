# Playtest gentle-swan — Investigate lazy scenery preparation and unloading

2026-09-30.

## Conversation context

The player asks whether more optimizations remain and whether overall loading can be faster:

> are there more optimizations we can try? are there more ideas? if not that, then is possible to make overall loading faster?

The assistant identifies shared ground composition reuse, duplicate startup preparation,
preparing distant scenery before it enters view, and separating partial animation from static
scenery as possible directions. These are proposals, not measured improvements.

> what are the scene preparation tasks? can loading measurements be done in parallel?

The assistant explains that investigation can proceed in separate checkouts, while timed runs
on the same machine need to run serially without competing heavy builds. Loading stages proposed
for attribution are download, engine startup, city generation, visual preparation and first play.
The assistant recommends measuring ground-sheet reuse before camera-driven preparation.

## Requested investigation

> let's investigate preparing distant scenery lazily -- that would make reusing ground artwork obsolete. my hypothesis is that the player rarely sees all tiles that get prepared so it's a lot of wasted memory and time. we can even unload scenery if it goes out of view too far

The assistant agrees to investigate prepared-versus-seen scenery, retained memory, preparation
near the camera and release at a greater distance, while distinguishing shared textures from
map-specific scenery and preserving off-screen gameplay.

> reusing composed ground is tricky since we do have some changes day to day -- so I doubt it will work consistently

The investigation prioritizes lazy preparation and unloading. Cross-day reuse is not a
prerequisite; reconstruction must reflect the current day's state. The claim that lazy scenery
makes ground-artwork reuse obsolete remains the player's hypothesis to evaluate.

## Boot prepares the nearby scenery

The assistant's earlier explanation identifies boot's ground paint and the first day's repaint
as two preparation passes. The player specifies how boot belongs in the lazy policy:

> the boot paint should only be for the block around home

> that would fall into the category of only closeby scenery and lazily create distant ones as the player comes near

The assistant understands boot as the first use of the same nearby-scenery policy and will check
the actual initial camera view and artwork overhang against the home-block boundary.

In the PR review, the player answers the boundary question directly:

> block around the home means plus margin otherwise you might get gaps

The margin is part of the player's request; its exact size remains unchosen.

## Download size is the first loading measurement

While the scenery investigation is being prepared, the player specifies where to start the
parallel loading investigation:

> for the loading investigation a start would be to inspect how big the package is that is getting downloaded

The assistant will inspect the deployed game package, engine WebAssembly and JavaScript sizes,
then attribute the package contents, keeping transfer costs separate from scene preparation.

## Keep the scenery investigation focused

The assistant reports a measured opportunity in nearby ground preparation and adds: "A separate
limit also emerged: route and closure planning dominates the measured day-start time, and lazy
scenery alone won't remove that cost." The player quotes that sentence and replies:

> let's focus on the one thing first

The assistant keeps the scenery work focused on nearby preparation and unloading. The timing of
route planning remains measurement context and does not open another optimization task.

## Coverage follows the routes the game offers

The measurement report calls its nearest/farthest calm-area BFS paths "synthetic routes" and
states that they omit daily closures and are not actual played routes. The player asks:

> synthetic routes -- by that you mean the paths we create? they are the most likely routes a player takes since other routes are blocked off

The assistant clarifies that the measured paths are simplified geometric stand-ins, not the
game's daily generated route choices, and will measure those generated choices with closures.

> and heavily discouraged

> only a very determined player would go off the path but also likely lose in the process

The game's generated viable routes are the primary coverage baseline for this investigation.
Deliberate off-path travel is a stress case rather than the expected scenery workload. Coverage
remains a model of offered routes, not a record of human trajectories.

## Unloading keeps a wider boundary than loading

The assistant reports that actual route coverage supports nearby preparation and that peak
memory savings depend on how far behind the player scenery remains loaded. The player asks:

> for unloading the radius should be bigger than for loading? that way you don't end up loading/unloading constantly when walking back and forth over the loading edge

The assistant confirms a smaller load boundary and a larger unload boundary. Already-loaded
scenery stays loaded between them, avoiding repeated recreation near the load boundary. The
exact gap remains to be measured against camera movement and preparation time.

In the PR review, the player explicitly confirms the larger unloading boundary:

> I do like the larger unloading be a requirement.

## Full review of the investigation PR

The player reviews the corrected route coverage and asks for the following changes. The two
design answers are also quoted in their corresponding sections above; the full review preserves
the reproduction and optional cleanup requests with their context.

> Review of bd026570 — not ready yet, two changes needed, then good to go.
>
> **1. Record my answers in the playtest and the queue.** Please add these, verbatim, to
> `docs/playtests/2026-09-30-gentle-swan.md` (it is new in this PR, so it can still take them):
>
> - Under "Unloading keeps a wider boundary than loading", on the larger unload radius:
>   > I do like the larger unloading be a requirement.
>
>   So "the player explicitly requires" stays as written in the queue entry, the decision
>   record and the description — it now rests on these words rather than on my earlier question.
>
> - Under "Boot prepares the nearby scenery", on what "the block around home" means:
>   > block around the home means plus margin otherwise you might get gaps
>
>   This is my answer, not your proposal. In
>   `docs/todo/2026-09-19-M159/prepare-static-visuals-ahead-of-view.md`, drop the
>   "**Proposed, not asked for:**" label on covering the home-centered initial viewport plus an
>   off-screen margin, and quote my sentence instead. In `docs/decisions/2026-09-19-M159-3.md`,
>   replace "Covering the home-centered view plus an off-screen margin is the assistant's proposed
>   interpretation" with my words. The exact margin is still unchosen; that part stays open.
>
> **2. Make the rerun commands work after the merge.** The two rerun blocks in
> `docs/evidence/m159-lazy-scenery-2026-09-30/README.md` and `ROUTES.md` run
> `git worktree add --detach` on `6aa23ba1` and `25e34fa0`. Both are commits that only exist on
> this branch, so a fresh clone fails once it is squashed and deleted. Add
> `git fetch origin refs/pull/444/head` before each `worktree add`, the way the M159
> danger-prediction evidence does for #439. GitHub keeps that ref after the branch is deleted, and
> both capture commits sit underneath it.
>
> **Optional, fix if you're touching the files anyway:**
>
> - The queue entry lost the sunny-lynx quote: "can we do them lazily instead whenever the player
>   gets into x tiles from them (when the image is still off-screen)?" Put it back alongside the
>   paraphrase.
> - "4 visible ground cells inside the home block" undersells it, since the home building covers
>   most of the block and has no ground cells under it. By area, the block fills about 18% of the
>   640×360 starting view. One clause saying so is enough.
> - `measure.py` and `measure_routes.py` default `--godot` to a macOS-only path
>   (`/Applications/Godot.app/...`). Require `--godot` or `$GODOT` instead.
> - The TileMapLayer docs link points at Godot 4.6; we're on 4.7.
>
> No need to rerun the probes. I checked every number in the tables against `results.json` and
> `routes.json`, and the measured source matches this head.

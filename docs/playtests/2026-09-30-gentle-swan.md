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

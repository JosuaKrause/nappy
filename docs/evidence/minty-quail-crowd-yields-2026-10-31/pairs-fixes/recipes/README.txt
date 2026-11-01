Run a recipe still (from a checkout, base or head), the way tools/scene-recipes.sh --screenshots does for its capture, plus --invincible:
  tools/shot.sh OUT.png SECONDS --recipe RECIPE.json --recipe-mode scripted --player-view --no-save --invincible
Needs, once per fresh worktree: godot --headless --import, tools/bake-atlases.sh, godot --headless --import again.
m1/m2 are the existing recipes of /tmp/c2b-runs/pics/recipes (dog-2.8, car-2.85). m3 is scene-recipes/trailer-trucks.json with a
crowd and three pinned walkers on the north sidewalk lanes of the junction; m4 is scene-recipes/tear-slide.json with seed 13 (its third
tear draws the pursuit marble), a crowd, and four pinned walkers crossing the main road; m5 is a market_stall / cafe_tables on a sidewalk
tile; m6-firetruck is scene-recipes/fire-truck.json with a crowd.
Base = origin/main 21171ee0, head = f9e82530. Same machine, same recipe, same seed.

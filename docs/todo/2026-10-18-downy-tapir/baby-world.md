# The baby reads the city's world after the building

**Found by reading, not run** (the codebase review filed in minty-quail). `Baby` caches its world
once, `_world = get_tree().get_first_node_in_group("world")` in `_ready()` (`src/player/baby.gd`,
near line 79). In the escape, `main` builds the building first, so the baby's `_ready` runs there;
when she leaves it, `main` (near lines 915-916) reparents the player into the city and `_ready` does
not run again. `InteriorScene` also stays in the tree and in the `world` group (only its collision is
freed, `take_the_walls_out()`), so even a fresh lookup would return it first.

If so, in the city section after a building start the baby asks the building for:
- her excitement (`excitement_sources_at`, answered by `InteriorEvents`, emptied by `stand_down()`):
  the city's trucks, vans, explosions and guards would cost her meter nothing;
- `is_alley` and `sleepiness_multiplier`;
- `decay_multiplier`, where city tiles that share the building's origin can land on the basement's
  rows and get its zero decay.

A boot straight into the city (`--start-escape` to the city) is unaffected. The player's last escape
run's log (`docs/evidence/escape-roadblock-2026-10-17/run-235901-seed4216201080-v0.28.0-7-g5f7923b6/run.log`)
shows the meter rising from city events, so the reading may be wrong or partial.

**First** confirm it headless: boot the escape from the building on that seed, walk out into the city,
and compare the meter's incoming excitement next to a city event with a straight city boot. **Then,
if it holds, the minimal fix:** the world is told, not discovered: `Baby.set_world(ctx)` called by
whoever places her, on every change of world, the way `main` already re-points the danger edge
(`_add_danger_edge()`). A test: after the handover, the baby's world is the city's and a city event's
field reaches her meter. If it does not hold, say what the run showed and close the item.

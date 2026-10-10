priority: now

# mossy-hawk — A movement script turns smoothly and ends where the abrupt one does · filed 2026-10-10

[dotted-wombat](../../playtests/2026-10-10-dotted-wombat.md), inbox #633, comment 1, in the
player's `now` band:

> can we make changing directions more smooth? in general when running a movement script we
> should have a smooth option where west 1s north 1s has a movement in 270 (left) then gradually
> going to 0 (north) in a way that the exact horizontal position ends up being the same as with
> the abrupt version (in the west north case; what I mean is they should end up in the same exact
> place no matter whether smooth is on or off). for the trailer I would want smooth to be on

The movement script is the compact walk string `AutoScreenshot._parse_script()` reads
(`src/dev/auto_screenshot.gd`): seconds followed by a direction letter, a capital letter for
running, `@<bearing>@` for a compass bearing, and a stand step. The dev flag `--walk` and a scene
recipe's `playback.walk` (`src/dev/scene_recipe_runtime.gd`, whose `_apply_input()` presses the
step's direction each physics tick) both use it, and the trailer's scenes are scene recipes
(`tools/trailer/shots.json`, [M204, the trailer from saved scenes](../../decisions/2026-09-25-M204.md)).

The items: [smooth-option.md](smooth-option.md), [trailer-turns-smoothly.md](trailer-turns-smoothly.md).

# The cities a few rigs rebuild are cached, and main is handed a ready map

**The ask.** On the board's test-isolation-plan, "yes" to its fifth step: cache the cities a few rigs
rebuild (inbox #1159 in gray-dolphin). On city-maps-later, "yes": the way to hand `main` a ready map
(`main.use_city_maps()`) is built with this cache, not with the hand-ins (inbox #1173 in gray-dolphin).

**Read as:** the finale, events and routes rigs build the same seed's city again and again; a cache
builds each once and hands a copy to each user. `main` takes a map source the same way, so a booted
suite can hand it the cached city instead of generating one.

**What it needs first:** a lossless copy of a `CityMap`. The scene recipe's serializer is not one:
`RecipeCityContext.capture()` then `restore()` loses `block_plans`, `block_layouts`, `calm_blocks`,
`playgrounds` and `recipe_trees`, and the copy fails `CityGenerator.validate()` with "only 0 calm
blocks, need 5" (found while designing #1166).

**Which map a test uses** stays writing-tests' rule (inbox #1172 in gray-dolphin): a booted day and every measurement
run on a real generated map, which is what the cache holds.

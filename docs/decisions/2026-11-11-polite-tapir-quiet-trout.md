# polite-tapir — The map interface's world half is split off WorldMap: the map hands out no navigator and holds no world · 2026-11-19

**What was asked.** polite-tapir's `standing-layer-breaks.md` holds the layer breaks
`tools/check_layers.py --list` prints; the player's words are that they are not forgotten (inbox #1268 in
olive-ferret). This group is "the map interface's world half": `WorldMap` (`src/world/world_map.gd`, the one
map interface the city's map and the building's map implement, in the model layer as the player chose, inbox
#904 in freckled-moose) named the world five times, holding the scene node that draws the map and handing out a
navigator and a draw layer. Fable's quota is out: Opus designed it in Fable's place (grassy-bison #1560) and a
Sonnet agent built it from the design; the pull request (#1570) carries the `fable-only` label and merged on its
Opus review, the player having lifted the hold for Fable ("we can lift the fable need there for now", "we can
just completely work without it for now. if it later finds any issues we can do follow ups", inbox #1571).

**What was built.** The world half is split off `WorldMap` and no class is added. `City.build()` builds one
`Navigator` over its map and keeps it; `SimulationBuilder.in_the_city()` is handed it; the building's events build
their own; every test rig's fallback is `Navigator.new(map)`. A navigator holds nothing but its map, so two over
the same map answer alike and nothing moves differently. The world that draws the map is handed on, not stored on
the map: `City` and `InteriorScene` stop writing `map.world = self`; `EventManager.draw_in(world)` hands it to the
spawner, each live event and the spread look (`EventInstance.add_slices_beside_it()`); `SteamGrates.lay()` is
handed the building; `main` hands the baby the world and asks the world node what its ground does to her.
`WorldMap.step()` (called by nothing), `navigator()`, `world`, `has_world()`, `add_entity()` and `process_player()`
are deleted. The three exceptions (`DrawLayer`, `Navigator`, `WorldContext`) leave `tools/layer_map.py` and the
five `world` lines leave `tools/field_reads.txt`; nothing is added to either. One reader the design missed, the
building's event rig in `tests/building_events.gd`, is handed the building too.

**Rejected** (the design's, each with its reason in the pull request's description): a permanent exception in
designing-classes (a model object would keep holding a scene node); a world-layer bundle of map, navigator and
world (about 30 signatures for callers that need only the map); moving `Navigator` into the model (it names
`ChaseWay`, world layer); moving `WorldMap` into the world (overturns inbox #904 in freckled-moose); callables
instead of the `WorldContext` (the same thing served two ways); building only the part outside #1548's files
(none of the five uses goes until the last reader does).

**Open to overturn (the designer's, and Fable's to look over when it is back):** a setter, `EventManager.draw_in()`,
rather than a new parameter of `setup()`; the city keeping its navigator (`City.navigator`) while the building's
events build their own; building it as its own pull request ahead of row 3b of minty-quail's `event-interface.md`,
which takes the hand-off as it finds it.

**The item.** The group leaves `standing-layer-breaks.md`'s list; the sentences in polite-tapir's and
minty-quail's READMEs about the building's `WorldMap.world`, and `WorldMap.world` under row 2b's "Left listed"
in `event-interface.md`, go with it.

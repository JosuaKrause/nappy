# azure-beaver — The task scenes are a handcrafted stretch with a rigged marble bag · 2026-10-05

Filed from [polite-dolphin](../playtests/2026-10-04-polite-dolphin.md) (inbox #555): "it should be 1)
only one stretch of a city with nothing (no ground!) off the path at all. and pedestrians etc and
deterioation and events should spawn like in a real game -- but authored", then "the whole point of
those scenes is that they are not seeded but handcrafted -- you can use a seed to create it. but then
everything should be placed manually. the events should still spawn using the same rules but the
marble bag should be rigged", the width "The streets she walks", and "right now it's just empty" /
"that's not a good test".

**Built.** Every task scene is a stretch (`extent: {"scope": "stretch"}` in its recipe): the streets she
walks from her start to the mark to the target, and nothing off it — no ground, building, shadow, tree
pit or decal, with a wall of collision along the void (`VoidEdge`). The recipe lists every placed thing:
each tile by type, the fronting buildings (district, variant, height, condition), street trees, props,
litter, cracks and posters; the dawn pastes nothing of its own. `tools/scene-draft.sh` writes that first
draft from a seed and the recipe's own route, plays it and adds the ground under any guard left in the
void, and every scene was drafted with it and then edited by hand; drafting again gives the same file.
Events come by the game's own rules from a rigged bag (`setup.route_bag`: marbles, pre-bag, owed, first
after), through `EventManager.start_recipe_route()`. The crowd covers the stretch, and walkers and cars
leaving where a street runs into the void come back at another such end. Every scene has a drafted
crowd, cracks, litter and posters, and rigs a cat ahead of the day's bag; new observations check the
cat came (`appeared`) and the crowd moves (`crowd`). All 21 saved scenes pass `tools/scene-recipes.sh`.

**The generated city stays behind the stretch** — a choice where the entry proposed the opposite. The
entry proposed that "the scene loads only the recipe, so it does not change when generation does"; but
the day's rules ask about the whole city (what is reachable from home, the district regions, the
neighbor's walk home), which a stretch alone cannot answer. So the city is still generated, it must
match the recipe tile for tile, lot for lot and tree for tree, and a scene that no longer matches is
refused by name (`stretch.witness`) rather than drawn over: a scene never changes silently when
generation does. Open to overturn.

**Chosen while building, open to overturn:**

- The stretch is every street segment she steps on, whole, with the junction at each end; off the
  street the tiles she walks and those beside them, an alley she enters whole, the area round each
  place the task pins, the start guard with his alley, and day 10's neighbor's way home. Day 12's park
  is a patch round her path and the swing.
- "Fronting buildings" are every lot next to a stretch tile, diagonals included.
- The starting crowd is a morning crowd standing on the stretch, with no car in her view at the start.
- Each bag is the day's own with one cat in front, due at 3s.
- Task targets stand on the stretch's streets, several moved within the asserted 540–644px (day 6's
  man shouting at 572px, the van at 545px, the roadblock at 621px). Day 6 takes a new route and ends at
  11s; days 6, 7, 8 and 13 take their first leg at 85° instead of due east.
- The fire-truck and trailer scenes stay whole-city scenes; the station door's scene is a stretch.
- On day 9 and at the station-door corner nobody is sent after her: the stretch has no ground far
  enough away for the robber to start from.

Not verified: free play in each scene in a window. On days 6–8 the rigged cat is sited inside a
building lot and never runs into view, as it does on the whole city.

## The player chooses full handcrafted layouts

On 2026-10-08, [mossy-marmot](../playtests/2026-10-08-mossy-marmot.md), inbox #618,
recorded the request to finish every open PR. Asked whether to complete independent layouts
inside this PR or retain the generated layout and handcraft later, the player selected
"Finish fully handcrafted layouts now (Recommended)". This rejects the generated-city
dependency described above. The unfinished construction work is retained in azure-beaver's
queue item until the scene loads explicit data without a generated witness.

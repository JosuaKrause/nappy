priority: now
after: 2026-09-27-olive-badger

# azure-beaver — The task scenes are a handcrafted stretch with a rigged marble bag · filed 2026-10-04

[polite-dolphin, the task scenes](../../playtests/2026-10-04-polite-dolphin.md) files the rest of
inbox #555, about busy-raven's task scenes ([busy-raven](../../decisions/2026-10-03-busy-raven.md)):

> also it seems like you created a full city? it should be 1) only one stretch of a city with nothing (no ground!) off the path at all. and pedestrians etc and deterioation and events should spawn like in a real game -- but authored

Asked how the spawning should be "like in a real game — but authored" (options: the real scheduler,
seeded; an authored list with real mechanics; both), the player wrote:

> the whole point of those scenes is that they are not seeded but handcrafted -- you can use a seed to create it. but then everything should be placed manually. the events should still spawn using the same rules but the marble bag should be rigged

Asked how wide the path is, the player chose "The streets she walks": every tile of the street
segments along her route from start to mark to target, both sidewalks and the carriageway, crossings
and corners; everything else void. And then:

> right now it's just empty

> that's not a good test

**Asked for:**

- Each task scene is **one stretch of city**: the streets she walks from her start to the mark to the
  target, and **nothing off it, no ground** drawn beyond.
- The scene is **handcrafted**: a seed may generate a first draft, but then **everything is placed
  manually** in the recipe (what stands along the stretch, its deterioration, its pedestrians and
  traffic), so a scene does not change when generation does.
- **Events spawn by the game's own rules**, with **the marble bag rigged**: the scene fixes what the
  bag holds, so she meets what the scene author chose, arriving the way a played day brings it.
- A scene is not empty: pedestrians, deterioration and events are there as in a real day.

**What exists.** Each scene is built on a full generated context city (`context_seed` 1917501, run
seed 11) with no background crowd and only the events the recipe names
(`docs/SCENE_RECIPES.md`: "Only explicit selections install events. The normal event scheduler and
director do not fill authored scenes"). Events drawn from a marble bag on her route are
[olive-badger](../2026-09-27-olive-badger/README.md), not built yet; this entry waits on it.

**Proposed, not asked for:**

- A tool turns a seed and a route into a first-draft recipe that lists every placed thing
  explicitly (tiles of the stretch, buildings fronting it, decals and other deterioration, posters,
  starting pedestrians and cars), which the author then edits; the scene loads only the recipe.
- "Spawn like in a real game" for pedestrians and cars read as: the recipe places the starting
  population, and the crowd's ordinary recycling keeps it going inside the stretch.
- "The marble bag rigged" read as: the recipe gives the bag's contents (and, if wanted, the pre-bag
  that fixes the first draws), and olive-badger's route bags draw from it.
- The stretch ends at its last tiles: walkers and cars leaving it are recycled at its ends, and the
  camera shows void beyond.

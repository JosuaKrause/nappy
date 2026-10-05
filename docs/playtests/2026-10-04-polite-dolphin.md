# Playtest polite-dolphin — The task scenes start a walk from the mark

2026-10-04. One note captured in the session, #555, about busy-raven's task scenes. The player's
words are copied word for word, after what they answered.

## #555 — busy-raven scenes: she does not start on the mark

Said on 2026-10-04 after being given the commands for the busy-raven task scenes
(`tools/run.sh --recipe scene-recipes/task-06-note.json` ... `task-14-last-night.json`,
`fire-truck.json`, `station-door-corner.json`), told that "each task scene starts with her at the
chalk mark, the task already offered"; the record lists "the mark already read when the scene
begins" as open to overturn.

> make them not start *on* the mark

Asked on 2026-10-04: "The task scenes start with her standing on the chalk mark, the mark already
read and the day's task offered (your #513 answer said the task is offered from the start). When she
starts off the mark, what should the mark be?" Options: "Unread, walk to it (Recommended)" — she
starts a short walk from the mark (about 150px, out of its notice), the mark unread; reading it
offers the task and places the target exactly as a played day does; "Read, start beside it" — the
task still offered from the first frame and the arrow live, but she stands a short step off the mark.

> Unread, walk to it (Recommended)

Said on 2026-10-04 right after asking that the task scenes not start on the mark. Each busy-raven
task scene is built on one generated context city (`context_seed` 1917501, run seed 11) with no
background crowd; only the events the recipe names are installed.

> also it seems like you created a full city? it should be 1) only one stretch of a city with nothing (no ground!) off the path at all. and pedestrians etc and deterioation and events should spawn like in a real game -- but authored

Asked on 2026-10-04, two questions. (1) "For the task scenes as one stretch (mark → target, nothing
drawn off the path), how should events, pedestrians and deterioration be 'like in a real game — but
authored'? Today a recipe installs only the events it names, by hand, and the day's scheduler never
runs in a scene." Options: "Real scheduler, seeded (Recommended)"; "Authored list, real mechanics";
"Both". The first answer below is the player's own text. (2) "How wide is 'the path' that gets
built?" Options: "The streets she walks (Recommended)" — every tile of the street segments along her
route from start to mark to target, both sidewalks and the carriageway, crossings and corners,
everything else void; "Only her own tiles". The last two lines were said right after.

> the whole point of those scenes is that they are not seeded but handcrafted -- you can use a seed to create it. but then everything should be placed manually. the events should still spawn using the same rules but the marble bag should be rigged
> The streets she walks (Recommended)
> right now it's just empty
> that's not a good test

## #557 — Fire-truck scene: the burning building is on screen at the start

Said on 2026-10-04 while playing the busy-raven scene `scene-recipes/fire-truck.json`, which starts
her at the doorstep on day 3 with `burning_building` named, the fire 432px west, documented as "out
of her view".

> the fire truck scene starts too close to the start -- the building is already on screen

## Routing

1. **#555, not on the mark** → built in the pull request that files it: the task scenes of days 6 to
   13 start her a short walk from an unread mark, overturning busy-raven's "the mark already read
   when the scene begins" ([busy-raven](../decisions/2026-10-03-busy-raven.md)) and, for those
   scenes, #513's "the day's task offered from the start".
2. **#555, a handcrafted stretch** → [azure-beaver, the task scenes are a handcrafted stretch with a
   rigged marble bag](../todo/2026-10-04-azure-beaver/README.md), after olive-badger.
3. **#557** → built in the same pull request: the fire-truck scene starts with the whole burning
   building out of view.

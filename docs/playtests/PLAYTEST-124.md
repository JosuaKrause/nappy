# Playtest 124 — Her building is the home square, and a blank ground floor has a door

2026-09-23. Said in conversation, in answer to M185, a ground floor is blank wall or shops, as
built on `feature/ground-floor-blank-or-shops` (PR 298), with stills of a commercial, a
residential and an industrial street and of her own building
(`docs/evidence/m185-ground-floor-2026-09-23/`). No run was played.

## What was put to the player

A multi-story building's ground floor is drawn as storefronts or blank wall, never windows;
her own building keeps its ground-floor windows. Her home's door is cut into the home block
rather than belonging to one building, so the build counted every building on the home block as
hers. The question: keep the whole home block as hers, or narrow it to the building her door is
in (the orchestrator's pick).

## What the player said

> "Her building is the entire home square. We should probably not randomize it."

1. **Her building is the whole home block**: every building on it keeps its ground-floor
   windows, as built.
2. **"We should probably not randomize it."** What "it" is was not said; asked back in the
   session (see `docs/TODO.md`, M185).

> "Another thing. Now that we don't have groundfloor windows (to have places for posters) we need
> entrances. If there is no store front we need one entrance door per building front (if it's
> multistory). Single story can still keep windows only (no posters on them)"

3. **A multi-story building front with no storefront has one entrance door.** With the windows
   gone from the ground floor, a front needs a way in; a storefront already is one.
4. **A single-story front keeps its windows and no door**, and carries no posters.

## Then, while the doors were being built

> "Also let's redo the store fronts as well"

5. **The storefronts are redrawn** to the same bar as the new doors, in one style with them.

## Then, on the doors, the redrawn storefronts and the two SVG reworks

Asked what "we should probably not randomize it" meant, with the orchestrator's reading (the home
block looks the same on every seed), and shown the doors and storefronts on PR 298 and the redrawn
animals (PR 300) and street obstructions (PR 301):

> "Yes, the home block should have fixed visuals. That way we can craft a convincing house that
> also matches with the interiors of the escape."

6. **The home block has fixed visuals**, the same on every seed, so it can be crafted into a
   convincing house that matches the escape's interiors.

> "All graphics look okay so far. We can merge them. I will have a closer look later and probably
> ask for some more changes but for now it's a clear improvement."

7. **The doors, the storefronts, the animals and the street obstructions are accepted for now**
   and merged; a closer look may bring more changes.

> "Only thing so far is the new standard door (industrial door and home door look fine). It pops
> out. But that is probably because the other parts of the buildings (walls, windows, fire
> escapes, etc) are not updated and look flat in comparison. So if say we update all those too
> and then have another look at the overall picture. Meanwhile let's merge what we have"

8. **The standard entrance door pops out** against the rest of the front; the industrial door
   and the home door look fine.
9. **The rest of the building is redrawn to the same bar** — walls, windows, fire escapes and the
   other parts — and then the whole picture is looked at again.

## Then, on the redrawn building fronts (M186, PR 303)

> "Fire escapes don't reach a ground floor. They always end one floor above"

10. **A fire escape ends one floor above the ground**: its lowest landing is at the first floor,
    and no flight comes down to the sidewalk.

## Then, on the first-floor fire escape (PR 303, at 81251559)

> "also, fire escape ladders. the graphics for them are good -- I like the variation with the
> flower pot. the placement is wrong. you start at the bottom of the top floor then the same
> texture gets placed on each floor. on the ground floor you only place the platform -- without a
> ladder (so from a certain angle that means there is no fire ladder on the ground floor). so if
>
> w - wall
> f - current fire escape texture
> t - only the platform of the fire escape at the top end of the texture
>
> a building looks like this
>
> ```
> wwwwwwww
> wfwwwwfw
> wfwwwwfw
> wfwwwwfw
> wtwwwwtw
> ```
>
> five story building for example"

12. **The fire escape graphics are good**, the potted-plant variant included.
13. **A fire escape climbs the whole front, one piece per floor**: the current texture is placed
    on every floor from the bottom of the top floor down, and the ground floor carries only the
    platform at the texture's top end, with no ladder — so nothing of the escape comes down to
    the sidewalk. In the example, a five-story front has the escape on its three middle floors,
    the platform alone on the ground floor, and plain wall on the top floor.

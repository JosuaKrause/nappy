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

## Then, on her own building

> "The home has windows behind the door. Let's remove them"

11. **No window shows behind her front door**: the ground-floor window drawn on the home block's
    wall where the door stands is removed, so the door stands on plain wall.

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

## Then, on which fire escape picture is stacked

> "the diagonal stairs are okay -- also, don't alternate the sides -- make both stairs face the
> same direction. always"

14. **The stacked fire escape is the balcony with its diagonal flight** hanging below it, the
    first redraw: the flight comes down from each balcony to the one below.
15. **Every flight faces the same direction, always**: the flights do not alternate up a stack,
    and the two variants are not mirrored.

> "you need to derive a texture without stairs though"

16. **The ground floor's platform is its own texture**, derived from the stair picture with the
    stairs taken out, rather than the stair picture cut short.

> "a two floor building cannot have a fire escape"

17. **A two-story building has no fire escape**; the fewest floors that carry one is three.

## Then, on the stacked fire escapes (PR 303, at 7da73f8a)

> "okay, the fire escapes look good now -- the flower pot version should be chosen at random. a
> wide building front could support two fire escapes but only if there is enough of a gap between
> them (at least 1.5 full fire escape widths between them)"

18. **The stacked fire escapes look good.**
19. **The flower pot is chosen at random**, balcony by balcony, rather than standing on every
    balcony of one variant.
20. **A wide front may carry two fire escapes**, but only with a gap of at least one and a half
    full fire escape widths between them.

## Then, on the closures across the street (M187, PR 306, at 35bbefe9)

> "the top construction pole is drawn above the barried when it should be behind"

21. **On an end-on roadworks barrier the far end post is drawn behind the barrier**, not over
    it; only the near post stands in front.

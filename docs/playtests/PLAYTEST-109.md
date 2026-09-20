# Playtest 109 — The baked pages: their shape, their dead space, and what is always loaded

2026-09-20. Said in conversation after the player ran `tools/bake-atlases.sh` and read the page
sizes it printed, while the first three consumer moves of M171, build-time atlases replace
individual textures, were in review. No run attached.

## What the player said

On the `.import` sidecars, after the bake and the loader had merged:

> "does that mean we also don't need .import files anymore?" · "after the initial atlas pr
> merges?"

On the release order:

> "let's cut it now before the atlas work fully lands" · "after atlas we cut a new minor version"

On the pages the bake printed:

> "a few notes. are overly horizontal pictures okay? it would be better to arrange things in a
> more squarish image (take the total number of cells and use the square root of it to define
> the width). putting both genders in the player atlas is a bit wasteful since it's guaranteed
> to not use half of it. any better approach for this? there is also a lot of dead space in eg
> the street_kit. the UI and head indicators could be combined. also, those are textures that
> should always be loaded. we cannot start loading something in the frame we need it. UI
> elements should always be there. events also has a lot of dead space"

On the answer offered for the dead space — a row width from the square root, members placed
by descending height, and a full rectangle packer only if a fill floor could not be met:

> "no, if you don't use a proper full rectangle packer you will always get dead space even if
> you start with big textures. you will get dead space where you can easily put smaller things.
> we don't need a perfect rectangle packing. a greedy approach is fine but don't let obvious
> empty space go wasted."

## What the bake printed, which is what the notes are about

| group | members | page |
|---|---:|---|
| buildings | 40 | 1810×68 |
| crowd | 30 | 854×50 |
| decoration | 13 | 464×56 |
| events | 261 | 2042×382 |
| ground | 89 | 2042×70 |
| head_indicators | 5 | 134×30 |
| interior | 41 | 1948×260 |
| street_kit | 13 | 1096×260 |
| stroller | 65 | 1812×50 |
| ui | 6 | 782×132 |

Measured from `assets/atlases/baked/regions.json` the same day, as member area over page area:
interior 27%, street_kit 46%, buildings 51%, events 57%, decoration 59%, ground 64%, crowd 73%,
head_indicators 74%, stroller 82%, ui 95%. The shelf packer fills one row to 2048px before it
opens the next, so a group under 2048px of total width is a single strip, and a row is as tall
as its tallest member: `street_kit` and `interior` each hold one picture 256px tall beside
members of 16 to 32px, and `events` holds one of 200px.

## What is asked for, as statements

1. **A page is roughly square.** The page width comes from the square root of the group's total
   size — the player's words: "take the total number of cells and use the square root of it to
   define the width" — and not from filling a 2048px row first.
2. **Dead space goes, by a rectangle packer.** `street_kit` and `events` are named; the
   measurement adds `interior` and `buildings`. Rows sorted by height were offered and refused:
   a row beside a tall picture still leaves room "where you can easily put smaller things". The
   packer tracks the free rectangles a placement leaves and puts later, smaller members into
   them. It is greedy and need not be optimal — "we don't need a perfect rectangle packing" —
   and it does not "let obvious empty space go wasted".
3. **The player page does not hold the parent the run never draws.** Asked as a question — "any
   better approach for this?" The parent is fixed for a run (`GRAPHICS.md`: carrying changes and
   texture resolution never reroll it), so the answer offered is three groups — the mother's
   views, the father's views, and the pram with the baby, which both share — with `Stroller`
   acquiring the pram's and the one parent's.
4. **The UI and the head indicators are one group.**
5. **That group is always loaded**, from boot: "UI elements should always be there."
6. **Nothing starts loading in the frame that needs it.** "we cannot start loading something in
   the frame we need it." A group is acquired ahead of its first draw — at boot, or behind the
   screens that already cover a wait — and never from a draw call or from the frame a thing
   first appears.
7. **The `.import` sidecars** of sources that leave the imported tree are deleted with the move,
   in M171's last item; the answer given is recorded there.
8. **The release after M171 closes is a minor version.** v0.13.1 was cut on 2026-09-20 ahead of
   the consumer moves, at the player's word.

# Playtest 123 — The leader is not a nice fellow, and the wanted notice shows people

2026-09-23. Said in conversation, in answer to the first poster review sheet for M180, posters
she notices, and loudspeakers that are somewhere
(`docs/evidence/poster-art-review-2026-09-23.png` on `feature/poster-art`). No run was played.

## What was put to the player

The sheet drew four kinds of poster and a torn one, each a 20×25px sheet on a 32×32 tile, and
three building fronts at the densities of day 4, day 8 and day 12. Three points were asked: the
uniform sheet's emblem (a ring with an upside-down T inside it), which the drawing agent was
least sure "resembles nothing real" and which the orchestrator read as a little like a power-off
icon; the leader's face, which read as blocky, more emoji than portrait; and every poster
sitting on the wall's lowest row.

## What the player said

> "the leader's portrait looks too neutral -- maybe something more grumpy looking. the leader is
> not going to be a nice fellow. in the rules start each line with a two pixel vertical line then
> a one pixel gap then the line (ie "| _________"). the wanted notices make clear that those are
> faces. it's not at all obvious right now. do a proper person silhouette. what is the model
> making those images? use opus 5.5. the posters are too big on the wall (they touch the floor)
> there should be gaps on all four sides of the tile. also, what does the torn poster look like?
> having only one row of posters is fine. also, yes, let's make people less blocky."

## Statements

1. **The leader's portrait is grumpy, not neutral**: "the leader is not going to be a nice
   fellow". Still nameless and resembling nobody real.
2. **Each printed line on the rules notice starts with a two-pixel vertical bar, a one-pixel
   gap, then the line** — "| _________". The curfew sheet is the same notice, so it follows.
3. **The wanted notice's faces read as faces**: "do a proper person silhouette" — head,
   neck and shoulders in each slot, where the first attempt read as nothing in particular.
4. **People on posters are less blocky**: the leader's portrait and the wanted notice's figures
   alike.
5. **A poster is smaller on its tile, with a gap on all four sides**: the first attempt touched
   the floor.
6. **The torn poster is shown on its own**, since the sheet only showed it on a wall, where it
   could not be told apart.
7. **One row of posters on a wall is fine.**
8. **Drawing is done by Opus 5.5**: "what is the model making those images? use opus 5.5". The
   first attempt was made by a Sonnet agent, the orchestrating skill's default for
   implementation.
9. **The emblem was not commented on**, so it stands as drawn until the player says otherwise.

## Later the same day, on the second pass

The orchestrator had offered a prompt for generating the posters with an image model, and
showed the second sheet (a grumpy leader, bar-gap-line rules, head-and-shoulders silhouettes, a
margin on every side). The player had said of the torn poster: "the 'torn poster' looks nothing
like a torn poster. let me create some references".

> "I don't want PNGs yet -- I'm giving you the references so you can make the stylized SVGs -- I
> will use codex later to convert to png using the appropriate skills. unless claude has an image
> creation tool now the png creation is a codex only task. the second pass looks better already.
> one note, for the posters to work there needs to be spaces without windows on the ground floor
> otherwise poster will be put over windows which doesn't make sense."

10. **The torn poster is redrawn as a stylized SVG from the player's reference photos**; no PNG
    comes before the SVGs are settled.
11. **PNG conversion is Codex's**, with the illustrated-png skill, since Claude Code has no image
    generator. A Claude session does not write image-model prompts for it.
12. **The second pass is better** than the first.
13. **A ground floor has stretches of wall without windows, and posters go there.** A poster
    pasted over a window makes no sense, so the building fronts owe blank wall on the ground
    floor for the posters to use.

## Then, sending a reference

The player sent a generated reference sheet for the posters in the conversation: the leader, the
rules, the curfew sheet, the uniform sheet with a phi-like emblem, and the wanted notice plain
and crossed. The orchestrator asked for it as a file, since a pasted image cannot be read by an
agent.

> "note, some poster types are repeated"

> "btw the docs/evidence folder is a mess. it's good for keeping raw evidence but art style
> references should be in their own folder that is easy to find (no intermediate folders that
> have lots of files/folders)"

14. **The reference sheet repeats some kinds**: the repeats are the same poster, not new kinds.
15. **Art style references live in a folder of their own, easy to find**, with no intermediate
    folder full of other files on the way to it. `docs/evidence/` keeps raw evidence only.

> "I cannot get a good reference for the ripped off poster. let opus give it a try and I'll
> review."

16. **The torn poster is drawn without a reference**, by Opus, and comes back to the player for
    review.

## On the power station, the same session

The orchestrator showed M183's first stills (the power station and the blackout): a door view,
where the hall's front reads as an apartment block, and a 4x crop of the overview, and proposed
redrawing the street front with high industrial windows, a heavy door, a hazard band and the
yard seen through its fence. It asked whether a power-station reference was wanted.

> "maybe for the full picture zoom out from the regular view instead of zooming in from the
> overview"

> "also, yes, go ahead and let opus try"

17. **A whole-building picture is the ordinary view zoomed out**, not an enlarged crop of the
    overview.
18. **The station's street front is redrawn by Opus** as proposed, without a reference, for the
    player to review.


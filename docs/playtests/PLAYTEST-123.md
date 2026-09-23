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

## The reference sheet stays in the conversation

> "I can't get a good reference right now"

19. **The pasted reference sheet is not in the repository**, so the orchestrator's description
    of it stands in for it. What it showed, per kind: *the leader* — a detailed, jowly, scowling
    middle-aged man with receding hair, heavy brows and a hard stare, dark suit, on a gray
    backing, a dark band across the bottom; *the rules* — a dark header bar, then four entries,
    each a short dark vertical bar beside two gray print lines, and a round red stamp with a
    diagonal slash overlapping the lower right; *the curfew sheet* — the header, a large plain
    clock (hands near four) with tick marks, then two bar-and-two-lines entries and the same
    stamp; *the uniform sheet* — near-black, with a cream emblem: a ring with a vertical bar
    through it that stands out above and below, on a flat foot bar, like the letter phi on a
    base; *the wanted notice* — gray-beige paper, a dark header, four mugshot frames each with a
    dark head-and-shoulders silhouette and two print lines beneath it, and in the crossed copy a
    red X over the bottom-left face. Flat fills, clean dark outlines, muted colors; the repeats on
    the sheet are the same kinds (statement 14).

## On the fourth pass, the torn variants, the station and the masts

The orchestrator showed the fourth poster sheet (drawn from the player's reference sheet), the
three torn variants (A the leader, B the rules with a flap, C the uniform sheet), the power
station's redrawn street front, and asked which torn variant to keep.

> "yes, one per kind or make it a mask that can be applied on a given poster (subtractive
> composite). all three looks good. vary between the torn pattern. power station looks good.
> mast in 292 is weird. it's in the middle of the road"

20. **A torn poster exists for every kind**, either drawn per kind or as a tear mask applied to
    any poster by subtractive composite.
21. **All three torn variants are good, and the tear pattern varies** between them.
22. **The power station's redrawn front is accepted.**
23. **A loudspeaker mast does not stand in the middle of the road**: the one in PR 292's picture
    does.

> "can you have an opus agent redraw the water main break image?"

24. **The burst water main's picture is redrawn by Opus**, with no complaint given beyond that.

On the tear-mask sheet (three tears applied to every kind, on single blank wall cells) and the
fourth pass's building fronts:

> "also have plain walls -- you had that in one of the poster examples but they are gone now --
> and it looks like posters go over windows now"

25. **The building fronts show plain walls**: stretches of ground floor with no window, visibly
    so, as one of the earlier sheets had, and not a window cell with a poster where the window
    would be. On the fourth pass's fronts a poster sat in the window rhythm and read as pasted
    over a window.

On the sixth pass's fronts (plain stretches of wall between window bays, posters only there):

> "you can make it a placement rule for multi-story buildings that the ground floor is either a
> blank wall (for posters later) or shops -- never windows -- the home building is an exception
> to that rule"

26. **A multi-story building's ground floor is blank wall or shops, never windows.** Blank wall
    is where posters go later. **Her own building is the exception** and keeps its ground-floor
    windows.

On the combined sheet (every kind intact and torn three ways, and fronts with plain wall):

> "posters all look good now"

27. **The poster art is accepted**: the six intact sheets, the three tear masks and the look of
    posters on plain wall.

> "hmm, there is no version of the wanted poster without X anymore?"

28. **The wanted notice has a version with no X.** Both drawn copies crossed the top-right face.
    The orchestrator split it three ways, open to overturn: no X; the neighbor's slot crossed
    only (a failed day 10); another face crossed only, so a wall can show "some crossed out in
    red" on a run where the neighbor was warned.

> "only one X and two Xs?"

29. **The wanted notice's copies are no X, one X and two Xs**: the one-X copy crosses another
    face, and the two-X copy adds the neighbor's slot, for a run where day 10 failed. This
    replaces the orchestrator's split in statement 28.

The orchestrator pointed out that the one-X copy crosses a face that is never the neighbor's, so
the neighbor's cross is always the second, and asked whether to keep a no-X copy as well.

> "if it's always Xed out then it cannot be mistaken with the neighbor" · "only X and double X"
> · "sgtm"

30. **The wanted notice has two copies: one X and two Xs.** The one-X copy crosses a face that is
    never the neighbor's; the two-X copy adds the neighbor's slot. There is no copy without an X,
    which replaces statements 28 and 29.

Asked about the day-8 front, where two uniform sheets sit slightly off-center over older sheets
and a sliver of the older one shows at an edge, as the M180 progression's "pasted over the older
ones" asks:

> "one note -- it looks like there was an attempt to put multiple posters on top of each other?"
> · "it looks odd -- the offset should be a bit bigger so it doesn't look like a glitch"

31. **A poster pasted over an older one is offset enough to read as deliberate**: more than a
    sliver of the older sheet shows, so it does not look like a drawing glitch.

> "some posters that are pasted over old ones can also just plain replace them"

32. **A new poster may cover an old one exactly**, replacing it, as well as being pasted over it
    with a visible offset.

> "if it's visibly over pasted for all of them then it will look weird"

33. **Visible overpasting is the exception**: most new sheets replace the old one exactly, and
    only some are pasted over it with an offset.

On the retaken mast still (PR 292) and the burst water main's redraw (PR 295), which adds a
fountain, a crater that reads as a hole, the split pipe and lamp-topped barriers:

> "mast looks fine now, too" · "new water main looks good"

34. **The loudspeaker mast's picture is accepted**, standing off the road.
35. **The burst water main's redraw is accepted**, fountain included.

